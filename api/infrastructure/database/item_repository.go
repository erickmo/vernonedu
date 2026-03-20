package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/item"
)

type ItemRepository struct {
	db *sqlx.DB
}

func NewItemRepository(db *sqlx.DB) *ItemRepository {
	return &ItemRepository{db: db}
}

type itemRecord struct {
	ID         uuid.UUID `db:"id"`
	BusinessID uuid.UUID `db:"business_id"`
	CanvasType string    `db:"canvas_type"`
	SectionID  string    `db:"section_id"`
	Text       string    `db:"text"`
	Note       string    `db:"note"`
	CreatedAt  time.Time `db:"created_at"`
	UpdatedAt  time.Time `db:"updated_at"`
}

func (rec *itemRecord) toDomain() *item.Item {
	return &item.Item{
		ID:         rec.ID,
		BusinessID: rec.BusinessID,
		CanvasType: rec.CanvasType,
		SectionID:  rec.SectionID,
		Text:       rec.Text,
		Note:       rec.Note,
		CreatedAt:  rec.CreatedAt,
		UpdatedAt:  rec.UpdatedAt,
	}
}

func (r *ItemRepository) Save(ctx context.Context, i *item.Item) error {
	query := `
		INSERT INTO items (id, business_id, canvas_type, section_id, text, note, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.ExecContext(ctx, query, i.ID, i.BusinessID, i.CanvasType, i.SectionID, i.Text, i.Note, i.CreatedAt, i.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save item: %w", err)
	}
	return nil
}

func (r *ItemRepository) Update(ctx context.Context, i *item.Item) error {
	query := `
		UPDATE items
		SET text = $1, note = $2, updated_at = $3
		WHERE id = $4
	`
	_, err := r.db.ExecContext(ctx, query, i.Text, i.Note, i.UpdatedAt, i.ID)
	if err != nil {
		return fmt.Errorf("failed to update item: %w", err)
	}
	return nil
}

func (r *ItemRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM items WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete item: %w", err)
	}
	return nil
}

func (r *ItemRepository) GetByID(ctx context.Context, id uuid.UUID) (*item.Item, error) {
	var rec itemRecord
	query := `SELECT id, business_id, canvas_type, section_id, text, note, created_at, updated_at FROM items WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get item: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *ItemRepository) ListByBusinessAndCanvas(ctx context.Context, businessID uuid.UUID, canvasType string) ([]*item.Item, error) {
	var recs []itemRecord
	query := `SELECT id, business_id, canvas_type, section_id, text, note, created_at, updated_at FROM items WHERE business_id = $1 AND canvas_type = $2 ORDER BY created_at ASC`
	if err := r.db.SelectContext(ctx, &recs, query, businessID, canvasType); err != nil {
		return nil, fmt.Errorf("failed to list items by business and canvas: %w", err)
	}
	items := make([]*item.Item, len(recs))
	for i, rec := range recs {
		items[i] = rec.toDomain()
	}
	return items, nil
}

func (r *ItemRepository) ListBySection(ctx context.Context, businessID uuid.UUID, canvasType, sectionID string) ([]*item.Item, error) {
	var recs []itemRecord
	query := `SELECT id, business_id, canvas_type, section_id, text, note, created_at, updated_at FROM items WHERE business_id = $1 AND canvas_type = $2 AND section_id = $3 ORDER BY created_at ASC`
	if err := r.db.SelectContext(ctx, &recs, query, businessID, canvasType, sectionID); err != nil {
		return nil, fmt.Errorf("failed to list items by section: %w", err)
	}
	items := make([]*item.Item, len(recs))
	for i, rec := range recs {
		items[i] = rec.toDomain()
	}
	return items, nil
}
