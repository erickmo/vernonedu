package mastercourse

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Sentinel error untuk validasi dan operasi pada MasterCourse
var (
	ErrInvalidName     = errors.New("nama master course tidak boleh kosong")
	ErrInvalidField    = errors.New("bidang (field) tidak boleh kosong")
	ErrCourseNotFound  = errors.New("master course tidak ditemukan")
	ErrAlreadyArchived = errors.New("master course sudah diarsipkan")
)

// MasterCourse adalah entitas utama yang merepresentasikan kursus di platform VernonEdu.
// Satu MasterCourse dapat memiliki beberapa CourseType (tipe pembelajaran) dan
// setiap CourseType dapat memiliki beberapa CourseVersion.
type MasterCourse struct {
	ID               uuid.UUID
	CourseCode       string
	CourseName       string
	Field            string    // bidang kursus: coding, culinary, barber, dst
	CoreCompetencies []string  // daftar kompetensi utama yang diajarkan
	Description      string
	Status           string    // active | archived
	SupportingAppUrl *string   // optional URL to supporting app (e.g. app-entrepreneur, app-blockcoding)
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

// NewMasterCourse membuat entitas MasterCourse baru dengan validasi awal.
// Status awal selalu "active".
func NewMasterCourse(courseCode, courseName, field, description string, coreCompetencies []string) (*MasterCourse, error) {
	if courseName == "" {
		return nil, ErrInvalidName
	}
	if field == "" {
		return nil, ErrInvalidField
	}
	if coreCompetencies == nil {
		coreCompetencies = []string{}
	}
	return &MasterCourse{
		ID:               uuid.New(),
		CourseCode:       courseCode,
		CourseName:       courseName,
		Field:            field,
		Description:      description,
		CoreCompetencies: coreCompetencies,
		Status:           "active",
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}, nil
}

// SetSupportingApp menetapkan URL supporting app untuk master course ini.
// Kirim nil untuk menghapus URL.
func (mc *MasterCourse) SetSupportingApp(url *string) {
	mc.SupportingAppUrl = url
	mc.UpdatedAt = time.Now()
}

// Archive mengarsipkan master course ini.
// Mengembalikan error jika sudah dalam status archived.
func (mc *MasterCourse) Archive() error {
	if mc.Status == "archived" {
		return ErrAlreadyArchived
	}
	mc.Status = "archived"
	mc.UpdatedAt = time.Now()
	return nil
}

// Update memperbarui data master course.
// Validasi nama dan field wajib dilakukan sebelum update disimpan.
func (mc *MasterCourse) Update(courseName, field, description string, coreCompetencies []string, supportingAppUrl *string) error {
	if courseName == "" {
		return ErrInvalidName
	}
	if field == "" {
		return ErrInvalidField
	}
	mc.CourseName = courseName
	mc.Field = field
	mc.Description = description
	mc.CoreCompetencies = coreCompetencies
	mc.SupportingAppUrl = supportingAppUrl
	mc.UpdatedAt = time.Now()
	return nil
}

// WriteRepository mendefinisikan operasi tulis untuk MasterCourse.
// Diimplementasikan di layer infrastructure/database.
type WriteRepository interface {
	Save(ctx context.Context, mc *MasterCourse) error
	Update(ctx context.Context, mc *MasterCourse) error
	Delete(ctx context.Context, id uuid.UUID) error
}

// ReadRepository mendefinisikan operasi baca untuk MasterCourse.
// Diimplementasikan di layer infrastructure/database (dengan Redis cache opsional).
type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*MasterCourse, error)
	GetByCode(ctx context.Context, code string) (*MasterCourse, error)
	List(ctx context.Context, offset, limit int, status, field string) ([]*MasterCourse, int, error)
}
