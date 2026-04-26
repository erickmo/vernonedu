package finance

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines finance data access.
type Repository interface {
	CreatePayment(ctx context.Context, p *Payment) error
	GetPaymentByID(ctx context.Context, id uuid.UUID) (*Payment, error)
	GetPaymentByEnrollmentID(ctx context.Context, enrollmentID uuid.UUID) (*Payment, error)
	UpdatePaymentStatus(ctx context.Context, id uuid.UUID, status PaymentStatus, paidAmount interface{}) error

	CreatePaymentTerm(ctx context.Context, t *PaymentTerm) error
	GetPaymentTermByID(ctx context.Context, id uuid.UUID) (*PaymentTerm, error)
	ListPaymentTerms(ctx context.Context, paymentID uuid.UUID) ([]*PaymentTerm, error)
	UpdateTermStatus(ctx context.Context, id uuid.UUID, status TermStatus) error
	ListOverdueTerms(ctx context.Context, before time.Time) ([]*PaymentTerm, error)

	CreateTransaction(ctx context.Context, tx *PaymentTransaction) error
	GetTransactionByID(ctx context.Context, id uuid.UUID) (*PaymentTransaction, error)
	UpdateTransactionStatus(ctx context.Context, id uuid.UUID, status TransactionStatus, confirmedBy *uuid.UUID) error

	CreateInvoice(ctx context.Context, inv *Invoice) error
	GetInvoiceByID(ctx context.Context, id uuid.UUID) (*Invoice, error)
	UpdateInvoiceStatus(ctx context.Context, id uuid.UUID, status InvoiceStatus) error
	ListOverdueInvoices(ctx context.Context, before time.Time) ([]*Invoice, error)

	CreateInvoiceLineItem(ctx context.Context, item *InvoiceLineItem) error
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates finance repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreatePayment(ctx context.Context, p *Payment) error {
	query := `
		INSERT INTO finance.payments (id, enrollment_id, payment_type, total_amount, paid_amount, status)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query, p.ID, p.EnrollmentID, p.PaymentType, p.TotalAmount, p.PaidAmount, p.Status).
		Scan(&p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return fmt.Errorf("finance.CreatePayment: %w", err)
	}
	return nil
}

func (r *repository) GetPaymentByID(ctx context.Context, id uuid.UUID) (*Payment, error) {
	query := `SELECT id, enrollment_id, payment_type, total_amount, paid_amount, status, created_at, updated_at
	          FROM finance.payments WHERE id = $1`

	p := &Payment{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&p.ID, &p.EnrollmentID, &p.PaymentType, &p.TotalAmount, &p.PaidAmount, &p.Status, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("finance.GetPaymentByID: %w", err)
	}
	return p, nil
}

func (r *repository) GetPaymentByEnrollmentID(ctx context.Context, enrollmentID uuid.UUID) (*Payment, error) {
	query := `SELECT id, enrollment_id, payment_type, total_amount, paid_amount, status, created_at, updated_at
	          FROM finance.payments WHERE enrollment_id = $1`

	p := &Payment{}
	err := r.pool.QueryRow(ctx, query, enrollmentID).Scan(
		&p.ID, &p.EnrollmentID, &p.PaymentType, &p.TotalAmount, &p.PaidAmount, &p.Status, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("finance.GetPaymentByEnrollmentID: %w", err)
	}
	return p, nil
}

func (r *repository) UpdatePaymentStatus(ctx context.Context, id uuid.UUID, status PaymentStatus, paidAmount interface{}) error {
	query := `UPDATE finance.payments SET status=$1, paid_amount=COALESCE($2, paid_amount) WHERE id=$3`
	ct, err := r.pool.Exec(ctx, query, status, paidAmount, id)
	if err != nil {
		return fmt.Errorf("finance.UpdatePaymentStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) CreatePaymentTerm(ctx context.Context, t *PaymentTerm) error {
	query := `
		INSERT INTO finance.payment_terms (id, payment_id, term_number, due_date, amount, status)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query, t.ID, t.PaymentID, t.TermNumber, t.DueDate, t.Amount, t.Status).
		Scan(&t.CreatedAt, &t.UpdatedAt)
	if err != nil {
		return fmt.Errorf("finance.CreatePaymentTerm: %w", err)
	}
	return nil
}

