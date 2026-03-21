package list_delegations

import (
	"context"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/delegation"
)

type ListDelegationsQuery struct {
	Offset         int
	Limit          int
	Status         string
	DelegationType string
}

type DelegationModel struct {
	ID               string  `json:"id"`
	Title            string  `json:"title"`
	Type             string  `json:"type"`
	Description      string  `json:"description"`
	AssignedToName   string  `json:"assigned_to_name"`
	AssignedByName   string  `json:"assigned_by_name"`
	Priority         string  `json:"priority"`
	Deadline         *string `json:"deadline,omitempty"`
	Status           string  `json:"status"`
	LinkedEntityID   string  `json:"linked_entity_id"`
	LinkedEntityType string  `json:"linked_entity_type"`
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
	delegations, total, err := h.readRepo.List(ctx, q.Offset, q.Limit, q.Status, q.DelegationType)
	if err != nil {
		return nil, err
	}
	stats, err := h.readRepo.Stats(ctx)
	if err != nil {
		return nil, err
	}

	models := make([]*DelegationModel, len(delegations))
	for i, d := range delegations {
		dm := &DelegationModel{
			ID:               d.ID.String(),
			Title:            d.Title,
			Type:             d.Type,
			Description:      d.Description,
			AssignedToName:   d.AssignedToName,
			AssignedByName:   d.AssignedByName,
			Priority:         d.Priority,
			Status:           d.Status,
			LinkedEntityID:   d.LinkedEntityID,
			LinkedEntityType: d.LinkedEntityType,
		}
		if d.Deadline != nil {
			dl := d.Deadline.Format("2006-01-02T15:04:05Z07:00")
			dm.Deadline = &dl
		}
		models[i] = dm
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
		Limit:  q.Limit,
	}, nil
}
