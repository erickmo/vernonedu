package delete_course_batch

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type DeleteCourseBatchCommand struct {
	CourseBatchID uuid.UUID `validate:"required"`
}

type Handler struct {
	courseBatchWriteRepo coursebatch.WriteRepository
	eventBus             eventbus.EventBus
}

func NewHandler(courseBatchWriteRepo coursebatch.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		courseBatchWriteRepo: courseBatchWriteRepo,
		eventBus:             eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteCourseBatchCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.courseBatchWriteRepo.Delete(ctx, deleteCmd.CourseBatchID); err != nil {
		log.Error().Err(err).Str("course_batch_id", deleteCmd.CourseBatchID.String()).Msg("failed to delete course batch")
		return err
	}

	event := &coursebatch.CourseBatchDeleted{
		CourseBatchID: deleteCmd.CourseBatchID,
		Timestamp:     time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CourseBatchDeleted event")
		return err
	}

	log.Info().Str("course_batch_id", deleteCmd.CourseBatchID.String()).Msg("course batch deleted successfully")
	return nil
}
