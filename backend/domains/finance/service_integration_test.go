//go:build integration

package finance_test

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

	"github.com/vernonedu/vernonedu2/backend/domains/finance"
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
			finance.invoice_line_items,
			finance.invoices,
			finance.payment_transactions,
			finance.payment_terms,
			finance.refunds,
			finance.student_credits,
			finance.payments,
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
	creatorID    uuid.UUID
	studentID    uuid.UUID
	enrollmentID uuid.UUID
}

func seedFixture(t *testing.T, pool *pgxpool.Pool) fixture {
	t.Helper()
	ctx := context.Background()
	var f fixture
	var deptID, courseID, batchID, studentUserID uuid.UUID

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('creator@t.local','x','course_creator')
		RETURNING id`).Scan(&f.creatorID))
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('student@t.local','x','student')
		RETURNING id`).Scan(&studentUserID))
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.departments (name, leader_id, created_by)
		VALUES ('Dept', $1, $1) RETURNING id`, f.creatorID).Scan(&deptID))
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.students (user_id, name, email, phone, source)
		VALUES ($1, 'Stu', 'student@t.local', '08', 'b2c')
		RETURNING id`, studentUserID).Scan(&f.studentID))
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.courses (name, department_id, course_creator_id, base_price, min_price, created_by)
		VALUES ('C', $1, $2, 1000000, 800000, $2) RETURNING id`, deptID, f.creatorID).Scan(&courseID))
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.course_batches (course_id, label, start_date, end_date, price, created_by)
		VALUES ($1, 'B1', CURRENT_DATE, CURRENT_DATE + 30, 1200000, $2)
		RETURNING id`, courseID, f.creatorID).Scan(&batchID))
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO enrollment.enrollments
			(student_id, course_batch_id, format, mode, payer, price, final_price, source)
		VALUES ($1, $2, 'regular', 'online', 'student', 1200000, 1200000, 'b2c')
		RETURNING id`, f.studentID, batchID).Scan(&f.enrollmentID))

	return f
}

func newService(t *testing.T, pool *pgxpool.Pool) *finance.Service {
	t.Helper()
	log := zap.NewNop()
	return finance.NewService(finance.NewRepository(pool), events.NewBus(log), log)
}

// insertTransaction creates a pending payment_transaction directly (no service helper exists).
func insertTransaction(t *testing.T, pool *pgxpool.Pool, termID uuid.UUID, amount decimal.Decimal) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	err := pool.QueryRow(context.Background(), `
		INSERT INTO finance.payment_transactions (payment_term_id, method, amount, status)
		VALUES ($1, 'bank_transfer', $2, 'pending')
		RETURNING id`, termID, amount).Scan(&id)
	require.NoError(t, err)
	return id
}

func TestPaymentLifecycle_FullPayment(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	total := decimal.NewFromInt(1200000)
	pay, err := svc.InitiatePayment(ctx, f.enrollmentID, total, finance.PaymentFull)
	require.NoError(t, err)
	require.Equal(t, finance.PaymentPending, pay.Status)

	term, err := svc.AddPaymentTerm(ctx, pay.ID, 1, time.Now().AddDate(0, 0, 7), total)
	require.NoError(t, err)
	require.Equal(t, finance.TermUnpaid, term.Status)

	txID := insertTransaction(t, pool, term.ID, total)
	require.NoError(t, svc.ConfirmTransaction(ctx, txID, f.creatorID))

	got, err := svc.GetPaymentByID(ctx, pay.ID)
	require.NoError(t, err)
	require.Equal(t, finance.PaymentPaid, got.Status)
	require.True(t, got.PaidAmount.Equal(total))

	// Confirming the same tx again is rejected
	require.Error(t, svc.ConfirmTransaction(ctx, txID, f.creatorID))
}

func TestPaymentLifecycle_Installment_PartialThenPaid(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	total := decimal.NewFromInt(1000000)
	pay, err := svc.InitiatePayment(ctx, f.enrollmentID, total, finance.PaymentInstallment)
	require.NoError(t, err)

	half := decimal.NewFromInt(500000)
	t1, err := svc.AddPaymentTerm(ctx, pay.ID, 1, time.Now().AddDate(0, 0, 7), half)
	require.NoError(t, err)
	t2, err := svc.AddPaymentTerm(ctx, pay.ID, 2, time.Now().AddDate(0, 0, 30), half)
	require.NoError(t, err)

	tx1 := insertTransaction(t, pool, t1.ID, half)
	require.NoError(t, svc.ConfirmTransaction(ctx, tx1, f.creatorID))

	got, err := svc.GetPaymentByID(ctx, pay.ID)
	require.NoError(t, err)
	require.Equal(t, finance.PaymentPartial, got.Status)
	require.True(t, got.PaidAmount.Equal(half))

	tx2 := insertTransaction(t, pool, t2.ID, half)
	require.NoError(t, svc.ConfirmTransaction(ctx, tx2, f.creatorID))

	got, err = svc.GetPaymentByID(ctx, pay.ID)
	require.NoError(t, err)
	require.Equal(t, finance.PaymentPaid, got.Status)
	require.True(t, got.PaidAmount.Equal(total))
}

func TestInvoiceLifecycle_DraftToSent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	pay, err := svc.InitiatePayment(ctx, f.enrollmentID, decimal.NewFromInt(1000000), finance.PaymentFull)
	require.NoError(t, err)

	due := time.Now().AddDate(0, 0, 14)
	inv := &finance.Invoice{
		EnrollmentID:   f.enrollmentID,
		PaymentID:      pay.ID,
		BilledTo:       "student",
		StudentID:      &f.studentID,
		IssuedDate:     time.Now(),
		DueDate:        &due,
		Subtotal:       decimal.NewFromInt(1000000),
		DiscountAmount: decimal.Zero,
		TotalAmount:    decimal.NewFromInt(1000000),
		CreatedBy:      f.creatorID,
	}
	items := []finance.InvoiceLineItem{
		{Label: "Course fee", Amount: decimal.NewFromInt(1000000)},
	}

	created, err := svc.CreateInvoice(ctx, inv, items)
	require.NoError(t, err)
	require.Equal(t, finance.InvoiceDraft, created.Status)
	require.NotEmpty(t, created.InvoiceNumber)

	require.NoError(t, svc.SendInvoice(ctx, created.ID))

	got, err := svc.GetInvoiceByID(ctx, created.ID)
	require.NoError(t, err)
	require.Equal(t, finance.InvoiceSent, got.Status)

	// Sending an already-sent invoice is rejected
	require.Error(t, svc.SendInvoice(ctx, created.ID))
}
