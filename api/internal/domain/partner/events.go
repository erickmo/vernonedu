package partner

import (
	"time"

	"github.com/google/uuid"
)

// MouExpiringEvent is published when an MOU is approaching its expiry date.
type MouExpiringEvent struct {
	MOUID     uuid.UUID `json:"mou_id"`
	PartnerID uuid.UUID `json:"partner_id"`
	EndDate   string    `json:"end_date"`
	Timestamp int64     `json:"timestamp"`
}

func NewMouExpiringEvent(mouID, partnerID uuid.UUID, endDate string) *MouExpiringEvent {
	return &MouExpiringEvent{
		MOUID:     mouID,
		PartnerID: partnerID,
		EndDate:   endDate,
		Timestamp: time.Now().Unix(),
	}
}

func (e *MouExpiringEvent) EventName() string      { return "MouExpiring" }
func (e *MouExpiringEvent) EventData() interface{} { return e }
