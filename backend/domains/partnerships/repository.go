package partnerships

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines partnerships data access.
type Repository interface {
	CreatePartner(ctx context.Context, p *Partner) error
	GetPartnerByID(ctx context.Context, id uuid.UUID) (*Partner, error)
	UpdatePartnerStatus(ctx context.Context, id uuid.UUID, status PartnerStatus) error
	ListPartners(ctx context.Context, status *PartnerStatus) ([]*Partner, error)

	CreateAgreement(ctx context.Context, a *PartnershipAgreement) error
	GetAgreementByID(ctx context.Context, id uuid.UUID) (*PartnershipAgreement, error)
	UpdateAgreementStatus(ctx context.Context, id uuid.UUID, status AgreementStatus) error
	ListAgreementsByPartner(ctx context.Context, partnerID uuid.UUID) ([]*PartnershipAgreement, error)

	CreateFranchisee(ctx context.Context, f *Franchisee) error
	GetFranchiseeByID(ctx context.Context, id uuid.UUID) (*Franchisee, error)
	ListFranchisees(ctx context.Context) ([]*Franchisee, error)

	CreateFranchiseAgreement(ctx context.Context, a *FranchiseAgreement) error
	GetFranchiseAgreementByFranchisee(ctx context.Context, franchiseeID uuid.UUID) (*FranchiseAgreement, error)

	CreateRoyaltyRecord(ctx context.Context, r *RoyaltyPaymentRecord) error
	GetRoyaltyRecordByID(ctx context.Context, id uuid.UUID) (*RoyaltyPaymentRecord, error)
	UpdateRoyaltyStatus(ctx context.Context, id uuid.UUID, status RoyaltyStatus) error
	ListRoyaltyRecordsByAgreement(ctx context.Context, agreementID uuid.UUID) ([]*RoyaltyPaymentRecord, error)
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates partnerships repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreatePartner(ctx context.Context, p *Partner) error {
	query := `
		INSERT INTO partnerships.partners (id, name, type, status, contact_name, contact_email, contact_phone, address, notes)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		p.ID, p.Name, p.Type, p.Status, p.ContactName, p.ContactEmail, p.ContactPhone, p.Address, p.Notes,
	).Scan(&p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return fmt.Errorf("partnerships.CreatePartner: %w", err)
	}
	return nil
}

func (r *repository) GetPartnerByID(ctx context.Context, id uuid.UUID) (*Partner, error) {
	query := `SELECT id, name, type, status, contact_name, contact_email, contact_phone, address, notes, deleted_at, created_at, updated_at
	          FROM partnerships.partners WHERE id = $1 AND deleted_at IS NULL`

	p := &Partner{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&p.ID, &p.Name, &p.Type, &p.Status, &p.ContactName, &p.ContactEmail, &p.ContactPhone,
		&p.Address, &p.Notes, &p.DeletedAt, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("partnerships.GetPartnerByID: %w", err)
	}
	return p, nil
}

func (r *repository) UpdatePartnerStatus(ctx context.Context, id uuid.UUID, status PartnerStatus) error {
	query := `UPDATE partnerships.partners SET status=$1 WHERE id=$2 AND deleted_at IS NULL`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("partnerships.UpdatePartnerStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListPartners(ctx context.Context, status *PartnerStatus) ([]*Partner, error) {
	query := `SELECT id, name, type, status, contact_name, contact_email, contact_phone, address, notes, deleted_at, created_at, updated_at
	          FROM partnerships.partners WHERE deleted_at IS NULL`
	args := []interface{}{}

	if status != nil {
		query += " AND status = $1"
		args = append(args, *status)
	}
	query += " ORDER BY name"

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("partnerships.ListPartners: %w", err)
	}
	defer rows.Close()

	var partners []*Partner
	for rows.Next() {
		p := &Partner{}
		if err := rows.Scan(&p.ID, &p.Name, &p.Type, &p.Status, &p.ContactName, &p.ContactEmail,
			&p.ContactPhone, &p.Address, &p.Notes, &p.DeletedAt, &p.CreatedAt, &p.UpdatedAt); err != nil {
			return nil, fmt.Errorf("partnerships.ListPartners scan: %w", err)
		}
		partners = append(partners, p)
	}
	return partners, rows.Err()
}

func (r *repository) CreateAgreement(ctx context.Context, a *PartnershipAgreement) error {
	query := `
		INSERT INTO partnerships.partnership_agreements
		  (id, partner_id, title, status, start_date, end_date, payment_model, payer, bulk_price, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		a.ID, a.PartnerID, a.Title, a.Status, a.StartDate, a.EndDate,
		a.PaymentModel, a.Payer, a.BulkPrice, a.CreatedBy,
	).Scan(&a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return fmt.Errorf("partnerships.CreateAgreement: %w", err)
	}
	return nil
}

func (r *repository) GetAgreementByID(ctx context.Context, id uuid.UUID) (*PartnershipAgreement, error) {
	query := `SELECT id, partner_id, title, status, start_date, end_date, payment_model, payer, bulk_price,
	                 signed_at, terminated_at, termination_reason, created_by, created_at, updated_at
	          FROM partnerships.partnership_agreements WHERE id = $1`

	a := &PartnershipAgreement{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&a.ID, &a.PartnerID, &a.Title, &a.Status, &a.StartDate, &a.EndDate, &a.PaymentModel, &a.Payer,
		&a.BulkPrice, &a.SignedAt, &a.TerminatedAt, &a.TerminationReason, &a.CreatedBy, &a.CreatedAt, &a.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("partnerships.GetAgreementByID: %w", err)
	}
	return a, nil
}

func (r *repository) UpdateAgreementStatus(ctx context.Context, id uuid.UUID, status AgreementStatus) error {
	query := `UPDATE partnerships.partnership_agreements SET status=$1 WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("partnerships.UpdateAgreementStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListAgreementsByPartner(ctx context.Context, partnerID uuid.UUID) ([]*PartnershipAgreement, error) {
	query := `SELECT id, partner_id, title, status, start_date, end_date, payment_model, payer, bulk_price,
	                 signed_at, terminated_at, termination_reason, created_by, created_at, updated_at
	          FROM partnerships.partnership_agreements WHERE partner_id = $1 ORDER BY created_at DESC`

	rows, err := r.pool.Query(ctx, query, partnerID)
	if err != nil {
		return nil, fmt.Errorf("partnerships.ListAgreementsByPartner: %w", err)
	}
	defer rows.Close()

	var agreements []*PartnershipAgreement
	for rows.Next() {
		a := &PartnershipAgreement{}
		if err := rows.Scan(&a.ID, &a.PartnerID, &a.Title, &a.Status, &a.StartDate, &a.EndDate, &a.PaymentModel,
			&a.Payer, &a.BulkPrice, &a.SignedAt, &a.TerminatedAt, &a.TerminationReason, &a.CreatedBy,
			&a.CreatedAt, &a.UpdatedAt); err != nil {
			return nil, fmt.Errorf("partnerships.ListAgreementsByPartner scan: %w", err)
		}
		agreements = append(agreements, a)
	}
	return agreements, rows.Err()
}

func (r *repository) CreateFranchisee(ctx context.Context, f *Franchisee) error {
	query := `
		INSERT INTO partnerships.franchisees (id, name, branch_name, location, contact, status, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query, f.ID, f.Name, f.BranchName, f.Location, f.Contact, f.Status, f.CreatedBy).
		Scan(&f.CreatedAt, &f.UpdatedAt)
	if err != nil {
		return fmt.Errorf("partnerships.CreateFranchisee: %w", err)
	}
	return nil
}

func (r *repository) GetFranchiseeByID(ctx context.Context, id uuid.UUID) (*Franchisee, error) {
	query := `SELECT id, name, branch_name, location, contact, status, created_by, created_at, updated_at, deleted_at
	          FROM partnerships.franchisees WHERE id = $1 AND deleted_at IS NULL`

	f := &Franchisee{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&f.ID, &f.Name, &f.BranchName, &f.Location, &f.Contact, &f.Status,
		&f.CreatedBy, &f.CreatedAt, &f.UpdatedAt, &f.DeletedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("partnerships.GetFranchiseeByID: %w", err)
	}
	return f, nil
}

func (r *repository) ListFranchisees(ctx context.Context) ([]*Franchisee, error) {
	query := `SELECT id, name, branch_name, location, contact, status, created_by, created_at, updated_at, deleted_at
	          FROM partnerships.franchisees WHERE deleted_at IS NULL ORDER BY name`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("partnerships.ListFranchisees: %w", err)
	}
	defer rows.Close()

	var franchisees []*Franchisee
	for rows.Next() {
		f := &Franchisee{}
		if err := rows.Scan(&f.ID, &f.Name, &f.BranchName, &f.Location, &f.Contact, &f.Status,
			&f.CreatedBy, &f.CreatedAt, &f.UpdatedAt, &f.DeletedAt); err != nil {
			return nil, fmt.Errorf("partnerships.ListFranchisees scan: %w", err)
		}
		franchisees = append(franchisees, f)
	}
	return franchisees, rows.Err()
}

