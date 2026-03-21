package list_referral_partners

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
)

type ListReferralPartnersQuery struct {
	Offset   int
	Limit    int
	IsActive *bool
}

type ReferralPartnerReadModel struct {
	ID               string  `json:"id"`
	Name             string  `json:"name"`
	ContactEmail     string  `json:"contact_email"`
	ReferralCode     string  `json:"referral_code"`
	CommissionType   string  `json:"commission_type"`
	CommissionValue  float64 `json:"commission_value"`
	IsActive         bool    `json:"is_active"`
	TotalReferrals   int     `json:"total_referrals"`
	TotalEnrolled    int     `json:"total_enrolled"`
	TotalCommission  float64 `json:"total_commission"`
	PendingCommission float64 `json:"pending_commission"`
}

type ListReferralPartnersResult struct {
	Data   []*ReferralPartnerReadModel `json:"data"`
	Total  int                         `json:"total"`
	Offset int                         `json:"offset"`
	Limit  int                         `json:"limit"`
}

type Handler struct {
	readRepo marketing.ReadRepository
}

func NewHandler(readRepo marketing.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListReferralPartnersQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	partners, total, err := h.readRepo.ListReferralPartners(ctx, q.Offset, q.Limit, q.IsActive)
	if err != nil {
		log.Error().Err(err).Msg("failed to list referral partners")
		return nil, err
	}

	readModels := make([]*ReferralPartnerReadModel, len(partners))
	for i, rp := range partners {
		readModels[i] = &ReferralPartnerReadModel{
			ID:               rp.ID.String(),
			Name:             rp.Name,
			ContactEmail:     rp.ContactEmail,
			ReferralCode:     rp.ReferralCode,
			CommissionType:   rp.CommissionType,
			CommissionValue:  rp.CommissionValue,
			IsActive:         rp.IsActive,
			TotalReferrals:   rp.TotalReferrals,
			TotalEnrolled:    rp.TotalEnrolled,
			TotalCommission:  rp.TotalCommission,
			PendingCommission: rp.PendingCommission,
		}
	}

	return &ListReferralPartnersResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
