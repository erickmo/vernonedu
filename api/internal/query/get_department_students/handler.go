package getdepartmentstudents

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
)

type GetDepartmentStudentsQuery struct {
	DepartmentID string
	// Status: "active" | "alumni" | "" (all)
	Status string
}

type DepartmentStudentReadModel struct {
	StudentID          string `json:"student_id"`
	StudentName        string `json:"student_name"`
	Email              string `json:"email"`
	Phone              string `json:"phone"`
	IsActive           bool   `json:"is_active"`
	JoinedAt           int64  `json:"joined_at"`
	EnrolledBatchCount int    `json:"enrolled_batch_count"`
}

type Handler struct {
	repo department.ReadRepository
}

func NewHandler(repo department.ReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, q interface{}) (interface{}, error) {
	query, ok := q.(*GetDepartmentStudentsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	deptID, err := uuid.Parse(query.DepartmentID)
	if err != nil {
		return nil, fmt.Errorf("invalid department id: %w", err)
	}

	students, err := h.repo.GetStudents(ctx, deptID, query.Status)
	if err != nil {
		return nil, fmt.Errorf("get department students: %w", err)
	}

	result := make([]*DepartmentStudentReadModel, len(students))
	for i, s := range students {
		result[i] = &DepartmentStudentReadModel{
			StudentID:          s.StudentID.String(),
			StudentName:        s.StudentName,
			Email:              s.Email,
			Phone:              s.Phone,
			IsActive:           s.IsActive,
			JoinedAt:           s.JoinedAt.Unix(),
			EnrolledBatchCount: s.EnrolledBatchCount,
		}
	}
	return result, nil
}
