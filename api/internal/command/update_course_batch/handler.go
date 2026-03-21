package update_course_batch

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdateCourseBatchCommand struct {
	CourseBatchID   uuid.UUID  `validate:"required"`
	BranchID        *uuid.UUID
	Name            string    `validate:"required,min=1"`
	StartDate       time.Time `validate:"required"`
	EndDate         time.Time `validate:"required"`
	MinParticipants int
	MaxParticipants int       `validate:"required,min=1"`
	IsActive        bool
	WebsiteVisible  bool
	Price           int64
	PaymentMethod   string
}

type Handler struct {
	courseBatchReadRepo  coursebatch.ReadRepository
	courseBatchWriteRepo coursebatch.WriteRepository
	eventBus             eventbus.EventBus
}

func NewHandler(courseBatchReadRepo coursebatch.ReadRepository, courseBatchWriteRepo coursebatch.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		courseBatchReadRepo:  courseBatchReadRepo,
		courseBatchWriteRepo: courseBatchWriteRepo,
		eventBus:             eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateCourseBatchCommand)
	if !ok {
		return ErrInvalidCommand
	}

	existingBatch, err := h.courseBatchReadRepo.GetByID(ctx, updateCmd.CourseBatchID)
	if err != nil {
		if errors.Is(err, coursebatch.ErrCourseBatchNotFound) {
			return coursebatch.ErrCourseBatchNotFound
		}
		log.Error().Err(err).Str("course_batch_id", updateCmd.CourseBatchID.String()).Msg("failed to get course batch")
		return err
	}

	if err := existingBatch.UpdateName(updateCmd.Name); err != nil {
		log.Error().Err(err).Msg("failed to update course batch name")
		return err
	}
	existingBatch.StartDate = updateCmd.StartDate
	existingBatch.EndDate = updateCmd.EndDate
	existingBatch.MinParticipants = updateCmd.MinParticipants
	existingBatch.MaxParticipants = updateCmd.MaxParticipants
	existingBatch.IsActive = updateCmd.IsActive
	existingBatch.WebsiteVisible = updateCmd.WebsiteVisible
	existingBatch.Price = updateCmd.Price
	if updateCmd.BranchID != nil {
		existingBatch.BranchID = updateCmd.BranchID
	}
	if updateCmd.PaymentMethod != "" && coursebatch.ValidPaymentMethods[updateCmd.PaymentMethod] {
		existingBatch.PaymentMethod = updateCmd.PaymentMethod
	}
	existingBatch.UpdatedAt = time.Now()

	if err := h.courseBatchWriteRepo.Update(ctx, existingBatch); err != nil {
		log.Error().Err(err).Msg("failed to update course batch")
		return err
	}

	event := &coursebatch.CourseBatchUpdated{
		CourseBatchID: existingBatch.ID,
		Timestamp:     time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CourseBatchUpdated event")
		return err
	}

	log.Info().Str("course_batch_id", existingBatch.ID.String()).Msg("course batch updated successfully")
	return nil
}
