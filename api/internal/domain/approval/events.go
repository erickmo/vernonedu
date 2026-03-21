package approval

import "github.com/google/uuid"

type ApprovalCreatedEvent struct {
	EventType  string    `json:"event_type"`
	ApprovalID uuid.UUID `json:"approval_id"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *ApprovalCreatedEvent) EventName() string      { return "ApprovalCreated" }
func (e *ApprovalCreatedEvent) EventData() interface{} { return e }

type ApprovalStepApprovedEvent struct {
	EventType   string    `json:"event_type"`
	ApprovalID  uuid.UUID `json:"approval_id"`
	StepNumber  int       `json:"step_number"`
	IsCompleted bool      `json:"is_completed"`
	Timestamp   int64     `json:"timestamp"`
}

func (e *ApprovalStepApprovedEvent) EventName() string      { return "ApprovalStepApproved" }
func (e *ApprovalStepApprovedEvent) EventData() interface{} { return e }

type ApprovalRejectedEvent struct {
	EventType  string    `json:"event_type"`
	ApprovalID uuid.UUID `json:"approval_id"`
	StepNumber int       `json:"step_number"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *ApprovalRejectedEvent) EventName() string      { return "ApprovalRejected" }
func (e *ApprovalRejectedEvent) EventData() interface{} { return e }

type ApprovalCancelledEvent struct {
	EventType  string    `json:"event_type"`
	ApprovalID uuid.UUID `json:"approval_id"`
	Timestamp  int64     `json:"timestamp"`
}

func (e *ApprovalCancelledEvent) EventName() string      { return "ApprovalCancelled" }
func (e *ApprovalCancelledEvent) EventData() interface{} { return e }
