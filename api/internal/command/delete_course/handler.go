package delete_course

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/course"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type DeleteCourseCommand struct {
	CourseID uuid.UUID `validate:"required"`
}

type Handler struct {
	courseWriteRepo course.WriteRepository
	eventBus        eventbus.EventBus
}

func NewHandler(courseWriteRepo course.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		courseWriteRepo: courseWriteRepo,
		eventBus:        eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteCourseCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.courseWriteRepo.Delete(ctx, deleteCmd.CourseID); err != nil {
		log.Error().Err(err).Str("course_id", deleteCmd.CourseID.String()).Msg("failed to delete course")
		return err
	}

	event := &course.CourseDeleted{
		CourseID:  deleteCmd.CourseID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CourseDeleted event")
		return err
	}

	log.Info().Str("course_id", deleteCmd.CourseID.String()).Msg("course deleted successfully")
	return nil
}
