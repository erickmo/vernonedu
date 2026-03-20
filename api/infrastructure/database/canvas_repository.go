package database

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/valuepropositioncanvas"
)

type CanvasRepository struct {
	db *sqlx.DB
}

func NewCanvasRepository(db *sqlx.DB) *CanvasRepository {
	return &CanvasRepository{db: db}
}

func (r *CanvasRepository) Save(ctx context.Context, vpc *valuepropositioncanvas.ValuePropositionCanvas) error {
	query := `
		INSERT INTO value_proposition_canvases (id, name, created_at, updated_at)
		VALUES ($1, $2, $3, $4)
	`
	_, err := r.db.ExecContext(ctx, query, vpc.ID, vpc.Name, vpc.CreatedAt, vpc.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save canvas: %w", err)
	}
	return nil
}

func (r *CanvasRepository) Update(ctx context.Context, vpc *valuepropositioncanvas.ValuePropositionCanvas) error {
	query := `
		UPDATE value_proposition_canvases
		SET name = $1, updated_at = $2
		WHERE id = $3
	`
	_, err := r.db.ExecContext(ctx, query, vpc.Name, vpc.UpdatedAt, vpc.ID)
	if err != nil {
		return fmt.Errorf("failed to update canvas: %w", err)
	}
	return nil
}

func (r *CanvasRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM value_proposition_canvases WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete canvas: %w", err)
	}
	return nil
}

func (r *CanvasRepository) GetByID(ctx context.Context, id uuid.UUID) (*valuepropositioncanvas.ValuePropositionCanvas, error) {
	var vpc valuepropositioncanvas.ValuePropositionCanvas
	query := `SELECT id, name, created_at, updated_at FROM value_proposition_canvases WHERE id = $1`
	if err := r.db.GetContext(ctx, &vpc, query, id); err != nil {
		return nil, fmt.Errorf("failed to get canvas: %w", err)
	}
	return &vpc, nil
}

func (r *CanvasRepository) List(ctx context.Context, offset, limit int) ([]*valuepropositioncanvas.ValuePropositionCanvas, error) {
	var canvases []*valuepropositioncanvas.ValuePropositionCanvas
	query := `SELECT id, name, created_at, updated_at FROM value_proposition_canvases ORDER BY created_at DESC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &canvases, query, limit, offset); err != nil {
		return nil, fmt.Errorf("failed to list canvases: %w", err)
	}
	return canvases, nil
}

func (r *CanvasRepository) Search(ctx context.Context, name string, offset, limit int) ([]*valuepropositioncanvas.ValuePropositionCanvas, error) {
	var canvases []*valuepropositioncanvas.ValuePropositionCanvas
	query := `SELECT id, name, created_at, updated_at FROM value_proposition_canvases WHERE name ILIKE $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`
	if err := r.db.SelectContext(ctx, &canvases, query, "%"+name+"%", limit, offset); err != nil {
		return nil, fmt.Errorf("failed to search canvases: %w", err)
	}
	return canvases, nil
}
