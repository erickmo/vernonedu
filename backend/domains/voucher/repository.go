package voucher

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines voucher data access.
type Repository interface {
	CreateVoucher(ctx context.Context, v *Voucher) error
	GetVoucherByID(ctx context.Context, id uuid.UUID) (*Voucher, error)
	GetVoucherByCode(ctx context.Context, code string) (*Voucher, error)
	ListVouchers(ctx context.Context, f ListFilter) ([]*Voucher, error)
	ListByAssignedStudent(ctx context.Context, studentID uuid.UUID) ([]*Voucher, error)
	DeactivateVoucher(ctx context.Context, id uuid.UUID) error

	// ApplyVoucher atomically validates, records usage and increments used_count.
	ApplyVoucher(ctx context.Context, vu *VoucherUsage) (*VoucherUsage, error)

	GetUsageByEnrollment(ctx context.Context, enrollmentID uuid.UUID) (*VoucherUsage, error)
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository constructs a voucher repository backed by a pgxpool.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

const voucherCols = `id, code, discount_type, discount_value, assigned_to, course_id, course_batch_id,
       valid_from, valid_until, max_uses, used_count, is_active, created_by, created_at, updated_at`

func scanVoucher(row pgx.Row, v *Voucher) error {
	return row.Scan(
		&v.ID, &v.Code, &v.DiscountType, &v.DiscountValue,
		&v.AssignedTo, &v.CourseID, &v.CourseBatchID,
		&v.ValidFrom, &v.ValidUntil, &v.MaxUses, &v.UsedCount,
		&v.IsActive, &v.CreatedBy, &v.CreatedAt, &v.UpdatedAt,
	)
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
		return fmt.Errorf("voucher.CreateVoucher: %w", err)
	}
	return nil
}

func (r *repository) GetVoucherByID(ctx context.Context, id uuid.UUID) (*Voucher, error) {
	query := fmt.Sprintf(`SELECT %s FROM enrollment.vouchers WHERE id = $1`, voucherCols)
	v := &Voucher{}
	if err := scanVoucher(r.pool.QueryRow(ctx, query, id), v); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("voucher.GetVoucherByID: %w", err)
	}
	return v, nil
}

func (r *repository) GetVoucherByCode(ctx context.Context, code string) (*Voucher, error) {
	query := fmt.Sprintf(`SELECT %s FROM enrollment.vouchers WHERE code = $1`, voucherCols)
	v := &Voucher{}
	if err := scanVoucher(r.pool.QueryRow(ctx, query, code), v); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("voucher.GetVoucherByCode: %w", err)
	}
	return v, nil
}

func (r *repository) ListVouchers(ctx context.Context, f ListFilter) ([]*Voucher, error) {
	conditions := []string{"1=1"}
	args := []any{}
	argIdx := 1

	if f.IsActive != nil {
		conditions = append(conditions, fmt.Sprintf("is_active = $%d", argIdx))
		args = append(args, *f.IsActive)
		argIdx++
	}
	if f.Code != "" {
		conditions = append(conditions, fmt.Sprintf("code ILIKE $%d", argIdx))
		args = append(args, "%"+f.Code+"%")
	}

	query := fmt.Sprintf(
		`SELECT %s FROM enrollment.vouchers WHERE %s ORDER BY created_at DESC`,
		voucherCols, strings.Join(conditions, " AND "),
	)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("voucher.ListVouchers: %w", err)
	}
	defer rows.Close()

	var out []*Voucher
	for rows.Next() {
		v := &Voucher{}
		if err := scanVoucher(rows, v); err != nil {
			return nil, fmt.Errorf("voucher.ListVouchers scan: %w", err)
		}
		out = append(out, v)
	}
	return out, rows.Err()
}

func (r *repository) ListByAssignedStudent(ctx context.Context, studentID uuid.UUID) ([]*Voucher, error) {
	query := fmt.Sprintf(
		`SELECT %s FROM enrollment.vouchers WHERE assigned_to = $1 AND is_active = TRUE ORDER BY created_at DESC`,
		voucherCols,
	)
	rows, err := r.pool.Query(ctx, query, studentID)
	if err != nil {
		return nil, fmt.Errorf("voucher.ListByAssignedStudent: %w", err)
	}
	defer rows.Close()

	var out []*Voucher
	for rows.Next() {
		v := &Voucher{}
		if err := scanVoucher(rows, v); err != nil {
			return nil, fmt.Errorf("voucher.ListByAssignedStudent scan: %w", err)
		}
		out = append(out, v)
	}
	return out, rows.Err()
}

