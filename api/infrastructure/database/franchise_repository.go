package database

import (
	"context"
	"database/sql"
	"errors"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
)

type FranchiseRepository struct {
	db *sqlx.DB
}

func NewFranchiseRepository(db *sqlx.DB) *FranchiseRepository {
	return &FranchiseRepository{db: db}
}

// ─── DB record types ────────────────────────────────────────────────────────

type franchiseeRecord struct {
	ID         uuid.UUID  `db:"id"`
	Name       string     `db:"name"`
	BranchName string     `db:"branch_name"`
	Location   string     `db:"location"`
	Contact    string     `db:"contact"`
	Status     string     `db:"status"`
	CreatedBy  *uuid.UUID `db:"created_by"`
	CreatedAt  time.Time  `db:"created_at"`
	UpdatedAt  time.Time  `db:"updated_at"`
}

type franchiseAgreementRecord struct {
	ID                uuid.UUID      `db:"id"`
	FranchiseeID      uuid.UUID      `db:"franchisee_id"`
	BuyInFee          float64        `db:"buy_in_fee"`
	MonthlyRoyalty    float64        `db:"monthly_royalty"`
	RevenueRoyaltyPct float64        `db:"revenue_royalty_pct"`
	StartDate         string         `db:"start_date"`
	EndDate           sql.NullString `db:"end_date"`
	Status            string         `db:"status"`
	CreatedAt         time.Time      `db:"created_at"`
	UpdatedAt         time.Time      `db:"updated_at"`
}

type royaltyPaymentRecord struct {
	ID                   uuid.UUID  `db:"id"`
	FranchiseAgreementID uuid.UUID  `db:"franchise_agreement_id"`
	Period               string     `db:"period"`
	GrossRevenue         float64    `db:"gross_revenue"`
	MonthlyRoyalty       float64    `db:"monthly_royalty"`
	RevenueRoyalty       float64    `db:"revenue_royalty"`
	TotalRoyalty         float64    `db:"total_royalty"`
	Status               string     `db:"status"`
	PaidAt               *time.Time `db:"paid_at"`
	RecordedBy           *uuid.UUID `db:"recorded_by"`
	CreatedAt            time.Time  `db:"created_at"`
	UpdatedAt            time.Time  `db:"updated_at"`
}

type branchOtherRevenueRecord struct {
	ID           uuid.UUID  `db:"id"`
	FranchiseeID uuid.UUID  `db:"franchisee_id"`
	Label        string     `db:"label"`
	Amount       float64    `db:"amount"`
	RevenueDate  string     `db:"revenue_date"`
	AddedBy      *uuid.UUID `db:"added_by"`
	CreatedAt    time.Time  `db:"created_at"`
	UpdatedAt    time.Time  `db:"updated_at"`
}

// ─── Write methods ───────────────────────────────────────────────────────────

func (r *FranchiseRepository) SaveFranchisee(ctx context.Context, f *franchise.Franchisee) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO franchisees (id, name, branch_name, location, contact, status, created_by, created_at, updated_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
		f.ID, f.Name, f.BranchName, f.Location, f.Contact, f.Status, f.CreatedBy, f.CreatedAt, f.UpdatedAt,
	)
	return err
}

func (r *FranchiseRepository) UpdateFranchisee(ctx context.Context, f *franchise.Franchisee) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE franchisees SET name=$1, branch_name=$2, location=$3, contact=$4, status=$5, updated_at=$6 WHERE id=$7`,
		f.Name, f.BranchName, f.Location, f.Contact, f.Status, f.UpdatedAt, f.ID,
	)
	return err
}

func (r *FranchiseRepository) SaveAgreement(ctx context.Context, a *franchise.FranchiseAgreement) error {
	endDate := sql.NullString{String: a.EndDate, Valid: a.EndDate != ""}
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO franchise_agreements (id, franchisee_id, buy_in_fee, monthly_royalty, revenue_royalty_pct, start_date, end_date, status, created_at, updated_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
		a.ID, a.FranchiseeID, a.BuyInFee, a.MonthlyRoyalty, a.RevenueRoyaltyPct, a.StartDate, endDate, a.Status, a.CreatedAt, a.UpdatedAt,
	)
	return err
}

func (r *FranchiseRepository) UpdateAgreement(ctx context.Context, a *franchise.FranchiseAgreement) error {
	endDate := sql.NullString{String: a.EndDate, Valid: a.EndDate != ""}
	_, err := r.db.ExecContext(ctx,
		`UPDATE franchise_agreements SET buy_in_fee=$1, monthly_royalty=$2, revenue_royalty_pct=$3, start_date=$4, end_date=$5, status=$6, updated_at=$7 WHERE id=$8`,
		a.BuyInFee, a.MonthlyRoyalty, a.RevenueRoyaltyPct, a.StartDate, endDate, a.Status, a.UpdatedAt, a.ID,
	)
	return err
}

func (r *FranchiseRepository) SaveRoyaltyPayment(ctx context.Context, rp *franchise.RoyaltyPaymentRecord) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO royalty_payment_records (id, franchise_agreement_id, period, gross_revenue, monthly_royalty, revenue_royalty, total_royalty, status, recorded_by, created_at, updated_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
		rp.ID, rp.FranchiseAgreementID, rp.Period, rp.GrossRevenue, rp.MonthlyRoyalty, rp.RevenueRoyalty, rp.TotalRoyalty, rp.Status, rp.RecordedBy, rp.CreatedAt, rp.UpdatedAt,
	)
	return err
}

func (r *FranchiseRepository) MarkRoyaltyPaid(ctx context.Context, id uuid.UUID, paidAt time.Time) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE royalty_payment_records SET status='paid', paid_at=$1, updated_at=$1 WHERE id=$2`,
		paidAt, id,
	)
	return err
}

