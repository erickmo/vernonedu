package department

import "github.com/google/uuid"

type DepartmentCreated struct {
	DepartmentID uuid.UUID `json:"department_id"`
	Name         string    `json:"name"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *DepartmentCreated) EventName() string {
	return "DepartmentCreated"
}

func (e *DepartmentCreated) EventData() interface{} {
	return e
}

type DepartmentUpdated struct {
	DepartmentID uuid.UUID `json:"department_id"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *DepartmentUpdated) EventName() string {
	return "DepartmentUpdated"
}

func (e *DepartmentUpdated) EventData() interface{} {
	return e
}

type DepartmentDeleted struct {
	DepartmentID uuid.UUID `json:"department_id"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *DepartmentDeleted) EventName() string {
	return "DepartmentDeleted"
}

func (e *DepartmentDeleted) EventData() interface{} {
	return e
}
