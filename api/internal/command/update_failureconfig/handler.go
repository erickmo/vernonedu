package update_failureconfig

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursetype"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ErrInvalidCommand dikembalikan ketika tipe command tidak sesuai.
var ErrInvalidCommand = errors.New("invalid update failure config command")

// UpdateFailureConfigCommand adalah command untuk memperbarui ComponentFailureConfig pada CourseType.
type UpdateFailureConfigCommand struct {
	CourseTypeID           uuid.UUID                       `validate:"required"`
	ComponentFailureConfig *coursetype.ComponentFailureConfig `validate:"required"`
}

// Handler menangani UpdateFailureConfigCommand.
type Handler struct {
	writeRepo coursetype.WriteRepository
	readRepo  coursetype.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo coursetype.WriteRepository, readRepo coursetype.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk memperbarui ComponentFailureConfig pada CourseType.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateFailureConfigCommand)
	if !ok {
		return ErrInvalidCommand
	}

	ct, err := h.readRepo.GetByID(ctx, c.CourseTypeID)
	if err != nil {
		log.Error().Err(err).Str("course_type_id", c.CourseTypeID.String()).Msg("course type not found")
		return err
	}

	ct.ComponentFailureConfig = c.ComponentFailureConfig

	if err := h.writeRepo.Update(ctx, ct); err != nil {
		log.Error().Err(err).Msg("failed to persist failure config update")
		return err
	}

	log.Info().Str("course_type_id", ct.ID.String()).Msg("failure config updated successfully")
	return nil
}
