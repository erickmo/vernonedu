package list_rooms

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/room"
)

type RoomListItem struct {
	ID          uuid.UUID `json:"id"`
	BuildingID  uuid.UUID `json:"building_id"`
	Name        string    `json:"name"`
	Capacity    *int      `json:"capacity"`
	Floor       *string   `json:"floor"`
	Facilities  []string  `json:"facilities"`
	Description string    `json:"description"`
	CreatedAt   int64     `json:"created_at"`
	UpdatedAt   int64     `json:"updated_at"`
}

type ListRoomsResult struct {
	Data  []*RoomListItem `json:"data"`
	Total int             `json:"total"`
}

type Handler struct {
	roomReadRepo room.ReadRepository
}

func NewHandler(roomReadRepo room.ReadRepository) *Handler {
	return &Handler{roomReadRepo: roomReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListRoomsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	limit := q.Limit
	if limit == 0 {
		limit = 20
	}

	rooms, total, err := h.roomReadRepo.List(ctx, q.BuildingID, q.Offset, limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list rooms")
		return nil, err
	}

	items := make([]*RoomListItem, 0, len(rooms))
	for _, r := range rooms {
		facilities := r.Facilities
		if facilities == nil {
			facilities = []string{}
		}
		items = append(items, &RoomListItem{
			ID:          r.ID,
			BuildingID:  r.BuildingID,
			Name:        r.Name,
			Capacity:    r.Capacity,
			Floor:       r.Floor,
			Facilities:  facilities,
			Description: r.Description,
			CreatedAt:   r.CreatedAt.Unix(),
			UpdatedAt:   r.UpdatedAt.Unix(),
		})
	}

	return &ListRoomsResult{Data: items, Total: total}, nil
}
