package enrollment

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// ConsumeVoucherParams carries inputs for atomic voucher consumption.
type ConsumeVoucherParams struct {
	VoucherID     uuid.UUID
	EnrollmentID  uuid.UUID
	StudentID     uuid.UUID
	OriginalPrice decimal.Decimal
	FinalPrice    decimal.Decimal
	CreatedBy     uuid.UUID
}

// Repository defines enrollment data access.
type Repository interface {
	CreateEnrollment(ctx context.Context, e *Enrollment) error
	GetEnrollmentByID(ctx context.Context, id uuid.UUID) (*Enrollment, error)
	GetEnrollmentByStudentAndBatch(ctx context.Context, studentID, batchID uuid.UUID) (*Enrollment, error)
	UpdateEnrollmentStatus(ctx context.Context, id uuid.UUID, payStatus PaymentStatus, compStatus CompletionStatus) error
	// UpdateEnrollmentCompletion updates only the completion_status column,
	// leaving payment_status untouched. Used by lifecycle transitions
	// (mark completed / drop) which must not coerce payment state.
	UpdateEnrollmentCompletion(ctx context.Context, id uuid.UUID, compStatus CompletionStatus) error
	ListEnrollmentsByStudent(ctx context.Context, studentID uuid.UUID) ([]*Enrollment, error)
	ListEnrollmentsByBatch(ctx context.Context, batchID uuid.UUID) ([]*Enrollment, error)
	CountEnrollmentsByBatchAndFormat(ctx context.Context, batchID uuid.UUID, format EnrollmentFormat) (int, error)

	GetVoucherByCode(ctx context.Context, code string) (*Voucher, error)
	GetVoucherByID(ctx context.Context, id uuid.UUID) (*Voucher, error)
	CreateVoucher(ctx context.Context, v *Voucher) error
	AssignVoucher(ctx context.Context, id, studentID uuid.UUID) error
	DeactivateVoucher(ctx context.Context, id uuid.UUID) error

	// ConsumeVoucher atomically locks, validates, increments used_count,
	// and inserts voucher_usages within a single transaction.
	ConsumeVoucher(ctx context.Context, p ConsumeVoucherParams) error
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates enrollment repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreateEnrollment(ctx context.Context, e *Enrollment) error {
	query := `
		INSERT INTO enrollment.enrollments
		  (id, student_id, course_batch_id, format, mode, payer, partner_id, franchisee_id,
		   price, final_price, voucher_id, credit_applied, student_credit_id,
		   payment_status, completion_status, source)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		e.ID, e.StudentID, e.CourseBatchID, e.Format, e.Mode, e.Payer, e.PartnerID, e.FranchiseeID,
		e.Price, e.FinalPrice, e.VoucherID, e.CreditApplied, e.StudentCreditID,
		e.PaymentStatus, e.CompletionStatus, e.Source,
	).Scan(&e.CreatedAt, &e.UpdatedAt)
	if err != nil {
		return fmt.Errorf("enrollment.CreateEnrollment: %w", err)
	}
	return nil
}

func (r *repository) GetEnrollmentByID(ctx context.Context, id uuid.UUID) (*Enrollment, error) {
	query := `
		SELECT id, student_id, course_batch_id, format, mode, payer, partner_id, franchisee_id,
		       price, final_price, voucher_id, credit_applied, student_credit_id,
		       payment_status, completion_status, source, created_at, updated_at
		FROM enrollment.enrollments WHERE id = $1`

	e := &Enrollment{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&e.ID, &e.StudentID, &e.CourseBatchID, &e.Format, &e.Mode, &e.Payer,
		&e.PartnerID, &e.FranchiseeID, &e.Price, &e.FinalPrice, &e.VoucherID,
		&e.CreditApplied, &e.StudentCreditID, &e.PaymentStatus, &e.CompletionStatus,
		&e.Source, &e.CreatedAt, &e.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("enrollment.GetEnrollmentByID: %w", err)
	}
	return e, nil
}

func (r *repository) GetEnrollmentByStudentAndBatch(ctx context.Context, studentID, batchID uuid.UUID) (*Enrollment, error) {
	query := `
		SELECT id, student_id, course_batch_id, format, mode, payer, partner_id, franchisee_id,
		       price, final_price, voucher_id, credit_applied, student_credit_id,
		       payment_status, completion_status, source, created_at, updated_at
		FROM enrollment.enrollments WHERE student_id = $1 AND course_batch_id = $2`

	e := &Enrollment{}
	err := r.pool.QueryRow(ctx, query, studentID, batchID).Scan(
		&e.ID, &e.StudentID, &e.CourseBatchID, &e.Format, &e.Mode, &e.Payer,
		&e.PartnerID, &e.FranchiseeID, &e.Price, &e.FinalPrice, &e.VoucherID,
		&e.CreditApplied, &e.StudentCreditID, &e.PaymentStatus, &e.CompletionStatus,
		&e.Source, &e.CreatedAt, &e.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("enrollment.GetEnrollmentByStudentAndBatch: %w", err)
	}
	return e, nil
}

func (r *repository) UpdateEnrollmentStatus(ctx context.Context, id uuid.UUID, payStatus PaymentStatus, compStatus CompletionStatus) error {
	query := `UPDATE enrollment.enrollments SET payment_status=$1, completion_status=$2 WHERE id=$3`
	ct, err := r.pool.Exec(ctx, query, payStatus, compStatus, id)
	if err != nil {
		return fmt.Errorf("enrollment.UpdateEnrollmentStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) UpdateEnrollmentCompletion(ctx context.Context, id uuid.UUID, compStatus CompletionStatus) error {
	const query = `UPDATE enrollment.enrollments SET completion_status=$1, updated_at=now() WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, compStatus, id)
	if err != nil {
		return fmt.Errorf("enrollment.UpdateEnrollmentCompletion: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListEnrollmentsByStudent(ctx context.Context, studentID uuid.UUID) ([]*Enrollment, error) {
	query := `
		SELECT id, student_id, course_batch_id, format, mode, payer, partner_id, franchisee_id,
		       price, final_price, voucher_id, credit_applied, student_credit_id,
		       payment_status, completion_status, source, created_at, updated_at
		FROM enrollment.enrollments WHERE student_id = $1 ORDER BY created_at DESC`

	rows, err := r.pool.Query(ctx, query, studentID)
	if err != nil {
		return nil, fmt.Errorf("enrollment.ListEnrollmentsByStudent: %w", err)
	}
	defer rows.Close()

	var enrollments []*Enrollment
	for rows.Next() {
		e := &Enrollment{}
		if err := rows.Scan(
			&e.ID, &e.StudentID, &e.CourseBatchID, &e.Format, &e.Mode, &e.Payer,
			&e.PartnerID, &e.FranchiseeID, &e.Price, &e.FinalPrice, &e.VoucherID,
			&e.CreditApplied, &e.StudentCreditID, &e.PaymentStatus, &e.CompletionStatus,
			&e.Source, &e.CreatedAt, &e.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("enrollment.ListEnrollmentsByStudent scan: %w", err)
		}
		enrollments = append(enrollments, e)
	}
	return enrollments, rows.Err()
}

func (r *repository) ListEnrollmentsByBatch(ctx context.Context, batchID uuid.UUID) ([]*Enrollment, error) {
	query := `
		SELECT id, student_id, course_batch_id, format, mode, payer, partner_id, franchisee_id,
		       price, final_price, voucher_id, credit_applied, student_credit_id,
		       payment_status, completion_status, source, created_at, updated_at
		FROM enrollment.enrollments WHERE course_batch_id = $1 ORDER BY created_at DESC`

	rows, err := r.pool.Query(ctx, query, batchID)
	if err != nil {
		return nil, fmt.Errorf("enrollment.ListEnrollmentsByBatch: %w", err)
	}
	defer rows.Close()

	var enrollments []*Enrollment
	for rows.Next() {
		e := &Enrollment{}
		if err := rows.Scan(
			&e.ID, &e.StudentID, &e.CourseBatchID, &e.Format, &e.Mode, &e.Payer,
			&e.PartnerID, &e.FranchiseeID, &e.Price, &e.FinalPrice, &e.VoucherID,
			&e.CreditApplied, &e.StudentCreditID, &e.PaymentStatus, &e.CompletionStatus,
			&e.Source, &e.CreatedAt, &e.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("enrollment.ListEnrollmentsByBatch scan: %w", err)
		}
		enrollments = append(enrollments, e)
	}
	return enrollments, rows.Err()
}

func (r *repository) CountEnrollmentsByBatchAndFormat(ctx context.Context, batchID uuid.UUID, format EnrollmentFormat) (int, error) {
	const query = `SELECT count(*) FROM enrollment.enrollments
		WHERE course_batch_id = $1 AND format = $2 AND completion_status <> 'dropped'`
	var count int
	if err := r.pool.QueryRow(ctx, query, batchID, format).Scan(&count); err != nil {
		return 0, fmt.Errorf("enrollment.CountEnrollmentsByBatchAndFormat: %w", err)
	}
	return count, nil
}

func (r *repository) GetVoucherByCode(ctx context.Context, code string) (*Voucher, error) {
	query := `
		SELECT id, code, discount_type, discount_value, assigned_to, course_id, course_batch_id,
		       valid_from, valid_until, max_uses, used_count, is_active, created_by, created_at, updated_at
		FROM enrollment.vouchers WHERE code = $1`

	v := &Voucher{}
	err := r.pool.QueryRow(ctx, query, code).Scan(
		&v.ID, &v.Code, &v.DiscountType, &v.DiscountValue, &v.AssignedTo, &v.CourseID,
		&v.CourseBatchID, &v.ValidFrom, &v.ValidUntil, &v.MaxUses, &v.UsedCount,
		&v.IsActive, &v.CreatedBy, &v.CreatedAt, &v.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("enrollment.GetVoucherByCode: %w", err)
	}
	return v, nil
}

// pgUniqueViolation is the SQLSTATE code for unique constraint violations.
const pgUniqueViolation = "23505"

func (r *repository) CreateVoucher(ctx context.Context, v *Voucher) error {
	query := `
		INSERT INTO enrollment.vouchers
		  (id, code, discount_type, discount_value, assigned_to, course_id, course_batch_id,
		   valid_from, valid_until, max_uses, is_active, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		v.ID, v.Code, v.DiscountType, v.DiscountValue, v.AssignedTo, v.CourseID, v.CourseBatchID,
		v.ValidFrom, v.ValidUntil, v.MaxUses, v.IsActive, v.CreatedBy,
	).Scan(&v.CreatedAt, &v.UpdatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgUniqueViolation {
			return apperrors.Conflictf("voucher code already exists")
		}
		return fmt.Errorf("enrollment.CreateVoucher: %w", err)
	}
	return nil
}

func (r *repository) GetVoucherByID(ctx context.Context, id uuid.UUID) (*Voucher, error) {
	query := `
		SELECT id, code, discount_type, discount_value, assigned_to, course_id, course_batch_id,
		       valid_from, valid_until, max_uses, used_count, is_active, created_by, created_at, updated_at
		FROM enrollment.vouchers WHERE id = $1`

	v := &Voucher{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&v.ID, &v.Code, &v.DiscountType, &v.DiscountValue, &v.AssignedTo, &v.CourseID,
		&v.CourseBatchID, &v.ValidFrom, &v.ValidUntil, &v.MaxUses, &v.UsedCount,
		&v.IsActive, &v.CreatedBy, &v.CreatedAt, &v.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("enrollment.GetVoucherByID: %w", err)
	}
	return v, nil
}

func (r *repository) AssignVoucher(ctx context.Context, id, studentID uuid.UUID) error {
	const query = `UPDATE enrollment.vouchers
		SET assigned_to=$2, updated_at=now()
		WHERE id=$1 AND assigned_to IS NULL`
	ct, err := r.pool.Exec(ctx, query, id, studentID)
	if err != nil {
		return fmt.Errorf("enrollment.AssignVoucher: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.Conflictf("voucher not found or already assigned")
	}
	return nil
}

func (r *repository) DeactivateVoucher(ctx context.Context, id uuid.UUID) error {
	const query = `UPDATE enrollment.vouchers SET is_active=false, updated_at=now() WHERE id=$1`
	ct, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("enrollment.DeactivateVoucher: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// ConsumeVoucher atomically locks the voucher row, validates state,
// increments used_count, and inserts a voucher_usages row in one tx.
// Relies on FOR UPDATE for concurrent safety and the UNIQUE(enrollment_id)
// constraint on voucher_usages to detect duplicate consumption.
func (r *repository) ConsumeVoucher(ctx context.Context, p ConsumeVoucherParams) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("enrollment.ConsumeVoucher begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	var (
		assignedTo *uuid.UUID
		validUntil *time.Time
		maxUses    *int
		usedCount  int
		isActive   bool
	)
	err = tx.QueryRow(ctx,
		`SELECT assigned_to, valid_until, max_uses, used_count, is_active
		 FROM enrollment.vouchers WHERE id = $1 FOR UPDATE`,
		p.VoucherID,
	).Scan(&assignedTo, &validUntil, &maxUses, &usedCount, &isActive)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("enrollment.ConsumeVoucher lock: %w", err)
	}

	if !isActive {
		return apperrors.Validationf("voucher inactive")
	}
	if assignedTo != nil && *assignedTo != p.StudentID {
		return apperrors.ErrForbidden
	}
	if validUntil != nil && validUntil.Before(time.Now().UTC()) {
		return apperrors.Validationf("voucher expired")
	}
	if maxUses != nil && usedCount >= *maxUses {
		return apperrors.Validationf("voucher max uses reached")
	}

	if _, err := tx.Exec(ctx,
		`UPDATE enrollment.vouchers
		 SET used_count = used_count + 1, updated_at = now()
		 WHERE id = $1`,
		p.VoucherID,
	); err != nil {
		return fmt.Errorf("enrollment.ConsumeVoucher incr: %w", err)
	}

	var usageID uuid.UUID
	err = tx.QueryRow(ctx,
		`INSERT INTO enrollment.voucher_usages
		   (id, voucher_id, enrollment_id, original_price, final_price, created_by)
		 VALUES ($1, $2, $3, $4, $5, $6)
		 ON CONFLICT (enrollment_id) DO NOTHING
		 RETURNING id`,
		uuid.New(), p.VoucherID, p.EnrollmentID, p.OriginalPrice, p.FinalPrice, p.CreatedBy,
	).Scan(&usageID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.Conflictf("voucher already used for this enrollment")
		}
		return fmt.Errorf("enrollment.ConsumeVoucher insert usage: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("enrollment.ConsumeVoucher commit: %w", err)
	}
	return nil
}
