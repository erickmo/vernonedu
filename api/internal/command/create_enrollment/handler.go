package create_enrollment

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/enrollment"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateEnrollmentCommand struct {
	StudentID     uuid.UUID `validate:"required"`
	CourseBatchID uuid.UUID `validate:"required"`
}

type Handler struct {
	writeRepo enrollment.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo enrollment.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateEnrollmentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	e, err := enrollment.NewEnrollment(c.StudentID, c.CourseBatchID)
	if err != nil {
		return err
	}

	if err := h.writeRepo.Save(ctx, e); err != nil {
		log.Error().Err(err).Msg("failed to save enrollment")
		return err
	}

	_ = h.eventBus.Publish(ctx, &enrollment.EnrollmentCreated{
		EnrollmentID:  e.ID,
		StudentID:     e.StudentID,
		CourseBatchID: e.CourseBatchID,
		Timestamp:     time.Now().Unix(),
	})
	log.Info().Str("enrollment_id", e.ID.String()).Msg("enrollment created")
	return nil
}
