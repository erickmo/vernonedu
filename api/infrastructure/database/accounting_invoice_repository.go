package database

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type invoiceRecord struct {
	ID            uuid.UUID  `db:"id"`
	InvoiceNumber string     `db:"invoice_number"`
	StudentID     *uuid.UUID `db:"student_id"`
	EnrollmentID  *uuid.UUID `db:"enrollment_id"`
	CourseBatchID *uuid.UUID `db:"course_batch_id"`
	StudentName   string     `db:"student_name"`
	BatchName     string     `db:"batch_name"`
	ClientName    string     `db:"client_name"`
	PaymentMethod string     `db:"payment_method"`
	Amount        float64    `db:"amount"`
	PaidAmount    *float64   `db:"paid_amount"`
	DueDate       *time.Time `db:"due_date"`
	PaidDate      *time.Time `db:"paid_date"`
	Status        string     `db:"status"`
	Notes         string     `db:"notes"`
	Source        string     `db:"source"`
	PaymentProof  *string    `db:"payment_proof"`
	BranchID      *uuid.UUID `db:"branch_id"`
	SessionID     *uuid.UUID `db:"session_id"`
	SentAt        *time.Time `db:"sent_at"`
	CancelledAt   *time.Time `db:"cancelled_at"`
	CancelReason  string     `db:"cancel_reason"`
	PaidBy        *uuid.UUID `db:"paid_by"`
	CreatedAt     time.Time  `db:"created_at"`
	UpdatedAt     time.Time  `db:"updated_at"`
}

func invoiceRecordToDomain(row invoiceRecord) *accounting.Invoice {
	return &accounting.Invoice{
		ID:            row.ID,
		InvoiceNumber: row.InvoiceNumber,
		StudentID:     row.StudentID,
		EnrollmentID:  row.EnrollmentID,
		CourseBatchID: row.CourseBatchID,
		StudentName:   row.StudentName,
		BatchName:     row.BatchName,
		ClientName:    row.ClientName,
		PaymentMethod: row.PaymentMethod,
		Amount:        row.Amount,
		PaidAmount:    row.PaidAmount,
		DueDate:       row.DueDate,
		PaidDate:      row.PaidDate,
		Status:        row.Status,
		Notes:         row.Notes,
		Source:        row.Source,
		PaymentProof:  row.PaymentProof,
		BranchID:      row.BranchID,
		SessionID:     row.SessionID,
		SentAt:        row.SentAt,
		CancelledAt:   row.CancelledAt,
		CancelReason:  row.CancelReason,
		PaidBy:        row.PaidBy,
		CreatedAt:     row.CreatedAt,
		UpdatedAt:     row.UpdatedAt,
	}
}

type AccountingInvoiceRepository struct {
	db *sqlx.DB
}

func NewAccountingInvoiceRepository(db *sqlx.DB) *AccountingInvoiceRepository {
	return &AccountingInvoiceRepository{db: db}
}

func (r *AccountingInvoiceRepository) Save(ctx context.Context, inv *accounting.Invoice) error {
	query := `
		INSERT INTO accounting_invoices
			(id, invoice_number, student_id, enrollment_id, course_batch_id,
			 student_name, batch_name, client_name, payment_method,
			 amount, paid_amount, due_date, paid_date,
			 status, notes, source, payment_proof,
			 branch_id, session_id, sent_at, cancelled_at, cancel_reason, paid_by,
			 created_at, updated_at)
		VALUES
			($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25)
		ON CONFLICT (id) DO UPDATE SET
			invoice_number  = EXCLUDED.invoice_number,
			student_name    = EXCLUDED.student_name,
			batch_name      = EXCLUDED.batch_name,
			client_name     = EXCLUDED.client_name,
			amount          = EXCLUDED.amount,
			paid_amount     = EXCLUDED.paid_amount,
			due_date        = EXCLUDED.due_date,
			paid_date       = EXCLUDED.paid_date,
			status          = EXCLUDED.status,
			notes           = EXCLUDED.notes,
			source          = EXCLUDED.source,
			payment_proof   = EXCLUDED.payment_proof,
			sent_at         = EXCLUDED.sent_at,
			cancelled_at    = EXCLUDED.cancelled_at,
			cancel_reason   = EXCLUDED.cancel_reason,
			paid_by         = EXCLUDED.paid_by,
			updated_at      = EXCLUDED.updated_at
	`
	_, err := r.db.ExecContext(ctx, query,
		inv.ID, inv.InvoiceNumber, inv.StudentID, inv.EnrollmentID, inv.CourseBatchID,
		inv.StudentName, inv.BatchName, inv.ClientName, inv.PaymentMethod,
		inv.Amount, inv.PaidAmount, inv.DueDate, inv.PaidDate,
		inv.Status, inv.Notes, inv.Source, inv.PaymentProof,
		inv.BranchID, inv.SessionID, inv.SentAt, inv.CancelledAt, inv.CancelReason, inv.PaidBy,
		inv.CreatedAt, inv.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save invoice: %w", err)
	}
	return nil
}

