package list_delegations

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/delegation"
)

type ListDelegationsQuery struct {
	Offset         int
	Limit          int
	Status         string
	DelegationType string
	AssignedToID   string
	RequestedByID  string
}

type DelegationModel struct {
	ID               string  `json:"id"`
	Title            string  `json:"title"`
	Type             string  `json:"type"`
	Description      string  `json:"description"`
	RequestedByID    string  `json:"requested_by_id"`
	RequestedByName  string  `json:"requested_by_name"`
	AssignedToID     string  `json:"assigned_to_id,omitempty"`
	AssignedToName   string  `json:"assigned_to_name"`
	AssignedToRole   string  `json:"assigned_to_role"`
	DueDate          *string `json:"due_date,omitempty"`
	Priority         string  `json:"priority"`
	Status           string  `json:"status"`
	LinkedEntityType *string `json:"linked_entity_type,omitempty"`
	LinkedEntityID   *string `json:"linked_entity_id,omitempty"`
	Notes            *string `json:"notes,omitempty"`
	CreatedAt        string  `json:"created_at"`
}

type DelegationStatsModel struct {
	ActiveCount             int `json:"active_count"`
	PendingCount            int `json:"pending_count"`
	InProgressCount         int `json:"in_progress_count"`
	CompletedThisMonthCount int `json:"completed_this_month_count"`
}

type ListDelegationResult struct {
	Data   []*DelegationModel    `json:"data"`
	Stats  *DelegationStatsModel `json:"stats"`
	Total  int                   `json:"total"`
	Offset int                   `json:"offset"`
	Limit  int                   `json:"limit"`
}

type Handler struct {
	readRepo delegation.ReadRepository
}

func NewHandler(readRepo delegation.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListDelegationsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	limit := q.Limit
	if limit == 0 {
		limit = 20
	}

	filter := delegation.ListFilter{
		Type:   q.DelegationType,
		Status: q.Status,
		Offset: q.Offset,
		Limit:  limit,
	}
	if q.AssignedToID != "" {
		id, err := uuid.Parse(q.AssignedToID)
		if err == nil {
			filter.AssignedToID = &id
		}
	}
	if q.RequestedByID != "" {
		id, err := uuid.Parse(q.RequestedByID)
		if err == nil {
			filter.RequestedByID = &id
		}
	}

	delegations, total, err := h.readRepo.List(ctx, filter)
	if err != nil {
		log.Error().Err(err).Msg("failed to list delegations")
		return nil, err
	}
	stats, err := h.readRepo.Stats(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to get delegation stats")
		return nil, err
	}

	models := make([]*DelegationModel, len(delegations))
	for i, d := range delegations {
		models[i] = toDelegationModel(d)
	}

	return &ListDelegationResult{
		Data: models,
		Stats: &DelegationStatsModel{
			ActiveCount:             stats.ActiveCount,
			PendingCount:            stats.PendingCount,
			InProgressCount:         stats.InProgressCount,
			CompletedThisMonthCount: stats.CompletedThisMonthCount,
		},
		Total:  total,
		Offset: q.Offset,
		Limit:  limit,
	}, nil
}

func toDelegationModel(d *delegation.Delegation) *DelegationModel {
	m := &DelegationModel{
		ID:              d.ID.String(),
		Title:           d.Title,
		Type:            string(d.Type),
		Description:     d.Description,
		RequestedByID:   d.RequestedByID.String(),
		RequestedByName: d.RequestedByName,
		AssignedToName:  d.AssignedToName,
		AssignedToRole:  d.AssignedToRole,
		Priority:        string(d.Priority),
		Status:          string(d.Status),
		Notes:           d.Notes,
		CreatedAt:       d.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
	if d.AssignedToID != nil {
		m.AssignedToID = d.AssignedToID.String()
	}
	if d.DueDate != nil {
		s := d.DueDate.Format("2006-01-02T15:04:05Z07:00")
		m.DueDate = &s
	}
	if d.LinkedEntityType != nil {
		m.LinkedEntityType = d.LinkedEntityType
	}
	if d.LinkedEntityID != nil {
		s := d.LinkedEntityID.String()
		m.LinkedEntityID = &s
	}
	return m
}
