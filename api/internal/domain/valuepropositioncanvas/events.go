package valuepropositioncanvas

import "github.com/google/uuid"

type ValuePropositionCanvasCreated struct {
	CanvasID  uuid.UUID `json:"canvas_id"`
	Name      string    `json:"name"`
	Timestamp int64     `json:"timestamp"`
}

func (e *ValuePropositionCanvasCreated) EventName() string {
	return "ValuePropositionCanvasCreated"
}

func (e *ValuePropositionCanvasCreated) EventData() interface{} {
	return e
}

type ValuePropositionCanvasUpdated struct {
	CanvasID  uuid.UUID `json:"canvas_id"`
	Name      string    `json:"name"`
	Timestamp int64     `json:"timestamp"`
}

func (e *ValuePropositionCanvasUpdated) EventName() string {
	return "ValuePropositionCanvasUpdated"
}

func (e *ValuePropositionCanvasUpdated) EventData() interface{} {
	return e
}

type ValuePropositionCanvasDeleted struct {
	CanvasID  uuid.UUID `json:"canvas_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *ValuePropositionCanvasDeleted) EventName() string {
	return "ValuePropositionCanvasDeleted"
}

func (e *ValuePropositionCanvasDeleted) EventData() interface{} {
	return e
}
