package charactertest

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Sentinel error untuk validasi dan operasi pada CharacterTestConfig
var (
	ErrInvalidTestType       = errors.New("tipe tes karakter tidak boleh kosong")
	ErrInvalidThreshold      = errors.New("passing threshold harus antara 0 dan 100")
	ErrConfigNotFound        = errors.New("konfigurasi tes karakter tidak ditemukan")
)

// CharacterTestConfig mendefinisikan konfigurasi tes karakter untuk sebuah CourseVersion.
// Berlaku khusus untuk tipe kursus "program_karir".
// Satu CourseVersion hanya memiliki satu CharacterTestConfig.
type CharacterTestConfig struct {
	ID                 uuid.UUID
	CourseVersionID    uuid.UUID
	TestType           string  // MBTI | DISC | custom
	TestProvider       string  // nama penyedia layanan tes
	PassingThreshold   float64 // nilai minimum untuk lulus (0-100)
	TalentpoolEligible bool    // true = peserta yang lulus otomatis masuk TalentPool
	CreatedAt          time.Time
	UpdatedAt          time.Time
}

// NewCharacterTestConfig membuat entitas CharacterTestConfig baru dengan validasi awal.
func NewCharacterTestConfig(courseVersionID uuid.UUID, testType, testProvider string, passingThreshold float64, talentpoolEligible bool) (*CharacterTestConfig, error) {
	if testType == "" {
		return nil, ErrInvalidTestType
	}
	if passingThreshold < 0 || passingThreshold > 100 {
		return nil, ErrInvalidThreshold
	}
	return &CharacterTestConfig{
		ID:                 uuid.New(),
		CourseVersionID:    courseVersionID,
		TestType:           testType,
		TestProvider:       testProvider,
		PassingThreshold:   passingThreshold,
		TalentpoolEligible: talentpoolEligible,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}, nil
}

// Update memperbarui data konfigurasi tes karakter.
func (ctc *CharacterTestConfig) Update(testType, testProvider string, passingThreshold float64, talentpoolEligible bool) error {
	if testType == "" {
		return ErrInvalidTestType
	}
	if passingThreshold < 0 || passingThreshold > 100 {
		return ErrInvalidThreshold
	}
	ctc.TestType = testType
	ctc.TestProvider = testProvider
	ctc.PassingThreshold = passingThreshold
	ctc.TalentpoolEligible = talentpoolEligible
	ctc.UpdatedAt = time.Now()
	return nil
}

// WriteRepository mendefinisikan operasi tulis untuk CharacterTestConfig.
// Diimplementasikan di layer infrastructure/database.
type WriteRepository interface {
	Save(ctx context.Context, ctc *CharacterTestConfig) error
	Update(ctx context.Context, ctc *CharacterTestConfig) error
}

// ReadRepository mendefinisikan operasi baca untuk CharacterTestConfig.
// Diimplementasikan di layer infrastructure/database (dengan Redis cache opsional).
type ReadRepository interface {
	GetByVersionID(ctx context.Context, courseVersionID uuid.UUID) (*CharacterTestConfig, error)
}
