package eventhandler

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
)

// MouExpiringPayload mirrors MouExpiringEvent fields from the partner domain.
type MouExpiringPayload struct {
	MOUID     uuid.UUID `json:"mou_id"`
	PartnerID uuid.UUID `json:"partner_id"`
	EndDate   string    `json:"end_date"`
	Timestamp int64     `json:"timestamp"`
}

// MouExpiryHandler handles MouExpiringEvent and creates in-app notifications
// for the accounting_leader and director roles.
type MouExpiryHandler struct {
	notifWriteRepo notification.WriteRepository
	// recipientIDs holds the set of user IDs to notify (accounting_leader, director, etc.).
	// In production these would be resolved from the user repository; for now callers
	// inject them directly so the handler stays repository-agnostic.
	recipientIDs []uuid.UUID
}

// NewMouExpiryHandler creates a handler. Pass the user IDs that should receive
// the expiry notification (typically accounting_leader and director).
func NewMouExpiryHandler(notifWriteRepo notification.WriteRepository, recipientIDs []uuid.UUID) *MouExpiryHandler {
	return &MouExpiryHandler{
		notifWriteRepo: notifWriteRepo,
		recipientIDs:   recipientIDs,
	}
}

// OnMouExpiring is the subscriber callback for the "MouExpiring" event.
func (h *MouExpiryHandler) OnMouExpiring(ctx context.Context, data []byte) error {
	var payload MouExpiringPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("MouExpiring: failed to unmarshal payload")
		return err
	}

	title := "MOU Akan Segera Berakhir"
	body := fmt.Sprintf(
		"MOU dengan partner ID %s akan berakhir pada %s. Mohon segera ditinjau dan diperbarui.",
		payload.PartnerID.String(), payload.EndDate,
	)
	meta := map[string]interface{}{
		"mou_id":     payload.MOUID.String(),
		"partner_id": payload.PartnerID.String(),
		"end_date":   payload.EndDate,
	}

	for _, recipientID := range h.recipientIDs {
		n := notification.NewNotification(
			recipientID,
			notification.TypeSystem,
			title,
			body,
			notification.ChannelInApp,
			meta,
		)
		if err := h.notifWriteRepo.Save(ctx, n); err != nil {
			log.Error().Err(err).
				Str("mou_id", payload.MOUID.String()).
				Str("recipient_id", recipientID.String()).
				Msg("MouExpiring: failed to save notification")
			return err
		}
		log.Info().
			Str("mou_id", payload.MOUID.String()).
			Str("recipient_id", recipientID.String()).
			Msg("MouExpiring: notification sent")
	}
	return nil
}
