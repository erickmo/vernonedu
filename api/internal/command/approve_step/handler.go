package approve_step

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/approval"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo approval.WriteRepository
	readRepo  approval.ReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo approval.WriteRepository, readRepo approval.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*ApproveStepCommand)
	if !ok {
		return ErrInvalidCommand
	}

	req, err := h.readRepo.GetByID(ctx, c.ApprovalID)
	if err != nil {
		return err
	}

	if req.Status != approval.StatusPending {
		return approval.ErrAlreadyFinalized
	}

	var currentStep *approval.ApprovalStep
	for _, s := range req.Steps {
		if s.StepNumber == req.CurrentStep {
			currentStep = s
			break
		}
	}
	if currentStep == nil {
		return approval.ErrApprovalNotFound
	}
	if currentStep.ApproverID != c.ApproverID {
		return approval.ErrNotCurrentApprover
	}

	now := time.Now()
	currentStep.Status = approval.StepApproved
	currentStep.Comment = c.Comment
	currentStep.ActedAt = &now

	if err := h.writeRepo.UpdateStep(ctx, currentStep); err != nil {
		log.Error().Err(err).Msg("failed to update approval step")
		return err
	}

	isCompleted := req.CurrentStep >= req.TotalSteps
	if isCompleted {
		req.Status = approval.StatusApproved
	} else {
		req.CurrentStep++
	}
	req.UpdatedAt = now

	if err := h.writeRepo.Update(ctx, req); err != nil {
		log.Error().Err(err).Msg("failed to update approval request")
		return err
	}

	event := &approval.ApprovalStepApprovedEvent{
		EventType:   "ApprovalStepApproved",
		ApprovalID:  req.ID,
		StepNumber:  currentStep.StepNumber,
		IsCompleted: isCompleted,
		Timestamp:   now.Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish ApprovalStepApproved event")
	}

	log.Info().Str("approval_id", req.ID.String()).Int("step", currentStep.StepNumber).Msg("approval step approved")
	return nil
}
