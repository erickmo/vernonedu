package course

import "github.com/google/uuid"

type CourseCreated struct {
	CourseID  uuid.UUID `json:"course_id"`
	Name      string    `json:"name"`
	Timestamp int64     `json:"timestamp"`
}

func (e *CourseCreated) EventName() string {
	return "CourseCreated"
}

func (e *CourseCreated) EventData() interface{} {
	return e
}

type CourseUpdated struct {
	CourseID  uuid.UUID `json:"course_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *CourseUpdated) EventName() string {
	return "CourseUpdated"
}

func (e *CourseUpdated) EventData() interface{} {
	return e
}

type CourseDeleted struct {
	CourseID  uuid.UUID `json:"course_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *CourseDeleted) EventName() string {
	return "CourseDeleted"
}

func (e *CourseDeleted) EventData() interface{} {
	return e
}
