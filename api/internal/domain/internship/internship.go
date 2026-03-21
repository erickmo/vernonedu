package internship

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Sentinel error untuk validasi dan operasi pada InternshipConfig
var (
	ErrInvalidPartnerName   = errors.New("nama perusahaan mitra tidak boleh kosong")
	ErrInvalidPositionTitle = errors.New("judul posisi magang tidak boleh kosong")
	ErrInvalidDuration      = errors.New("durasi magang harus lebih dari nol minggu")
	ErrConfigNotFound       = errors.New("konfigurasi magang tidak ditemukan")
)

// InternshipConfig mendefinisikan konfigurasi program magang untuk sebuah CourseVersion.
// Berlaku khusus untuk tipe kursus "program_karir".
// Satu CourseVersion hanya memiliki satu InternshipConfig.
type InternshipConfig struct {
	ID                 uuid.UUID
	CourseVersionID    uuid.UUID
	PartnerCompanyName string
	PartnerCompanyID   *uuid.UUID // FK ke entitas Company jika sudah terdaftar di sistem
	PositionTitle      string
	DurationWeeks      int
	SupervisorName     string
	SupervisorContact  string
	MOUDocumentURL     string
	IsCompanyProvided  bool // true = lembaga mencarikan perusahaan, false = peserta mencari sendiri
	CreatedAt          time.Time
	UpdatedAt          time.Time
}

// NewInternshipConfig membuat entitas InternshipConfig baru dengan validasi awal.
func NewInternshipConfig(courseVersionID uuid.UUID, partnerCompanyName string, partnerCompanyID *uuid.UUID, positionTitle string, durationWeeks int, supervisorName, supervisorContact, mouDocumentURL string, isCompanyProvided bool) (*InternshipConfig, error) {
	if partnerCompanyName == "" {
		return nil, ErrInvalidPartnerName
	}
	if positionTitle == "" {
		return nil, ErrInvalidPositionTitle
	}
	if durationWeeks <= 0 {
		return nil, ErrInvalidDuration
	}
	return &InternshipConfig{
		ID:                 uuid.New(),
		CourseVersionID:    courseVersionID,
		PartnerCompanyName: partnerCompanyName,
		PartnerCompanyID:   partnerCompanyID,
		PositionTitle:      positionTitle,
		DurationWeeks:      durationWeeks,
		SupervisorName:     supervisorName,
		SupervisorContact:  supervisorContact,
		MOUDocumentURL:     mouDocumentURL,
		IsCompanyProvided:  isCompanyProvided,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}, nil
}

// Update memperbarui data konfigurasi magang.
func (ic *InternshipConfig) Update(partnerCompanyName string, partnerCompanyID *uuid.UUID, positionTitle string, durationWeeks int, supervisorName, supervisorContact, mouDocumentURL string, isCompanyProvided bool) error {
	if partnerCompanyName == "" {
		return ErrInvalidPartnerName
	}
	if positionTitle == "" {
		return ErrInvalidPositionTitle
	}
	if durationWeeks <= 0 {
		return ErrInvalidDuration
	}
	ic.PartnerCompanyName = partnerCompanyName
	ic.PartnerCompanyID = partnerCompanyID
	ic.PositionTitle = positionTitle
	ic.DurationWeeks = durationWeeks
	ic.SupervisorName = supervisorName
	ic.SupervisorContact = supervisorContact
	ic.MOUDocumentURL = mouDocumentURL
	ic.IsCompanyProvided = isCompanyProvided
	ic.UpdatedAt = time.Now()
	return nil
}

// WriteRepository mendefinisikan operasi tulis untuk InternshipConfig.
// Diimplementasikan di layer infrastructure/database.
type WriteRepository interface {
	Save(ctx context.Context, ic *InternshipConfig) error
	Update(ctx context.Context, ic *InternshipConfig) error
}

// ReadRepository mendefinisikan operasi baca untuk InternshipConfig.
// Diimplementasikan di layer infrastructure/database (dengan Redis cache opsional).
type ReadRepository interface {
	GetByVersionID(ctx context.Context, courseVersionID uuid.UUID) (*InternshipConfig, error)
}
