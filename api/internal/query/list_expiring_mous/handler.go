package list_expiring_mous

import (
	"context"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
)

type ListExpiringMOUsQuery struct {
	WithinMonths int
}

type ExpiringMOUReadModel struct {
	ID             string `json:"id"`
	PartnerID      string `json:"partner_id"`
	PartnerName    string `json:"partner_name"`
	DocumentNumber string `json:"document_number"`
	Title          string `json:"title"`
	EndDate        string `json:"end_date"`
	Status         string `json:"status"`
}

type Handler struct {
	readRepo partner.ReadRepository
}

func NewHandler(readRepo partner.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListExpiringMOUsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	withinMonths := q.WithinMonths
	if withinMonths == 0 {
		withinMonths = 3
	}
	mous, err := h.readRepo.ListExpiringMOUs(ctx, withinMonths)
	if err != nil {
		return nil, err
	}
	models := make([]ExpiringMOUReadModel, len(mous))
	for i, m := range mous {
		models[i] = ExpiringMOUReadModel{
			ID:             m.ID.String(),
			PartnerID:      m.PartnerID.String(),
			PartnerName:    m.PartnerName,
			DocumentNumber: m.DocumentNumber,
			Title:          m.Title,
			EndDate:        m.EndDate,
			Status:         m.Status,
		}
	}
	return models, nil
}
