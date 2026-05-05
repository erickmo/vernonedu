package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadSourceRepository struct {
	db *sqlx.DB
}

func NewLeadSourceRepository(db *sqlx.DB) *LeadSourceRepository {
	return &LeadSourceRepository{db: db}
}

type leadSourceRow struct {
	ID        string    `db:"id"`
	Name      string    `db:"name"`
	IsActive  bool      `db:"is_active"`
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
}

func (row *leadSourceRow) toDomain() (*lead.LeadSource, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse lead_source id: %w", err)
	}
	return &lead.LeadSource{
		ID:        id,
		Name:      row.Name,
		IsActive:  row.IsActive,
		CreatedAt: row.CreatedAt,
		UpdatedAt: row.UpdatedAt,
	}, nil
}

func (r *LeadSourceRepository) SaveSource(ctx context.Context, s *lead.LeadSource) error {
	query := `
		INSERT INTO lead_sources (id, name, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err := r.db.ExecContext(ctx, query, s.ID.String(), s.Name, s.IsActive, s.CreatedAt, s.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save lead source: %w", err)
	}
	return nil
}

func (r *LeadSourceRepository) UpdateSource(ctx context.Context, s *lead.LeadSource) error {
	query := `UPDATE lead_sources SET name=$1, is_active=$2, updated_at=$3 WHERE id=$4`
	_, err := r.db.ExecContext(ctx, query, s.Name, s.IsActive, s.UpdatedAt, s.ID.String())
	if err != nil {
		return fmt.Errorf("failed to update lead source: %w", err)
	}
	return nil
}

func (r *LeadSourceRepository) DeleteSource(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM lead_sources WHERE id=$1`, id.String())
	if err != nil {
		return fmt.Errorf("failed to delete lead source: %w", err)
	}
	return nil
}

func (r *LeadSourceRepository) GetSourceByID(ctx context.Context, id uuid.UUID) (*lead.LeadSource, error) {
	var row leadSourceRow
	query := `SELECT id, name, is_active, created_at, updated_at FROM lead_sources WHERE id=$1`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get lead source: %w", err)
	}
	return row.toDomain()
}

func (r *LeadSourceRepository) ListSources(ctx context.Context) ([]*lead.LeadSource, error) {
	var rows []leadSourceRow
	query := `SELECT id, name, is_active, created_at, updated_at FROM lead_sources ORDER BY name`
	if err := r.db.SelectContext(ctx, &rows, query); err != nil {
		return nil, fmt.Errorf("failed to list lead sources: %w", err)
	}
	sources := make([]*lead.LeadSource, 0, len(rows))
	for _, row := range rows {
		s, err := row.toDomain()
		if err != nil {
			return nil, err
		}
		sources = append(sources, s)
	}
	return sources, nil
}
