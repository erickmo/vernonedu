package settings

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrFacilitatorLevelNotFound = errors.New("facilitator level not found")
	ErrHolidayNotFound          = errors.New("holiday not found")
)

// CommissionConfig holds company-wide commission percentages.
// Stored as a singleton row in commission_configs.
type CommissionConfig struct {
	OpLeaderPct       float64
	OpLeaderBasis     string // "profit" | "revenue"
	DeptLeaderPct     float64
	DeptLeaderBasis   string
	CourseCreatorPct  float64
	CourseCreatorBasis string
	UpdatedAt         time.Time
}

// FacilitatorLevel maps a numbered level to a fixed fee per session.
type FacilitatorLevel struct {
	ID           uuid.UUID
	Level        int
	Name         string
	FeePerSession int64 // in IDR (rupiah)
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

// Holiday represents a public or company holiday that affects scheduling.
type Holiday struct {
	ID        uuid.UUID
	Date      time.Time
	Name      string
	CreatedAt time.Time
}

// CommissionWriteRepository persists commission config (singleton upsert).
type CommissionWriteRepository interface {
	Upsert(ctx context.Context, cfg *CommissionConfig) error
}

// CommissionReadRepository reads commission config.
type CommissionReadRepository interface {
	Get(ctx context.Context) (*CommissionConfig, error)
}

// FacilitatorLevelWriteRepository replaces all facilitator levels (full replace).
type FacilitatorLevelWriteRepository interface {
	ReplaceAll(ctx context.Context, levels []*FacilitatorLevel) error
}

// FacilitatorLevelReadRepository reads facilitator levels.
type FacilitatorLevelReadRepository interface {
	List(ctx context.Context) ([]*FacilitatorLevel, error)
}

// HolidayWriteRepository manages holidays.
type HolidayWriteRepository interface {
	Save(ctx context.Context, h *Holiday) error
	Delete(ctx context.Context, id uuid.UUID) error
}

// HolidayReadRepository reads holidays.
type HolidayReadRepository interface {
	ListByYear(ctx context.Context, year int) ([]*Holiday, error)
}
