package create_course_batch

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/approval"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateCourseBatchCommand struct {
	CourseID        uuid.UUID  `validate:"required"`
	MasterCourseID  *uuid.UUID
	BranchID        *uuid.UUID
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
	CreatorRole     string
	InitiatorID     uuid.UUID
}

type Handler struct {
	courseBatchWriteRepo coursebatch.WriteRepository
	eventBus             eventbus.EventBus
	approvalWriteRepo    approval.WriteRepository // optional, nil = no approval
}

func NewHandler(courseBatchWriteRepo coursebatch.WriteRepository, eventBus eventbus.EventBus, approvalWriteRepo approval.WriteRepository) *Handler {
	return &Handler{
		courseBatchWriteRepo: courseBatchWriteRepo,
		eventBus:             eventBus,
		approvalWriteRepo:    approvalWriteRepo,
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
	newCourseBatch.BranchID = createCmd.BranchID

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

	// Determine status based on creator role
	if createCmd.CreatorRole == "operation_admin" || createCmd.CreatorRole == "course_owner" {
		newCourseBatch.Status = coursebatch.CourseBatchStatusPending
	} else {
		newCourseBatch.Status = coursebatch.CourseBatchStatusActive
	}

	if err := h.courseBatchWriteRepo.Save(ctx, newCourseBatch); err != nil {
		log.Error().Err(err).Msg("failed to save course batch")
		return err
	}

	// Create approval request if needed
	if createCmd.CreatorRole == "operation_admin" || createCmd.CreatorRole == "course_owner" {
		initiatorID := createCmd.InitiatorID

		var steps []approval.StepInput
		switch createCmd.CreatorRole {
		case "operation_admin":
			steps = []approval.StepInput{
				{ApproverID: uuid.Nil, ApproverRole: "course_owner"},
				{ApproverID: uuid.Nil, ApproverRole: "operation_leader"},
				{ApproverID: uuid.Nil, ApproverRole: "dept_leader"},
			}
		case "course_owner":
			steps = []approval.StepInput{
				{ApproverID: uuid.Nil, ApproverRole: "operation_leader"},
				{ApproverID: uuid.Nil, ApproverRole: "dept_leader"},
			}
		}

		req, err := approval.NewApprovalRequest(
			approval.TypeCreateBatch,
			"course_batch",
			newCourseBatch.ID,
			initiatorID,
			"batch creation requires approval",
			steps,
		)
		if err != nil {
			log.Error().Err(err).Msg("failed to create approval request")
		} else if h.approvalWriteRepo != nil {
			if err := h.approvalWriteRepo.Save(ctx, req); err != nil {
				log.Error().Err(err).Msg("failed to save approval request")
			}
		}
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
