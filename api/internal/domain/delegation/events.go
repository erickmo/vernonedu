package delegation

import "github.com/google/uuid"

// DelegationCreatedEvent is published after a delegation is successfully created.
// The assignee should be notified.
type DelegationCreatedEvent struct {
	DelegationID    uuid.UUID `json:"delegation_id"`
	Title           string    `json:"title"`
	RequestedByID   uuid.UUID `json:"requested_by_id"`
	RequestedByName string    `json:"requested_by_name"`
	AssignedToID    uuid.UUID `json:"assigned_to_id"`
	AssignedToName  string    `json:"assigned_to_name"`
	Priority        string    `json:"priority"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *DelegationCreatedEvent) EventName() string      { return "DelegationCreated" }
func (e *DelegationCreatedEvent) EventData() interface{} { return e }

// DelegationCompletedEvent is published after a delegation is marked completed.
// The requester should be notified.
type DelegationCompletedEvent struct {
	DelegationID   uuid.UUID `json:"delegation_id"`
	Title          string    `json:"title"`
	RequestedByID  uuid.UUID `json:"requested_by_id"`
	AssignedToID   uuid.UUID `json:"assigned_to_id"`
	AssignedToName string    `json:"assigned_to_name"`
	Timestamp      int64     `json:"timestamp"`
}

func (e *DelegationCompletedEvent) EventName() string      { return "DelegationCompleted" }
func (e *DelegationCompletedEvent) EventData() interface{} { return e }