func (r *AccountingInvoiceRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status string) error {
	query := `
		UPDATE accounting_invoices
		SET status=$1, updated_at=$2
		WHERE id=$3
	`
	now := time.Now()
	_, err := r.db.ExecContext(ctx, query, status, now, id)
	if err != nil {
		return fmt.Errorf("failed to update invoice status: %w", err)
	}
	return nil
}

func (r *AccountingInvoiceRepository) MarkPaid(ctx context.Context, id uuid.UUID, paidAt time.Time, paidAmount float64, paidBy uuid.UUID, proof string) error {
	now := time.Now()
	var proofPtr *string
	if proof != "" {
		proofPtr = &proof
	}
	query := `
		UPDATE accounting_invoices
		SET status='paid', paid_date=$1, paid_amount=$2, paid_by=$3, payment_proof=$4, updated_at=$5
		WHERE id=$6
	`
	_, err := r.db.ExecContext(ctx, query, paidAt, paidAmount, paidBy, proofPtr, now, id)
	if err != nil {
		return fmt.Errorf("failed to mark invoice paid: %w", err)
	}
	return nil
}

func (r *AccountingInvoiceRepository) Cancel(ctx context.Context, id uuid.UUID, reason string) error {
	now := time.Now()
	query := `
		UPDATE accounting_invoices
		SET status='cancelled', cancelled_at=$1, cancel_reason=$2, updated_at=$3
		WHERE id=$4
	`
	_, err := r.db.ExecContext(ctx, query, now, reason, now, id)
	if err != nil {
		return fmt.Errorf("failed to cancel invoice: %w", err)
	}
	return nil
}

func (r *AccountingInvoiceRepository) MarkSent(ctx context.Context, id uuid.UUID) error {
	now := time.Now()
	query := `
		UPDATE accounting_invoices
		SET status='sent', sent_at=$1, updated_at=$2
		WHERE id=$3
	`
	_, err := r.db.ExecContext(ctx, query, now, now, id)
	if err != nil {
		return fmt.Errorf("failed to mark invoice sent: %w", err)
	}
	return nil
}

func (r *AccountingInvoiceRepository) MarkOverdue(ctx context.Context, ids []uuid.UUID) error {
	if len(ids) == 0 {
		return nil
	}
	now := time.Now()
	args := make([]interface{}, 0, len(ids)+1)
	args = append(args, now)
	placeholders := make([]string, len(ids))
	for i, id := range ids {
		placeholders[i] = fmt.Sprintf("$%d", i+2)
		args = append(args, id)
	}
	query := fmt.Sprintf(`
		UPDATE accounting_invoices
		SET status='overdue', updated_at=$1
		WHERE id IN (%s)
	`, strings.Join(placeholders, ","))
	_, err := r.db.ExecContext(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to mark invoices overdue: %w", err)
	}
	return nil
}

func (r *AccountingInvoiceRepository) GetByID(ctx context.Context, id uuid.UUID) (*accounting.Invoice, error) {
	var row invoiceRecord
	query := `
		SELECT id,
		       COALESCE(invoice_number,'') AS invoice_number,
		       student_id, enrollment_id, course_batch_id,
		       COALESCE(student_name,'') AS student_name,
		       COALESCE(batch_name,'') AS batch_name,
		       COALESCE(client_name,'') AS client_name,
		       COALESCE(payment_method,'') AS payment_method,
		       amount, paid_amount, due_date, paid_date, status,
		       COALESCE(notes,'') AS notes,
		       COALESCE(source,'manual') AS source,
		       payment_proof, branch_id, session_id, sent_at,
		       cancelled_at, COALESCE(cancel_reason,'') AS cancel_reason, paid_by,
		       created_at, updated_at
		FROM accounting_invoices
		WHERE id = $1
	`
	if err := r.db.GetContext(ctx, &row, query, id); err != nil {
		return nil, fmt.Errorf("failed to get invoice: %w", err)
	}
	inv := invoiceRecordToDomain(row)
	return inv, nil
}

