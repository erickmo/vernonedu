package internship

import "github.com/google/uuid"

// InternshipConfigCreated dipublikasikan setiap kali konfigurasi magang baru berhasil dibuat.
type InternshipConfigCreated struct {
	ConfigID        uuid.UUID `json:"config_id"`
	CourseVersionID uuid.UUID `json:"course_version_id"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *InternshipConfigCreated) EventName() string {
	return "InternshipConfigCreated"
}

func (e *InternshipConfigCreated) EventData() interface{} {
	return e
}

// InternshipConfigUpdated dipublikasikan setiap kali konfigurasi magang diperbarui.
type InternshipConfigUpdated struct {
	ConfigID        uuid.UUID `json:"config_id"`
	CourseVersionID uuid.UUID `json:"course_version_id"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *InternshipConfigUpdated) EventName() string {
	return "InternshipConfigUpdated"
}

func (e *InternshipConfigUpdated) EventData() interface{} {
	return e
}
