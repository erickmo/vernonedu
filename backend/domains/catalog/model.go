package catalog

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type CourseFormat string

const (
	FormatRegular          CourseFormat = "regular"
	FormatPrivate          CourseFormat = "private"
	FormatInhouseTraining  CourseFormat = "inhouse_training"
	FormatInschoolProgram  CourseFormat = "inschool_program"
)

type BatchStatus string

const (
	BatchDraft   BatchStatus = "draft"
	BatchOpen    BatchStatus = "open"
	BatchOngoing BatchStatus = "ongoing"
	BatchClosed  BatchStatus = "closed"
)

type DeliveryMode string

const (
	ModeOnline  DeliveryMode = "online"
	ModeOffline DeliveryMode = "offline"
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

type Course struct {
	ID                   uuid.UUID        `json:"id"`
	Name                 string           `json:"name"`
	DepartmentID         uuid.UUID        `json:"department_id"`
	CourseCreatorID      uuid.UUID        `json:"course_creator_id"`
	BasePrice            decimal.Decimal  `json:"base_price"`
	MinPrice             decimal.Decimal  `json:"min_price"`
	Description          *string          `json:"description,omitempty"`
	IsActive             bool             `json:"is_active"`
	ProfitSplitOverride  *map[string]any  `json:"profit_split_override,omitempty"`
	CreatedBy            uuid.UUID        `json:"created_by"`
	CreatedAt            time.Time        `json:"created_at"`
	UpdatedAt            time.Time        `json:"updated_at"`
}

type CourseFormatConfig struct {
	ID          uuid.UUID    `json:"id"`
	CourseID    uuid.UUID    `json:"course_id"`
	Format      CourseFormat `json:"format"`
	IsEnabled   bool         `json:"is_enabled"`
	MinStudents *int         `json:"min_students,omitempty"`
	MaxStudents *int         `json:"max_students,omitempty"`
	ModeOnline  bool         `json:"mode_online"`
	ModeOffline bool         `json:"mode_offline"`
	CreatedAt   time.Time    `json:"created_at"`
	UpdatedAt   time.Time    `json:"updated_at"`
}

type CourseBatch struct {
	ID                   uuid.UUID       `json:"id"`
	CourseID             uuid.UUID       `json:"course_id"`
	Label                string          `json:"label"`
	StartDate            time.Time       `json:"start_date"`
	EndDate              time.Time       `json:"end_date"`
	Price                decimal.Decimal `json:"price"`
	BatchBulkPrice       *decimal.Decimal `json:"batch_bulk_price,omitempty"`
	Status               BatchStatus     `json:"status"`
	WebRegistrationOpen  bool            `json:"web_registration_open"`
	RegistrationOpenAt   *time.Time      `json:"registration_open_at,omitempty"`
	RegistrationCloseAt  *time.Time      `json:"registration_close_at,omitempty"`
	CreatedBy            uuid.UUID       `json:"created_by"`
	CreatedAt            time.Time       `json:"created_at"`
	UpdatedAt            time.Time       `json:"updated_at"`
}

type Class struct {
	ID             uuid.UUID    `json:"id"`
	CourseBatchID  uuid.UUID    `json:"course_batch_id"`
	Title          *string      `json:"title,omitempty"`
	SessionDate    time.Time    `json:"session_date"`
	StartTime      string       `json:"start_time"`
	EndTime        string       `json:"end_time"`
	Mode           DeliveryMode `json:"mode"`
	Location       *string      `json:"location,omitempty"`
	OnlineLink     *string      `json:"online_link,omitempty"`
	InstructorID   uuid.UUID    `json:"instructor_id"`
	InstructorType string       `json:"instructor_type"`
	AssignedBy     string       `json:"assigned_by"`
	CreatedAt      time.Time    `json:"created_at"`
	UpdatedAt      time.Time    `json:"updated_at"`
}

type CourseModule struct {
	ID        uuid.UUID    `json:"id"`
	CourseID  uuid.UUID    `json:"course_id"`
	Title     string       `json:"title"`
	Order     int          `json:"order"`
	IsActive  bool         `json:"is_active"`
	CreatedBy uuid.UUID    `json:"created_by"`
	CreatedAt time.Time    `json:"created_at"`
	UpdatedAt time.Time    `json:"updated_at"`
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
	ID              uuid.UUID  `json:"id"`
	CourseBatchID   uuid.UUID  `json:"course_batch_id"`
	ModuleID        uuid.UUID  `json:"module_id"`
	VersionPolicy   string     `json:"version_policy"`
	LockedVersionID *uuid.UUID `json:"locked_version_id,omitempty"`
	SetBy           uuid.UUID  `json:"set_by"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}
