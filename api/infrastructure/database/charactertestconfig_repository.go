package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/charactertest"
)

// CharacterTestConfigRepository mengimplementasikan charactertest.WriteRepository dan charactertest.ReadRepository.
// Menggunakan PostgreSQL dengan sqlx untuk operasi database.
type CharacterTestConfigRepository struct {
	db *sqlx.DB
}

// NewCharacterTestConfigRepository membuat instance baru CharacterTestConfigRepository.
func NewCharacterTestConfigRepository(db *sqlx.DB) *CharacterTestConfigRepository {
	return &CharacterTestConfigRepository{db: db}
}

// characterTestConfigRecord adalah representasi row dari tabel character_test_configs.
type characterTestConfigRecord struct {
	ID                 uuid.UUID `db:"id"`
	CourseVersionID    uuid.UUID `db:"course_version_id"`
	TestType           string    `db:"test_type"`
	TestProvider       string    `db:"test_provider"`
	PassingThreshold   float64   `db:"passing_threshold"`
	TalentpoolEligible bool      `db:"talentpool_eligible"`
	CreatedAt          time.Time `db:"created_at"`
	UpdatedAt          time.Time `db:"updated_at"`
}

// toDomain mengonversi record database ke domain entity CharacterTestConfig.
func (rec *characterTestConfigRecord) toDomain() *charactertest.CharacterTestConfig {
	return &charactertest.CharacterTestConfig{
		ID:                 rec.ID,
		CourseVersionID:    rec.CourseVersionID,
		TestType:           rec.TestType,
		TestProvider:       rec.TestProvider,
		PassingThreshold:   rec.PassingThreshold,
		TalentpoolEligible: rec.TalentpoolEligible,
		CreatedAt:          rec.CreatedAt,
		UpdatedAt:          rec.UpdatedAt,
	}
}

// Save menyimpan entitas CharacterTestConfig baru ke database.
func (r *CharacterTestConfigRepository) Save(ctx context.Context, ctc *charactertest.CharacterTestConfig) error {
	query := `
		INSERT INTO character_test_configs (id, course_version_id, test_type, test_provider,
		                                    passing_threshold, talentpool_eligible, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.ExecContext(ctx, query,
		ctc.ID, ctc.CourseVersionID, ctc.TestType, ctc.TestProvider,
		ctc.PassingThreshold, ctc.TalentpoolEligible, ctc.CreatedAt, ctc.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save character test config: %w", err)
	}
	return nil
}

// Update memperbarui data CharacterTestConfig yang sudah ada di database.
func (r *CharacterTestConfigRepository) Update(ctx context.Context, ctc *charactertest.CharacterTestConfig) error {
	query := `
		UPDATE character_test_configs
		SET test_type = $1, test_provider = $2, passing_threshold = $3, talentpool_eligible = $4, updated_at = $5
		WHERE id = $6
	`
	_, err := r.db.ExecContext(ctx, query,
		ctc.TestType, ctc.TestProvider, ctc.PassingThreshold, ctc.TalentpoolEligible, ctc.UpdatedAt, ctc.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update character test config: %w", err)
	}
	return nil
}

// GetByVersionID mengambil CharacterTestConfig berdasarkan course_version_id.
func (r *CharacterTestConfigRepository) GetByVersionID(ctx context.Context, courseVersionID uuid.UUID) (*charactertest.CharacterTestConfig, error) {
	var rec characterTestConfigRecord
	query := `
		SELECT id, course_version_id, test_type, test_provider,
		       passing_threshold, talentpool_eligible, created_at, updated_at
		FROM character_test_configs WHERE course_version_id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, courseVersionID); err != nil {
		return nil, fmt.Errorf("failed to get character test config by version id: %w", err)
	}
	return rec.toDomain(), nil
}
