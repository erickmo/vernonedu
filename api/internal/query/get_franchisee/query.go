package get_franchisee

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
)

var ErrInvalidQuery = errors.New("invalid query type")

type GetFranchiseeQuery struct {
	ID uuid.UUID
}

type FranchiseeDetailModel struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	BranchName string `json:"branch_name"`
	Location   string `json:"location"`
	Contact    string `json:"contact"`
	Status     string `json:"status"`
	CreatedAt  string `json:"created_at"`
	UpdatedAt  string `json:"updated_at"`
}

type Handler struct {
	readRepo franchise.ReadRepository
}

func NewHandler(readRepo franchise.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetFranchiseeQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	f, err := h.readRepo.GetFranchiseeByID(ctx, q.ID)
	if err != nil {
		return nil, err
	}
	return &FranchiseeDetailModel{
		ID:         f.ID.String(),
		Name:       f.Name,
		BranchName: f.BranchName,
		Location:   f.Location,
		Contact:    f.Contact,
		Status:     f.Status,
		CreatedAt:  f.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:  f.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}, nil
}
