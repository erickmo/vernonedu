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
	StudentID             uuid.UUID `validate:"required"`
	Name                  string    `validate:"required,min=1"`
	Email                 string    `validate:"required,email"`
	Phone                 string
	DepartmentID          string
	IsActive              bool
	Address               string
	City                  string
	Province              string
	PostalCode            string
	BirthDate             string // "YYYY-MM-DD" or ""
	Gender                string
	NIK                   string
	PhotoURL              string
	EducationLevel        string
	SchoolName            string
	EmergencyContactName  string
	EmergencyContactPhone string
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
	s.Address = c.Address
	s.City = c.City
	s.Province = c.Province
	s.PostalCode = c.PostalCode
	s.Gender = c.Gender
	s.NIK = c.NIK
	s.PhotoURL = c.PhotoURL
	s.EducationLevel = c.EducationLevel
	s.SchoolName = c.SchoolName
	s.EmergencyContactName = c.EmergencyContactName
	s.EmergencyContactPhone = c.EmergencyContactPhone

	if c.BirthDate != "" {
		t, err := time.Parse("2006-01-02", c.BirthDate)
		if err == nil {
			s.BirthDate = &t
		}
	} else {
		s.BirthDate = nil
	}

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