func (r *FranchiseRepository) SaveOtherRevenue(ctx context.Context, rv *franchise.BranchOtherRevenue) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO branch_other_revenues (id, franchisee_id, label, amount, revenue_date, added_by, created_at, updated_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
		rv.ID, rv.FranchiseeID, rv.Label, rv.Amount, rv.RevenueDate, rv.AddedBy, rv.CreatedAt, rv.UpdatedAt,
	)
	return err
}

func (r *FranchiseRepository) UpdateOtherRevenue(ctx context.Context, rv *franchise.BranchOtherRevenue) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE branch_other_revenues SET label=$1, amount=$2, revenue_date=$3, updated_at=$4 WHERE id=$5`,
		rv.Label, rv.Amount, rv.RevenueDate, rv.UpdatedAt, rv.ID,
	)
	return err
}

func (r *FranchiseRepository) DeleteOtherRevenue(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM branch_other_revenues WHERE id=$1`, id)
	return err
}

// ─── Read methods ────────────────────────────────────────────────────────────

func (r *FranchiseRepository) GetFranchiseeByID(ctx context.Context, id uuid.UUID) (*franchise.Franchisee, error) {
	var rec franchiseeRecord
	err := r.db.GetContext(ctx, &rec, `SELECT * FROM franchisees WHERE id=$1`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, franchise.ErrFranchiseeNotFound
	}
	if err != nil {
		return nil, err
	}
	return franchiseeFromRecord(&rec), nil
}

func (r *FranchiseRepository) ListFranchisees(ctx context.Context, offset, limit int, status, search string) ([]*franchise.Franchisee, int, error) {
	args := []interface{}{}
	where := "WHERE 1=1"
	idx := 1
	if status != "" {
		where += " AND status=$" + strconv.Itoa(idx)
		args = append(args, status)
		idx++
	}
	if search != "" {
		where += " AND (name ILIKE $" + strconv.Itoa(idx) + " OR branch_name ILIKE $" + strconv.Itoa(idx) + ")"
		args = append(args, "%"+search+"%")
		idx++
	}
	var total int
	err := r.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM franchisees "+where, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}
	args = append(args, limit, offset)
	rows, err := r.db.QueryxContext(ctx,
		"SELECT * FROM franchisees "+where+" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(idx)+" OFFSET $"+strconv.Itoa(idx+1),
		args...,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	var result []*franchise.Franchisee
	for rows.Next() {
		var rec franchiseeRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, 0, err
		}
		result = append(result, franchiseeFromRecord(&rec))
	}
	return result, total, nil
}

func (r *FranchiseRepository) GetAgreementByFranchiseeID(ctx context.Context, franchiseeID uuid.UUID) (*franchise.FranchiseAgreement, error) {
	var rec franchiseAgreementRecord
	err := r.db.GetContext(ctx, &rec, `SELECT * FROM franchise_agreements WHERE franchisee_id=$1 ORDER BY created_at DESC LIMIT 1`, franchiseeID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, franchise.ErrAgreementNotFound
	}
	if err != nil {
		return nil, err
	}
	return agreementFromRecord(&rec), nil
}

func (r *FranchiseRepository) GetAgreementByID(ctx context.Context, id uuid.UUID) (*franchise.FranchiseAgreement, error) {
	var rec franchiseAgreementRecord
	err := r.db.GetContext(ctx, &rec, `SELECT * FROM franchise_agreements WHERE id=$1`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, franchise.ErrAgreementNotFound
	}
	if err != nil {
		return nil, err
	}
	return agreementFromRecord(&rec), nil
}