func (r *repository) GetPaymentTermByID(ctx context.Context, id uuid.UUID) (*PaymentTerm, error) {
	query := `SELECT id, payment_id, term_number, due_date, amount, status, created_at, updated_at
	          FROM finance.payment_terms WHERE id = $1`

	t := &PaymentTerm{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&t.ID, &t.PaymentID, &t.TermNumber, &t.DueDate, &t.Amount, &t.Status, &t.CreatedAt, &t.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("finance.GetPaymentTermByID: %w", err)
	}
	return t, nil
}

func (r *repository) ListPaymentTerms(ctx context.Context, paymentID uuid.UUID) ([]*PaymentTerm, error) {
	query := `SELECT id, payment_id, term_number, due_date, amount, status, created_at, updated_at
	          FROM finance.payment_terms WHERE payment_id = $1 ORDER BY term_number`

	rows, err := r.pool.Query(ctx, query, paymentID)
	if err != nil {
		return nil, fmt.Errorf("finance.ListPaymentTerms: %w", err)
	}
	defer rows.Close()

	var terms []*PaymentTerm
	for rows.Next() {
		t := &PaymentTerm{}
		if err := rows.Scan(&t.ID, &t.PaymentID, &t.TermNumber, &t.DueDate, &t.Amount, &t.Status, &t.CreatedAt, &t.UpdatedAt); err != nil {
			return nil, fmt.Errorf("finance.ListPaymentTerms scan: %w", err)
		}
		terms = append(terms, t)
	}
	return terms, rows.Err()
}

func (r *repository) UpdateTermStatus(ctx context.Context, id uuid.UUID, status TermStatus) error {
	query := `UPDATE finance.payment_terms SET status=$1 WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("finance.UpdateTermStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListOverdueTerms(ctx context.Context, before time.Time) ([]*PaymentTerm, error) {
	query := `SELECT id, payment_id, term_number, due_date, amount, status, created_at, updated_at
	          FROM finance.payment_terms WHERE status='unpaid' AND due_date < $1`

	rows, err := r.pool.Query(ctx, query, before)
	if err != nil {
		return nil, fmt.Errorf("finance.ListOverdueTerms: %w", err)
	}
	defer rows.Close()

	var terms []*PaymentTerm
	for rows.Next() {
		t := &PaymentTerm{}
		if err := rows.Scan(&t.ID, &t.PaymentID, &t.TermNumber, &t.DueDate, &t.Amount, &t.Status, &t.CreatedAt, &t.UpdatedAt); err != nil {
			return nil, fmt.Errorf("finance.ListOverdueTerms scan: %w", err)
		}
		terms = append(terms, t)
	}
	return terms, rows.Err()
}

func (r *repository) CreateTransaction(ctx context.Context, tx *PaymentTransaction) error {
	query := `
		INSERT INTO finance.payment_transactions (id, payment_term_id, method, amount, status, gateway_ref, proof_url)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		tx.ID, tx.PaymentTermID, tx.Method, tx.Amount, tx.Status, tx.GatewayRef, tx.ProofURL,
	).Scan(&tx.CreatedAt, &tx.UpdatedAt)
	if err != nil {
		return fmt.Errorf("finance.CreateTransaction: %w", err)
	}
	return nil
}

func (r *repository) GetTransactionByID(ctx context.Context, id uuid.UUID) (*PaymentTransaction, error) {
	query := `SELECT id, payment_term_id, method, amount, status, gateway_ref, proof_url, confirmed_by, confirmed_at, created_at, updated_at
	          FROM finance.payment_transactions WHERE id = $1`

	tx := &PaymentTransaction{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&tx.ID, &tx.PaymentTermID, &tx.Method, &tx.Amount, &tx.Status,
		&tx.GatewayRef, &tx.ProofURL, &tx.ConfirmedBy, &tx.ConfirmedAt,
		&tx.CreatedAt, &tx.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("finance.GetTransactionByID: %w", err)
	}
	return tx, nil
}

