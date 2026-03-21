package coursetype

import "github.com/google/uuid"

// CourseTypeActivated dipublikasikan ketika course type diaktifkan kembali.
type CourseTypeActivated struct {
	CourseTypeID   uuid.UUID `json:"course_type_id"`
	MasterCourseID uuid.UUID `json:"master_course_id"`
	TypeName       string    `json:"type_name"`
	Timestamp      int64     `json:"timestamp"`
}

func (e *CourseTypeActivated) EventName() string {
	return "CourseTypeActivated"
}

func (e *CourseTypeActivated) EventData() interface{} {
	return e
}

// CourseTypeDeactivated dipublikasikan ketika course type dinonaktifkan.
type CourseTypeDeactivated struct {
	CourseTypeID   uuid.UUID `json:"course_type_id"`
	MasterCourseID uuid.UUID `json:"master_course_id"`
	TypeName       string    `json:"type_name"`
	Timestamp      int64     `json:"timestamp"`
}

func (e *CourseTypeDeactivated) EventName() string {
	return "CourseTypeDeactivated"
}

func (e *CourseTypeDeactivated) EventData() interface{} {
	return e
}

// CourseTypeUpdated dipublikasikan setiap kali konfigurasi course type diperbarui.
type CourseTypeUpdated struct {
	CourseTypeID uuid.UUID `json:"course_type_id"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *CourseTypeUpdated) EventName() string {
	return "CourseTypeUpdated"
}

func (e *CourseTypeUpdated) EventData() interface{} {
	return e
}
