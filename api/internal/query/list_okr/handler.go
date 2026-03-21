package list_okr

import (
	"context"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/okr"
)

type ListOkrQuery struct {
	Level string
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
	q, ok := query.(*ListOkrQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	objectives, err := h.readRepo.List(ctx, q.Level)
	if err != nil {
		return nil, err
	}

	models := make([]*OkrObjectiveModel, len(objectives))
	for i, obj := range objectives {
		krModels := make([]*KeyResultModel, len(obj.KeyResults))
		for j, kr := range obj.KeyResults {
			krModels[j] = &KeyResultModel{
				ID:       kr.ID.String(),
				Title:    kr.Title,
				Progress: kr.Progress,
			}
		}
		models[i] = &OkrObjectiveModel{
			ID:         obj.ID.String(),
			Title:      obj.Title,
			OwnerName:  obj.OwnerName,
			Period:     obj.Period,
			Level:      obj.Level,
			Status:     obj.Status,
			Progress:   obj.Progress,
			KeyResults: krModels,
		}
	}
	return map[string]interface{}{"data": models}, nil
}
