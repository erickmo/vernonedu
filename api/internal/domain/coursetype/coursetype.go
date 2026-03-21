package coursetype

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Sentinel error untuk validasi dan operasi pada CourseType
var (
	ErrInvalidTypeName      = errors.New("nama tipe kursus tidak valid")
	ErrInvalidCertType      = errors.New("tipe sertifikasi tidak valid")
	ErrCourseTypeNotFound   = errors.New("tipe kursus tidak ditemukan")
	ErrAlreadyActive        = errors.New("tipe kursus sudah aktif")
	ErrAlreadyInactive      = errors.New("tipe kursus sudah tidak aktif")
)

// ValidTypes adalah daftar tipe pembelajaran yang diperbolehkan dalam sistem VernonEdu.
var ValidTypes = []string{
	"regular",
	"private",
	"company_training",
	"collab_university",
	"collab_school",
	"program_karir",
}

// ValidCertTypes adalah daftar tipe sertifikasi yang diperbolehkan.
var ValidCertTypes = []string{
	"internal",
	"SKS",
	"nilai_rapor",
	"corporate",
	"career_certificate",
}

// ComponentFailureConfig mendefinisikan perilaku sistem ketika komponen program_karir gagal.
// Berlaku khusus untuk tipe "program_karir".
type ComponentFailureConfig struct {
	Pembelajaran  string `json:"pembelajaran"`   // retry | continue_no_cert | disqualified
	Internship    string `json:"internship"`     // retry | continue_no_cert | disqualified
	CharacterTest string `json:"character_test"` // retry | continue_no_talentpool | disqualified
}

// CourseType adalah konfigurasi tipe pembelajaran untuk sebuah MasterCourse.
// Setiap MasterCourse dapat memiliki beberapa CourseType aktif sekaligus.
type CourseType struct {
	ID               uuid.UUID
	MasterCourseID   uuid.UUID
	TypeName         string  // salah satu dari ValidTypes
	IsActive         bool
	PriceType        string  // fixed | range | by_request
	PriceMin         *int64
	PriceMax         *int64
	PriceCurrency    string
	PriceNotes       string
	TargetAudience   string
	ExtraDocs        []string // daftar dokumen tambahan yang diperlukan peserta
	CertificationType string   // salah satu dari ValidCertTypes
	// Khusus program_karir: konfigurasi perilaku saat komponen gagal
	ComponentFailureConfig *ComponentFailureConfig
	NormalPrice            int64 // regular/normal price (IDR, in rupiah)
	MinPrice               int64 // minimum/floor price that batch pricing can go down to
	MinParticipants        int   // minimum participants required to run
	MaxParticipants        int   // maximum participants allowed
	CreatedAt              time.Time
	UpdatedAt              time.Time
}

// isValidType memeriksa apakah typeName termasuk dalam ValidTypes.
func isValidType(typeName string) bool {
	for _, v := range ValidTypes {
		if v == typeName {
			return true
		}
	}
	return false
}

// isValidCertType memeriksa apakah certType termasuk dalam ValidCertTypes.
func isValidCertType(certType string) bool {
	for _, v := range ValidCertTypes {
		if v == certType {
			return true
		}
	}
	return false
}

// NewCourseType membuat entitas CourseType baru dengan validasi awal.
// Status awal selalu aktif (IsActive = true).
func NewCourseType(masterCourseID uuid.UUID, typeName, priceType, priceCurrency, targetAudience, certType string, extraDocs []string, failureConfig *ComponentFailureConfig, normalPrice, minPrice int64, minParticipants, maxParticipants int) (*CourseType, error) {
	if !isValidType(typeName) {
		return nil, ErrInvalidTypeName
	}
	if certType != "" && !isValidCertType(certType) {
		return nil, ErrInvalidCertType
	}
	if extraDocs == nil {
		extraDocs = []string{}
	}
	return &CourseType{
		ID:                     uuid.New(),
		MasterCourseID:         masterCourseID,
		TypeName:               typeName,
		IsActive:               true,
		PriceType:              priceType,
		PriceCurrency:          priceCurrency,
		TargetAudience:         targetAudience,
		ExtraDocs:              extraDocs,
		CertificationType:      certType,
		ComponentFailureConfig: failureConfig,
		NormalPrice:            normalPrice,
		MinPrice:               minPrice,
		MinParticipants:        minParticipants,
		MaxParticipants:        maxParticipants,
		CreatedAt:              time.Now(),
		UpdatedAt:              time.Now(),
	}, nil
}

