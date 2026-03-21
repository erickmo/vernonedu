package delete_student

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type DeleteStudentCommand struct {
	StudentID uuid.UUID `validate:"required"`
}

type Handler struct {
	writeRepo student.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo student.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteStudentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.writeRepo.Delete(ctx, c.StudentID); err != nil {
		log.Error().Err(err).Msg("failed to delete student")
		return err
	}

	_ = h.eventBus.Publish(ctx, &student.StudentDeleted{StudentID: c.StudentID, Timestamp: time.Now().Unix()})
	log.Info().Str("student_id", c.StudentID.String()).Msg("student deleted")
	return nil
}
