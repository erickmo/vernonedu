package coursemodule

import "github.com/google/uuid"

// ModuleCreated dipublikasikan setiap kali modul kursus baru berhasil dibuat.
type ModuleCreated struct {
	ModuleID        uuid.UUID `json:"module_id"`
	CourseVersionID uuid.UUID `json:"course_version_id"`
	ModuleCode      string    `json:"module_code"`
	ModuleTitle     string    `json:"module_title"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *ModuleCreated) EventName() string {
	return "ModuleCreated"
}

func (e *ModuleCreated) EventData() interface{} {
	return e
}

// ModuleUpdated dipublikasikan setiap kali data modul kursus diperbarui.
type ModuleUpdated struct {
	ModuleID        uuid.UUID `json:"module_id"`
	CourseVersionID uuid.UUID `json:"course_version_id"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *ModuleUpdated) EventName() string {
	return "ModuleUpdated"
}

func (e *ModuleUpdated) EventData() interface{} {
	return e
}

// ModuleDeleted dipublikasikan ketika modul kursus dihapus.
type ModuleDeleted struct {
	ModuleID        uuid.UUID `json:"module_id"`
	CourseVersionID uuid.UUID `json:"course_version_id"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *ModuleDeleted) EventName() string {
	return "ModuleDeleted"
}

func (e *ModuleDeleted) EventData() interface{} {
	return e
}
