package get_partner

import (
	"context"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
)

type GetPartnerQuery struct {
	ID string
}

type MOUModel struct {
	ID             string `json:"id"`
	DocumentNumber string `json:"document_number"`
	Title          string `json:"title"`
	StartDate      string `json:"start_date"`
	EndDate        string `json:"end_date"`
	Status         string `json:"status"`
	DocumentURL    string `json:"document_url"`
	Notes          string `json:"notes"`
}

type LogModel struct {
	ID         string `json:"id"`
	LogDate    string `json:"log_date"`
	EntityName string `json:"entity_name"`
	EntityType string `json:"entity_type"`
	Status     string `json:"status"`
	Notes      string `json:"notes"`
}

type PartnerDetailModel struct {
	ID            string      `json:"id"`
	Name          string      `json:"name"`
	Industry      string      `json:"industry"`
	Address       string      `json:"address"`
	ContactPerson string      `json:"contact_person"`
	ContactEmail  string      `json:"contact_email"`
	ContactPhone  string      `json:"contact_phone"`
	Website       string      `json:"website"`
	LogoURL       string      `json:"logo_url"`
	GroupName     string      `json:"group_name"`
	Status        string      `json:"status"`
	PartnerSince  string      `json:"partner_since,omitempty"`
	Notes         string      `json:"notes"`
	MOUs          []*MOUModel `json:"mous"`
	Logs          []*LogModel `json:"logs"`
}

type Handler struct {
	readRepo partner.ReadRepository
}

func NewHandler(readRepo partner.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetPartnerQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	id, err := uuid.Parse(q.ID)
	if err != nil {
		return nil, ErrInvalidQuery
	}

	p, err := h.readRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	mous, err := h.readRepo.ListMOUs(ctx, id)
	if err != nil {
		return nil, err
	}

	logs, err := h.readRepo.ListLogs(ctx, id)
	if err != nil {
		return nil, err
	}

	mouModels := make([]*MOUModel, len(mous))
	for i, m := range mous {
		mouModels[i] = &MOUModel{
			ID:             m.ID.String(),
			DocumentNumber: m.DocumentNumber,
			Title:          m.Title,
			StartDate:      m.StartDate,
			EndDate:        m.EndDate,
			Status:         m.Status,
			DocumentURL:    m.DocumentURL,
			Notes:          m.Notes,
		}
	}

	logModels := make([]*LogModel, len(logs))
	for i, l := range logs {
		logModels[i] = &LogModel{
			ID:         l.ID.String(),
			LogDate:    l.LogDate,
			EntityName: l.EntityName,
			EntityType: l.EntityType,
			Status:     l.Status,
			Notes:      l.Notes,
		}
	}

	detail := &PartnerDetailModel{
		ID:            p.ID.String(),
		Name:          p.Name,
		Industry:      p.Industry,
		Address:       p.Address,
		ContactPerson: p.ContactPerson,
		ContactEmail:  p.ContactEmail,
		ContactPhone:  p.ContactPhone,
		Website:       p.Website,
		LogoURL:       p.LogoURL,
		GroupName:     p.GroupName,
		Status:        p.Status,
		Notes:         p.Notes,
		MOUs:          mouModels,
		Logs:          logModels,
	}
	if p.PartnerSince != nil {
		detail.PartnerSince = p.PartnerSince.Format("2006-01-02")
	}

	return detail, nil
}
