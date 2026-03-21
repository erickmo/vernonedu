package student

import "github.com/google/uuid"

type StudentCreated struct {
	StudentID uuid.UUID `json:"student_id"`
	Name      string    `json:"name"`
	Timestamp int64     `json:"timestamp"`
}

func (e *StudentCreated) EventName() string    { return "StudentCreated" }
func (e *StudentCreated) EventData() interface{} { return e }

type StudentUpdated struct {
	StudentID uuid.UUID `json:"student_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *StudentUpdated) EventName() string    { return "StudentUpdated" }
func (e *StudentUpdated) EventData() interface{} { return e }

type StudentDeleted struct {
	StudentID uuid.UUID `json:"student_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *StudentDeleted) EventName() string    { return "StudentDeleted" }
func (e *StudentDeleted) EventData() interface{} { return e }
