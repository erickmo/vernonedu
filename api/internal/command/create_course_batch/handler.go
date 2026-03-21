package create_course_batch

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateCourseBatchCommand struct {
	CourseID        uuid.UUID  `validate:"required"`
	MasterCourseID  *uuid.UUID
	Code            string
	Name            string    `validate:"required,min=1"`
	StartDate       time.Time `validate:"required"`
	EndDate         time.Time `validate:"required"`
	MinParticipants int
	MaxParticipants int       `validate:"required,min=1"`
	IsActive        bool
	WebsiteVisible  bool
	Price           int64
	PaymentMethod   string
}

type Handler struct {
	courseBatchWriteRepo coursebatch.WriteRepository
	eventBus             eventbus.EventBus
}

func NewHandler(courseBatchWriteRepo coursebatch.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		courseBatchWriteRepo: courseBatchWriteRepo,
		eventBus:             eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	createCmd, ok := cmd.(*CreateCourseBatchCommand)
	if !ok {
		return ErrInvalidCommand
	}

	newCourseBatch, err := coursebatch.NewCourseBatch(
		createCmd.CourseID,
		createCmd.Name,
		createCmd.StartDate,
		createCmd.EndDate,
		createCmd.MinParticipants,
		createCmd.MaxParticipants,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create course batch")
		return err
	}
	newCourseBatch.IsActive = createCmd.IsActive
	newCourseBatch.MasterCourseID = createCmd.MasterCourseID

	// Auto-generate code if not provided
	if createCmd.Code != "" {
		newCourseBatch.Code = createCmd.Code
	} else {
		newCourseBatch.Code = fmt.Sprintf("BATCH-%s-%04d", time.Now().Format("2006"), time.Now().UnixNano()%10000)
	}

	newCourseBatch.MinParticipants = createCmd.MinParticipants
	newCourseBatch.WebsiteVisible = true
	if createCmd.PaymentMethod != "" && coursebatch.ValidPaymentMethods[createCmd.PaymentMethod] {
		newCourseBatch.PaymentMethod = createCmd.PaymentMethod
	} else {
		newCourseBatch.PaymentMethod = coursebatch.PaymentMethodUpfront
	}
	newCourseBatch.Price = createCmd.Price

	if err := h.courseBatchWriteRepo.Save(ctx, newCourseBatch); err != nil {
		log.Error().Err(err).Msg("failed to save course batch")
		return err
	}

	event := &coursebatch.CourseBatchCreated{
		CourseBatchID: newCourseBatch.ID,
		Name:          newCourseBatch.Name,
		Timestamp:     time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish CourseBatchCreated event")
		return err
	}

	log.Info().Str("course_batch_id", newCourseBatch.ID.String()).Msg("course batch created successfully")
	return nil
}
