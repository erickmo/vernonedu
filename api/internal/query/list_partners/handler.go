package list_partners

import (
	"context"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
)

type ListPartnersQuery struct {
	Offset int
	Limit  int
	Status string
}

type PartnerReadModel struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	Industry      string `json:"industry"`
	GroupName     string `json:"group_name"`
	Status        string `json:"status"`
	PartnerSince  string `json:"partner_since,omitempty"`
	ContactEmail  string `json:"contact_email"`
	ContactPhone  string `json:"contact_phone"`
	ContactPerson string `json:"contact_person"`
	Website       string `json:"website"`
	Address       string `json:"address"`
}

type PartnerStatsModel struct {
	ActiveCount      int `json:"active_count"`
	ExpiringCount    int `json:"expiring_count"`
	NegotiatingCount int `json:"negotiating_count"`
	UncontactedCount int `json:"uncontacted_count"`
}

type ListResult struct {
	Data   []*PartnerReadModel `json:"data"`
	Stats  *PartnerStatsModel  `json:"stats"`
	Total  int                 `json:"total"`
	Offset int                 `json:"offset"`
	Limit  int                 `json:"limit"`
}

type Handler struct {
	readRepo partner.ReadRepository
}

func NewHandler(readRepo partner.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListPartnersQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	partners, total, err := h.readRepo.List(ctx, q.Offset, q.Limit, q.Status)
	if err != nil {
		return nil, err
	}
	stats, err := h.readRepo.Stats(ctx)
	if err != nil {
		return nil, err
	}

	models := make([]*PartnerReadModel, len(partners))
	for i, p := range partners {
		rm := &PartnerReadModel{
			ID:            p.ID.String(),
			Name:          p.Name,
			Industry:      p.Industry,
			GroupName:     p.GroupName,
			Status:        p.Status,
			ContactEmail:  p.ContactEmail,
			ContactPhone:  p.ContactPhone,
			ContactPerson: p.ContactPerson,
			Website:       p.Website,
			Address:       p.Address,
		}
		if p.PartnerSince != nil {
			rm.PartnerSince = p.PartnerSince.Format("2006-01-02")
		}
		models[i] = rm
	}

	return &ListResult{
		Data: models,
		Stats: &PartnerStatsModel{
			ActiveCount:      stats.ActiveCount,
			ExpiringCount:    stats.ExpiringCount,
			NegotiatingCount: stats.NegotiatingCount,
			UncontactedCount: stats.UncontactedCount,
		},
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