func (r *repository) CreateFranchiseAgreement(ctx context.Context, a *FranchiseAgreement) error {
	query := `
		INSERT INTO partnerships.franchise_agreements
		  (id, franchisee_id, buy_in_fee, monthly_royalty, revenue_royalty_pct, start_date, end_date, status)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		a.ID, a.FranchiseeID, a.BuyInFee, a.MonthlyRoyalty, a.RevenueRoyaltyPct, a.StartDate, a.EndDate, a.Status,
	).Scan(&a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return fmt.Errorf("partnerships.CreateFranchiseAgreement: %w", err)
	}
	return nil
}

func (r *repository) GetFranchiseAgreementByFranchisee(ctx context.Context, franchiseeID uuid.UUID) (*FranchiseAgreement, error) {
	query := `SELECT id, franchisee_id, buy_in_fee, monthly_royalty, revenue_royalty_pct, start_date, end_date, status, created_at, updated_at
	          FROM partnerships.franchise_agreements WHERE franchisee_id = $1 AND status='active' ORDER BY start_date DESC LIMIT 1`

	a := &FranchiseAgreement{}
	err := r.pool.QueryRow(ctx, query, franchiseeID).Scan(
		&a.ID, &a.FranchiseeID, &a.BuyInFee, &a.MonthlyRoyalty, &a.RevenueRoyaltyPct,
		&a.StartDate, &a.EndDate, &a.Status, &a.CreatedAt, &a.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("partnerships.GetFranchiseAgreementByFranchisee: %w", err)
	}
	return a, nil
}

func (r *repository) CreateRoyaltyRecord(ctx context.Context, rec *RoyaltyPaymentRecord) error {
	query := `
		INSERT INTO partnerships.royalty_payment_records
		  (id, franchise_agreement_id, period, gross_revenue, monthly_royalty, revenue_royalty, total_royalty, status, recorded_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		rec.ID, rec.FranchiseAgreementID, rec.Period, rec.GrossRevenue, rec.MonthlyRoyalty,
		rec.RevenueRoyalty, rec.TotalRoyalty, rec.Status, rec.RecordedBy,
	).Scan(&rec.CreatedAt, &rec.UpdatedAt)
	if err != nil {
		return fmt.Errorf("partnerships.CreateRoyaltyRecord: %w", err)
	}
	return nil
}

