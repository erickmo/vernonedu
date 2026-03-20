package designthinking

import "github.com/google/uuid"

type DesignThinkingCreated struct {
	DesignThinkingID uuid.UUID `json:"design_thinking_id"`
	Name             string    `json:"name"`
	Timestamp        int64     `json:"timestamp"`
}

func (e *DesignThinkingCreated) EventName() string {
	return "DesignThinkingCreated"
}

func (e *DesignThinkingCreated) EventData() interface{} {
	return e
}

type DesignThinkingUpdated struct {
	DesignThinkingID uuid.UUID `json:"design_thinking_id"`
	Name             string    `json:"name"`
	Timestamp        int64     `json:"timestamp"`
}

func (e *DesignThinkingUpdated) EventName() string {
	return "DesignThinkingUpdated"
}

func (e *DesignThinkingUpdated) EventData() interface{} {
	return e
}

type DesignThinkingDeleted struct {
	DesignThinkingID uuid.UUID `json:"design_thinking_id"`
	Timestamp        int64     `json:"timestamp"`
}

func (e *DesignThinkingDeleted) EventName() string {
	return "DesignThinkingDeleted"
}

func (e *DesignThinkingDeleted) EventData() interface{} {
	return e
}
