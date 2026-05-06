package list_lead

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

type LeadReadModel struct {
	ID        uuid.UUID     `json:"id"`
	Name      string        `json:"name"`
	Email     string        `json:"email"`
	Phone     string        `json:"phone"`
	Source    *LeadSourceRM `json:"source"`
	Notes     string        `json:"notes"`
	Status    string        `json:"status"`
	PicID     *uuid.UUID    `json:"pic_id"`
	CreatedAt int64         `json:"created_at"`
	UpdatedAt int64         `json:"updated_at"`
}

type ListResult struct {
	Data   []*LeadReadModel `json:"data"`
	Total  int              `json:"total"`
	Offset int              `json:"offset"`
	Limit  int              `json:"limit"`
}

type Handler struct {
	leadReadRepo   lead.ReadRepository
	sourceReadRepo lead.SourceReadRepository
}

func NewHandler(leadReadRepo lead.ReadRepository, sourceReadRepo lead.SourceReadRepository) *Handler {
	return &Handler{leadReadRepo: leadReadRepo, sourceReadRepo: sourceReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query any) (any, error) {
	q, ok := query.(*ListLeadQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	leads, total, err := h.leadReadRepo.List(ctx, q.Offset, q.Limit, q.Status, q.SourceID, q.Search, q.SortBy, q.SortDir)
	if err != nil {
		log.Error().Err(err).Msg("failed to list leads")
		return nil, err
	}

	allSources, _ := h.sourceReadRepo.ListSources(ctx)
	sourceMap := make(map[uuid.UUID]*lead.LeadSource, len(allSources))
	for _, s := range allSources {
		sourceMap[s.ID] = s
	}

	readModels := make([]*LeadReadModel, len(leads))
	for i, l := range leads {
		var sourceRM *LeadSourceRM
		if l.SourceID != nil {
			if s, ok := sourceMap[*l.SourceID]; ok {
				sourceRM = &LeadSourceRM{ID: s.ID, Name: s.Name}
			}
		}
		readModels[i] = &LeadReadModel{
			ID:        l.ID,
			Name:      l.Name,
			Email:     l.Email,
			Phone:     l.Phone,
			Source:    sourceRM,
			Notes:     l.Notes,
			Status:    l.Status,
			PicID:     l.PicID,
			CreatedAt: l.CreatedAt.Unix(),
			UpdatedAt: l.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
