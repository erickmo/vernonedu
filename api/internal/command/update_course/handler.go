package update_course

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/course"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdateCourseCommand struct {
	CourseID    uuid.UUID `validate:"required"`
	Name        string    `validate:"required,min=1"`
	Description string
	IsActive    bool
}

type Handler struct {
	courseReadRepo  course.ReadRepository
	courseWriteRepo course.WriteRepository
	eventBus        eventbus.EventBus
}

func NewHandler(courseReadRepo course.ReadRepository, courseWriteRepo course.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		courseReadRepo:  courseReadRepo,
		courseWriteRepo: courseWriteRepo,
		eventBus:        eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateCourseCommand)
	if !ok {
		return ErrInvalidCommand
	}

	existingCourse, err := h.courseReadRepo.GetByID(ctx, updateCmd.CourseID)
	if err != nil {
		if errors.Is(err, course.ErrCourseNotFound) {
			return course.ErrCourseNotFound
		}
		log.Error().Err(err).Str("course_id", updateCmd.CourseID.String()).Msg("failed to get course")
		return err
	}

	if err := existingCourse.UpdateName(updateCmd.Name); err != nil {
		log.Error().Err(err).Msg("failed to update course name")
		return err
	}
	existingCourse.Description = updateCmd.Description
	existingCourse.IsActive = updateCmd.IsActive

	if err := h.courseWriteRepo.Update(ctx, existingCourse); err != nil {
		log.Error().Err(err).Msg("failed to update course")
		return err
	}

	event := &course.CourseUpdated{
		CourseID:  existingCourse.ID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CourseUpdated event")
		return err
	}

	log.Info().Str("course_id", existingCourse.ID.String()).Msg("course updated successfully")
	return nil
}
