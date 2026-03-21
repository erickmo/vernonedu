package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/investment"
)

type InvestmentRepository struct {
	db *sqlx.DB
}

func NewInvestmentRepository(db *sqlx.DB) *InvestmentRepository {
	return &InvestmentRepository{db: db}
}

type investmentRecord struct {
	ID          uuid.UUID `db:"id"`
	Title       string    `db:"title"`
	Category    string    `db:"category"`
	ProposedBy  string    `db:"proposed_by"`
	Amount      int64     `db:"amount"`
	ExpectedROI float64   `db:"expected_roi"`
	ActualSpend int64     `db:"actual_spend"`
	Status      string    `db:"status"`
	ApprovedBy  string    `db:"approved_by"`
	Notes       string    `db:"notes"`
	CreatedAt   time.Time `db:"created_at"`
	UpdatedAt   time.Time `db:"updated_at"`
}

func (rec *investmentRecord) toDomain() *investment.InvestmentPlan {
	return &investment.InvestmentPlan{
		ID:          rec.ID,
		Title:       rec.Title,
		Category:    rec.Category,
		ProposedBy:  rec.ProposedBy,
		Amount:      rec.Amount,
		ExpectedROI: rec.ExpectedROI,
		ActualSpend: rec.ActualSpend,
		Status:      rec.Status,
		ApprovedBy:  rec.ApprovedBy,
		Notes:       rec.Notes,
		CreatedAt:   rec.CreatedAt,
		UpdatedAt:   rec.UpdatedAt,
	}
}

type investmentStatsRecord struct {
	TotalPlanned    int64   `db:"total_planned"`
	OngoingCount    int     `db:"ongoing_count"`
	OngoingAmount   int64   `db:"ongoing_amount"`
	CompletedCount  int     `db:"completed_count"`
	CompletedAmount int64   `db:"completed_amount"`
	AvgROI          float64 `db:"avg_roi"`
}

func (r *InvestmentRepository) Save(ctx context.Context, p *investment.InvestmentPlan) error {
	query := `
		INSERT INTO investment_plans (id, title, category, proposed_by, amount, expected_roi, actual_spend, status, approved_by, notes, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		p.ID, p.Title, p.Category, p.ProposedBy, p.Amount, p.ExpectedROI,
		p.ActualSpend, p.Status, p.ApprovedBy, p.Notes, p.CreatedAt, p.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save investment plan: %w", err)
	}
	return nil
}

func (r *InvestmentRepository) Update(ctx context.Context, p *investment.InvestmentPlan) error {
	query := `
		UPDATE investment_plans SET title=$1, category=$2, proposed_by=$3, amount=$4, expected_roi=$5,
		actual_spend=$6, status=$7, approved_by=$8, notes=$9, updated_at=$10 WHERE id=$11
	`
	_, err := r.db.ExecContext(ctx, query,
		p.Title, p.Category, p.ProposedBy, p.Amount, p.ExpectedROI,
		p.ActualSpend, p.Status, p.ApprovedBy, p.Notes, time.Now(), p.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update investment plan: %w", err)
	}
	return nil
}

func (r *InvestmentRepository) List(ctx context.Context, offset, limit int, status string) ([]*investment.InvestmentPlan, int, error) {
	var total int
	countArgs := []interface{}{}
	countQuery := `SELECT COUNT(*) FROM investment_plans`
	if status != "" {
		countQuery += ` WHERE status = $1`
		countArgs = append(countArgs, status)
	}
	if err := r.db.GetContext(ctx, &total, countQuery, countArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to count investment plans: %w", err)
	}

	var recs []investmentRecord
	var listQuery string
	var listArgs []interface{}
	if status != "" {
		listQuery = `SELECT id, title, category, proposed_by, amount, expected_roi, actual_spend, status, approved_by, notes, created_at, updated_at FROM investment_plans WHERE status = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`
		listArgs = []interface{}{status, limit, offset}
	} else {
		listQuery = `SELECT id, title, category, proposed_by, amount, expected_roi, actual_spend, status, approved_by, notes, created_at, updated_at FROM investment_plans ORDER BY created_at DESC LIMIT $1 OFFSET $2`
		listArgs = []interface{}{limit, offset}
	}
	if err := r.db.SelectContext(ctx, &recs, listQuery, listArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list investment plans: %w", err)
	}

	plans := make([]*investment.InvestmentPlan, len(recs))
	for i, rec := range recs {
		plans[i] = rec.toDomain()
	}
	return plans, total, nil
}

func (r *InvestmentRepository) Stats(ctx context.Context) (*investment.InvestmentStats, error) {
	var rec investmentStatsRecord
	query := `
		SELECT
		  COALESCE(SUM(amount), 0) AS total_planned,
		  COUNT(CASE WHEN status = 'in_progress' THEN 1 END) AS ongoing_count,
		  COALESCE(SUM(CASE WHEN status = 'in_progress' THEN amount ELSE 0 END), 0) AS ongoing_amount,
		  COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed_count,
		  COALESCE(SUM(CASE WHEN status = 'completed' THEN actual_spend ELSE 0 END), 0) AS completed_amount,
		  COALESCE(AVG(expected_roi), 0) AS avg_roi
		FROM investment_plans
	`
	if err := r.db.GetContext(ctx, &rec, query); err != nil {
		return nil, fmt.Errorf("failed to get investment stats: %w", err)
	}
	return &investment.InvestmentStats{
		TotalPlanned:    rec.TotalPlanned,
		OngoingCount:    rec.OngoingCount,
		OngoingAmount:   rec.OngoingAmount,
		CompletedCount:  rec.CompletedCount,
		CompletedAmount: rec.CompletedAmount,
		AvgROI:          rec.AvgROI,
	}, nil
}
