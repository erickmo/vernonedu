package listdepartmentsummary

import (
	"context"
	"fmt"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
)

type ListDepartmentSummaryQuery struct{}

type DepartmentSummaryReadModel struct {
	ID                  string `json:"id"`
	Name                string `json:"name"`
	Description         string `json:"description"`
	CourseCount         int    `json:"course_count"`
	BatchUpcoming       int    `json:"batch_upcoming"`
	BatchOngoing        int    `json:"batch_ongoing"`
	BatchCompleted      int    `json:"batch_completed"`
	PaidEnrollmentCount int    `json:"paid_enrollment_count"`
}

type Handler struct {
	repo department.ReadRepository
}

func NewHandler(repo department.ReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, q interface{}) (interface{}, error) {
	_, ok := q.(*ListDepartmentSummaryQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	summaries, err := h.repo.GetSummaries(ctx)
	if err != nil {
		return nil, fmt.Errorf("get department summaries: %w", err)
	}

	result := make([]*DepartmentSummaryReadModel, len(summaries))
	for i, s := range summaries {
		result[i] = &DepartmentSummaryReadModel{
			ID:                  s.ID.String(),
			Name:                s.Name,
			Description:         s.Description,
			CourseCount:         s.CourseCount,
			BatchUpcoming:       s.BatchUpcoming,
			BatchOngoing:        s.BatchOngoing,
			BatchCompleted:      s.BatchCompleted,
			PaidEnrollmentCount: s.PaidEnrollmentCount,
		}
	}
	return result, nil
}
