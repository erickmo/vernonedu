package courseversion

import "github.com/google/uuid"

// VersionCreated dipublikasikan setiap kali versi kursus baru berhasil dibuat (status: draft).
type VersionCreated struct {
	VersionID     uuid.UUID `json:"version_id"`
	CourseTypeID  uuid.UUID `json:"course_type_id"`
	VersionNumber string    `json:"version_number"`
	ChangeType    string    `json:"change_type"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *VersionCreated) EventName() string {
	return "VersionCreated"
}

func (e *VersionCreated) EventData() interface{} {
	return e
}

// VersionPromotedToReview dipublikasikan ketika versi dipromosikan dari draft ke review.
type VersionPromotedToReview struct {
	VersionID    uuid.UUID `json:"version_id"`
	CourseTypeID uuid.UUID `json:"course_type_id"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *VersionPromotedToReview) EventName() string {
	return "VersionPromotedToReview"
}

func (e *VersionPromotedToReview) EventData() interface{} {
	return e
}

// VersionApproved dipublikasikan ketika versi berhasil disetujui (review → approved).
type VersionApproved struct {
	VersionID    uuid.UUID `json:"version_id"`
	CourseTypeID uuid.UUID `json:"course_type_id"`
	ApprovedBy   uuid.UUID `json:"approved_by"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *VersionApproved) EventName() string {
	return "VersionApproved"
}

func (e *VersionApproved) EventData() interface{} {
	return e
}

// VersionArchived dipublikasikan ketika versi diarsipkan (approved → archived).
type VersionArchived struct {
	VersionID    uuid.UUID `json:"version_id"`
	CourseTypeID uuid.UUID `json:"course_type_id"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *VersionArchived) EventName() string {
	return "VersionArchived"
}

func (e *VersionArchived) EventData() interface{} {
	return e
}
