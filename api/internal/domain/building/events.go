package building

import "github.com/google/uuid"

type BuildingCreatedEvent struct {
	EventType  string    `json:"event_type"`
	BuildingID uuid.UUID `json:"building_id"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *BuildingCreatedEvent) EventName() string      { return e.EventType }
func (e *BuildingCreatedEvent) EventData() interface{} { return e }

type BuildingUpdatedEvent struct {
	EventType  string    `json:"event_type"`
	BuildingID uuid.UUID `json:"building_id"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *BuildingUpdatedEvent) EventName() string      { return e.EventType }
func (e *BuildingUpdatedEvent) EventData() interface{} { return e }

type BuildingDeletedEvent struct {
	EventType  string    `json:"event_type"`
	BuildingID uuid.UUID `json:"building_id"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *BuildingDeletedEvent) EventName() string      { return e.EventType }
func (e *BuildingDeletedEvent) EventData() interface{} { return e }