// Activate mengaktifkan course type ini.
// Mengembalikan error jika sudah dalam status aktif.
func (ct *CourseType) Activate() error {
	if ct.IsActive {
		return ErrAlreadyActive
	}
	ct.IsActive = true
	ct.UpdatedAt = time.Now()
	return nil
}

// Deactivate menonaktifkan course type ini.
// Mengembalikan error jika sudah dalam status tidak aktif.
func (ct *CourseType) Deactivate() error {
	if !ct.IsActive {
		return ErrAlreadyInactive
	}
	ct.IsActive = false
	ct.UpdatedAt = time.Now()
	return nil
}

// UpdatePrice memperbarui informasi harga course type.
// priceMin dan priceMax bersifat opsional (pointer).
func (ct *CourseType) UpdatePrice(priceType string, priceMin, priceMax *int64, priceCurrency, priceNotes string) {
	ct.PriceType = priceType
	ct.PriceMin = priceMin
	ct.PriceMax = priceMax
	ct.PriceCurrency = priceCurrency
	ct.PriceNotes = priceNotes
	ct.UpdatedAt = time.Now()
}

// UpdateParticipants memperbarui batas minimum dan maksimum peserta.
func (ct *CourseType) UpdateParticipants(min, max int) {
	ct.MinParticipants = min
	ct.MaxParticipants = max
	ct.UpdatedAt = time.Now()
}

// UpdatePricing memperbarui harga normal dan harga minimum batch.
func (ct *CourseType) UpdatePricing(normalPrice, minPrice int64) {
	ct.NormalPrice = normalPrice
	ct.MinPrice = minPrice
	ct.UpdatedAt = time.Now()
}

// Update memperbarui data konfigurasi course type.
func (ct *CourseType) Update(targetAudience, certType string, extraDocs []string, failureConfig *ComponentFailureConfig, normalPrice, minPrice int64, minParticipants, maxParticipants int) error {
	if certType != "" && !isValidCertType(certType) {
		return ErrInvalidCertType
	}
	if extraDocs == nil {
		extraDocs = []string{}
	}
	ct.TargetAudience = targetAudience
	ct.CertificationType = certType
	ct.ExtraDocs = extraDocs
	ct.ComponentFailureConfig = failureConfig
	ct.NormalPrice = normalPrice
	ct.MinPrice = minPrice
	ct.MinParticipants = minParticipants
	ct.MaxParticipants = maxParticipants
	ct.UpdatedAt = time.Now()
	return nil
}

// WriteRepository mendefinisikan operasi tulis untuk CourseType.
// Diimplementasikan di layer infrastructure/database.
type WriteRepository interface {
	Save(ctx context.Context, ct *CourseType) error
	Update(ctx context.Context, ct *CourseType) error
	Delete(ctx context.Context, id uuid.UUID) error
}

// ReadRepository mendefinisikan operasi baca untuk CourseType.
// Diimplementasikan di layer infrastructure/database (dengan Redis cache opsional).
type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*CourseType, error)
	ListByMasterCourse(ctx context.Context, masterCourseID uuid.UUID) ([]*CourseType, error)
	GetByMasterCourseAndType(ctx context.Context, masterCourseID uuid.UUID, typeName string) (*CourseType, error)
}
