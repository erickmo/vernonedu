package list_enrollment_summary

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/enrollment"
)

type BatchSummaryReadModel struct {
	BatchID          uuid.UUID  `json:"batch_id"`
	BatchName        string     `json:"batch_name"`
	StartDate        string     `json:"start_date"`
	EndDate          string     `json:"end_date"`
	MaxParticipants  int        `json:"max_participants"`
	IsActive         bool       `json:"is_active"`
	CourseID         string     `json:"course_id"`
	CourseName       string     `json:"course_name"`
	DepartmentID     string     `json:"department_id"`
	DepartmentName   string     `json:"department_name"`
	EnrollmentCount  int        `json:"enrollment_count"`
	PaidCount        int        `json:"paid_count"`
	LatestEnrolledAt *time.Time `json:"latest_enrolled_at"`
}

type ListEnrollmentSummaryQuery struct{}

type Handler struct {
	readRepo enrollment.ReadRepository
}

func NewHandler(readRepo enrollment.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	_, ok := query.(*ListEnrollmentSummaryQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	summaries, err := h.readRepo.ListBatchSummary(ctx)
	if err != nil {
		return nil, err
	}

	result := make([]*BatchSummaryReadModel, len(summaries))
	for i, s := range summaries {
		result[i] = &BatchSummaryReadModel{
			BatchID:          s.BatchID,
			BatchName:        s.BatchName,
			StartDate:        s.StartDate,
			EndDate:          s.EndDate,
			MaxParticipants:  s.MaxParticipants,
			IsActive:         s.IsActive,
			CourseID:         s.CourseID,
			CourseName:       s.CourseName,
			DepartmentID:     s.DepartmentID,
			DepartmentName:   s.DepartmentName,
			EnrollmentCount:  s.EnrollmentCount,
			PaidCount:        s.PaidCount,
			LatestEnrolledAt: s.LatestEnrolledAt,
		}
	}
	return result, nil
}
