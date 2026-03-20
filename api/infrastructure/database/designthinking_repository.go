package database

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/designthinking"
)

type DesignThinkingRepository struct {
	db *sqlx.DB
}

func NewDesignThinkingRepository(db *sqlx.DB) *DesignThinkingRepository {
	return &DesignThinkingRepository{db: db}
}

func (r *DesignThinkingRepository) Save(ctx context.Context, dt *designthinking.DesignThinking) error {
	query := `
		INSERT INTO design_thinkings (id, name, created_at, updated_at)
		VALUES ($1, $2, $3, $4)
	`
	_, err := r.db.ExecContext(ctx, query, dt.ID, dt.Name, dt.CreatedAt, dt.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save design thinking: %w", err)
	}
	return nil
}

func (r *DesignThinkingRepository) Update(ctx context.Context, dt *designthinking.DesignThinking) error {
	query := `
		UPDATE design_thinkings
		SET name = $1, updated_at = $2
		WHERE id = $3
	`
	_, err := r.db.ExecContext(ctx, query, dt.Name, dt.UpdatedAt, dt.ID)
	if err != nil {
		return fmt.Errorf("failed to update design thinking: %w", err)
	}
	return nil
}

func (r *DesignThinkingRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM design_thinkings WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete design thinking: %w", err)
	}
	return nil
}

func (r *DesignThinkingRepository) GetByID(ctx context.Context, id uuid.UUID) (*designthinking.DesignThinking, error) {
	var dt designthinking.DesignThinking
	query := `SELECT id, name, created_at, updated_at FROM design_thinkings WHERE id = $1`
	if err := r.db.GetContext(ctx, &dt, query, id); err != nil {
		return nil, fmt.Errorf("failed to get design thinking: %w", err)
	}
	return &dt, nil
}

func (r *DesignThinkingRepository) List(ctx context.Context, offset, limit int) ([]*designthinking.DesignThinking, error) {
	var dts []*designthinking.DesignThinking
	query := `SELECT id, name, created_at, updated_at FROM design_thinkings ORDER BY created_at DESC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &dts, query, limit, offset); err != nil {
		return nil, fmt.Errorf("failed to list design thinkings: %w", err)
	}
	return dts, nil
}

func (r *DesignThinkingRepository) Search(ctx context.Context, name string, offset, limit int) ([]*designthinking.DesignThinking, error) {
	var dts []*designthinking.DesignThinking
	query := `SELECT id, name, created_at, updated_at FROM design_thinkings WHERE name ILIKE $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`
	if err := r.db.SelectContext(ctx, &dts, query, "%"+name+"%", limit, offset); err != nil {
		return nil, fmt.Errorf("failed to search design thinkings: %w", err)
	}
	return dts, nil
}
