package get_marketing_stats

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
)

type GetMarketingStatsQuery struct{}

type MarketingStatsReadModel struct {
	TotalLeads               int     `json:"total_leads"`
	LeadsThisMonth           int     `json:"leads_this_month"`
	LeadsPrevMonth           int     `json:"leads_prev_month"`
	LeadToStudentPct         float64 `json:"lead_to_student_pct"`
	ScheduledPosts           int     `json:"scheduled_posts"`
	PostedThisMonth          int     `json:"posted_this_month"`
	ActiveReferralPartners   int     `json:"active_referral_partners"`
	ReferralRevenueThisMonth float64 `json:"referral_revenue_this_month"`
}

type Handler struct {
	readRepo marketing.ReadRepository
}

func NewHandler(readRepo marketing.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	_, ok := query.(*GetMarketingStatsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	stats, err := h.readRepo.GetStats(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to get marketing stats")
		return nil, err
	}

	return &MarketingStatsReadModel{
		TotalLeads:               stats.TotalLeads,
		LeadsThisMonth:           stats.LeadsThisMonth,
		LeadsPrevMonth:           stats.LeadsPrevMonth,
		LeadToStudentPct:         stats.LeadToStudentPct,
		ScheduledPosts:           stats.ScheduledPosts,
		PostedThisMonth:          stats.PostedThisMonth,
		ActiveReferralPartners:   stats.ActiveReferralPartners,
		ReferralRevenueThisMonth: stats.ReferralRevenueThisMonth,
	}, nil
}
