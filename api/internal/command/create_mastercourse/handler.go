package create_mastercourse

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/mastercourse"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)


// CreateMasterCourseCommand adalah command untuk membuat MasterCourse baru.
type CreateMasterCourseCommand struct {
	CourseCode       string   `validate:"required"`
	CourseName       string   `validate:"required,min=1"`
	Field            string   `validate:"required"`
	CoreCompetencies []string
	Description      string
}

// Handler menangani CreateMasterCourseCommand.
type Handler struct {
	writeRepo mastercourse.WriteRepository
	eventBus  eventbus.EventBus
}

// NewHandler membuat instance baru Handler.
func NewHandler(writeRepo mastercourse.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

// Handle mengeksekusi command untuk membuat MasterCourse baru.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateMasterCourseCommand)
	if !ok {
		return ErrInvalidCommand
	}

	mc, err := mastercourse.NewMasterCourse(c.CourseCode, c.CourseName, c.Field, c.Description, c.CoreCompetencies)
	if err != nil {
		log.Error().Err(err).Msg("failed to create master course entity")
		return err
	}

	if err := h.writeRepo.Save(ctx, mc); err != nil {
		log.Error().Err(err).Msg("failed to save master course")
		return err
	}

	event := &mastercourse.MasterCourseCreated{
		MasterCourseID: mc.ID,
		CourseCode:     mc.CourseCode,
		CourseName:     mc.CourseName,
		Field:          mc.Field,
		Timestamp:      time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish MasterCourseCreated event")
	}

	log.Info().Str("master_course_id", mc.ID.String()).Msg("master course created successfully")
	return nil
}
