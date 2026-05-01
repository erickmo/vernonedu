//go:build integration

package enrollment_test

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

	"github.com/vernonedu/vernonedu2/backend/domains/enrollment"
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
	creatorID uuid.UUID
	deptID    uuid.UUID
	courseID  uuid.UUID
	batchID   uuid.UUID
	studentID uuid.UUID
}

func seedFixture(t *testing.T, pool *pgxpool.Pool) fixture {
	t.Helper()
	ctx := context.Background()
	var f fixture

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('creator@t.local','x','course_creator')
		RETURNING id`).Scan(&f.creatorID))

	var studentUserID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('student@t.local','x','student')
		RETURNING id`).Scan(&studentUserID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.departments (name, leader_id, created_by)
		VALUES ('Dept', $1, $1)
		RETURNING id`, f.creatorID).Scan(&f.deptID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.students (user_id, name, email, phone, source)
		VALUES ($1, 'Stu', 'student@t.local', '08', 'b2c')
		RETURNING id`, studentUserID).Scan(&f.studentID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.courses (name, department_id, course_creator_id, base_price, min_price, created_by)
		VALUES ('C', $1, $2, 1000000, 800000, $2)
		RETURNING id`, f.deptID, f.creatorID).Scan(&f.courseID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.course_batches (course_id, label, start_date, end_date, price, created_by)
		VALUES ($1, 'B1', CURRENT_DATE, CURRENT_DATE + 30, 1200000, $2)
		RETURNING id`, f.courseID, f.creatorID).Scan(&f.batchID))

	return f
}

func newService(t *testing.T, pool *pgxpool.Pool) *enrollment.Service {
	t.Helper()
	log := zap.NewNop()
	return enrollment.NewService(enrollment.NewRepository(pool), events.NewBus(log), log)
}

func TestEnroll_HappyPath(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	e, err := svc.Enroll(ctx, enrollment.EnrollInput{
		StudentID:     f.studentID,
		CourseBatchID: f.batchID,
		Format:        enrollment.FormatRegular,
		Mode:          enrollment.ModeOnline,
		Payer:         "student",
		Price:         decimal.NewFromInt(1200000),
		Source:        "b2c",
	})
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, e.ID)
	require.True(t, e.FinalPrice.Equal(decimal.NewFromInt(1200000)))
	require.Equal(t, enrollment.PaymentPending, e.PaymentStatus)
	require.Equal(t, enrollment.CompletionOngoing, e.CompletionStatus)
}

func TestEnroll_DuplicateRejected(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	in := enrollment.EnrollInput{
		StudentID:     f.studentID,
		CourseBatchID: f.batchID,
		Format:        enrollment.FormatRegular,
		Mode:          enrollment.ModeOnline,
		Payer:         "student",
		Price:         decimal.NewFromInt(1200000),
		Source:        "b2c",
	}
	_, err := svc.Enroll(ctx, in)
	require.NoError(t, err)

	_, err = svc.Enroll(ctx, in)
	require.Error(t, err)
	require.Contains(t, err.Error(), "already enrolled")
}

func TestEnroll_AppliesPercentageVoucher(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	ctx := context.Background()
	var voucherID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO enrollment.vouchers (code, discount_type, discount_value, valid_from, is_active, created_by)
		VALUES ('PROMO10', 'percentage', 10, CURRENT_DATE, TRUE, $1)
		RETURNING id`, f.creatorID).Scan(&voucherID))

	svc := newService(t, pool)
	e, err := svc.Enroll(ctx, enrollment.EnrollInput{
		StudentID:     f.studentID,
		CourseBatchID: f.batchID,
		Format:        enrollment.FormatRegular,
		Mode:          enrollment.ModeOnline,
		Payer:         "student",
		Price:         decimal.NewFromInt(1000000),
		VoucherCode:   "PROMO10",
		Source:        "b2c",
	})
	require.NoError(t, err)
	require.True(t, e.FinalPrice.Equal(decimal.NewFromInt(900000)), "got %s", e.FinalPrice)
	require.NotNil(t, e.VoucherID)
	require.Equal(t, voucherID, *e.VoucherID)
}

func TestDropEnrollment(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	e, err := svc.Enroll(ctx, enrollment.EnrollInput{
		StudentID:     f.studentID,
		CourseBatchID: f.batchID,
		Format:        enrollment.FormatRegular,
		Mode:          enrollment.ModeOnline,
		Payer:         "student",
		Price:         decimal.NewFromInt(1200000),
		Source:        "b2c",
	})
	require.NoError(t, err)

	require.NoError(t, svc.DropEnrollment(ctx, e.ID))

	got, err := svc.GetEnrollment(ctx, e.ID)
	require.NoError(t, err)
	require.Equal(t, enrollment.CompletionDropped, got.CompletionStatus)

	// drop twice rejected
	require.Error(t, svc.DropEnrollment(ctx, e.ID))

	// suppress unused
	_ = time.Now
}
