package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/business"
)

type BusinessRepository struct {
	db *sqlx.DB
}

func NewBusinessRepository(db *sqlx.DB) *BusinessRepository {
	return &BusinessRepository{db: db}
}

type businessRecord struct {
	ID        uuid.UUID `db:"id"`
	UserID    uuid.UUID `db:"user_id"`
	Name      string    `db:"name"`
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
}

func (rec *businessRecord) toDomain() *business.Business {
	return &business.Business{
		ID:        rec.ID,
		UserID:    rec.UserID,
		Name:      rec.Name,
		CreatedAt: rec.CreatedAt,
		UpdatedAt: rec.UpdatedAt,
	}
}

func (r *BusinessRepository) Save(ctx context.Context, b *business.Business) error {
	query := `
		INSERT INTO businesses (id, user_id, name, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err := r.db.ExecContext(ctx, query, b.ID, b.UserID, b.Name, b.CreatedAt, b.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save business: %w", err)
	}
	return nil
}

func (r *BusinessRepository) Update(ctx context.Context, b *business.Business) error {
	query := `
		UPDATE businesses
		SET name = $1, updated_at = $2
		WHERE id = $3
	`
	_, err := r.db.ExecContext(ctx, query, b.Name, b.UpdatedAt, b.ID)
	if err != nil {
		return fmt.Errorf("failed to update business: %w", err)
	}
	return nil
}

func (r *BusinessRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM businesses WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete business: %w", err)
	}
	return nil
}

func (r *BusinessRepository) GetByID(ctx context.Context, id uuid.UUID) (*business.Business, error) {
	var rec businessRecord
	query := `SELECT id, user_id, name, created_at, updated_at FROM businesses WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get business: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *BusinessRepository) List(ctx context.Context, userID uuid.UUID, offset, limit int) ([]*business.Business, error) {
	var recs []businessRecord
	query := `SELECT id, user_id, name, created_at, updated_at FROM businesses WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`
	if err := r.db.SelectContext(ctx, &recs, query, userID, limit, offset); err != nil {
		return nil, fmt.Errorf("failed to list businesses: %w", err)
	}
	businesses := make([]*business.Business, len(recs))
	for i, rec := range recs {
		businesses[i] = rec.toDomain()
	}
	return businesses, nil
}

func (r *BusinessRepository) Search(ctx context.Context, userID uuid.UUID, name string, offset, limit int) ([]*business.Business, error) {
	var recs []businessRecord
	query := `SELECT id, user_id, name, created_at, updated_at FROM businesses WHERE user_id = $1 AND name ILIKE $2 ORDER BY created_at DESC LIMIT $3 OFFSET $4`
	if err := r.db.SelectContext(ctx, &recs, query, userID, "%"+name+"%", limit, offset); err != nil {
		return nil, fmt.Errorf("failed to search businesses: %w", err)
	}
	businesses := make([]*business.Business, len(recs))
	for i, rec := range recs {
		businesses[i] = rec.toDomain()
	}
	return businesses, nil
}

func (r *BusinessRepository) ListByUserID(ctx context.Context, userID uuid.UUID, offset, limit int) ([]*business.Business, error) {
	return r.List(ctx, userID, offset, limit)
}
