package database

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
)

type PayableRepository struct {
	db *sqlx.DB
}

func NewPayableRepository(db *sqlx.DB) *PayableRepository {
	return &PayableRepository{db: db}
}

type payableRow struct {
	ID                    string         `db:"id"`
	Type                  string         `db:"type"`
	RecipientID           string         `db:"recipient_id"`
	RecipientName         string         `db:"recipient_name"`
	BatchID               *string        `db:"batch_id"`
	Amount                int64          `db:"amount"`
	CalculationBasis      sql.NullString `db:"calculation_basis"`
	CalculationPercentage sql.NullFloat64 `db:"calculation_percentage"`
	Status                string         `db:"status"`
	Source                string         `db:"source"`
	PaidAt                *time.Time     `db:"paid_at"`
	PaymentProof          sql.NullString `db:"payment_proof"`
	BranchID              *string        `db:"branch_id"`
	Notes                 string         `db:"notes"`
	CreatedAt             time.Time      `db:"created_at"`
	UpdatedAt             time.Time      `db:"updated_at"`
}

func (r *PayableRepository) Save(ctx context.Context, p *payable.Payable) error {
	var batchID, branchID *string
	if p.BatchID != nil {
		s := p.BatchID.String()
		batchID = &s
	}
	if p.BranchID != nil {
		s := p.BranchID.String()
		branchID = &s
	}
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO payables
			(id, type, recipient_id, recipient_name, batch_id, amount,
			 calculation_basis, calculation_percentage, status, source,
			 paid_at, payment_proof, branch_id, notes, created_at, updated_at)
		VALUES
			($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)`,
		p.ID, p.Type, p.RecipientID, p.RecipientName, batchID, p.Amount,
		p.CalculationBasis, p.CalculationPercentage, p.Status, p.Source,
		p.PaidAt, p.PaymentProof, branchID, p.Notes, p.CreatedAt, p.UpdatedAt,
	)
	return err
}

func (r *PayableRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status string, paidAt *time.Time, paymentProof string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE payables SET status=$1, paid_at=$2, payment_proof=$3, updated_at=NOW()
		WHERE id=$4`,
		status, paidAt, paymentProof, id,
	)
	return err
}

func (r *PayableRepository) GetByID(ctx context.Context, id uuid.UUID) (*payable.Payable, error) {
	var row payableRow
	err := r.db.GetContext(ctx, &row, `SELECT * FROM payables WHERE id=$1`, id)
	if err == sql.ErrNoRows {
		return nil, payable.ErrPayableNotFound
	}
	if err != nil {
		return nil, err
	}
	return rowToPayable(&row)
}

func (r *PayableRepository) List(
	ctx context.Context,
	payableType, status, batchID, recipientID, dateFrom, dateTo string,
	offset, limit int,
) ([]*payable.Payable, int, error) {
	args := []interface{}{}
	conds := []string{}
	idx := 1

	if payableType != "" {
		conds = append(conds, fmt.Sprintf("type=$%d", idx))
		args = append(args, payableType)
		idx++
	}
	if status != "" {
		conds = append(conds, fmt.Sprintf("status=$%d", idx))
		args = append(args, status)
		idx++
	}
	if batchID != "" {
		conds = append(conds, fmt.Sprintf("batch_id=$%d", idx))
		args = append(args, batchID)
		idx++
	}
	if recipientID != "" {
		conds = append(conds, fmt.Sprintf("recipient_id=$%d", idx))
		args = append(args, recipientID)
		idx++
	}
	if dateFrom != "" {
		conds = append(conds, fmt.Sprintf("created_at >= $%d", idx))
		args = append(args, dateFrom)
		idx++
	}
	if dateTo != "" {
		conds = append(conds, fmt.Sprintf("created_at <= $%d", idx))
		args = append(args, dateTo)
		idx++
	}

	where := ""
	if len(conds) > 0 {
		where = "WHERE " + strings.Join(conds, " AND ")
	}

	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM payables %s", where)
	if err := r.db.QueryRowContext(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	dataQuery := fmt.Sprintf("SELECT * FROM payables %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d", where, idx, idx+1)
	args = append(args, limit, offset)

	rows, err := r.db.QueryxContext(ctx, dataQuery, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var result []*payable.Payable
	for rows.Next() {
		var row payableRow
		if err := rows.StructScan(&row); err != nil {
			return nil, 0, err
		}
		p, err := rowToPayable(&row)
		if err != nil {
			return nil, 0, err
		}
		result = append(result, p)
	}

	return result, total, nil
}

func (r *PayableRepository) Stats(ctx context.Context) (*payable.PayableStats, error) {
	rows, err := r.db.QueryxContext(ctx, `
		SELECT status, COUNT(*) as cnt, COALESCE(SUM(amount),0) as total_amount
		FROM payables
		GROUP BY status
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	stats := &payable.PayableStats{}
	for rows.Next() {
		var status string
		var cnt int
		var totalAmount int64
		if err := rows.Scan(&status, &cnt, &totalAmount); err != nil {
			return nil, err
		}
		switch status {
		case payable.StatusPending:
			stats.TotalPending = cnt
			stats.AmountPending = totalAmount
		case payable.StatusApproved:
			stats.TotalApproved = cnt
			stats.AmountApproved = totalAmount
		case payable.StatusPaid:
			stats.TotalPaid = cnt
		case payable.StatusCancelled:
			stats.TotalCancelled = cnt
		}
	}

	return stats, nil
}

func rowToPayable(row *payableRow) (*payable.Payable, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, err
	}
	recipientID, err := uuid.Parse(row.RecipientID)
	if err != nil {
		return nil, err
	}

	p := &payable.Payable{
		ID:            id,
		Type:          row.Type,
		RecipientID:   recipientID,
		RecipientName: row.RecipientName,
		Amount:        row.Amount,
		Status:        row.Status,
		Source:        row.Source,
		PaidAt:        row.PaidAt,
		Notes:         row.Notes,
		CreatedAt:     row.CreatedAt,
		UpdatedAt:     row.UpdatedAt,
	}

	if row.BatchID != nil {
		bid, err := uuid.Parse(*row.BatchID)
		if err != nil {
			return nil, err
		}
		p.BatchID = &bid
	}
	if row.BranchID != nil {
		bid, err := uuid.Parse(*row.BranchID)
		if err != nil {
			return nil, err
		}
		p.BranchID = &bid
	}
	if row.CalculationBasis.Valid {
		p.CalculationBasis = row.CalculationBasis.String
	}
	if row.CalculationPercentage.Valid {
		p.CalculationPercentage = row.CalculationPercentage.Float64
	}
	if row.PaymentProof.Valid {
		p.PaymentProof = row.PaymentProof.String
	}

	return p, nil
}
