package get_course_batch_detail

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
)

type GetCourseBatchDetailQuery struct {
	CourseBatchID uuid.UUID
}

type BatchEnrollmentReadModel struct {
	EnrollmentID  uuid.UUID `json:"enrollment_id"`
	StudentID     uuid.UUID `json:"student_id"`
	StudentName   string    `json:"student_name"`
	StudentEmail  string    `json:"student_email"`
	StudentPhone  string    `json:"student_phone"`
	EnrolledAt    string    `json:"enrolled_at"`
	Status        string    `json:"status"`
	PaymentStatus string    `json:"payment_status"`
}

type BatchDetailReadModel struct {
	ID                string                      `json:"id"`
	Name              string                      `json:"name"`
	StartDate         string                      `json:"start_date"`
	EndDate           string                      `json:"end_date"`
	MaxParticipants   int                         `json:"max_participants"`
	IsActive          bool                        `json:"is_active"`
	CourseID          string                      `json:"course_id"`
	CourseName        string                      `json:"course_name"`
	CourseDescription string                      `json:"course_description"`
	DepartmentID      string                      `json:"department_id"`
	DepartmentName    string                      `json:"department_name"`
	FacilitatorID     string                      `json:"facilitator_id"`
	FacilitatorName   string                      `json:"facilitator_name"`
	FacilitatorEmail  string                      `json:"facilitator_email"`
	TotalEnrolled     int                         `json:"total_enrolled"`
	PaidCount         int                         `json:"paid_count"`
	PendingCount      int                         `json:"pending_count"`
	FailedCount       int                         `json:"failed_count"`
	CreatedAt         int64                       `json:"created_at"`
	Enrollments       []*BatchEnrollmentReadModel `json:"enrollments"`
}

type Handler struct {
	readRepo coursebatch.ReadRepository
}

func NewHandler(readRepo coursebatch.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCourseBatchDetailQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	detail, err := h.readRepo.GetBatchDetail(ctx, q.CourseBatchID)
	if err != nil {
		log.Error().Err(err).Str("batch_id", q.CourseBatchID.String()).Msg("failed to get course batch detail")
		return nil, err
	}

	enrollments := make([]*BatchEnrollmentReadModel, len(detail.Enrollments))
	var paidCount, pendingCount, failedCount int
	for i, e := range detail.Enrollments {
		enrollments[i] = &BatchEnrollmentReadModel{
			EnrollmentID:  e.EnrollmentID,
			StudentID:     e.StudentID,
			StudentName:   e.StudentName,
			StudentEmail:  e.StudentEmail,
			StudentPhone:  e.StudentPhone,
			EnrolledAt:    e.EnrolledAt.Format("2006-01-02T15:04:05Z07:00"),
			Status:        e.Status,
			PaymentStatus: e.PaymentStatus,
		}
		switch e.PaymentStatus {
		case "paid":
			paidCount++
		case "pending":
			pendingCount++
		case "failed":
			failedCount++
		}
	}

	return &BatchDetailReadModel{
		ID:                detail.ID.String(),
		Name:              detail.Name,
		StartDate:         detail.StartDate.Format("2006-01-02T15:04:05Z07:00"),
		EndDate:           detail.EndDate.Format("2006-01-02T15:04:05Z07:00"),
		MaxParticipants:   detail.MaxParticipants,
		IsActive:          detail.IsActive,
		CourseID:          detail.CourseID,
		CourseName:        detail.CourseName,
		CourseDescription: detail.CourseDescription,
		DepartmentID:      detail.DepartmentID,
		DepartmentName:    detail.DepartmentName,
		FacilitatorID:     detail.FacilitatorID,
		FacilitatorName:   detail.FacilitatorName,
		FacilitatorEmail:  detail.FacilitatorEmail,
		TotalEnrolled:     len(detail.Enrollments),
		PaidCount:         paidCount,
		PendingCount:      pendingCount,
		FailedCount:       failedCount,
		CreatedAt:         detail.CreatedAt.Unix(),
		Enrollments:       enrollments,
	}, nil
}
