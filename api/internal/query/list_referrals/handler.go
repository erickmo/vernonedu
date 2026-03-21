package list_referrals

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
)

type ListReferralsQuery struct {
	PartnerIDStr string
}

type ReferralReadModel struct {
	ID          string  `json:"id"`
	PartnerName string  `json:"partner_name"`
	Status      string  `json:"status"`
	Commission  float64 `json:"commission"`
	CreatedAt   int64   `json:"created_at"`
}

type ListReferralsResult struct {
	Data []*ReferralReadModel `json:"data"`
}

type Handler struct {
	readRepo marketing.ReadRepository
}

func NewHandler(readRepo marketing.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListReferralsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	partnerID, err := uuid.Parse(q.PartnerIDStr)
	if err != nil {
		return nil, ErrInvalidQuery
	}

	referrals, err := h.readRepo.ListReferrals(ctx, partnerID)
	if err != nil {
		log.Error().Err(err).Msg("failed to list referrals")
		return nil, err
	}

	readModels := make([]*ReferralReadModel, len(referrals))
	for i, r := range referrals {
		readModels[i] = &ReferralReadModel{
			ID:          r.ID.String(),
			PartnerName: r.PartnerName,
			Status:      r.Status,
			Commission:  r.Commission,
			CreatedAt:   r.CreatedAt.Unix(),
		}
	}

	return &ListReferralsResult{Data: readModels}, nil
}
