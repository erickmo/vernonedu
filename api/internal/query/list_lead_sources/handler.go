package list_lead_sources

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadSourceReadModel struct {
	ID       uuid.UUID `json:"id"`
	Name     string    `json:"name"`
	IsActive bool      `json:"is_active"`
}

type Handler struct {
	sourceReadRepo lead.SourceReadRepository
}

func NewHandler(sourceReadRepo lead.SourceReadRepository) *Handler {
	return &Handler{sourceReadRepo: sourceReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListLeadSourcesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	sources, err := h.sourceReadRepo.ListSources(ctx, q.Search, q.SortBy, q.SortDir)
	if err != nil {
		log.Error().Err(err).Msg("failed to list lead sources")
		return nil, err
	}
	readModels := make([]*LeadSourceReadModel, len(sources))
	for i, s := range sources {
		readModels[i] = &LeadSourceReadModel{
			ID:       s.ID,
			Name:     s.Name,
			IsActive: s.IsActive,
		}
	}
	return readModels, nil
}
