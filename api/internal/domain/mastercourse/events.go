package mastercourse

import "github.com/google/uuid"

// MasterCourseCreated dipublikasikan setiap kali master course baru berhasil dibuat.
type MasterCourseCreated struct {
	MasterCourseID uuid.UUID `json:"master_course_id"`
	CourseCode     string    `json:"course_code"`
	CourseName     string    `json:"course_name"`
	Field          string    `json:"field"`
	Timestamp      int64     `json:"timestamp"`
}

func (e *MasterCourseCreated) EventName() string {
	return "MasterCourseCreated"
}

func (e *MasterCourseCreated) EventData() interface{} {
	return e
}

// MasterCourseUpdated dipublikasikan setiap kali data master course diperbarui.
type MasterCourseUpdated struct {
	MasterCourseID uuid.UUID `json:"master_course_id"`
	Timestamp      int64     `json:"timestamp"`
}

func (e *MasterCourseUpdated) EventName() string {
	return "MasterCourseUpdated"
}

func (e *MasterCourseUpdated) EventData() interface{} {
	return e
}

// MasterCourseArchived dipublikasikan ketika master course diarsipkan.
type MasterCourseArchived struct {
	MasterCourseID uuid.UUID `json:"master_course_id"`
	Timestamp      int64     `json:"timestamp"`
}

func (e *MasterCourseArchived) EventName() string {
	return "MasterCourseArchived"
}

func (e *MasterCourseArchived) EventData() interface{} {
	return e
}
