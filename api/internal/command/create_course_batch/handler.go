package create_course_batch

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/approval"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

const (
	creatorRoleOpAdmin     = "operation_admin"
	creatorRoleCourseOwner = "course_owner"
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
	// CourseVersionID, jika diisi, divalidasi harus sudah approval_status='approved'.
	CourseVersionID *uuid.UUID
	// CourseType-related fields
	CourseTypeID      *uuid.UUID
	PriceType         string
	ActualPrice       *int64
	DiscountedPrice   *int64
	NumSessions       int
	NumStudents       int
	// CourseType bounds for validation (fetched by HTTP handler before dispatch)
	CTMinPrice        int64
	CTNormalPrice     int64
	CTMinSessions     int
	CTMaxSessions     int
	CTMinParticipants int
	CTMaxParticipants int
}

type Handler struct {
	courseBatchWriteRepo  coursebatch.WriteRepository
	eventBus              eventbus.EventBus
	approvalWriteRepo     approval.WriteRepository           // optional, nil = no approval
	courseVersionReadRepo courseversion.ReadRepository       // optional, nil = skip approval gate
}

func NewHandler(courseBatchWriteRepo coursebatch.WriteRepository, eventBus eventbus.EventBus, approvalWriteRepo approval.WriteRepository, courseVersionReadRepo courseversion.ReadRepository) *Handler {
	return &Handler{
		courseBatchWriteRepo:  courseBatchWriteRepo,
		eventBus:              eventBus,
		approvalWriteRepo:     approvalWriteRepo,
		courseVersionReadRepo: courseVersionReadRepo,
	}
}

// ensureCourseVersionApproved memvalidasi bahwa course version yang direferensi
// sudah mencapai approval_status='approved'. Jika command tidak punya
// CourseVersionID atau readRepo nil, validasi di-skip.
func (h *Handler) ensureCourseVersionApproved(ctx context.Context, versionID *uuid.UUID) error {
	if versionID == nil || h.courseVersionReadRepo == nil {
		return nil
	}
	cv, err := h.courseVersionReadRepo.GetByID(ctx, *versionID)
	if err != nil {
		return fmt.Errorf("failed to load course version: %w", err)
	}
	if cv.ApprovalStatus != courseversion.ApprovalStatusApproved {
		return courseversion.ErrCourseVersionNotApproved
	}
	return nil
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	createCmd, ok := cmd.(*CreateCourseBatchCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.ensureCourseVersionApproved(ctx, createCmd.CourseVersionID); err != nil {
		log.Warn().Err(err).Msg("course version approval gate failed for batch creation")
		return err
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

	newCourseBatch.CourseTypeID    = createCmd.CourseTypeID
	newCourseBatch.PriceType       = createCmd.PriceType
	newCourseBatch.ActualPrice     = createCmd.ActualPrice
	newCourseBatch.DiscountedPrice = createCmd.DiscountedPrice
	newCourseBatch.NumSessions     = createCmd.NumSessions
	newCourseBatch.NumStudents     = createCmd.NumStudents

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

	if createCmd.CourseTypeID != nil {
		if createCmd.PriceType != "by_request" && createCmd.ActualPrice != nil {
			if *createCmd.ActualPrice < createCmd.CTMinPrice {
				return coursebatch.ErrActualPriceTooLow
			}
			if *createCmd.ActualPrice > createCmd.CTNormalPrice {
				return coursebatch.ErrActualPriceTooHigh
			}
			if createCmd.DiscountedPrice != nil && *createCmd.DiscountedPrice > *createCmd.ActualPrice {
				return coursebatch.ErrDiscountedPriceTooHigh
			}
		}
		if createCmd.NumSessions < createCmd.CTMinSessions || createCmd.NumSessions > createCmd.CTMaxSessions {
			return coursebatch.ErrNumSessionsOutOfRange
		}
		if createCmd.NumStudents < createCmd.CTMinParticipants || createCmd.NumStudents > createCmd.CTMaxParticipants {
			return coursebatch.ErrNumStudentsOutOfRange
		}
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
