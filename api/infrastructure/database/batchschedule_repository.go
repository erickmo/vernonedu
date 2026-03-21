package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/batchschedule"
)

type BatchScheduleRepository struct {
	db *sqlx.DB
}

func NewBatchScheduleRepository(db *sqlx.DB) *BatchScheduleRepository {
	return &BatchScheduleRepository{db: db}
}

type batchScheduleRecord struct {
	ID              uuid.UUID  `db:"id"`
	CourseBatchID   uuid.UUID  `db:"course_batch_id"`
	ModuleID        *uuid.UUID `db:"module_id"`
	RoomID          *uuid.UUID `db:"room_id"`
	ScheduledAt     time.Time  `db:"scheduled_at"`
	DurationMinutes int        `db:"duration_minutes"`
	Notes           string     `db:"notes"`
	Status          string     `db:"status"`
	CreatedAt       time.Time  `db:"created_at"`
	UpdatedAt       time.Time  `db:"updated_at"`
}

func (rec *batchScheduleRecord) toDomain() *batchschedule.BatchSchedule {
	return &batchschedule.BatchSchedule{
		ID:              rec.ID,
		CourseBatchID:   rec.CourseBatchID,
		ModuleID:        rec.ModuleID,
		RoomID:          rec.RoomID,
		ScheduledAt:     rec.ScheduledAt,
		DurationMinutes: rec.DurationMinutes,
		Notes:           rec.Notes,
		Status:          rec.Status,
		CreatedAt:       rec.CreatedAt,
		UpdatedAt:       rec.UpdatedAt,
	}
}

func (r *BatchScheduleRepository) Save(ctx context.Context, s *batchschedule.BatchSchedule) error {
	q := `INSERT INTO batch_schedules (id, course_batch_id, module_id, room_id, scheduled_at, duration_minutes, notes, status, created_at, updated_at)
          VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`
	_, err := r.db.ExecContext(ctx, q, s.ID, s.CourseBatchID, s.ModuleID, s.RoomID, s.ScheduledAt, s.DurationMinutes, s.Notes, s.Status, s.CreatedAt, s.UpdatedAt)
	if err != nil {
		return fmt.Errorf("save batch schedule: %w", err)
	}
	return nil
}

func (r *BatchScheduleRepository) Update(ctx context.Context, s *batchschedule.BatchSchedule) error {
	q := `UPDATE batch_schedules SET module_id=$1, room_id=$2, scheduled_at=$3, duration_minutes=$4, notes=$5, status=$6, updated_at=$7 WHERE id=$8`
	_, err := r.db.ExecContext(ctx, q, s.ModuleID, s.RoomID, s.ScheduledAt, s.DurationMinutes, s.Notes, s.Status, s.UpdatedAt, s.ID)
	return err
}

func (r *BatchScheduleRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM batch_schedules WHERE id=$1`, id)
	return err
}

func (r *BatchScheduleRepository) GetByID(ctx context.Context, id uuid.UUID) (*batchschedule.BatchSchedule, error) {
	var rec batchScheduleRecord
	err := r.db.GetContext(ctx, &rec, `SELECT id, course_batch_id, module_id, room_id, scheduled_at, duration_minutes, notes, status, created_at, updated_at FROM batch_schedules WHERE id=$1`, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, batchschedule.ErrScheduleNotFound
		}
		return nil, fmt.Errorf("get batch schedule: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *BatchScheduleRepository) ListByBatch(ctx context.Context, courseBatchID uuid.UUID) ([]*batchschedule.BatchSchedule, error) {
	var recs []batchScheduleRecord
	err := r.db.SelectContext(ctx, &recs, `SELECT id, course_batch_id, module_id, room_id, scheduled_at, duration_minutes, notes, status, created_at, updated_at FROM batch_schedules WHERE course_batch_id=$1 ORDER BY scheduled_at ASC`, courseBatchID)
	if err != nil {
		return nil, fmt.Errorf("list batch schedules: %w", err)
	}
	result := make([]*batchschedule.BatchSchedule, len(recs))
	for i, rec := range recs {
		result[i] = rec.toDomain()
	}
	return result, nil
}

func (r *BatchScheduleRepository) CheckRoomConflict(ctx context.Context, roomID uuid.UUID, from, to time.Time, excludeID uuid.UUID) (bool, error) {
	// A conflict exists if any schedule for the same room overlaps [from, to)
	// Overlap condition: scheduled_at < to AND (scheduled_at + duration_minutes * interval) > from
	q := `SELECT COUNT(*) FROM batch_schedules
          WHERE room_id = $1
          AND status != 'cancelled'
          AND id != $2
          AND scheduled_at < $3
          AND (scheduled_at + (duration_minutes * interval '1 minute')) > $4`
	var count int
	err := r.db.GetContext(ctx, &count, q, roomID, excludeID, to, from)
	if err != nil {
		return false, fmt.Errorf("check room conflict: %w", err)
	}
	return count > 0, nil
}
