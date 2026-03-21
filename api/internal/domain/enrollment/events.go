package enrollment

import "github.com/google/uuid"

type EnrollmentCreated struct {
	EnrollmentID  uuid.UUID `json:"enrollment_id"`
	StudentID     uuid.UUID `json:"student_id"`
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *EnrollmentCreated) EventName() string    { return "EnrollmentCreated" }
func (e *EnrollmentCreated) EventData() interface{} { return e }

type EnrollmentStatusUpdated struct {
	EnrollmentID uuid.UUID `json:"enrollment_id"`
	Status       string    `json:"status"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *EnrollmentStatusUpdated) EventName() string    { return "EnrollmentStatusUpdated" }
func (e *EnrollmentStatusUpdated) EventData() interface{} { return e }
