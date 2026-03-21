package talentpool

import "github.com/google/uuid"

// TalentPoolEntryCreated dipublikasikan setiap kali peserta baru berhasil masuk ke talent pool.
type TalentPoolEntryCreated struct {
	TalentPoolID    uuid.UUID `json:"talent_pool_id"`
	ParticipantID   uuid.UUID `json:"participant_id"`
	MasterCourseID  uuid.UUID `json:"master_course_id"`
	CourseVersionID uuid.UUID `json:"course_version_id"`
	Timestamp       int64     `json:"timestamp"`
}

func (e *TalentPoolEntryCreated) EventName() string {
	return "TalentPoolEntryCreated"
}

func (e *TalentPoolEntryCreated) EventData() interface{} {
	return e
}

// TalentPoolStatusUpdated dipublikasikan ketika status peserta talent pool berubah
// (misalnya dari active ke inactive).
type TalentPoolStatusUpdated struct {
	TalentPoolID uuid.UUID `json:"talent_pool_id"`
	NewStatus    string    `json:"new_status"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *TalentPoolStatusUpdated) EventName() string {
	return "TalentPoolStatusUpdated"
}

func (e *TalentPoolStatusUpdated) EventData() interface{} {
	return e
}

// TalentPoolPlacementAdded dipublikasikan setiap kali peserta talent pool berhasil
// ditempatkan ke perusahaan (status berubah menjadi "placed").
type TalentPoolPlacementAdded struct {
	TalentPoolID  uuid.UUID `json:"talent_pool_id"`
	ParticipantID uuid.UUID `json:"participant_id"`
	CompanyName   string    `json:"company_name"`
	Position      string    `json:"position"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *TalentPoolPlacementAdded) EventName() string {
	return "TalentPoolPlacementAdded"
}

func (e *TalentPoolPlacementAdded) EventData() interface{} {
	return e
}