func (r *repository) GetRoyaltyRecordByID(ctx context.Context, id uuid.UUID) (*RoyaltyPaymentRecord, error) {
	query := `SELECT id, franchise_agreement_id, period, gross_revenue, monthly_royalty, revenue_royalty, total_royalty, status, paid_at, recorded_by, created_at, updated_at
	          FROM partnerships.royalty_payment_records WHERE id = $1`

	rec := &RoyaltyPaymentRecord{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&rec.ID, &rec.FranchiseAgreementID, &rec.Period, &rec.GrossRevenue, &rec.MonthlyRoyalty,
		&rec.RevenueRoyalty, &rec.TotalRoyalty, &rec.Status, &rec.PaidAt, &rec.RecordedBy,
		&rec.CreatedAt, &rec.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("partnerships.GetRoyaltyRecordByID: %w", err)
	}
	return rec, nil
}

func (r *repository) UpdateRoyaltyStatus(ctx context.Context, id uuid.UUID, status RoyaltyStatus) error {
	query := `UPDATE partnerships.royalty_payment_records SET status=$1 WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("partnerships.UpdateRoyaltyStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListRoyaltyRecordsByAgreement(ctx context.Context, agreementID uuid.UUID) ([]*RoyaltyPaymentRecord, error) {
	query := `SELECT id, franchise_agreement_id, period, gross_revenue, monthly_royalty, revenue_royalty, total_royalty, status, paid_at, recorded_by, created_at, updated_at
	          FROM partnerships.royalty_payment_records WHERE franchise_agreement_id = $1 ORDER BY period DESC`

	rows, err := r.pool.Query(ctx, query, agreementID)
	if err != nil {
		return nil, fmt.Errorf("partnerships.ListRoyaltyRecordsByAgreement: %w", err)
	}
	defer rows.Close()

	var records []*RoyaltyPaymentRecord
	for rows.Next() {
		rec := &RoyaltyPaymentRecord{}
		if err := rows.Scan(&rec.ID, &rec.FranchiseAgreementID, &rec.Period, &rec.GrossRevenue, &rec.MonthlyRoyalty,
			&rec.RevenueRoyalty, &rec.TotalRoyalty, &rec.Status, &rec.PaidAt, &rec.RecordedBy,
			&rec.CreatedAt, &rec.UpdatedAt); err != nil {
			return nil, fmt.Errorf("partnerships.ListRoyaltyRecordsByAgreement scan: %w", err)
		}
		records = append(records, rec)
	}
	return records, rows.Err()
}
