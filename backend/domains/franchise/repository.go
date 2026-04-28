package franchise

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines franchise data access.
type Repository interface {
	CreateFranchisee(ctx context.Context, f *Franchisee) error
	GetFranchiseeByID(ctx context.Context, id uuid.UUID) (*Franchisee, error)
	ListFranchisees(ctx context.Context) ([]*Franchisee, error)
	GetFranchiseeByUserID(ctx context.Context, userID uuid.UUID) (*Franchisee, error)
	ListRoyaltyByFranchisee(ctx context.Context, franchiseeID uuid.UUID) ([]*RoyaltyPaymentRecord, error)

	CreateAgreement(ctx context.Context, a *FranchiseAgreement) error
	GetAgreementByFranchiseeID(ctx context.Context, franchiseeID uuid.UUID) (*FranchiseAgreement, error)

	CreateBranchOtherRevenue(ctx context.Context, r *BranchOtherRevenue) error

	CreateRoyaltyRecord(ctx context.Context, rec *RoyaltyPaymentRecord) error
	GetRoyaltyRecord(ctx context.Context, franchiseeID uuid.UUID, period string) (*RoyaltyPaymentRecord, error)
	GetRoyaltyRecordByID(ctx context.Context, id uuid.UUID) (*RoyaltyPaymentRecord, error)
	MarkRoyaltyPaid(ctx context.Context, id uuid.UUID) error
	MarkOverdueRoyalties(ctx context.Context) error

	GetEnrollmentRevenue(ctx context.Context, franchiseeID uuid.UUID, period string) (string, error)
	GetOtherRevenue(ctx context.Context, franchiseeID uuid.UUID, period string) (string, error)
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates a franchise repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreateFranchisee(ctx context.Context, f *Franchisee) error {
	query := `
		INSERT INTO franchise.franchisees (id, name, branch_name, location, contact, status, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		f.ID, f.Name, f.BranchName, f.Location, f.Contact, f.Status, f.CreatedBy,
	).Scan(&f.CreatedAt, &f.UpdatedAt)
	if err != nil {
		return fmt.Errorf("franchise.CreateFranchisee: %w", err)
	}
	return nil
}

func (r *repository) GetFranchiseeByID(ctx context.Context, id uuid.UUID) (*Franchisee, error) {
	query := `
		SELECT id, name, branch_name, location, contact, status, created_by, user_id, created_at, updated_at
		FROM franchise.franchisees WHERE id = $1`

	f := &Franchisee{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&f.ID, &f.Name, &f.BranchName, &f.Location, &f.Contact,
		&f.Status, &f.CreatedBy, &f.UserID, &f.CreatedAt, &f.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("franchise.GetFranchiseeByID: %w", err)
	}
	return f, nil
}

func (r *repository) ListFranchisees(ctx context.Context) ([]*Franchisee, error) {
	query := `
		SELECT id, name, branch_name, location, contact, status, created_by, user_id, created_at, updated_at
		FROM franchise.franchisees ORDER BY created_at DESC`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("franchise.ListFranchisees: %w", err)
	}
	defer rows.Close()

	var list []*Franchisee
	for rows.Next() {
		f := &Franchisee{}
		if err := rows.Scan(
			&f.ID, &f.Name, &f.BranchName, &f.Location, &f.Contact,
			&f.Status, &f.CreatedBy, &f.UserID, &f.CreatedAt, &f.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("franchise.ListFranchisees scan: %w", err)
		}
		list = append(list, f)
	}
	return list, rows.Err()
}

func (r *repository) CreateAgreement(ctx context.Context, a *FranchiseAgreement) error {
	query := `
		INSERT INTO franchise.franchise_agreements
		  (id, franchisee_id, buy_in_fee, monthly_royalty, revenue_royalty_pct, start_date, end_date, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		a.ID, a.FranchiseeID, a.BuyInFee, a.MonthlyRoyalty,
		a.RevenueRoyaltyPct, a.StartDate, a.EndDate, a.Status,
	).Scan(&a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return fmt.Errorf("franchise.CreateAgreement: %w", err)
	}
	return nil
}

func (r *repository) GetAgreementByFranchiseeID(ctx context.Context, franchiseeID uuid.UUID) (*FranchiseAgreement, error) {
	query := `
		SELECT id, franchisee_id, buy_in_fee, monthly_royalty, revenue_royalty_pct,
		       start_date, end_date, status, created_at, updated_at
		FROM franchise.franchise_agreements WHERE franchisee_id = $1 AND status = 'active'
		LIMIT 1`

	a := &FranchiseAgreement{}
	err := r.pool.QueryRow(ctx, query, franchiseeID).Scan(
		&a.ID, &a.FranchiseeID, &a.BuyInFee, &a.MonthlyRoyalty, &a.RevenueRoyaltyPct,
		&a.StartDate, &a.EndDate, &a.Status, &a.CreatedAt, &a.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("franchise.GetAgreementByFranchiseeID: %w", err)
	}
	return a, nil
}

func (r *repository) CreateBranchOtherRevenue(ctx context.Context, rev *BranchOtherRevenue) error {
	query := `
		INSERT INTO franchise.branch_other_revenues
		  (id, franchisee_id, label, amount, revenue_date, added_by)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		rev.ID, rev.FranchiseeID, rev.Label, rev.Amount, rev.RevenueDate, rev.AddedBy,
	).Scan(&rev.CreatedAt, &rev.UpdatedAt)
	if err != nil {
		return fmt.Errorf("franchise.CreateBranchOtherRevenue: %w", err)
	}
	return nil
}

func (r *repository) CreateRoyaltyRecord(ctx context.Context, rec *RoyaltyPaymentRecord) error {
	query := `
		INSERT INTO franchise.royalty_payment_records
		  (id, franchise_agreement_id, period, gross_revenue, monthly_royalty,
		   revenue_royalty, total_royalty, status, recorded_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING created_at`

	err := r.pool.QueryRow(ctx, query,
		rec.ID, rec.FranchiseAgreementID, rec.Period, rec.GrossRevenue,
		rec.MonthlyRoyalty, rec.RevenueRoyalty, rec.TotalRoyalty, rec.Status, rec.RecordedBy,
	).Scan(&rec.CreatedAt)
	if err != nil {
		return fmt.Errorf("franchise.CreateRoyaltyRecord: %w", err)
	}
	return nil
}

func (r *repository) GetRoyaltyRecord(ctx context.Context, franchiseeID uuid.UUID, period string) (*RoyaltyPaymentRecord, error) {
	query := `
		SELECT rpr.id, rpr.franchise_agreement_id, rpr.period, rpr.gross_revenue,
		       rpr.monthly_royalty, rpr.revenue_royalty, rpr.total_royalty,
		       rpr.status, rpr.created_at, rpr.paid_at, rpr.recorded_by
		FROM franchise.royalty_payment_records rpr
		JOIN franchise.franchise_agreements fa ON fa.id = rpr.franchise_agreement_id
		WHERE fa.franchisee_id = $1 AND rpr.period = $2`

	rec := &RoyaltyPaymentRecord{}
	err := r.pool.QueryRow(ctx, query, franchiseeID, period).Scan(
		&rec.ID, &rec.FranchiseAgreementID, &rec.Period, &rec.GrossRevenue,
		&rec.MonthlyRoyalty, &rec.RevenueRoyalty, &rec.TotalRoyalty,
		&rec.Status, &rec.CreatedAt, &rec.PaidAt, &rec.RecordedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("franchise.GetRoyaltyRecord: %w", err)
	}
	return rec, nil
}

func (r *repository) GetRoyaltyRecordByID(ctx context.Context, id uuid.UUID) (*RoyaltyPaymentRecord, error) {
	query := `
		SELECT id, franchise_agreement_id, period, gross_revenue, monthly_royalty,
		       revenue_royalty, total_royalty, status, created_at, paid_at, recorded_by
		FROM franchise.royalty_payment_records WHERE id = $1`

	rec := &RoyaltyPaymentRecord{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&rec.ID, &rec.FranchiseAgreementID, &rec.Period, &rec.GrossRevenue,
		&rec.MonthlyRoyalty, &rec.RevenueRoyalty, &rec.TotalRoyalty,
		&rec.Status, &rec.CreatedAt, &rec.PaidAt, &rec.RecordedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("franchise.GetRoyaltyRecordByID: %w", err)
	}
	return rec, nil
}

func (r *repository) MarkRoyaltyPaid(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE franchise.royalty_payment_records SET status='paid', paid_at=now() WHERE id=$1 AND status<>'paid'`
	ct, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("franchise.MarkRoyaltyPaid: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// MarkOverdueRoyalties marks unpaid royalty records as overdue when the period
// end date + 14 days has passed. Period is YYYY-MM; end date = last day of month.
func (r *repository) MarkOverdueRoyalties(ctx context.Context) error {
	query := `
		UPDATE franchise.royalty_payment_records
		SET status = 'overdue'
		WHERE status = 'unpaid'
		  AND (to_date(period || '-01', 'YYYY-MM-DD') + interval '1 month - 1 day' + interval '14 days') < now()`

	_, err := r.pool.Exec(ctx, query)
	if err != nil {
		return fmt.Errorf("franchise.MarkOverdueRoyalties: %w", err)
	}
	return nil
}

// GetEnrollmentRevenue returns the sum of enrollment price_paid for a franchisee
// in the given period (YYYY-MM). Returns the sum as a decimal string.
func (r *repository) GetEnrollmentRevenue(ctx context.Context, franchiseeID uuid.UUID, period string) (string, error) {
	query := `
		SELECT COALESCE(SUM(e.final_price), 0)::TEXT
		FROM enrollment.enrollments e
		WHERE e.franchisee_id = $1
		  AND date_trunc('month', e.created_at) = date_trunc('month', to_date($2 || '-01', 'YYYY-MM-DD'))`

	var sum string
	err := r.pool.QueryRow(ctx, query, franchiseeID, period).Scan(&sum)
	if err != nil {
		return "0", fmt.Errorf("franchise.GetEnrollmentRevenue: %w", err)
	}
	return sum, nil
}

func (r *repository) GetFranchiseeByUserID(ctx context.Context, userID uuid.UUID) (*Franchisee, error) {
	query := `
		SELECT id, name, branch_name, location, contact, status, created_by, user_id, created_at, updated_at
		FROM franchise.franchisees WHERE user_id = $1`

	f := &Franchisee{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&f.ID, &f.Name, &f.BranchName, &f.Location, &f.Contact,
		&f.Status, &f.CreatedBy, &f.UserID, &f.CreatedAt, &f.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("franchise.GetFranchiseeByUserID: %w", err)
	}
	return f, nil
}

func (r *repository) ListRoyaltyByFranchisee(ctx context.Context, franchiseeID uuid.UUID) ([]*RoyaltyPaymentRecord, error) {
	query := `
		SELECT rpr.id, rpr.franchise_agreement_id, rpr.period, rpr.gross_revenue,
		       rpr.monthly_royalty, rpr.revenue_royalty, rpr.total_royalty,
		       rpr.status, rpr.created_at, rpr.paid_at, rpr.recorded_by
		FROM franchise.royalty_payment_records rpr
		JOIN franchise.franchise_agreements fa ON fa.id = rpr.franchise_agreement_id
		WHERE fa.franchisee_id = $1
		ORDER BY rpr.period DESC`

	rows, err := r.pool.Query(ctx, query, franchiseeID)
	if err != nil {
		return nil, fmt.Errorf("franchise.ListRoyaltyByFranchisee: %w", err)
	}
	defer rows.Close()

	var list []*RoyaltyPaymentRecord
	for rows.Next() {
		rec := &RoyaltyPaymentRecord{}
		if err := rows.Scan(
			&rec.ID, &rec.FranchiseAgreementID, &rec.Period, &rec.GrossRevenue,
			&rec.MonthlyRoyalty, &rec.RevenueRoyalty, &rec.TotalRoyalty,
			&rec.Status, &rec.CreatedAt, &rec.PaidAt, &rec.RecordedBy,
		); err != nil {
			return nil, fmt.Errorf("franchise.ListRoyaltyByFranchisee scan: %w", err)
		}
		list = append(list, rec)
	}
	return list, nil
}

// GetOtherRevenue returns the sum of branch_other_revenues for a franchisee
// in the given period (YYYY-MM). Returns the sum as a decimal string.
func (r *repository) GetOtherRevenue(ctx context.Context, franchiseeID uuid.UUID, period string) (string, error) {
	query := `
		SELECT COALESCE(SUM(amount), 0)::TEXT
		FROM franchise.branch_other_revenues
		WHERE franchisee_id = $1
		  AND to_char(revenue_date, 'YYYY-MM') = $2`

	var sum string
	err := r.pool.QueryRow(ctx, query, franchiseeID, period).Scan(&sum)
	if err != nil {
		return "0", fmt.Errorf("franchise.GetOtherRevenue: %w", err)
	}
	return sum, nil
}
