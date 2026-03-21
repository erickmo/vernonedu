package update_student

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdateStudentCommand struct {
	StudentID    uuid.UUID `validate:"required"`
	Name         string    `validate:"required,min=1"`
	Email        string    `validate:"required,email"`
	Phone        string
	DepartmentID string
	IsActive     bool
}

type Handler struct {
	readRepo  student.ReadRepository
	writeRepo student.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(readRepo student.ReadRepository, writeRepo student.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{readRepo: readRepo, writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateStudentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	s, err := h.readRepo.GetByID(ctx, c.StudentID)
	if err != nil {
		return err
	}

	s.Name = c.Name
	s.Email = c.Email
	s.Phone = c.Phone
	s.IsActive = c.IsActive

	if c.DepartmentID != "" {
		id, err := uuid.Parse(c.DepartmentID)
		if err == nil {
			s.DepartmentID = &id
		}
	} else {
		s.DepartmentID = nil
	}
	s.UpdatedAt = time.Now()

	if err := h.writeRepo.Update(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to update student")
		return err
	}

	_ = h.eventBus.Publish(ctx, &student.StudentUpdated{StudentID: s.ID, Timestamp: time.Now().Unix()})
	log.Info().Str("student_id", s.ID.String()).Msg("student updated")
	return nil
}