func (r *repository) DeactivateVoucher(ctx context.Context, id uuid.UUID) error {
	ct, err := r.pool.Exec(ctx,
		`UPDATE enrollment.vouchers SET is_active = FALSE WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("voucher.DeactivateVoucher: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// ApplyVoucher runs atomically: SELECT FOR UPDATE → validate → INSERT usage → UPDATE used_count.
func (r *repository) ApplyVoucher(ctx context.Context, vu *VoucherUsage) (*VoucherUsage, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("voucher.ApplyVoucher begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	locked, err := lockVoucher(ctx, tx, vu.VoucherID)
	if err != nil {
		return nil, err
	}

	if err := validateLocked(locked, time.Now()); err != nil {
		return nil, err
	}

	out, err := insertUsage(ctx, tx, vu)
	if err != nil {
		return nil, err
	}

	if err := incrementUsedCount(ctx, tx, vu.VoucherID); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("voucher.ApplyVoucher commit: %w", err)
	}
	return out, nil
}

// lockedVoucher holds the minimal fields needed for validation under lock.
type lockedVoucher struct {
	usedCount int
	maxUses   *int
	isActive  bool
	validUntil *time.Time
	assignedTo *uuid.UUID
	courseID   *uuid.UUID
	batchID    *uuid.UUID
}

func lockVoucher(ctx context.Context, tx pgx.Tx, id uuid.UUID) (*lockedVoucher, error) {
	query := `
		SELECT used_count, max_uses, is_active, valid_until, assigned_to, course_id, course_batch_id
		FROM enrollment.vouchers WHERE id = $1 FOR UPDATE`
	lv := &lockedVoucher{}
	err := tx.QueryRow(ctx, query, id).Scan(
		&lv.usedCount, &lv.maxUses, &lv.isActive, &lv.validUntil,
		&lv.assignedTo, &lv.courseID, &lv.batchID,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("voucher.lockVoucher: %w", err)
	}
	return lv, nil
}

func validateLocked(lv *lockedVoucher, now time.Time) error {
	if !lv.isActive {
		return apperrors.Validationf("voucher is not active")
	}
	if lv.validUntil != nil && now.After(*lv.validUntil) {
		return apperrors.Validationf("voucher has expired")
	}
	if lv.maxUses != nil && lv.usedCount >= *lv.maxUses {
		return apperrors.Validationf("voucher usage limit reached")
	}
	return nil
}

func insertUsage(ctx context.Context, tx pgx.Tx, vu *VoucherUsage) (*VoucherUsage, error) {
	query := `
		INSERT INTO enrollment.voucher_usages (id, voucher_id, enrollment_id, original_price, final_price, created_by)
		VALUES ($1,$2,$3,$4,$5,$6)
		RETURNING used_at`
	out := *vu
	err := tx.QueryRow(ctx, query,
		vu.ID, vu.VoucherID, vu.EnrollmentID, vu.OriginalPrice, vu.FinalPrice, vu.CreatedBy,
	).Scan(&out.UsedAt)
	if err != nil {
		return nil, fmt.Errorf("voucher.insertUsage: %w", err)
	}
	return &out, nil
}

func incrementUsedCount(ctx context.Context, tx pgx.Tx, id uuid.UUID) error {
	_, err := tx.Exec(ctx,
		`UPDATE enrollment.vouchers SET used_count = used_count + 1 WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("voucher.incrementUsedCount: %w", err)
	}
	return nil
}

func (r *repository) GetUsageByEnrollment(ctx context.Context, enrollmentID uuid.UUID) (*VoucherUsage, error) {
	query := `
		SELECT id, voucher_id, enrollment_id, original_price, final_price, used_at, created_by
		FROM enrollment.voucher_usages WHERE enrollment_id = $1`
	vu := &VoucherUsage{}
	err := r.pool.QueryRow(ctx, query, enrollmentID).Scan(
		&vu.ID, &vu.VoucherID, &vu.EnrollmentID, &vu.OriginalPrice, &vu.FinalPrice, &vu.UsedAt, &vu.CreatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("voucher.GetUsageByEnrollment: %w", err)
	}
	return vu, nil
}
