package list_course

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/course"
)

type ListCourseQuery struct {
	Offset int
	Limit  int
}

type CourseReadModel struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Description  string `json:"description"`
	DepartmentID string `json:"department_id"`
	OwnerID      string `json:"owner_id"`
	IsActive     bool   `json:"is_active"`
	CreatedAt    int64  `json:"created_at"`
	UpdatedAt    int64  `json:"updated_at"`
}

type ListResult struct {
	Data   []*CourseReadModel `json:"data"`
	Total  int                `json:"total"`
	Offset int                `json:"offset"`
	Limit  int                `json:"limit"`
}

type Handler struct {
	courseReadRepo course.ReadRepository
}

func NewHandler(courseReadRepo course.ReadRepository) *Handler {
	return &Handler{
		courseReadRepo: courseReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCourseQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	courses, total, err := h.courseReadRepo.List(ctx, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list courses")
		return nil, err
	}

	readModels := make([]*CourseReadModel, len(courses))
	for i, c := range courses {
		departmentID := ""
		if c.DepartmentID != nil {
			departmentID = c.DepartmentID.String()
		}
		ownerID := ""
		if c.OwnerID != nil {
			ownerID = c.OwnerID.String()
		}
		readModels[i] = &CourseReadModel{
			ID:           c.ID.String(),
			Name:         c.Name,
			Description:  c.Description,
			DepartmentID: departmentID,
			OwnerID:      ownerID,
			IsActive:     c.IsActive,
			CreatedAt:    c.CreatedAt.Unix(),
			UpdatedAt:    c.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
