package get_department

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
)

type GetDepartmentQuery struct {
	DepartmentID uuid.UUID
}

type DepartmentReadModel struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	LeaderID    string    `json:"leader_id"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   int64     `json:"created_at"`
	UpdatedAt   int64     `json:"updated_at"`
}

type Handler struct {
	departmentReadRepo department.ReadRepository
}

func NewHandler(departmentReadRepo department.ReadRepository) *Handler {
	return &Handler{
		departmentReadRepo: departmentReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetDepartmentQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	d, err := h.departmentReadRepo.GetByID(ctx, q.DepartmentID)
	if err != nil {
		log.Error().Err(err).Str("department_id", q.DepartmentID.String()).Msg("failed to get department")
		return nil, err
	}

	leaderID := ""
	if d.LeaderID != nil {
		leaderID = d.LeaderID.String()
	}

	readModel := &DepartmentReadModel{
		ID:          d.ID,
		Name:        d.Name,
		Description: d.Description,
		LeaderID:    leaderID,
		IsActive:    d.IsActive,
		CreatedAt:   d.CreatedAt.Unix(),
		UpdatedAt:   d.UpdatedAt.Unix(),
	}

	return readModel, nil
}
