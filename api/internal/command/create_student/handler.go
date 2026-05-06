package create_student

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateStudentCommand struct {
	Name                  string `validate:"required,min=1"`
	Email                 string `validate:"required,email"`
	Phone                 string
	DepartmentID          string
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
	writeRepo student.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo student.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateStudentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	var deptID *uuid.UUID
	if c.DepartmentID != "" {
		id, err := uuid.Parse(c.DepartmentID)
		if err == nil {
			deptID = &id
		}
	}

	s, err := student.NewStudent(c.Name, c.Email, c.Phone, deptID)
	if err != nil {
		return err
	}

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
	}

	if err := h.writeRepo.Save(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to save student")
		return err
	}

	_ = h.eventBus.Publish(ctx, &student.StudentCreated{StudentID: s.ID, Name: s.Name, Timestamp: time.Now().Unix()})
	log.Info().Str("student_id", s.ID.String()).Msg("student created")
	return nil
}
