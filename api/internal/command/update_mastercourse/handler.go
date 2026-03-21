package update_mastercourse

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/mastercourse"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)


// UpdateMasterCourseCommand adalah command untuk memperbarui MasterCourse.
type UpdateMasterCourseCommand struct {
	MasterCourseID   uuid.UUID `validate:"required"`
	CourseName       string    `validate:"required,min=1"`
	Field            string    `validate:"required"`
	CoreCompetencies []string
	Description      string
	SupportingAppUrl string
}

// Handler menangani UpdateMasterCourseCommand.
type Handler struct {
	writeRepo mastercourse.WriteRepository
	readRepo  mastercourse.ReadRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo mastercourse.WriteRepository, readRepo mastercourse.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk memperbarui MasterCourse.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateMasterCourseCommand)
	if !ok {
		return ErrInvalidCommand
	}

	mc, err := h.readRepo.GetByID(ctx, c.MasterCourseID)
	if err != nil {
		log.Error().Err(err).Str("id", c.MasterCourseID.String()).Msg("master course not found")
		return err
	}

	var supportingAppUrl *string
	if c.SupportingAppUrl != "" {
		url := c.SupportingAppUrl
		supportingAppUrl = &url
	}

	if err := mc.Update(c.CourseName, c.Field, c.Description, c.CoreCompetencies, supportingAppUrl); err != nil {
		log.Error().Err(err).Msg("failed to update master course entity")
		return err
	}

	if err := h.writeRepo.Update(ctx, mc); err != nil {
		log.Error().Err(err).Msg("failed to persist master course update")
		return err
	}

	event := &mastercourse.MasterCourseUpdated{
		MasterCourseID: mc.ID,
		Timestamp:      time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish MasterCourseUpdated event")
	}

	log.Info().Str("master_course_id", mc.ID.String()).Msg("master course updated successfully")
	return nil
}
