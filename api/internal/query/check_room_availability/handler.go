package check_room_availability

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/room"
)

type ConflictItem struct {
	ScheduleID uuid.UUID `json:"schedule_id"`
	BatchID    uuid.UUID `json:"batch_id"`
	BatchName  string    `json:"batch_name"`
	StartAt    int64     `json:"start_at"`
	EndAt      int64     `json:"end_at"`
}

type AvailabilityResult struct {
	RoomID    uuid.UUID       `json:"room_id"`
	Available bool            `json:"available"`
	Conflicts []*ConflictItem `json:"conflicts"`
}

type Handler struct {
	roomReadRepo room.ReadRepository
}

func NewHandler(roomReadRepo room.ReadRepository) *Handler {
	return &Handler{roomReadRepo: roomReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*CheckRoomAvailabilityQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	conflicts, err := h.roomReadRepo.CheckAvailability(ctx, q.RoomID, q.From, q.To)
	if err != nil {
		log.Error().Err(err).Str("room_id", q.RoomID.String()).Msg("failed to check room availability")
		return nil, err
	}

	items := make([]*ConflictItem, 0, len(conflicts))
	for _, c := range conflicts {
		items = append(items, &ConflictItem{
			ScheduleID: c.ScheduleID,
			BatchID:    c.BatchID,
			BatchName:  c.BatchName,
			StartAt:    c.StartAt.Unix(),
			EndAt:      c.EndAt.Unix(),
		})
	}

	return &AvailabilityResult{
		RoomID:    q.RoomID,
		Available: len(items) == 0,
		Conflicts: items,
	}, nil
}
