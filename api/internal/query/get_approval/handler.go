package get_approval

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/approval"
	listapprovals "github.com/vernonedu/entrepreneurship-api/internal/query/list_approvals"
)

type Handler struct {
	readRepo approval.ReadRepository
}

func NewHandler(readRepo approval.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetApprovalQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	a, err := h.readRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Msg("failed to get approval")
		return nil, err
	}

	return listapprovals.ToReadModel(a), nil
}
