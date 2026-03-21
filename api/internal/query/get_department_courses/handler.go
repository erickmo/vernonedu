package getdepartmentcourses

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
)

type GetDepartmentCoursesQuery struct {
	DepartmentID string
}

type DepartmentCourseReadModel struct {
	CourseID    string `json:"course_id"`
	CourseName  string `json:"course_name"`
	Description string `json:"description"`
	IsActive    bool   `json:"is_active"`
	BatchCount  int    `json:"batch_count"`
}

type Handler struct {
	repo department.ReadRepository
}

func NewHandler(repo department.ReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, q interface{}) (interface{}, error) {
	query, ok := q.(*GetDepartmentCoursesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	deptID, err := uuid.Parse(query.DepartmentID)
	if err != nil {
		return nil, fmt.Errorf("invalid department id: %w", err)
	}

	courses, err := h.repo.GetCourses(ctx, deptID)
	if err != nil {
		return nil, fmt.Errorf("get department courses: %w", err)
	}

	result := make([]*DepartmentCourseReadModel, len(courses))
	for i, c := range courses {
		result[i] = &DepartmentCourseReadModel{
			CourseID:    c.CourseID,
			CourseName:  c.CourseName,
			Description: c.Description,
			IsActive:    c.IsActive,
			BatchCount:  c.BatchCount,
		}
	}
	return result, nil
}
