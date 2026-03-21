package coursebatch

import "github.com/google/uuid"

type CourseBatchCreated struct {
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	Name          string    `json:"name"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *CourseBatchCreated) EventName() string {
	return "CourseBatchCreated"
}

func (e *CourseBatchCreated) EventData() interface{} {
	return e
}

type CourseBatchUpdated struct {
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *CourseBatchUpdated) EventName() string {
	return "CourseBatchUpdated"
}

func (e *CourseBatchUpdated) EventData() interface{} {
	return e
}

type CourseBatchDeleted struct {
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *CourseBatchDeleted) EventName() string {
	return "CourseBatchDeleted"
}

func (e *CourseBatchDeleted) EventData() interface{} {
	return e
}
