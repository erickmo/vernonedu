package list_approvals

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/approval"
)

type StepReadModel struct {
	ID           uuid.UUID `json:"id"`
	StepNumber   int       `json:"step_number"`
	ApproverID   uuid.UUID `json:"approver_id"`
	ApproverRole string    `json:"approver_role"`
	Status       string    `json:"status"`
	Comment      string    `json:"comment"`
	ActedAt      *int64    `json:"acted_at"`
}

type ApprovalReadModel struct {
	ID          uuid.UUID        `json:"id"`
	Type        string           `json:"type"`
	EntityType  string           `json:"entity_type"`
	EntityID    uuid.UUID        `json:"entity_id"`
	InitiatorID uuid.UUID        `json:"initiator_id"`
	CurrentStep int              `json:"current_step"`
	TotalSteps  int              `json:"total_steps"`
	Status      string           `json:"status"`
	Reason      string           `json:"reason"`
	Steps       []*StepReadModel `json:"steps"`
	CreatedAt   int64            `json:"created_at"`
	UpdatedAt   int64            `json:"updated_at"`
}

type ListResult struct {
	Data   []*ApprovalReadModel `json:"data"`
	Total  int                  `json:"total"`
	Offset int                  `json:"offset"`
	Limit  int                  `json:"limit"`
}

type Handler struct {
	readRepo approval.ReadRepository
}

func NewHandler(readRepo approval.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListApprovalsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	approvals, total, err := h.readRepo.List(ctx, q.Offset, q.Limit, q.Status, q.ApproverID)
	if err != nil {
		log.Error().Err(err).Msg("failed to list approvals")
		return nil, err
	}

	readModels := make([]*ApprovalReadModel, len(approvals))
	for i, a := range approvals {
		readModels[i] = ToReadModel(a)
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}

// ToReadModel converts an ApprovalRequest domain entity to an ApprovalReadModel.
// Exported so it can be reused by get_approval handler.
func ToReadModel(a *approval.ApprovalRequest) *ApprovalReadModel {
	steps := make([]*StepReadModel, len(a.Steps))
	for i, s := range a.Steps {
		var actedAt *int64
		if s.ActedAt != nil {
			t := s.ActedAt.Unix()
			actedAt = &t
		}
		steps[i] = &StepReadModel{
			ID:           s.ID,
			StepNumber:   s.StepNumber,
			ApproverID:   s.ApproverID,
			ApproverRole: s.ApproverRole,
			Status:       string(s.Status),
			Comment:      s.Comment,
			ActedAt:      actedAt,
		}
	}
	return &ApprovalReadModel{
		ID:          a.ID,
		Type:        string(a.Type),
		EntityType:  a.EntityType,
		EntityID:    a.EntityID,
		InitiatorID: a.InitiatorID,
		CurrentStep: a.CurrentStep,
		TotalSteps:  a.TotalSteps,
		Status:      string(a.Status),
		Reason:      a.Reason,
		Steps:       steps,
		CreatedAt:   a.CreatedAt.Unix(),
		UpdatedAt:   a.UpdatedAt.Unix(),
	}
}
