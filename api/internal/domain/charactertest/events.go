package charactertest

import "github.com/google/uuid"

// CharacterTestConfigCreated dipublikasikan setiap kali konfigurasi tes karakter baru berhasil dibuat.
type CharacterTestConfigCreated struct {
	ConfigID        uuid.UUID `json:"config_id"`
	CourseVersionID uuid.UUID `json:"course_version_id"`
	TestType        string    `json:"test_type"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *CharacterTestConfigCreated) EventName() string {
	return "CharacterTestConfigCreated"
}

func (e *CharacterTestConfigCreated) EventData() interface{} {
	return e
}

// CharacterTestConfigUpdated dipublikasikan setiap kali konfigurasi tes karakter diperbarui.
type CharacterTestConfigUpdated struct {
	ConfigID        uuid.UUID `json:"config_id"`
	CourseVersionID uuid.UUID `json:"course_version_id"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *CharacterTestConfigUpdated) EventName() string {
	return "CharacterTestConfigUpdated"
}

func (e *CharacterTestConfigUpdated) EventData() interface{} {
	return e
}
