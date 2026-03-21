package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/room"
)

type RoomRepository struct {
	db *sqlx.DB
}

func NewRoomRepository(db *sqlx.DB) *RoomRepository {
	return &RoomRepository{db: db}
}

type roomRow struct {
	ID          string         `db:"id"`
	BuildingID  string         `db:"building_id"`
	Name        string         `db:"name"`
	Capacity    *int           `db:"capacity"`
	Floor       *string        `db:"floor"`
	Facilities  pq.StringArray `db:"facilities"`
	Description string         `db:"description"`
	CreatedAt   time.Time      `db:"created_at"`
	UpdatedAt   time.Time      `db:"updated_at"`
}

func (row *roomRow) toDomain() (*room.Room, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse room id: %w", err)
	}
	buildingID, err := uuid.Parse(row.BuildingID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse building id: %w", err)
	}

	facilities := []string(row.Facilities)
	if facilities == nil {
		facilities = []string{}
	}

	return &room.Room{
		ID:          id,
		BuildingID:  buildingID,
		Name:        row.Name,
		Capacity:    row.Capacity,
		Floor:       row.Floor,
		Facilities:  facilities,
		Description: row.Description,
		CreatedAt:   row.CreatedAt,
		UpdatedAt:   row.UpdatedAt,
	}, nil
}

func (r *RoomRepository) Save(ctx context.Context, rm *room.Room) error {
	query := `
		INSERT INTO rooms (id, building_id, name, capacity, floor, facilities, description, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.db.ExecContext(ctx, query,
		rm.ID.String(), rm.BuildingID.String(), rm.Name, rm.Capacity, rm.Floor,
		pq.Array(rm.Facilities), rm.Description, rm.CreatedAt, rm.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save room: %w", err)
	}
	return nil
}

func (r *RoomRepository) Update(ctx context.Context, rm *room.Room) error {
	query := `
		UPDATE rooms
		SET name=$1, capacity=$2, floor=$3, facilities=$4, description=$5, updated_at=$6
		WHERE id=$7
	`
	_, err := r.db.ExecContext(ctx, query,
		rm.Name, rm.Capacity, rm.Floor, pq.Array(rm.Facilities), rm.Description, rm.UpdatedAt,
		rm.ID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to update room: %w", err)
	}
	return nil
}

func (r *RoomRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM rooms WHERE id=$1`, id.String())
	if err != nil {
		return fmt.Errorf("failed to delete room: %w", err)
	}
	return nil
}

func (r *RoomRepository) GetByID(ctx context.Context, id uuid.UUID) (*room.Room, error) {
	var row roomRow
	query := `
		SELECT id, building_id, name, capacity, floor, facilities, description, created_at, updated_at
		FROM rooms WHERE id=$1
	`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get room: %w", err)
	}
	return row.toDomain()
}

func (r *RoomRepository) List(ctx context.Context, buildingID string, offset, limit int) ([]*room.Room, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM rooms WHERE ($1='' OR building_id=$1::uuid)`
	if err := r.db.GetContext(ctx, &total, countQuery, buildingID); err != nil {
		return nil, 0, fmt.Errorf("failed to count rooms: %w", err)
	}

	var rows []roomRow
	query := `
		SELECT id, building_id, name, capacity, floor, facilities, description, created_at, updated_at
		FROM rooms
		WHERE ($1='' OR building_id=$1::uuid)
		ORDER BY name ASC
		LIMIT $2 OFFSET $3
	`
	if err := r.db.SelectContext(ctx, &rows, query, buildingID, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list rooms: %w", err)
	}

	rooms := make([]*room.Room, 0, len(rows))
	for _, row := range rows {
		rm, err := row.toDomain()
		if err != nil {
			return nil, 0, err
		}
		rooms = append(rooms, rm)
	}
	return rooms, total, nil
}

type scheduleConflictRow struct {
	ScheduleID string    `db:"id"`
	BatchID    string    `db:"batch_id"`
	BatchName  string    `db:"batch_name"`
	StartAt    time.Time `db:"scheduled_at"`
	EndAt      time.Time `db:"end_at"`
}

func (r *RoomRepository) CheckAvailability(ctx context.Context, roomID uuid.UUID, from, to time.Time) ([]*room.ScheduleConflict, error) {
	var rows []scheduleConflictRow
	query := `
		SELECT bs.id, bs.batch_id, cb.name AS batch_name, bs.scheduled_at, bs.end_at
		FROM batch_schedules bs
		JOIN course_batches cb ON cb.id = bs.batch_id
		WHERE bs.room_id = $1
		  AND bs.scheduled_at < $3
		  AND bs.end_at > $2
		ORDER BY bs.scheduled_at ASC
	`
	if err := r.db.SelectContext(ctx, &rows, query, roomID.String(), from, to); err != nil {
		return nil, fmt.Errorf("failed to check room availability: %w", err)
	}

	conflicts := make([]*room.ScheduleConflict, 0, len(rows))
	for _, row := range rows {
		scheduleID, err := uuid.Parse(row.ScheduleID)
		if err != nil {
			return nil, fmt.Errorf("failed to parse schedule id: %w", err)
		}
		batchID, err := uuid.Parse(row.BatchID)
		if err != nil {
			return nil, fmt.Errorf("failed to parse batch id: %w", err)
		}
		conflicts = append(conflicts, &room.ScheduleConflict{
			ScheduleID: scheduleID,
			BatchID:    batchID,
			BatchName:  row.BatchName,
			StartAt:    row.StartAt,
			EndAt:      row.EndAt,
		})
	}
	return conflicts, nil
}
