package archive_mastercourse

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/mastercourse"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)


// ArchiveMasterCourseCommand adalah command untuk mengarsipkan MasterCourse.
type ArchiveMasterCourseCommand struct {
	MasterCourseID uuid.UUID `validate:"required"`
}

// Handler menangani ArchiveMasterCourseCommand.
type Handler struct {
	writeRepo mastercourse.WriteRepository
	readRepo  mastercourse.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo mastercourse.WriteRepository, readRepo mastercourse.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk mengarsipkan MasterCourse.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*ArchiveMasterCourseCommand)
	if !ok {
		return ErrInvalidCommand
	}

	mc, err := h.readRepo.GetByID(ctx, c.MasterCourseID)
	if err != nil {
		log.Error().Err(err).Str("id", c.MasterCourseID.String()).Msg("master course not found")
		return err
	}

	if err := mc.Archive(); err != nil {
		log.Error().Err(err).Msg("failed to archive master course entity")
		return err
	}

	if err := h.writeRepo.Update(ctx, mc); err != nil {
		log.Error().Err(err).Msg("failed to persist master course archive")
		return err
	}

	event := &mastercourse.MasterCourseArchived{
		MasterCourseID: mc.ID,
		Timestamp:      time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish MasterCourseArchived event")
	}

	log.Info().Str("master_course_id", mc.ID.String()).Msg("master course archived successfully")
	return nil
}