func (r *repository) UpdateTransactionStatus(ctx context.Context, id uuid.UUID, status TransactionStatus, confirmedBy *uuid.UUID) error {
	now := time.Now()
	var confirmedAt *time.Time
	if status == TxConfirmed {
		confirmedAt = &now
	}
	query := `UPDATE finance.payment_transactions SET status=$1, confirmed_by=$2, confirmed_at=$3 WHERE id=$4`
	ct, err := r.pool.Exec(ctx, query, status, confirmedBy, confirmedAt, id)
	if err != nil {
		return fmt.Errorf("finance.UpdateTransactionStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) CreateInvoice(ctx context.Context, inv *Invoice) error {
	query := `
		INSERT INTO finance.invoices
		  (id, invoice_number, enrollment_id, payment_id, billed_to, partner_id, student_id,
		   status, issued_date, due_date, subtotal, discount_amount, total_amount, notes, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		inv.ID, inv.InvoiceNumber, inv.EnrollmentID, inv.PaymentID, inv.BilledTo,
		inv.PartnerID, inv.StudentID, inv.Status, inv.IssuedDate, inv.DueDate,
		inv.Subtotal, inv.DiscountAmount, inv.TotalAmount, inv.Notes, inv.CreatedBy,
	).Scan(&inv.CreatedAt, &inv.UpdatedAt)
	if err != nil {
		return fmt.Errorf("finance.CreateInvoice: %w", err)
	}
	return nil
}

func (r *repository) GetInvoiceByID(ctx context.Context, id uuid.UUID) (*Invoice, error) {
	query := `SELECT id, invoice_number, enrollment_id, payment_id, billed_to, partner_id, student_id,
	                 status, issued_date, due_date, subtotal, discount_amount, total_amount, notes, created_by, created_at, updated_at
	          FROM finance.invoices WHERE id = $1`

	inv := &Invoice{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&inv.ID, &inv.InvoiceNumber, &inv.EnrollmentID, &inv.PaymentID, &inv.BilledTo,
		&inv.PartnerID, &inv.StudentID, &inv.Status, &inv.IssuedDate, &inv.DueDate,
		&inv.Subtotal, &inv.DiscountAmount, &inv.TotalAmount, &inv.Notes,
		&inv.CreatedBy, &inv.CreatedAt, &inv.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("finance.GetInvoiceByID: %w", err)
	}
	return inv, nil
}

func (r *repository) UpdateInvoiceStatus(ctx context.Context, id uuid.UUID, status InvoiceStatus) error {
	query := `UPDATE finance.invoices SET status=$1 WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("finance.UpdateInvoiceStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListOverdueInvoices(ctx context.Context, before time.Time) ([]*Invoice, error) {
	query := `SELECT id, invoice_number, enrollment_id, payment_id, billed_to, partner_id, student_id,
	                 status, issued_date, due_date, subtotal, discount_amount, total_amount, notes, created_by, created_at, updated_at
	          FROM finance.invoices WHERE status='sent' AND due_date < $1`

	rows, err := r.pool.Query(ctx, query, before)
	if err != nil {
		return nil, fmt.Errorf("finance.ListOverdueInvoices: %w", err)
	}
	defer rows.Close()

	var invoices []*Invoice
	for rows.Next() {
		inv := &Invoice{}
		if err := rows.Scan(
			&inv.ID, &inv.InvoiceNumber, &inv.EnrollmentID, &inv.PaymentID, &inv.BilledTo,
			&inv.PartnerID, &inv.StudentID, &inv.Status, &inv.IssuedDate, &inv.DueDate,
			&inv.Subtotal, &inv.DiscountAmount, &inv.TotalAmount, &inv.Notes,
			&inv.CreatedBy, &inv.CreatedAt, &inv.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("finance.ListOverdueInvoices scan: %w", err)
		}
		invoices = append(invoices, inv)
	}
	return invoices, rows.Err()
}

func (r *repository) CreateInvoiceLineItem(ctx context.Context, item *InvoiceLineItem) error {
	query := `INSERT INTO finance.invoice_line_items (id, invoice_id, label, amount, sort_order)
	          VALUES ($1, $2, $3, $4, $5) RETURNING created_at`

	err := r.pool.QueryRow(ctx, query, item.ID, item.InvoiceID, item.Label, item.Amount, item.SortOrder).
		Scan(&item.CreatedAt)
	if err != nil {
		return fmt.Errorf("finance.CreateInvoiceLineItem: %w", err)
	}
	return nil
}
