package get_lead

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadReadModel struct {
	ID        uuid.UUID  `json:"id"`
	Name      string     `json:"name"`
	Email     string     `json:"email"`
	Phone     string     `json:"phone"`
	Interest  string     `json:"interest"`
	Source    string     `json:"source"`
	Notes     string     `json:"notes"`
	Status    string     `json:"status"`
	PicID     *uuid.UUID `json:"pic_id"`
	CreatedAt int64      `json:"created_at"`
	UpdatedAt int64      `json:"updated_at"`
}

type Handler struct {
	leadReadRepo lead.ReadRepository
}

func NewHandler(leadReadRepo lead.ReadRepository) *Handler {
	return &Handler{
		leadReadRepo: leadReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetLeadQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	l, err := h.leadReadRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("lead_id", q.ID.String()).Msg("failed to get lead")
		return nil, err
	}

	readModel := &LeadReadModel{
		ID:        l.ID,
		Name:      l.Name,
		Email:     l.Email,
		Phone:     l.Phone,
		Interest:  l.Interest,
		Source:    l.Source,
		Notes:     l.Notes,
		Status:    l.Status,
		PicID:     l.PicID,
		CreatedAt: l.CreatedAt.Unix(),
		UpdatedAt: l.UpdatedAt.Unix(),
	}

	return readModel, nil
}
