package get_room

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/room"
)

type RoomReadModel struct {
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

type Handler struct {
	roomReadRepo room.ReadRepository
}

func NewHandler(roomReadRepo room.ReadRepository) *Handler {
	return &Handler{roomReadRepo: roomReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetRoomQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	r, err := h.roomReadRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("room_id", q.ID.String()).Msg("failed to get room")
		return nil, err
	}

	facilities := r.Facilities
	if facilities == nil {
		facilities = []string{}
	}

	return &RoomReadModel{
		ID:          r.ID,
		BuildingID:  r.BuildingID,
		Name:        r.Name,
		Capacity:    r.Capacity,
		Floor:       r.Floor,
		Facilities:  facilities,
		Description: r.Description,
		CreatedAt:   r.CreatedAt.Unix(),
		UpdatedAt:   r.UpdatedAt.Unix(),
	}, nil
}
