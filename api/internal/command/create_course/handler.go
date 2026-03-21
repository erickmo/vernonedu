package create_course

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/course"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateCourseCommand struct {
	Name        string `validate:"required,min=1"`
	Description string
	IsActive    bool
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
	createCmd, ok := cmd.(*CreateCourseCommand)
	if !ok {
		return ErrInvalidCommand
	}

	newCourse, err := course.NewCourse(createCmd.Name, createCmd.Description, createCmd.IsActive)
	if err != nil {
		log.Error().Err(err).Msg("failed to create course")
		return err
	}

	if err := h.courseWriteRepo.Save(ctx, newCourse); err != nil {
		log.Error().Err(err).Msg("failed to save course")
		return err
	}

	event := &course.CourseCreated{
		CourseID:  newCourse.ID,
		Name:      newCourse.Name,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CourseCreated event")
		return err
	}

	log.Info().Str("course_id", newCourse.ID.String()).Msg("course created successfully")
	return nil
}
