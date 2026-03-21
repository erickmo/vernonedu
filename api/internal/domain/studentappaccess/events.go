package studentappaccess

import "github.com/google/uuid"

type AppAccessGrantedEvent struct {
	EventType string    `json:"event_type"`
	StudentID uuid.UUID `json:"student_id"`
	AppName   string    `json:"app_name"`
	BatchID   uuid.UUID `json:"batch_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *AppAccessGrantedEvent) EventName() string      { return "AppAccessGranted" }
func (e *AppAccessGrantedEvent) EventData() interface{} { return e }

type AppAccessRevokedEvent struct {
	EventType string    `json:"event_type"`
	StudentID uuid.UUID `json:"student_id"`
	BatchID   uuid.UUID `json:"batch_id"`
	Reason    string    `json:"reason"`
	Timestamp int64     `json:"timestamp"`
}

func (e *AppAccessRevokedEvent) EventName() string      { return "AppAccessRevoked" }
func (e *AppAccessRevokedEvent) EventData() interface{} { return e }
