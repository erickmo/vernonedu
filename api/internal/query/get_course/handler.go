package get_course

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/course"
)

type GetCourseQuery struct {
	CourseID uuid.UUID
}

type CourseReadModel struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	DepartmentID string    `json:"department_id"`
	OwnerID      string    `json:"owner_id"`
	IsActive     bool      `json:"is_active"`
	CreatedAt    int64     `json:"created_at"`
	UpdatedAt    int64     `json:"updated_at"`
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
	q, ok := query.(*GetCourseQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	c, err := h.courseReadRepo.GetByID(ctx, q.CourseID)
	if err != nil {
		log.Error().Err(err).Str("course_id", q.CourseID.String()).Msg("failed to get course")
		return nil, err
	}

	departmentID := ""
	if c.DepartmentID != nil {
		departmentID = c.DepartmentID.String()
	}

	ownerID := ""
	if c.OwnerID != nil {
		ownerID = c.OwnerID.String()
	}

	readModel := &CourseReadModel{
		ID:           c.ID,
		Name:         c.Name,
		Description:  c.Description,
		DepartmentID: departmentID,
		OwnerID:      ownerID,
		IsActive:     c.IsActive,
		CreatedAt:    c.CreatedAt.Unix(),
		UpdatedAt:    c.UpdatedAt.Unix(),
	}

	return readModel, nil
}
