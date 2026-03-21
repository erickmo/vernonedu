package lead

import "github.com/google/uuid"

type LeadConvertedEvent struct {
	EventType string    `json:"event_type"`
	LeadID    uuid.UUID `json:"lead_id"`
	StudentID uuid.UUID `json:"student_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *LeadConvertedEvent) EventName() string {
	return "LeadConverted"
}

func (e *LeadConvertedEvent) EventData() interface{} {
	return e
}

type LeadCreatedEvent struct {
	EventType string    `json:"event_type"`
	LeadID    uuid.UUID `json:"lead_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *LeadCreatedEvent) EventName() string {
	return "LeadCreated"
}

func (e *LeadCreatedEvent) EventData() interface{} {
	return e
}

type LeadUpdatedEvent struct {
	EventType string    `json:"event_type"`
	LeadID    uuid.UUID `json:"lead_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *LeadUpdatedEvent) EventName() string {
	return "LeadUpdated"
}

func (e *LeadUpdatedEvent) EventData() interface{} {
	return e
}

type LeadDeletedEvent struct {
	EventType string    `json:"event_type"`
	LeadID    uuid.UUID `json:"lead_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *LeadDeletedEvent) EventName() string {
	return "LeadDeleted"
}

func (e *LeadDeletedEvent) EventData() interface{} {
	return e
}
