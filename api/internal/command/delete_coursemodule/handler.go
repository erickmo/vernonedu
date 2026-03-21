package delete_coursemodule

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursemodule"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ErrInvalidCommand dikembalikan ketika tipe command tidak sesuai.
var ErrInvalidCommand = errors.New("invalid delete course module command")

// DeleteCourseModuleCommand adalah command untuk menghapus CourseModule.
type DeleteCourseModuleCommand struct {
	ModuleID uuid.UUID `validate:"required"`
}

// Handler menangani DeleteCourseModuleCommand.
type Handler struct {
	writeRepo coursemodule.WriteRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo coursemodule.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk menghapus CourseModule.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteCourseModuleCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.writeRepo.Delete(ctx, c.ModuleID); err != nil {
		log.Error().Err(err).Str("module_id", c.ModuleID.String()).Msg("failed to delete course module")
		return err
	}

	log.Info().Str("module_id", c.ModuleID.String()).Msg("course module deleted successfully")
	return nil
}
