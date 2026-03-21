package list_department

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
)

type ListDepartmentQuery struct {
	Offset int
	Limit  int
}

type DepartmentReadModel struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	LeaderID    string `json:"leader_id"`
	IsActive    bool   `json:"is_active"`
	CreatedAt   int64  `json:"created_at"`
	UpdatedAt   int64  `json:"updated_at"`
}

type ListResult struct {
	Data   []*DepartmentReadModel `json:"data"`
	Total  int                   `json:"total"`
	Offset int                   `json:"offset"`
	Limit  int                   `json:"limit"`
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
	q, ok := query.(*ListDepartmentQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	departments, total, err := h.departmentReadRepo.List(ctx, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list departments")
		return nil, err
	}

	readModels := make([]*DepartmentReadModel, len(departments))
	for i, d := range departments {
		leaderID := ""
		if d.LeaderID != nil {
			leaderID = d.LeaderID.String()
		}
		readModels[i] = &DepartmentReadModel{
			ID:          d.ID.String(),
			Name:        d.Name,
			Description: d.Description,
			LeaderID:    leaderID,
			IsActive:    d.IsActive,
			CreatedAt:   d.CreatedAt.Unix(),
			UpdatedAt:   d.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
