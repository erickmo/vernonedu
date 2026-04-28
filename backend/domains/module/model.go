package module

import (
	"time"

	"github.com/google/uuid"
)

type ModuleStatus string

const (
	ModuleDraft     ModuleStatus = "draft"
	ModulePublished ModuleStatus = "published"
	ModuleArchived  ModuleStatus = "archived"
)

type AssetType string

const (
	AssetVideo    AssetType = "video"
	AssetPDF      AssetType = "pdf"
	AssetDocument AssetType = "document"
	AssetLink     AssetType = "link"
	AssetImage    AssetType = "image"
	AssetOther    AssetType = "other"
)

type VersionPolicy string

const (
	PolicyAutoLatest VersionPolicy = "auto_latest"
	PolicyLocked     VersionPolicy = "locked"
)

type CoverageStatus string

const (
	CoveragePlanned CoverageStatus = "planned"
	CoverageCovered CoverageStatus = "covered"
)

type CourseModule struct {
	ID        uuid.UUID `json:"id"`
	CourseID  uuid.UUID `json:"course_id"`
	Title     string    `json:"title"`
	Order     int       `json:"order"`
	IsActive  bool      `json:"is_active"`
	CreatedBy uuid.UUID `json:"created_by"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ModuleVersion struct {
	ID            uuid.UUID    `json:"id"`
	ModuleID      uuid.UUID    `json:"module_id"`
	VersionNumber int          `json:"version_number"`
	Title         string       `json:"title"`
	Description   *string      `json:"description,omitempty"`
	Status        ModuleStatus `json:"status"`
	PublishedAt   *time.Time   `json:"published_at,omitempty"`
	PublishedBy   *uuid.UUID   `json:"published_by,omitempty"`
	CreatedBy     uuid.UUID    `json:"created_by"`
	CreatedAt     time.Time    `json:"created_at"`
	UpdatedAt     time.Time    `json:"updated_at"`
}

type ModuleAsset struct {
	ID              uuid.UUID `json:"id"`
	ModuleVersionID uuid.UUID `json:"module_version_id"`
	Title           string    `json:"title"`
	AssetType       AssetType `json:"asset_type"`
	URL             string    `json:"url"`
	SizeBytes       *int64    `json:"size_bytes,omitempty"`
	Order           int       `json:"order"`
	IsDownloadable  bool      `json:"is_downloadable"`
	CreatedBy       uuid.UUID `json:"created_by"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type BatchModuleConfig struct {
	ID              uuid.UUID     `json:"id"`
	CourseBatchID   uuid.UUID     `json:"course_batch_id"`
	ModuleID        uuid.UUID     `json:"module_id"`
	VersionPolicy   VersionPolicy `json:"version_policy"`
	LockedVersionID *uuid.UUID    `json:"locked_version_id,omitempty"`
	SetBy           uuid.UUID     `json:"set_by"`
	CreatedAt       time.Time     `json:"created_at"`
	UpdatedAt       time.Time     `json:"updated_at"`
}

type ClassModuleCoverage struct {
	ID            uuid.UUID      `json:"id"`
	ClassID       uuid.UUID      `json:"class_id"`
	ModuleID      uuid.UUID      `json:"module_id"`
	Status        CoverageStatus `json:"status"`
	CoveredBy     *uuid.UUID     `json:"covered_by,omitempty"`
	CoveredAt     *time.Time     `json:"covered_at,omitempty"`
	IsAutoCovered bool           `json:"is_auto_covered"`
	Notes         *string        `json:"notes,omitempty"`
	CreatedBy     uuid.UUID      `json:"created_by"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
}

// BatchProgress is a read model for batch progress summary.
type BatchProgress struct {
	BatchID        uuid.UUID `json:"batch_id"`
	TotalModules   int       `json:"total_modules"`
	CoveredModules int       `json:"covered_modules"`
	ProgressPct    float64   `json:"progress_pct"`
}

// StudentModuleView is a read model for student-facing module list.
type StudentModuleView struct {
	ModuleID      uuid.UUID      `json:"module_id"`
	Title         string         `json:"title"`
	Order         int            `json:"order"`
	VersionID     uuid.UUID      `json:"version_id"`
	VersionTitle  string         `json:"version_title"`
	VersionNumber int            `json:"version_number"`
	Assets        []*ModuleAsset `json:"assets"`
}
