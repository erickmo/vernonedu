package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
)

type BuildingRepository struct {
	db *sqlx.DB
}

func NewBuildingRepository(db *sqlx.DB) *BuildingRepository {
	return &BuildingRepository{db: db}
}

type buildingRow struct {
	ID          string    `db:"id"`
	Name        string    `db:"name"`
	Address     string    `db:"address"`
	Description string    `db:"description"`
	CreatedAt   time.Time `db:"created_at"`
	UpdatedAt   time.Time `db:"updated_at"`
}

func (row *buildingRow) toDomain() (*building.Building, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse building id: %w", err)
	}
	return &building.Building{
		ID:          id,
		Name:        row.Name,
		Address:     row.Address,
		Description: row.Description,
		CreatedAt:   row.CreatedAt,
		UpdatedAt:   row.UpdatedAt,
	}, nil
}

func (r *BuildingRepository) Save(ctx context.Context, b *building.Building) error {
	query := `
		INSERT INTO buildings (id, name, address, description, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := r.db.ExecContext(ctx, query,
		b.ID.String(), b.Name, b.Address, b.Description, b.CreatedAt, b.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save building: %w", err)
	}
	return nil
}

func (r *BuildingRepository) Update(ctx context.Context, b *building.Building) error {
	query := `
		UPDATE buildings
		SET name=$1, address=$2, description=$3, updated_at=$4
		WHERE id=$5
	`
	_, err := r.db.ExecContext(ctx, query,
		b.Name, b.Address, b.Description, b.UpdatedAt, b.ID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to update building: %w", err)
	}
	return nil
}

func (r *BuildingRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM buildings WHERE id=$1`, id.String())
	if err != nil {
		return fmt.Errorf("failed to delete building: %w", err)
	}
	return nil
}

func (r *BuildingRepository) GetByID(ctx context.Context, id uuid.UUID) (*building.Building, error) {
	var row buildingRow
	query := `SELECT id, name, address, description, created_at, updated_at FROM buildings WHERE id=$1`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get building: %w", err)
	}
	return row.toDomain()
}

func (r *BuildingRepository) List(ctx context.Context, offset, limit int) ([]*building.Building, int, error) {
	var total int
	if err := r.db.GetContext(ctx, &total, `SELECT COUNT(*) FROM buildings`); err != nil {
		return nil, 0, fmt.Errorf("failed to count buildings: %w", err)
	}

	var rows []buildingRow
	query := `
		SELECT id, name, address, description, created_at, updated_at
		FROM buildings
		ORDER BY name ASC
		LIMIT $1 OFFSET $2
	`
	if err := r.db.SelectContext(ctx, &rows, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list buildings: %w", err)
	}

	buildings := make([]*building.Building, 0, len(rows))
	for _, row := range rows {
		b, err := row.toDomain()
		if err != nil {
			return nil, 0, err
		}
		buildings = append(buildings, b)
	}
	return buildings, total, nil
}
