package delete_mastercourse

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/mastercourse"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)


// DeleteMasterCourseCommand adalah command untuk menghapus MasterCourse.
type DeleteMasterCourseCommand struct {
	MasterCourseID uuid.UUID `validate:"required"`
}

// Handler menangani DeleteMasterCourseCommand.
type Handler struct {
	writeRepo mastercourse.WriteRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo mastercourse.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk menghapus MasterCourse.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteMasterCourseCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.writeRepo.Delete(ctx, c.MasterCourseID); err != nil {
		log.Error().Err(err).Str("id", c.MasterCourseID.String()).Msg("failed to delete master course")
		return err
	}

	log.Info().Str("master_course_id", c.MasterCourseID.String()).Msg("master course deleted successfully")
	return nil
}
