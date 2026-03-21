package list_batch_schedules

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/batchschedule"
)

type ListBatchSchedulesQuery struct {
	CourseBatchID uuid.UUID
}

type BatchScheduleReadModel struct {
	ID              string    `json:"id"`
	CourseBatchID   string    `json:"course_batch_id"`
	ModuleID        *string   `json:"module_id"`
	RoomID          *string   `json:"room_id"`
	ScheduledAt     time.Time `json:"scheduled_at"`
	EndTime         time.Time `json:"end_time"`
	DurationMinutes int       `json:"duration_minutes"`
	Notes           string    `json:"notes"`
	Status          string    `json:"status"`
}

type Handler struct {
	readRepo batchschedule.ReadRepository
}

func NewHandler(readRepo batchschedule.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListBatchSchedulesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	schedules, err := h.readRepo.ListByBatch(ctx, q.CourseBatchID)
	if err != nil {
		log.Error().Err(err).Msg("failed to list batch schedules")
		return nil, err
	}

	result := make([]*BatchScheduleReadModel, len(schedules))
	for i, s := range schedules {
		rm := &BatchScheduleReadModel{
			ID:              s.ID.String(),
			CourseBatchID:   s.CourseBatchID.String(),
			ScheduledAt:     s.ScheduledAt,
			EndTime:         s.EndTime(),
			DurationMinutes: s.DurationMinutes,
			Notes:           s.Notes,
			Status:          s.Status,
		}
		if s.ModuleID != nil {
			id := s.ModuleID.String()
			rm.ModuleID = &id
		}
		if s.RoomID != nil {
			id := s.RoomID.String()
			rm.RoomID = &id
		}
		result[i] = rm
	}
	return map[string]interface{}{"data": result}, nil
}
