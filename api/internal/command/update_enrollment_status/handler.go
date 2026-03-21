package update_enrollment_status

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/enrollment"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type UpdateEnrollmentStatusCommand struct {
	EnrollmentID uuid.UUID `validate:"required"`
	Status       string    `validate:"required"`
}

var validStatuses = map[string]bool{
	"active": true, "completed": true, "dropped": true, "withdrawn": true,
}

type Handler struct {
	writeRepo enrollment.WriteRepository
}

func NewHandler(writeRepo enrollment.WriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateEnrollmentStatusCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if !validStatuses[c.Status] {
		return ErrInvalidStatus
	}
	if err := h.writeRepo.UpdateStatus(ctx, c.EnrollmentID, c.Status); err != nil {
		log.Error().Err(err).Str("enrollment_id", c.EnrollmentID.String()).Msg("failed to update enrollment status")
		return err
	}
	log.Info().Str("enrollment_id", c.EnrollmentID.String()).Str("status", c.Status).Msg("enrollment status updated")
	return nil
}
