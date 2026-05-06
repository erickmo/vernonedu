package get_lead

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadSourceRM struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

type LeadInterestRM struct {
	ID         uuid.UUID `json:"id"`
	EntityType string    `json:"entity_type"`
	EntityID   uuid.UUID `json:"entity_id"`
	EntityName string    `json:"entity_name"`
}

type LeadReadModel struct {
	ID        uuid.UUID        `json:"id"`
	Name      string           `json:"name"`
	Email     string           `json:"email"`
	Phone     string           `json:"phone"`
	Source    *LeadSourceRM    `json:"source"`
	Interests []*LeadInterestRM `json:"interests"`
	Notes     string           `json:"notes"`
	Status    string           `json:"status"`
	PicID     *uuid.UUID       `json:"pic_id"`
	CreatedAt int64            `json:"created_at"`
	UpdatedAt int64            `json:"updated_at"`
}

type Handler struct {
	leadReadRepo     lead.ReadRepository
	sourceReadRepo   lead.SourceReadRepository
	interestReadRepo lead.InterestReadRepository
}

func NewHandler(leadReadRepo lead.ReadRepository, sourceReadRepo lead.SourceReadRepository, interestReadRepo lead.InterestReadRepository) *Handler {
	return &Handler{
		leadReadRepo:     leadReadRepo,
		sourceReadRepo:   sourceReadRepo,
		interestReadRepo: interestReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query any) (any, error) {
	q, ok := query.(*GetLeadQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	l, err := h.leadReadRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("lead_id", q.ID.String()).Msg("failed to get lead")
		return nil, err
	}

	var sourceRM *LeadSourceRM
	if l.SourceID != nil {
		s, err := h.sourceReadRepo.GetSourceByID(ctx, *l.SourceID)
		if err == nil {
			sourceRM = &LeadSourceRM{ID: s.ID, Name: s.Name}
		}
	}

	rawInterests, err := h.interestReadRepo.ListInterests(ctx, l.ID)
	if err != nil {
		log.Error().Err(err).Str("lead_id", q.ID.String()).Msg("failed to list lead interests")
		return nil, err
	}

	interests := make([]*LeadInterestRM, len(rawInterests))
	for i, ri := range rawInterests {
		interests[i] = &LeadInterestRM{
			ID:         ri.ID,
			EntityType: ri.EntityType,
			EntityID:   ri.EntityID,
			EntityName: ri.EntityName,
		}
	}

	return &LeadReadModel{
		ID:        l.ID,
		Name:      l.Name,
		Email:     l.Email,
		Phone:     l.Phone,
		Source:    sourceRM,
		Interests: interests,
		Notes:     l.Notes,
		Status:    l.Status,
		PicID:     l.PicID,
		CreatedAt: l.CreatedAt.Unix(),
		UpdatedAt: l.UpdatedAt.Unix(),
	}, nil
}
