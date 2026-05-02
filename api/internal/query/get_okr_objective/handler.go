package get_okr_objective

import (
	"context"
	"fmt"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/okr"
)

type GetOkrObjectiveQuery struct {
	ID string
}

type KeyResultModel struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Progress int    `json:"progress"`
}

type OkrObjectiveModel struct {
	ID         string            `json:"id"`
	Title      string            `json:"title"`
	OwnerName  string            `json:"owner_name"`
	Period     string            `json:"period"`
	Level      string            `json:"level"`
	Status     string            `json:"status"`
	Progress   int               `json:"progress"`
	KeyResults []*KeyResultModel `json:"key_results"`
}

type Handler struct {
	readRepo okr.ReadRepository
}

func NewHandler(readRepo okr.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetOkrObjectiveQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	id, err := uuid.Parse(q.ID)
	if err != nil {
		return nil, fmt.Errorf("invalid objective id: %w", err)
	}
	obj, err := h.readRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	krModels := make([]*KeyResultModel, len(obj.KeyResults))
	for j, kr := range obj.KeyResults {
		krModels[j] = &KeyResultModel{
			ID:       kr.ID.String(),
			Title:    kr.Title,
			Progress: kr.Progress,
		}
	}
	return &OkrObjectiveModel{
		ID:         obj.ID.String(),
		Title:      obj.Title,
		OwnerName:  obj.OwnerName,
		Period:     obj.Period,
		Level:      obj.Level,
		Status:     obj.Status,
		Progress:   obj.Progress,
		KeyResults: krModels,
	}, nil
}
