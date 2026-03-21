package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type coaRecord struct {
	ID          uuid.UUID `db:"id"`
	Code        string    `db:"code"`
	Name        string    `db:"name"`
	AccountType string    `db:"account_type"`
	ParentCode  string    `db:"parent_code"`
	IsActive    bool      `db:"is_active"`
	CreatedAt   time.Time `db:"created_at"`
}

type CoaRepository struct {
	db *sqlx.DB
}

func NewCoaRepository(db *sqlx.DB) *CoaRepository {
	return &CoaRepository{db: db}
}

func (r *CoaRepository) List(ctx context.Context) ([]*accounting.ChartOfAccount, error) {
	var rows []coaRecord
	err := r.db.SelectContext(ctx, &rows,
		`SELECT id, code, name, account_type, COALESCE(parent_code,'') AS parent_code, is_active, created_at
		 FROM chart_of_accounts
		 WHERE is_active = true
		 ORDER BY code`)
	if err != nil {
		return nil, fmt.Errorf("failed to list chart of accounts: %w", err)
	}

	out := make([]*accounting.ChartOfAccount, len(rows))
	for i, row := range rows {
		out[i] = &accounting.ChartOfAccount{
			ID:          row.ID,
			Code:        row.Code,
			Name:        row.Name,
			AccountType: row.AccountType,
			ParentCode:  row.ParentCode,
			IsActive:    row.IsActive,
			CreatedAt:   row.CreatedAt,
		}
	}
	return out, nil
}
