package enrollment

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines enrollment data access.
type Repository interface {
	CreateEnrollment(ctx context.Context, e *Enrollment) error
	GetEnrollmentByID(ctx context.Context, id uuid.UUID) (*Enrollment, error)
	GetEnrollmentByStudentAndBatch(ctx context.Context, studentID, batchID uuid.UUID) (*Enrollment, error)
	UpdateEnrollmentStatus(ctx context.Context, id uuid.UUID, payStatus PaymentStatus, compStatus CompletionStatus) error
	ListEnrollmentsByStudent(ctx context.Context, studentID uuid.UUID) ([]*Enrollment, error)
	ListEnrollmentsByBatch(ctx context.Context, batchID uuid.UUID) ([]*Enrollment, error)

	GetVoucherByCode(ctx context.Context, code string) (*Voucher, error)
	CreateVoucher(ctx context.Context, v *Voucher) error
	IncrementVoucherUsage(ctx context.Context, voucherID uuid.UUID) error

	CreateVoucherUsage(ctx context.Context, vu *VoucherUsage) error
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
		   price, final_price, voucher_id, credit_applied, payment_status, completion_status, source)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		e.ID, e.StudentID, e.CourseBatchID, e.Format, e.Mode, e.Payer, e.PartnerID, e.FranchiseeID,
		e.Price, e.FinalPrice, e.VoucherID, e.CreditApplied, e.PaymentStatus, e.CompletionStatus, e.Source,
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
		return fmt.Errorf("enrollment.CreateVoucher: %w", err)
	}
	return nil
}

func (r *repository) IncrementVoucherUsage(ctx context.Context, voucherID uuid.UUID) error {
	query := `UPDATE enrollment.vouchers SET used_count = used_count + 1 WHERE id = $1`
	ct, err := r.pool.Exec(ctx, query, voucherID)
	if err != nil {
		return fmt.Errorf("enrollment.IncrementVoucherUsage: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) CreateVoucherUsage(ctx context.Context, vu *VoucherUsage) error {
	query := `
		INSERT INTO enrollment.voucher_usages (id, voucher_id, enrollment_id, original_price, final_price, created_by)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING used_at`

	err := r.pool.QueryRow(ctx, query,
		vu.ID, vu.VoucherID, vu.EnrollmentID, vu.OriginalPrice, vu.FinalPrice, vu.CreatedBy,
	).Scan(&vu.UsedAt)
	if err != nil {
		return fmt.Errorf("enrollment.CreateVoucherUsage: %w", err)
	}
	return nil
}
