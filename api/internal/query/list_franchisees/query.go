package list_franchisees

import (
	"context"
	"errors"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
)

var ErrInvalidQuery = errors.New("invalid query type")

type ListFranchiseesQuery struct {
	Offset int
	Limit  int
	Status string
	Search string
}

type FranchiseeReadModel struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	BranchName string `json:"branch_name"`
	Location   string `json:"location"`
	Contact    string `json:"contact"`
	Status     string `json:"status"`
	CreatedAt  string `json:"created_at"`
}

type ListResult struct {
	Data   []*FranchiseeReadModel `json:"data"`
	Total  int                    `json:"total"`
	Offset int                    `json:"offset"`
	Limit  int                    `json:"limit"`
}

type Handler struct {
	readRepo franchise.ReadRepository
}

func NewHandler(readRepo franchise.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListFranchiseesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	franchisees, total, err := h.readRepo.ListFranchisees(ctx, q.Offset, q.Limit, q.Status, q.Search)
	if err != nil {
		return nil, err
	}
	models := make([]*FranchiseeReadModel, len(franchisees))
	for i, f := range franchisees {
		models[i] = &FranchiseeReadModel{
			ID:         f.ID.String(),
			Name:       f.Name,
			BranchName: f.BranchName,
			Location:   f.Location,
			Contact:    f.Contact,
			Status:     f.Status,
			CreatedAt:  f.CreatedAt.Format("2006-01-02T15:04:05Z"),
		}
	}
	return &ListResult{Data: models, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
