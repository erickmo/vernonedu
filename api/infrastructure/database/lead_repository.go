package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadRepository struct {
	db *sqlx.DB
}

func NewLeadRepository(db *sqlx.DB) *LeadRepository {
	return &LeadRepository{db: db}
}

type leadRow struct {
	ID        string    `db:"id"`
	Name      string    `db:"name"`
	Email     string    `db:"email"`
	Phone     string    `db:"phone"`
	Interest  string    `db:"interest"`
	Source    string    `db:"source"`
	Notes     string    `db:"notes"`
	Status    string    `db:"status"`
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
}

func (row *leadRow) toDomain() (*lead.Lead, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse lead id: %w", err)
	}
	return &lead.Lead{
		ID:        id,
		Name:      row.Name,
		Email:     row.Email,
		Phone:     row.Phone,
		Interest:  row.Interest,
		Source:    row.Source,
		Notes:     row.Notes,
		Status:    row.Status,
		CreatedAt: row.CreatedAt,
		UpdatedAt: row.UpdatedAt,
	}, nil
}

func (r *LeadRepository) Save(ctx context.Context, l *lead.Lead) error {
	query := `
		INSERT INTO leads (id, name, email, phone, interest, source, notes, status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err := r.db.ExecContext(ctx, query,
		l.ID.String(), l.Name, l.Email, l.Phone, l.Interest, l.Source, l.Notes, l.Status,
		l.CreatedAt, l.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) Update(ctx context.Context, l *lead.Lead) error {
	query := `
		UPDATE leads
		SET name=$1, email=$2, phone=$3, interest=$4, source=$5, notes=$6, status=$7, updated_at=$8
		WHERE id=$9
	`
	_, err := r.db.ExecContext(ctx, query,
		l.Name, l.Email, l.Phone, l.Interest, l.Source, l.Notes, l.Status, l.UpdatedAt,
		l.ID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to update lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM leads WHERE id=$1`
	_, err := r.db.ExecContext(ctx, query, id.String())
	if err != nil {
		return fmt.Errorf("failed to delete lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) GetByID(ctx context.Context, id uuid.UUID) (*lead.Lead, error) {
	var row leadRow
	query := `SELECT id, name, email, phone, interest, source, notes, status, created_at, updated_at FROM leads WHERE id=$1`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get lead: %w", err)
	}
	return row.toDomain()
}

func (r *LeadRepository) List(ctx context.Context, offset, limit int, status string) ([]*lead.Lead, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM leads WHERE ($1='' OR status=$1)`
	if err := r.db.GetContext(ctx, &total, countQuery, status); err != nil {
		return nil, 0, fmt.Errorf("failed to count leads: %w", err)
	}

	var rows []leadRow
	query := `
		SELECT id, name, email, phone, interest, source, notes, status, created_at, updated_at
		FROM leads
		WHERE ($1='' OR status=$1)
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	if err := r.db.SelectContext(ctx, &rows, query, status, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list leads: %w", err)
	}

	leads := make([]*lead.Lead, 0, len(rows))
	for _, row := range rows {
		l, err := row.toDomain()
		if err != nil {
			return nil, 0, err
		}
		leads = append(leads, l)
	}
	return leads, total, nil
}
