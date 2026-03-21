package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

// ─── CommissionConfig ──────────────────────────────────────────────────────────

type SettingsRepository struct {
	db *sqlx.DB
}

func NewSettingsRepository(db *sqlx.DB) *SettingsRepository {
	return &SettingsRepository{db: db}
}

type commissionConfigRecord struct {
	ID                 int       `db:"id"`
	OpLeaderPct        float64   `db:"op_leader_pct"`
	OpLeaderBasis      string    `db:"op_leader_basis"`
	DeptLeaderPct      float64   `db:"dept_leader_pct"`
	DeptLeaderBasis    string    `db:"dept_leader_basis"`
	CourseCreatorPct   float64   `db:"course_creator_pct"`
	CourseCreatorBasis string    `db:"course_creator_basis"`
	UpdatedAt          time.Time `db:"updated_at"`
}

func (r *SettingsRepository) Upsert(ctx context.Context, cfg *settings.CommissionConfig) error {
	query := `
		UPDATE commission_configs
		SET op_leader_pct      = $1,
		    op_leader_basis     = $2,
		    dept_leader_pct     = $3,
		    dept_leader_basis   = $4,
		    course_creator_pct  = $5,
		    course_creator_basis= $6,
		    updated_at          = $7
		WHERE id = (SELECT MIN(id) FROM commission_configs)
	`
	_, err := r.db.ExecContext(ctx, query,
		cfg.OpLeaderPct, cfg.OpLeaderBasis,
		cfg.DeptLeaderPct, cfg.DeptLeaderBasis,
		cfg.CourseCreatorPct, cfg.CourseCreatorBasis,
		cfg.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to upsert commission config: %w", err)
	}
	return nil
}

func (r *SettingsRepository) Get(ctx context.Context) (*settings.CommissionConfig, error) {
	var rec commissionConfigRecord
	query := `SELECT * FROM commission_configs ORDER BY id LIMIT 1`
	if err := r.db.GetContext(ctx, &rec, query); err != nil {
		return nil, fmt.Errorf("failed to get commission config: %w", err)
	}
	return &settings.CommissionConfig{
		OpLeaderPct:        rec.OpLeaderPct,
		OpLeaderBasis:      rec.OpLeaderBasis,
		DeptLeaderPct:      rec.DeptLeaderPct,
		DeptLeaderBasis:    rec.DeptLeaderBasis,
		CourseCreatorPct:   rec.CourseCreatorPct,
		CourseCreatorBasis: rec.CourseCreatorBasis,
		UpdatedAt:          rec.UpdatedAt,
	}, nil
}

// ─── FacilitatorLevel ─────────────────────────────────────────────────────────

type facilitatorLevelRecord struct {
	ID            uuid.UUID `db:"id"`
	Level         int       `db:"level"`
	Name          string    `db:"name"`
	FeePerSession int64     `db:"fee_per_session"`
	CreatedAt     time.Time `db:"created_at"`
	UpdatedAt     time.Time `db:"updated_at"`
}

func (rec *facilitatorLevelRecord) toDomain() *settings.FacilitatorLevel {
	return &settings.FacilitatorLevel{
		ID:            rec.ID,
		Level:         rec.Level,
		Name:          rec.Name,
		FeePerSession: rec.FeePerSession,
		CreatedAt:     rec.CreatedAt,
		UpdatedAt:     rec.UpdatedAt,
	}
}

// ReplaceAll deletes all existing levels and inserts the new set in one transaction.
func (r *SettingsRepository) ReplaceAll(ctx context.Context, levels []*settings.FacilitatorLevel) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	if _, err := tx.ExecContext(ctx, `DELETE FROM facilitator_levels`); err != nil {
		return fmt.Errorf("failed to clear facilitator levels: %w", err)
	}

	for _, l := range levels {
		_, err := tx.ExecContext(ctx, `
			INSERT INTO facilitator_levels (id, level, name, fee_per_session, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6)
		`, l.ID, l.Level, l.Name, l.FeePerSession, l.CreatedAt, l.UpdatedAt)
		if err != nil {
			return fmt.Errorf("failed to insert facilitator level %d: %w", l.Level, err)
		}
	}

	return tx.Commit()
}