func (r *FranchiseRepository) ListRoyaltyPayments(ctx context.Context, franchiseeID uuid.UUID, period string) ([]*franchise.RoyaltyPaymentRecord, error) {
	query := `SELECT rpr.* FROM royalty_payment_records rpr
	          JOIN franchise_agreements fa ON rpr.franchise_agreement_id = fa.id
	          WHERE fa.franchisee_id=$1`
	args := []interface{}{franchiseeID}
	if period != "" {
		query += " AND rpr.period=$2"
		args = append(args, period)
	}
	query += " ORDER BY rpr.period DESC"
	rows, err := r.db.QueryxContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var result []*franchise.RoyaltyPaymentRecord
	for rows.Next() {
		var rec royaltyPaymentRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, err
		}
		result = append(result, royaltyPaymentFromRecord(&rec))
	}
	return result, nil
}

func (r *FranchiseRepository) GetRoyaltyPaymentByID(ctx context.Context, id uuid.UUID) (*franchise.RoyaltyPaymentRecord, error) {
	var rec royaltyPaymentRecord
	err := r.db.GetContext(ctx, &rec, `SELECT * FROM royalty_payment_records WHERE id=$1`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, franchise.ErrRoyaltyRecordNotFound
	}
	if err != nil {
		return nil, err
	}
	return royaltyPaymentFromRecord(&rec), nil
}

func (r *FranchiseRepository) ListOtherRevenues(ctx context.Context, franchiseeID uuid.UUID, period string) ([]*franchise.BranchOtherRevenue, error) {
	query := `SELECT * FROM branch_other_revenues WHERE franchisee_id=$1`
	args := []interface{}{franchiseeID}
	if period != "" {
		query += " AND TO_CHAR(revenue_date, 'YYYY-MM')=$2"
		args = append(args, period)
	}
	query += " ORDER BY revenue_date DESC"
	rows, err := r.db.QueryxContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var result []*franchise.BranchOtherRevenue
	for rows.Next() {
		var rec branchOtherRevenueRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, err
		}
		result = append(result, otherRevenueFromRecord(&rec))
	}
	return result, nil
}

func (r *FranchiseRepository) GetOtherRevenueByID(ctx context.Context, id uuid.UUID) (*franchise.BranchOtherRevenue, error) {
	var rec branchOtherRevenueRecord
	err := r.db.GetContext(ctx, &rec, `SELECT * FROM branch_other_revenues WHERE id=$1`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, franchise.ErrOtherRevenueNotFound
	}
	if err != nil {
		return nil, err
	}
	return otherRevenueFromRecord(&rec), nil
}

// ─── Mappers ─────────────────────────────────────────────────────────────────

func franchiseeFromRecord(rec *franchiseeRecord) *franchise.Franchisee {
	return &franchise.Franchisee{
		ID:         rec.ID,
		Name:       rec.Name,
		BranchName: rec.BranchName,
		Location:   rec.Location,
		Contact:    rec.Contact,
		Status:     rec.Status,
		CreatedBy:  rec.CreatedBy,
		CreatedAt:  rec.CreatedAt,
		UpdatedAt:  rec.UpdatedAt,
	}
}

func agreementFromRecord(rec *franchiseAgreementRecord) *franchise.FranchiseAgreement {
	endDate := ""
	if rec.EndDate.Valid {
		endDate = rec.EndDate.String
	}
	return &franchise.FranchiseAgreement{
		ID:                rec.ID,
		FranchiseeID:      rec.FranchiseeID,
		BuyInFee:          rec.BuyInFee,
		MonthlyRoyalty:    rec.MonthlyRoyalty,
		RevenueRoyaltyPct: rec.RevenueRoyaltyPct,
		StartDate:         rec.StartDate,
		EndDate:           endDate,
		Status:            rec.Status,
		CreatedAt:         rec.CreatedAt,
		UpdatedAt:         rec.UpdatedAt,
	}
}

func royaltyPaymentFromRecord(rec *royaltyPaymentRecord) *franchise.RoyaltyPaymentRecord {
	return &franchise.RoyaltyPaymentRecord{
		ID:                   rec.ID,
		FranchiseAgreementID: rec.FranchiseAgreementID,
		Period:               rec.Period,
		GrossRevenue:         rec.GrossRevenue,
		MonthlyRoyalty:       rec.MonthlyRoyalty,
		RevenueRoyalty:       rec.RevenueRoyalty,
		TotalRoyalty:         rec.TotalRoyalty,
		Status:               rec.Status,
		PaidAt:               rec.PaidAt,
		RecordedBy:           rec.RecordedBy,
		CreatedAt:            rec.CreatedAt,
		UpdatedAt:            rec.UpdatedAt,
	}
}

func otherRevenueFromRecord(rec *branchOtherRevenueRecord) *franchise.BranchOtherRevenue {
	return &franchise.BranchOtherRevenue{
		ID:           rec.ID,
		FranchiseeID: rec.FranchiseeID,
		Label:        rec.Label,
		Amount:       rec.Amount,
		RevenueDate:  rec.RevenueDate,
		AddedBy:      rec.AddedBy,
		CreatedAt:    rec.CreatedAt,
		UpdatedAt:    rec.UpdatedAt,
	}
}
