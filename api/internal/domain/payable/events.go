package payable

import "github.com/google/uuid"

type PayableCreatedEvent struct {
	EventType   string    `json:"event_type"`
	PayableID   uuid.UUID `json:"payable_id"`
	PayableType string    `json:"payable_type"`
	RecipientID uuid.UUID `json:"recipient_id"`
	Amount      int64     `json:"amount"`
	Timestamp   int64     `json:"timestamp"`
}

func (e *PayableCreatedEvent) EventName() string      { return e.EventType }
func (e *PayableCreatedEvent) EventData() interface{} { return e }

type PayableApprovedEvent struct {
	EventType string    `json:"event_type"`
	PayableID uuid.UUID `json:"payable_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *PayableApprovedEvent) EventName() string      { return e.EventType }
func (e *PayableApprovedEvent) EventData() interface{} { return e }

type PayablePaidEvent struct {
	EventType   string    `json:"event_type"`
	PayableID   uuid.UUID `json:"payable_id"`
	PayableType string    `json:"payable_type"`
	RecipientID uuid.UUID `json:"recipient_id"`
	Amount      int64     `json:"amount"`
	Timestamp   int64     `json:"timestamp"`
}

func (e *PayablePaidEvent) EventName() string      { return e.EventType }
func (e *PayablePaidEvent) EventData() interface{} { return e }

type PayableCancelledEvent struct {
	EventType string    `json:"event_type"`
	PayableID uuid.UUID `json:"payable_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *PayableCancelledEvent) EventName() string      { return e.EventType }
func (e *PayableCancelledEvent) EventData() interface{} { return e }