func (r *AccountingInvoiceRepository) List(ctx context.Context, offset, limit, month, year int, status string) ([]*accounting.Invoice, int, error) {
	var total int
	countQuery := `
		SELECT COUNT(*) FROM accounting_invoices
		WHERE ($1='' OR status=$1)
		  AND ($2=0 OR EXTRACT(MONTH FROM created_at)=$2)
		  AND ($3=0 OR EXTRACT(YEAR FROM created_at)=$3)
	`
	if err := r.db.GetContext(ctx, &total, countQuery, status, month, year); err != nil {
		return nil, 0, fmt.Errorf("failed to count invoices: %w", err)
	}

	var rows []invoiceRecord
	query := `
		SELECT id,
		       COALESCE(invoice_number,'') AS invoice_number,
		       student_id, enrollment_id, course_batch_id,
		       COALESCE(student_name,'') AS student_name,
		       COALESCE(batch_name,'') AS batch_name,
		       COALESCE(client_name,'') AS client_name,
		       COALESCE(payment_method,'') AS payment_method,
		       amount, paid_amount, due_date, paid_date, status,
		       COALESCE(notes,'') AS notes,
		       COALESCE(source,'manual') AS source,
		       payment_proof, branch_id, session_id, sent_at,
		       cancelled_at, COALESCE(cancel_reason,'') AS cancel_reason, paid_by,
		       created_at, updated_at
		FROM accounting_invoices
		WHERE ($1='' OR status=$1)
		  AND ($2=0 OR EXTRACT(MONTH FROM created_at)=$2)
		  AND ($3=0 OR EXTRACT(YEAR FROM created_at)=$3)
		ORDER BY created_at DESC
		LIMIT $4 OFFSET $5
	`
	if err := r.db.SelectContext(ctx, &rows, query, status, month, year, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list invoices: %w", err)
	}

	out := make([]*accounting.Invoice, len(rows))
	for i, row := range rows {
		out[i] = invoiceRecordToDomain(row)
	}
	return out, total, nil
}

func (r *AccountingInvoiceRepository) ListEnriched(ctx context.Context, filters accounting.InvoiceFilters) ([]*accounting.Invoice, int, error) {
	conditions := []string{"1=1"}
	args := []interface{}{}
	argIdx := 1

	if filters.Status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIdx))
		args = append(args, filters.Status)
		argIdx++
	}
	if filters.BatchID != nil {
		conditions = append(conditions, fmt.Sprintf("course_batch_id = $%d", argIdx))
		args = append(args, *filters.BatchID)
		argIdx++
	}
	if filters.StudentID != nil {
		conditions = append(conditions, fmt.Sprintf("student_id = $%d", argIdx))
		args = append(args, *filters.StudentID)
		argIdx++
	}
	if filters.PaymentMethod != "" {
		conditions = append(conditions, fmt.Sprintf("payment_method = $%d", argIdx))
		args = append(args, filters.PaymentMethod)
		argIdx++
	}
	if filters.DateFrom != nil {
		conditions = append(conditions, fmt.Sprintf("created_at >= $%d", argIdx))
		args = append(args, *filters.DateFrom)
		argIdx++
	}
	if filters.DateTo != nil {
		conditions = append(conditions, fmt.Sprintf("created_at <= $%d", argIdx))
		args = append(args, *filters.DateTo)
		argIdx++
	}
	if filters.Month > 0 {
		conditions = append(conditions, fmt.Sprintf("EXTRACT(MONTH FROM created_at) = $%d", argIdx))
		args = append(args, filters.Month)
		argIdx++
	}
	if filters.Year > 0 {
		conditions = append(conditions, fmt.Sprintf("EXTRACT(YEAR FROM created_at) = $%d", argIdx))
		args = append(args, filters.Year)
		argIdx++
	}

	where := strings.Join(conditions, " AND ")

	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM accounting_invoices WHERE %s`, where)
	var total int
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count enriched invoices: %w", err)
	}

	selectArgs := append(args, filters.Limit, filters.Offset)
	dataQuery := fmt.Sprintf(`
		SELECT id,
		       COALESCE(invoice_number,'') AS invoice_number,
		       student_id, enrollment_id, course_batch_id,
		       COALESCE(student_name,'') AS student_name,
		       COALESCE(batch_name,'') AS batch_name,
		       COALESCE(client_name,'') AS client_name,
		       COALESCE(payment_method,'') AS payment_method,
		       amount, paid_amount, due_date, paid_date, status,
		       COALESCE(notes,'') AS notes,
		       COALESCE(source,'manual') AS source,
		       payment_proof, branch_id, session_id, sent_at,
		       cancelled_at, COALESCE(cancel_reason,'') AS cancel_reason, paid_by,
		       created_at, updated_at
		FROM accounting_invoices
		WHERE %s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, where, argIdx, argIdx+1)

	var rows []invoiceRecord
	if err := r.db.SelectContext(ctx, &rows, dataQuery, selectArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list enriched invoices: %w", err)
	}

	out := make([]*accounting.Invoice, len(rows))
	for i, row := range rows {
		out[i] = invoiceRecordToDomain(row)
	}
	return out, total, nil
}

