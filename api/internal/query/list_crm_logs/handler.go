package list_crm_logs

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type CrmLogReadModel struct {
	ID            uuid.UUID  `json:"id"`
	LeadID        uuid.UUID  `json:"lead_id"`
	ContactedByID uuid.UUID  `json:"contacted_by_id"`
	ContactMethod string     `json:"contact_method"`
	Response      string     `json:"response"`
	FollowUpDate  *time.Time `json:"follow_up_date"`
	CreatedAt     int64      `json:"created_at"`
}

type Handler struct {
	crmLogReadRepo lead.CrmLogReadRepository
}

func NewHandler(crmLogReadRepo lead.CrmLogReadRepository) *Handler {
	return &Handler{
		crmLogReadRepo: crmLogReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCrmLogsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	logs, err := h.crmLogReadRepo.ListCrmLogs(ctx, q.LeadID)
	if err != nil {
		log.Error().Err(err).Str("lead_id", q.LeadID.String()).Msg("failed to list crm logs")
		return nil, err
	}

	readModels := make([]*CrmLogReadModel, len(logs))
	for i, l := range logs {
		readModels[i] = &CrmLogReadModel{
			ID:            l.ID,
			LeadID:        l.LeadID,
			ContactedByID: l.ContactedByID,
			ContactMethod: l.ContactMethod,
			Response:      l.Response,
			FollowUpDate:  l.FollowUpDate,
			CreatedAt:     l.CreatedAt.Unix(),
		}
	}

	return readModels, nil
}
