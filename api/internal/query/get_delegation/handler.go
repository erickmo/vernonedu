package get_delegation

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/delegation"
)

type DelegationDetail struct {
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
	UpdatedAt        string  `json:"updated_at"`
}

type Handler struct {
	readRepo delegation.ReadRepository
}

func NewHandler(readRepo delegation.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetDelegationQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	d, err := h.readRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("delegation_id", q.ID.String()).Msg("failed to get delegation")
		return nil, err
	}

	return toDelegationDetail(d), nil
}

func toDelegationDetail(d *delegation.Delegation) *DelegationDetail {
	detail := &DelegationDetail{
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
		UpdatedAt:       d.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
	if d.AssignedToID != nil {
		s := d.AssignedToID.String()
		detail.AssignedToID = s
	}
	if d.DueDate != nil {
		s := d.DueDate.Format("2006-01-02T15:04:05Z07:00")
		detail.DueDate = &s
	}
	if d.LinkedEntityType != nil {
		detail.LinkedEntityType = d.LinkedEntityType
	}
	if d.LinkedEntityID != nil {
		s := d.LinkedEntityID.String()
		detail.LinkedEntityID = &s
	}
	return detail
}
