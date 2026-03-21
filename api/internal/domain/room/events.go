package room

import "github.com/google/uuid"

type RoomCreatedEvent struct {
	EventType string    `json:"event_type"`
	RoomID    uuid.UUID `json:"room_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *RoomCreatedEvent) EventName() string      { return e.EventType }
func (e *RoomCreatedEvent) EventData() interface{} { return e }

type RoomUpdatedEvent struct {
	EventType string    `json:"event_type"`
	RoomID    uuid.UUID `json:"room_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *RoomUpdatedEvent) EventName() string      { return e.EventType }
func (e *RoomUpdatedEvent) EventData() interface{} { return e }

type RoomDeletedEvent struct {
	EventType string    `json:"event_type"`
	RoomID    uuid.UUID `json:"room_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *RoomDeletedEvent) EventName() string      { return e.EventType }
func (e *RoomDeletedEvent) EventData() interface{} { return e }
