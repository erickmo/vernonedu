package getdepartmentbatches

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
)

type GetDepartmentBatchesQuery struct {
	DepartmentID string
}

type DepartmentBatchReadModel struct {
	BatchID         string `json:"batch_id"`
	BatchName       string `json:"batch_name"`
	StartDate       string `json:"start_date"`
	EndDate         string `json:"end_date"`
	MaxParticipants int    `json:"max_participants"`
	IsActive        bool   `json:"is_active"`
	CourseName      string `json:"course_name"`
	FacilitatorID   string `json:"facilitator_id"`
	FacilitatorName string `json:"facilitator_name"`
	EnrollmentCount int    `json:"enrollment_count"`
}

type Handler struct {
	repo department.ReadRepository
}

func NewHandler(repo department.ReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, q interface{}) (interface{}, error) {
	query, ok := q.(*GetDepartmentBatchesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	deptID, err := uuid.Parse(query.DepartmentID)
	if err != nil {
		return nil, fmt.Errorf("invalid department id: %w", err)
	}

	batches, err := h.repo.GetBatches(ctx, deptID)
	if err != nil {
		return nil, fmt.Errorf("get department batches: %w", err)
	}

	result := make([]*DepartmentBatchReadModel, len(batches))
	for i, b := range batches {
		result[i] = &DepartmentBatchReadModel{
			BatchID:         b.BatchID.String(),
			BatchName:       b.BatchName,
			StartDate:       b.StartDate,
			EndDate:         b.EndDate,
			MaxParticipants: b.MaxParticipants,
			IsActive:        b.IsActive,
			CourseName:      b.CourseName,
			FacilitatorID:   b.FacilitatorID,
			FacilitatorName: b.FacilitatorName,
			EnrollmentCount: b.EnrollmentCount,
		}
	}
	return result, nil
}
