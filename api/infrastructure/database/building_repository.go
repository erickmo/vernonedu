package database

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/rs/zerolog/log"

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

type buildingWithRoomsRow struct {
	ID            string    `db:"id"`
	Name          string    `db:"name"`
	Address       string    `db:"address"`
	Description   string    `db:"description"`
	CreatedAt     time.Time `db:"created_at"`
	UpdatedAt     time.Time `db:"updated_at"`
	RoomCount     int       `db:"room_count"`
	TotalCapacity int       `db:"total_capacity"`
	RoomsJSON     []byte    `db:"rooms"`
}

type roomSummaryJSON struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Capacity int    `json:"capacity"`
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

func (r *BuildingRepository) ListWithRooms(ctx context.Context, offset, limit int, search string) ([]building.BuildingWithRooms, int, error) {
	var total int
	countQuery := `
		SELECT COUNT(DISTINCT b.id)
		FROM buildings b
		WHERE ($1 = '' OR b.name ILIKE '%' || $1 || '%' OR b.address ILIKE '%' || $1 || '%')
	`
	if err := r.db.GetContext(ctx, &total, countQuery, search); err != nil {
		return nil, 0, fmt.Errorf("failed to count buildings: %w", err)
	}

	query := `
		SELECT
			b.id, b.name, b.address, b.description, b.created_at, b.updated_at,
			COUNT(rm.id)::int AS room_count,
			COALESCE(SUM(rm.capacity), 0)::int AS total_capacity,
			COALESCE(
				json_agg(
					json_build_object('id', rm.id::text, 'name', rm.name, 'capacity', COALESCE(rm.capacity, 0))
					ORDER BY rm.name
				) FILTER (WHERE rm.id IS NOT NULL),
				'[]'::json
			) AS rooms
		FROM buildings b
		LEFT JOIN rooms rm ON rm.building_id = b.id
		WHERE ($3 = '' OR b.name ILIKE '%' || $3 || '%' OR b.address ILIKE '%' || $3 || '%')
		GROUP BY b.id, b.name, b.address, b.description, b.created_at, b.updated_at
		ORDER BY b.name ASC
		LIMIT $1 OFFSET $2
	`
	var rows []buildingWithRoomsRow
	if err := r.db.SelectContext(ctx, &rows, query, limit, offset, search); err != nil {
		return nil, 0, fmt.Errorf("failed to list buildings with rooms: %w", err)
	}

	result := make([]building.BuildingWithRooms, 0, len(rows))
	for _, row := range rows {
		id, err := uuid.Parse(row.ID)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to parse building id: %w", err)
		}

		var roomsData []roomSummaryJSON
		if len(row.RoomsJSON) > 0 {
			if err := json.Unmarshal(row.RoomsJSON, &roomsData); err != nil {
				return nil, 0, fmt.Errorf("failed to unmarshal rooms: %w", err)
			}
		}

		rooms := make([]building.RoomSummary, 0, len(roomsData))
		for _, rd := range roomsData {
			rid, err := uuid.Parse(rd.ID)
			if err != nil {
				log.Warn().Err(err).Str("room_id", rd.ID).Msg("skipping room with invalid UUID in building list")
				continue
			}
			rooms = append(rooms, building.RoomSummary{
				ID:       rid,
				Name:     rd.Name,
				Capacity: rd.Capacity,
			})
		}

		result = append(result, building.BuildingWithRooms{
			Building: building.Building{
				ID:          id,
				Name:        row.Name,
				Address:     row.Address,
				Description: row.Description,
				CreatedAt:   row.CreatedAt,
				UpdatedAt:   row.UpdatedAt,
			},
			RoomCount:     row.RoomCount,
			TotalCapacity: row.TotalCapacity,
			Rooms:         rooms,
		})
	}
	return result, total, nil
}
