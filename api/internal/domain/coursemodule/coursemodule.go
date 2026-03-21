package coursemodule

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Sentinel error untuk validasi dan operasi pada CourseModule
var (
	ErrInvalidTitle    = errors.New("judul modul tidak boleh kosong")
	ErrInvalidCode     = errors.New("kode modul tidak boleh kosong")
	ErrInvalidSequence = errors.New("urutan modul harus lebih dari nol")
	ErrModuleNotFound  = errors.New("modul tidak ditemukan")
)

// ValidContentDepths adalah daftar kedalaman konten yang diperbolehkan.
var ValidContentDepths = []string{"intro", "standard", "advanced"}

// CourseModule merepresentasikan satu modul pembelajaran dalam sebuah CourseVersion.
// Setiap modul memiliki urutan (sequence), topik, aktivitas praktis, dan metode penilaian.
// Modul dapat berupa referensi ke master module pool (IsReference = true).
type CourseModule struct {
	ID                  uuid.UUID
	CourseVersionID     uuid.UUID
	ModuleCode          string    // kode modul, contoh: M1, M2, M3
	ModuleTitle         string
	DurationHours       float64
	Sequence            int       // urutan modul dalam kurikulum
	ContentDepth        string    // intro | standard | advanced
	Topics              []string  // daftar topik yang dicakup modul ini
	PracticalActivities []string  // daftar aktivitas praktik
	AssessmentMethod    string    // metode penilaian modul
	ToolsRequired       []string  // daftar alat/software yang dibutuhkan
	Requirements        []string  // prerequisite skills/knowledge required before taking this module
	IsReference         bool      // true = modul ini merujuk ke master module pool
	RefModuleID         *uuid.UUID // FK ke master module pool jika IsReference = true
	CreatedAt           time.Time
	UpdatedAt           time.Time
}

// NewCourseModule membuat entitas CourseModule baru dengan validasi awal.
func NewCourseModule(courseVersionID uuid.UUID, moduleCode, moduleTitle, contentDepth, assessmentMethod string, durationHours float64, sequence int, topics, practicalActivities, toolsRequired []string, requirements []string, isReference bool, refModuleID *uuid.UUID) (*CourseModule, error) {
	if moduleCode == "" {
		return nil, ErrInvalidCode
	}
	if moduleTitle == "" {
		return nil, ErrInvalidTitle
	}
	if sequence <= 0 {
		return nil, ErrInvalidSequence
	}
	if topics == nil {
		topics = []string{}
	}
	if practicalActivities == nil {
		practicalActivities = []string{}
	}
	if toolsRequired == nil {
		toolsRequired = []string{}
	}
	if requirements == nil {
		requirements = []string{}
	}
	return &CourseModule{
		ID:                  uuid.New(),
		CourseVersionID:     courseVersionID,
		ModuleCode:          moduleCode,
		ModuleTitle:         moduleTitle,
		DurationHours:       durationHours,
		Sequence:            sequence,
		ContentDepth:        contentDepth,
		Topics:              topics,
		PracticalActivities: practicalActivities,
		AssessmentMethod:    assessmentMethod,
		ToolsRequired:       toolsRequired,
		Requirements:        requirements,
		IsReference:         isReference,
		RefModuleID:         refModuleID,
		CreatedAt:           time.Now(),
		UpdatedAt:           time.Now(),
	}, nil
}

// Update memperbarui data modul kursus.
func (cm *CourseModule) Update(moduleTitle, contentDepth, assessmentMethod string, durationHours float64, sequence int, topics, practicalActivities, toolsRequired []string, requirements []string) error {
	if moduleTitle == "" {
		return ErrInvalidTitle
	}
	if sequence <= 0 {
		return ErrInvalidSequence
	}
	if topics == nil {
		topics = []string{}
	}
	if practicalActivities == nil {
		practicalActivities = []string{}
	}
	if toolsRequired == nil {
		toolsRequired = []string{}
	}
	if requirements == nil {
		requirements = []string{}
	}
	cm.ModuleTitle = moduleTitle
	cm.ContentDepth = contentDepth
	cm.AssessmentMethod = assessmentMethod
	cm.DurationHours = durationHours
	cm.Sequence = sequence
	cm.Topics = topics
	cm.PracticalActivities = practicalActivities
	cm.ToolsRequired = toolsRequired
	cm.Requirements = requirements
	cm.UpdatedAt = time.Now()
	return nil
}

// WriteRepository mendefinisikan operasi tulis untuk CourseModule.
// Diimplementasikan di layer infrastructure/database.
type WriteRepository interface {
	Save(ctx context.Context, cm *CourseModule) error
	Update(ctx context.Context, cm *CourseModule) error
	Delete(ctx context.Context, id uuid.UUID) error
	// DeleteAllByVersion menghapus semua modul yang terkait dengan satu CourseVersion.
	DeleteAllByVersion(ctx context.Context, courseVersionID uuid.UUID) error
}

// ReadRepository mendefinisikan operasi baca untuk CourseModule.
// Diimplementasikan di layer infrastructure/database (dengan Redis cache opsional).
type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*CourseModule, error)
	ListByVersion(ctx context.Context, courseVersionID uuid.UUID) ([]*CourseModule, error)
	GetByCode(ctx context.Context, courseVersionID uuid.UUID, moduleCode string) (*CourseModule, error)
}
