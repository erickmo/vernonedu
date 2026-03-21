package list_mous

import (
	"context"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
)

type ListMOUsQuery struct {
	PartnerIDStr string
}

type MOUReadModel struct {
	ID             string `json:"id"`
	PartnerID      string `json:"partner_id"`
	DocumentNumber string `json:"document_number"`
	Title          string `json:"title"`
	StartDate      string `json:"start_date"`
	EndDate        string `json:"end_date"`
	Status         string `json:"status"`
	DocumentURL    string `json:"document_url"`
	Notes          string `json:"notes"`
	CreatedAt      int64  `json:"created_at"`
}

type Handler struct {
	readRepo partner.ReadRepository
}

func NewHandler(readRepo partner.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListMOUsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	partnerID, err := uuid.Parse(q.PartnerIDStr)
	if err != nil {
		return nil, ErrInvalidPartnerID
	}
	mous, err := h.readRepo.ListMOUs(ctx, partnerID)
	if err != nil {
		return nil, err
	}
	models := make([]MOUReadModel, len(mous))
	for i, m := range mous {
		models[i] = MOUReadModel{
			ID:             m.ID.String(),
			PartnerID:      m.PartnerID.String(),
			DocumentNumber: m.DocumentNumber,
			Title:          m.Title,
			StartDate:      m.StartDate,
			EndDate:        m.EndDate,
			Status:         m.Status,
			DocumentURL:    m.DocumentURL,
			Notes:          m.Notes,
			CreatedAt:      m.CreatedAt.Unix(),
		}
	}
	return models, nil
}
