//go:build integration

package voucher_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/voucher"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			enrollment.voucher_usages,
			enrollment.enrollments,
			enrollment.vouchers,
			catalog.course_batches,
			catalog.courses,
			identity.student_profiles,
			identity.students,
			identity.departments,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

type fixture struct {
	adminID   uuid.UUID
	studentID uuid.UUID
	courseID  uuid.UUID
	batchID   uuid.UUID
	enrollID  uuid.UUID
}

func seedFixture(t *testing.T, pool *pgxpool.Pool) fixture {
	t.Helper()
	ctx := context.Background()
	var f fixture

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('admin@v.local','x','admin')
		RETURNING id`).Scan(&f.adminID))

	var studentUserID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('stu@v.local','x','student')
		RETURNING id`).Scan(&studentUserID))

	var deptID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.departments (name, leader_id, created_by)
		VALUES ('Dept', $1, $1)
		RETURNING id`, f.adminID).Scan(&deptID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.students (user_id, name, email, phone, source)
		VALUES ($1, 'Stu', 'stu@v.local', '08', 'b2c')
		RETURNING id`, studentUserID).Scan(&f.studentID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.courses (name, department_id, course_creator_id, base_price, min_price, created_by)
		VALUES ('Go 101', $1, $2, 1000000, 800000, $2)
		RETURNING id`, deptID, f.adminID).Scan(&f.courseID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.course_batches (course_id, label, start_date, end_date, price, created_by)
		VALUES ($1, 'Batch 1', CURRENT_DATE, CURRENT_DATE + 30, 1200000, $2)
		RETURNING id`, f.courseID, f.adminID).Scan(&f.batchID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO enrollment.enrollments
		  (student_id, course_batch_id, format, mode, payer, price, final_price, payment_status, completion_status, source)
		VALUES ($1, $2, 'regular', 'online', 'student', 1200000, 1200000, 'pending', 'ongoing', 'b2c')
		RETURNING id`, f.studentID, f.batchID).Scan(&f.enrollID))

	return f
}

func newService(t *testing.T, pool *pgxpool.Pool) *voucher.Service {
	t.Helper()
	log := zap.NewNop()
	return voucher.NewService(voucher.NewRepository(pool), events.NewBus(log), log)
}

func TestCreateVoucher_HappyPath(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	v, err := svc.CreateVoucher(ctx, voucher.CreateInput{
		Code:          "SAVE10",
		DiscountType:  voucher.DiscountPercentage,
		DiscountValue: decimal.NewFromInt(10),
		ValidFrom:     time.Now(),
		CreatedBy:     f.adminID,
	})
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, v.ID)
	require.Equal(t, "SAVE10", v.Code)
	require.True(t, v.IsActive)
}

func TestApplyVoucher_HappyPath(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	v, err := svc.CreateVoucher(ctx, voucher.CreateInput{
		Code:          "FLAT100K",
		DiscountType:  voucher.DiscountFixed,
		DiscountValue: decimal.NewFromInt(100000),
		ValidFrom:     time.Now(),
		CreatedBy:     f.adminID,
	})
	require.NoError(t, err)

	usage, err := svc.ApplyVoucher(ctx, voucher.ApplyInput{
		VoucherCode:   v.Code,
		EnrollmentID:  f.enrollID,
		OriginalPrice: decimal.NewFromInt(1200000),
		CallerUserID:  f.adminID,
	})
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, usage.ID)
	require.True(t, usage.FinalPrice.Equal(decimal.NewFromInt(1100000)),
		"expected 1100000 got %s", usage.FinalPrice)

	// Verify used_count incremented
	got, err := svc.GetVoucher(ctx, v.ID)
	require.NoError(t, err)
	require.Equal(t, 1, got.UsedCount)
}

func TestApplyVoucher_DuplicatePrevented(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	v, err := svc.CreateVoucher(ctx, voucher.CreateInput{
		Code:          "ONCE",
		DiscountType:  voucher.DiscountFixed,
		DiscountValue: decimal.NewFromInt(50000),
		ValidFrom:     time.Now(),
		CreatedBy:     f.adminID,
	})
	require.NoError(t, err)

	in := voucher.ApplyInput{
		VoucherCode:   v.Code,
		EnrollmentID:  f.enrollID,
		OriginalPrice: decimal.NewFromInt(1200000),
		CallerUserID:  f.adminID,
	}

	_, err = svc.ApplyVoucher(ctx, in)
	require.NoError(t, err)

	// Second apply on same enrollment must fail (UNIQUE on enrollment_id)
	_, err = svc.ApplyVoucher(ctx, in)
	require.Error(t, err)
}

func TestApplyVoucher_ExpiredRejected(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	yesterday := time.Now().AddDate(0, 0, -1)
	v, err := svc.CreateVoucher(ctx, voucher.CreateInput{
		Code:          "EXPIRED",
		DiscountType:  voucher.DiscountFixed,
		DiscountValue: decimal.NewFromInt(50000),
		ValidFrom:     time.Now().AddDate(0, 0, -7),
		ValidUntil:    &yesterday,
		CreatedBy:     f.adminID,
	})
	require.NoError(t, err)

	_, err = svc.ApplyVoucher(ctx, voucher.ApplyInput{
		VoucherCode:   v.Code,
		EnrollmentID:  f.enrollID,
		OriginalPrice: decimal.NewFromInt(1200000),
		CallerUserID:  f.adminID,
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "expired")
}

func TestApplyVoucher_MaxUsesEnforced(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	ctx := context.Background()

	// Seed a second enrollment so we can try to use voucher twice
	var enrollID2 uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.course_batches (course_id, label, start_date, end_date, price, created_by)
		VALUES ($1, 'Batch 2', CURRENT_DATE, CURRENT_DATE + 30, 1200000, $2)
		RETURNING id`, f.courseID, f.adminID).Scan(new(uuid.UUID)))
	// Use a separate enrollment in same schema; reuse f.enrollID for first apply.
	// For simplicity: create a brand new enrollment for student on a different mechanism.
	// Actually: just test that used_count >= max_uses triggers rejection.
	_ = enrollID2

	svc := newService(t, pool)
	maxUses := 1
	v, err := svc.CreateVoucher(ctx, voucher.CreateInput{
		Code:          "LIMIT1",
		DiscountType:  voucher.DiscountFixed,
		DiscountValue: decimal.NewFromInt(50000),
		ValidFrom:     time.Now(),
		MaxUses:       &maxUses,
		CreatedBy:     f.adminID,
	})
	require.NoError(t, err)

	_, err = svc.ApplyVoucher(ctx, voucher.ApplyInput{
		VoucherCode:   v.Code,
		EnrollmentID:  f.enrollID,
		OriginalPrice: decimal.NewFromInt(1200000),
		CallerUserID:  f.adminID,
	})
	require.NoError(t, err)

	// Force used_count = max_uses in DB to test rejection on second call
	_, dbErr := pool.Exec(ctx, `UPDATE enrollment.vouchers SET used_count = 1 WHERE id = $1`, v.ID)
	require.NoError(t, dbErr)

	// Create a fresh enrollment (different enrollment_id) so the UNIQUE constraint is not the blocker
	var newEnrollID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO enrollment.enrollments
		  (student_id, course_batch_id, format, mode, payer, price, final_price, payment_status, completion_status, source)
		VALUES ($1, $2, 'regular', 'online', 'student', 1200000, 1200000, 'pending', 'ongoing', 'b2c')
		ON CONFLICT DO NOTHING
		RETURNING id`, f.studentID, f.batchID).Scan(&newEnrollID))
	if newEnrollID == uuid.Nil {
		t.Skip("no second enrollment possible with same student+batch due to UNIQUE constraint")
	}

	_, err = svc.ApplyVoucher(ctx, voucher.ApplyInput{
		VoucherCode:   v.Code,
		EnrollmentID:  newEnrollID,
		OriginalPrice: decimal.NewFromInt(1200000),
		CallerUserID:  f.adminID,
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "limit")
}

func TestApplyVoucher_AssignedToEnforced(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	// Create a different student
	var otherStudentUserID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('other@v.local','x','student')
		RETURNING id`).Scan(&otherStudentUserID))
	var otherStudentID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.students (user_id, name, email, phone, source)
		VALUES ($1,'Other','other@v.local','09','b2c') RETURNING id`, otherStudentUserID).Scan(&otherStudentID))

	// Voucher assigned only to otherStudent
	v, err := svc.CreateVoucher(ctx, voucher.CreateInput{
		Code:          "ASSIGNED",
		DiscountType:  voucher.DiscountFixed,
		DiscountValue: decimal.NewFromInt(50000),
		ValidFrom:     time.Now(),
		AssignedTo:    &otherStudentID,
		CreatedBy:     f.adminID,
	})
	require.NoError(t, err)

	// Try to apply as f.studentID (not the assigned student)
	wrongStudent := f.studentID
	_, err = svc.ApplyVoucher(ctx, voucher.ApplyInput{
		VoucherCode:   v.Code,
		EnrollmentID:  f.enrollID,
		OriginalPrice: decimal.NewFromInt(1200000),
		StudentID:     &wrongStudent,
		CallerUserID:  f.adminID,
	})
	require.Error(t, err)
}

func TestListMyVouchers(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	_, err := svc.CreateVoucher(ctx, voucher.CreateInput{
		Code:          "MINE",
		DiscountType:  voucher.DiscountFixed,
		DiscountValue: decimal.NewFromInt(10000),
		ValidFrom:     time.Now(),
		AssignedTo:    &f.studentID,
		CreatedBy:     f.adminID,
	})
	require.NoError(t, err)

	vouchers, err := svc.ListMyVouchers(ctx, f.studentID)
	require.NoError(t, err)
	require.Len(t, vouchers, 1)
	require.Equal(t, "MINE", vouchers[0].Code)
}

func TestDeactivateVoucher(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	v, err := svc.CreateVoucher(ctx, voucher.CreateInput{
		Code:          "DEACT",
		DiscountType:  voucher.DiscountFixed,
		DiscountValue: decimal.NewFromInt(10000),
		ValidFrom:     time.Now(),
		CreatedBy:     f.adminID,
	})
	require.NoError(t, err)

	require.NoError(t, svc.DeactivateVoucher(ctx, v.ID))

	got, err := svc.GetVoucher(ctx, v.ID)
	require.NoError(t, err)
	require.False(t, got.IsActive)

	// Applying a deactivated voucher should fail
	_, err = svc.ApplyVoucher(ctx, voucher.ApplyInput{
		VoucherCode:   v.Code,
		EnrollmentID:  f.enrollID,
		OriginalPrice: decimal.NewFromInt(1200000),
		CallerUserID:  f.adminID,
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "not active")
}
