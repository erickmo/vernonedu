package convert_lead_to_student

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	leadReadRepo     lead.ReadRepository
	leadWriteRepo    lead.WriteRepository
	studentWriteRepo student.WriteRepository
	eventBus         eventbus.EventBus
}

func NewHandler(
	leadReadRepo lead.ReadRepository,
	leadWriteRepo lead.WriteRepository,
	studentWriteRepo student.WriteRepository,
	eventBus eventbus.EventBus,
) *Handler {
	return &Handler{
		leadReadRepo:     leadReadRepo,
		leadWriteRepo:    leadWriteRepo,
		studentWriteRepo: studentWriteRepo,
		eventBus:         eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	convertCmd, ok := cmd.(*ConvertLeadToStudentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	existingLead, err := h.leadReadRepo.GetByID(ctx, convertCmd.LeadID)
	if err != nil {
		if errors.Is(err, lead.ErrLeadNotFound) {
			return ErrLeadNotFound
		}
		log.Error().Err(err).Str("lead_id", convertCmd.LeadID.String()).Msg("failed to get lead")
		return err
	}

	if existingLead.Status == "enrolled" {
		return ErrLeadAlreadyConverted
	}

	if existingLead.Email == "" {
		return student.ErrInvalidEmail
	}

	newStudent, err := student.NewStudent(existingLead.Name, existingLead.Email, existingLead.Phone, nil)
	if err != nil {
		log.Error().Err(err).Msg("failed to create student from lead")
		return err
	}

	if err := h.studentWriteRepo.Save(ctx, newStudent); err != nil {
		log.Error().Err(err).Msg("failed to save student")
		return err
	}

	existingLead.Status = "enrolled"
	existingLead.UpdatedAt = time.Now()

	if err := h.leadWriteRepo.Update(ctx, existingLead); err != nil {
		log.Error().Err(err).Msg("failed to update lead status to enrolled")
		return err
	}

	event := &lead.LeadConvertedEvent{
		EventType: "LeadConverted",
		LeadID:    existingLead.ID,
		StudentID: newStudent.ID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish LeadConverted event")
		return err
	}

	log.Info().
		Str("lead_id", existingLead.ID.String()).
		Str("student_id", newStudent.ID.String()).
		Msg("lead converted to student successfully")
	return nil
}
