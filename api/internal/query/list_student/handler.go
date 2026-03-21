package list_student

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
)

type ListStudentQuery struct {
	Offset int
	Limit  int
}

type StudentReadModel struct {
	ID                   uuid.UUID `json:"id"`
	Name                 string    `json:"name"`
	Email                string    `json:"email"`
	Phone                string    `json:"phone"`
	DepartmentID         string    `json:"department_id"`
	JoinedAt             string    `json:"joined_at"`
	IsActive             bool      `json:"is_active"`
	ActiveBatchCount     int       `json:"active_batch_count"`
	CompletedCourseCount int       `json:"completed_course_count"`
	CreatedAt            int64     `json:"created_at"`
	UpdatedAt            int64     `json:"updated_at"`
}

type ListResult struct {
	Data   []*StudentReadModel `json:"data"`
	Total  int                 `json:"total"`
	Offset int                 `json:"offset"`
	Limit  int                 `json:"limit"`
}

type Handler struct {
	readRepo student.ReadRepository
}

func NewHandler(readRepo student.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListStudentQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	students, total, err := h.readRepo.ListWithCounts(ctx, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list students")
		return nil, err
	}

	readModels := make([]*StudentReadModel, len(students))
	for i, s := range students {
		deptID := ""
		if s.DepartmentID != nil {
			deptID = s.DepartmentID.String()
		}
		readModels[i] = &StudentReadModel{
			ID:                   s.ID,
			Name:                 s.Name,
			Email:                s.Email,
			Phone:                s.Phone,
			DepartmentID:         deptID,
			JoinedAt:             s.JoinedAt.Format("2006-01-02T15:04:05Z07:00"),
			IsActive:             s.IsActive,
			ActiveBatchCount:     s.ActiveBatchCount,
			CompletedCourseCount: s.CompletedCourseCount,
			CreatedAt:            s.CreatedAt.Unix(),
			UpdatedAt:            s.UpdatedAt.Unix(),
		}
	}

	return &ListResult{Data: readModels, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