func (r *AccountingInvoiceRepository) GetStats(ctx context.Context, branchID *uuid.UUID) (*accounting.InvoiceStats, error) {
	type statsRow struct {
		Status string  `db:"status"`
		Count  int     `db:"cnt"`
		Total  float64 `db:"total"`
	}

	var whereClause string
	var args []interface{}
	if branchID != nil {
		whereClause = "WHERE branch_id = $1"
		args = append(args, *branchID)
	}

	query := fmt.Sprintf(`
		SELECT status,
		       COUNT(*) AS cnt,
		       COALESCE(SUM(amount),0) AS total
		FROM accounting_invoices
		%s
		GROUP BY status
	`, whereClause)

	var rows []statsRow
	if err := r.db.SelectContext(ctx, &rows, query, args...); err != nil {
		return nil, fmt.Errorf("failed to get invoice stats: %w", err)
	}

	stats := &accounting.InvoiceStats{}
	for _, row := range rows {
		stats.TotalCount += row.Count
		stats.TotalAmount += row.Total
		switch row.Status {
		case accounting.InvoiceStatusPaid:
			stats.PaidCount = row.Count
			stats.PaidAmount = row.Total
		case accounting.InvoiceStatusOverdue:
			stats.OverdueCount = row.Count
			stats.OverdueAmount = row.Total
			stats.OutstandingCount += row.Count
			stats.OutstandingAmount += row.Total
		case accounting.InvoiceStatusDraft, accounting.InvoiceStatusSent:
			stats.OutstandingCount += row.Count
			stats.OutstandingAmount += row.Total
		}
	}
	return stats, nil
}

func (r *AccountingInvoiceRepository) FindOverdueUnpaid(ctx context.Context, asOf time.Time) ([]*accounting.Invoice, error) {
	query := `
		SELECT id,
		       COALESCE(invoice_number,'') AS invoice_number,
		       student_id, enrollment_id, course_batch_id,
		       COALESCE(student_name,'') AS student_name,
		       COALESCE(batch_name,'') AS batch_name,
		       COALESCE(client_name,'') AS client_name,
		       COALESCE(payment_method,'') AS payment_method,
		       amount, paid_amount, due_date, paid_date, status,
		       COALESCE(notes,'') AS notes,
		       COALESCE(source,'manual') AS source,
		       payment_proof, branch_id, session_id, sent_at,
		       cancelled_at, COALESCE(cancel_reason,'') AS cancel_reason, paid_by,
		       created_at, updated_at
		FROM accounting_invoices
		WHERE status IN ('draft','sent')
		  AND due_date IS NOT NULL
		  AND due_date < $1
	`
	var rows []invoiceRecord
	if err := r.db.SelectContext(ctx, &rows, query, asOf); err != nil {
		return nil, fmt.Errorf("failed to find overdue invoices: %w", err)
	}

	out := make([]*accounting.Invoice, len(rows))
	for i, row := range rows {
		out[i] = invoiceRecordToDomain(row)
	}
	return out, nil
}