func (r *SettingsRepository) ListFacilitatorLevels(ctx context.Context) ([]*settings.FacilitatorLevel, error) {
	var recs []facilitatorLevelRecord
	query := `SELECT id, level, name, fee_per_session, created_at, updated_at FROM facilitator_levels ORDER BY level`
	if err := r.db.SelectContext(ctx, &recs, query); err != nil {
		return nil, fmt.Errorf("failed to list facilitator levels: %w", err)
	}
	out := make([]*settings.FacilitatorLevel, len(recs))
	for i, rec := range recs {
		out[i] = rec.toDomain()
	}
	return out, nil
}

// ─── Holiday ──────────────────────────────────────────────────────────────────

type holidayRecord struct {
	ID        uuid.UUID `db:"id"`
	Date      time.Time `db:"date"`
	Name      string    `db:"name"`
	CreatedAt time.Time `db:"created_at"`
}

func (rec *holidayRecord) toDomain() *settings.Holiday {
	return &settings.Holiday{
		ID:        rec.ID,
		Date:      rec.Date,
		Name:      rec.Name,
		CreatedAt: rec.CreatedAt,
	}
}

func (r *SettingsRepository) SaveHoliday(ctx context.Context, h *settings.Holiday) error {
	query := `
		INSERT INTO holidays (id, date, name, created_at)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (date) DO UPDATE SET name = EXCLUDED.name
	`
	_, err := r.db.ExecContext(ctx, query, h.ID, h.Date, h.Name, h.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to save holiday: %w", err)
	}
	return nil
}

func (r *SettingsRepository) DeleteHoliday(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM holidays WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("failed to delete holiday: %w", err)
	}
	return nil
}

func (r *SettingsRepository) ListHolidaysByYear(ctx context.Context, year int) ([]*settings.Holiday, error) {
	var recs []holidayRecord
	query := `
		SELECT id, date, name, created_at
		FROM holidays
		WHERE EXTRACT(YEAR FROM date) = $1
		ORDER BY date
	`
	if err := r.db.SelectContext(ctx, &recs, query, year); err != nil {
		return nil, fmt.Errorf("failed to list holidays: %w", err)
	}
	out := make([]*settings.Holiday, len(recs))
	for i, rec := range recs {
		out[i] = rec.toDomain()
	}
	return out, nil
}

// ─── Domain Interface Adapters ─────────────────────────────────────────────────

// CommissionRepo adapts SettingsRepository to settings.CommissionWriteRepository + CommissionReadRepository.
type CommissionRepo struct{ repo *SettingsRepository }

func NewCommissionRepo(r *SettingsRepository) *CommissionRepo { return &CommissionRepo{repo: r} }
func (c *CommissionRepo) Upsert(ctx context.Context, cfg *settings.CommissionConfig) error {
	return c.repo.Upsert(ctx, cfg)
}
func (c *CommissionRepo) Get(ctx context.Context) (*settings.CommissionConfig, error) {
	return c.repo.Get(ctx)
}

// FacilitatorRepo adapts SettingsRepository to FacilitatorLevel interfaces.
type FacilitatorRepo struct{ repo *SettingsRepository }

func NewFacilitatorRepo(r *SettingsRepository) *FacilitatorRepo { return &FacilitatorRepo{repo: r} }
func (f *FacilitatorRepo) ReplaceAll(ctx context.Context, levels []*settings.FacilitatorLevel) error {
	return f.repo.ReplaceAll(ctx, levels)
}
func (f *FacilitatorRepo) List(ctx context.Context) ([]*settings.FacilitatorLevel, error) {
	return f.repo.ListFacilitatorLevels(ctx)
}

// HolidayRepo adapts SettingsRepository to Holiday interfaces.
type HolidayRepo struct{ repo *SettingsRepository }

func NewHolidayRepo(r *SettingsRepository) *HolidayRepo { return &HolidayRepo{repo: r} }
func (h *HolidayRepo) Save(ctx context.Context, hol *settings.Holiday) error {
	return h.repo.SaveHoliday(ctx, hol)
}
func (h *HolidayRepo) Delete(ctx context.Context, id uuid.UUID) error {
	return h.repo.DeleteHoliday(ctx, id)
}
func (h *HolidayRepo) ListByYear(ctx context.Context, year int) ([]*settings.Holiday, error) {
	return h.repo.ListHolidaysByYear(ctx, year)
}
