package database

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursetype"
)

// CourseTypeRepository mengimplementasikan coursetype.WriteRepository dan coursetype.ReadRepository.
// Menggunakan PostgreSQL dengan sqlx untuk operasi database.
type CourseTypeRepository struct {
	db *sqlx.DB
}

// NewCourseTypeRepository membuat instance baru CourseTypeRepository.
func NewCourseTypeRepository(db *sqlx.DB) *CourseTypeRepository {
	return &CourseTypeRepository{db: db}
}

// courseTypeRecord adalah representasi row dari tabel course_types.
type courseTypeRecord struct {
	ID                     uuid.UUID  `db:"id"`
	MasterCourseID         uuid.UUID  `db:"master_course_id"`
	TypeName               string     `db:"type_name"`
	IsActive               bool       `db:"is_active"`
	PriceType              string     `db:"price_type"`
	PriceMin               *int64     `db:"price_min"`
	PriceMax               *int64     `db:"price_max"`
	PriceCurrency          string     `db:"price_currency"`
	PriceNotes             string     `db:"price_notes"`
	TargetAudience         string     `db:"target_audience"`
	ExtraDocs              []byte     `db:"extra_docs"`              // JSONB → []string
	CertificationType      string     `db:"certification_type"`
	ComponentFailureConfig []byte     `db:"component_failure_config"` // JSONB → *ComponentFailureConfig
	CreatedAt              time.Time  `db:"created_at"`
	UpdatedAt              time.Time  `db:"updated_at"`
}

// toDomain mengonversi record database ke domain entity CourseType.
func (rec *courseTypeRecord) toDomain() (*coursetype.CourseType, error) {
	// Unmarshal extra_docs dari JSONB
	var extraDocs []string
	if len(rec.ExtraDocs) > 0 {
		if err := json.Unmarshal(rec.ExtraDocs, &extraDocs); err != nil {
			return nil, fmt.Errorf("failed to unmarshal extra_docs: %w", err)
		}
	}
	if extraDocs == nil {
		extraDocs = []string{}
	}

	// Unmarshal component_failure_config dari JSONB
	var failureConfig *coursetype.ComponentFailureConfig
	if len(rec.ComponentFailureConfig) > 0 && string(rec.ComponentFailureConfig) != "null" {
		failureConfig = &coursetype.ComponentFailureConfig{}
		if err := json.Unmarshal(rec.ComponentFailureConfig, failureConfig); err != nil {
			return nil, fmt.Errorf("failed to unmarshal component_failure_config: %w", err)
		}
	}

	return &coursetype.CourseType{
		ID:                     rec.ID,
		MasterCourseID:         rec.MasterCourseID,
		TypeName:               rec.TypeName,
		IsActive:               rec.IsActive,
		PriceType:              rec.PriceType,
		PriceMin:               rec.PriceMin,
		PriceMax:               rec.PriceMax,
		PriceCurrency:          rec.PriceCurrency,
		PriceNotes:             rec.PriceNotes,
		TargetAudience:         rec.TargetAudience,
		ExtraDocs:              extraDocs,
		CertificationType:      rec.CertificationType,
		ComponentFailureConfig: failureConfig,
		CreatedAt:              rec.CreatedAt,
		UpdatedAt:              rec.UpdatedAt,
	}, nil
}

// Save menyimpan entitas CourseType baru ke database.
func (r *CourseTypeRepository) Save(ctx context.Context, ct *coursetype.CourseType) error {
	extraDocsJSON, err := json.Marshal(ct.ExtraDocs)
	if err != nil {
		return fmt.Errorf("failed to marshal extra_docs: %w", err)
	}
	failureConfigJSON, err := json.Marshal(ct.ComponentFailureConfig)
	if err != nil {
		return fmt.Errorf("failed to marshal component_failure_config: %w", err)
	}

	query := `
		INSERT INTO course_types (id, master_course_id, type_name, is_active, price_type, price_min, price_max,
		                          price_currency, price_notes, target_audience, extra_docs, certification_type,
		                          component_failure_config, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
	`
	_, err = r.db.ExecContext(ctx, query,
		ct.ID, ct.MasterCourseID, ct.TypeName, ct.IsActive, ct.PriceType,
		ct.PriceMin, ct.PriceMax, ct.PriceCurrency, ct.PriceNotes, ct.TargetAudience,
		extraDocsJSON, ct.CertificationType, failureConfigJSON, ct.CreatedAt, ct.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save course type: %w", err)
	}
	return nil
}

// Update memperbarui data CourseType yang sudah ada di database.
func (r *CourseTypeRepository) Update(ctx context.Context, ct *coursetype.CourseType) error {
	extraDocsJSON, err := json.Marshal(ct.ExtraDocs)
	if err != nil {
		return fmt.Errorf("failed to marshal extra_docs: %w", err)
	}
	failureConfigJSON, err := json.Marshal(ct.ComponentFailureConfig)
	if err != nil {
		return fmt.Errorf("failed to marshal component_failure_config: %w", err)
	}

	query := `
		UPDATE course_types
		SET is_active = $1, price_type = $2, price_min = $3, price_max = $4, price_currency = $5,
		    price_notes = $6, target_audience = $7, extra_docs = $8, certification_type = $9,
		    component_failure_config = $10, updated_at = $11
		WHERE id = $12
	`
	_, err = r.db.ExecContext(ctx, query,
		ct.IsActive, ct.PriceType, ct.PriceMin, ct.PriceMax, ct.PriceCurrency,
		ct.PriceNotes, ct.TargetAudience, extraDocsJSON, ct.CertificationType,
		failureConfigJSON, ct.UpdatedAt, ct.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update course type: %w", err)
	}
	return nil
}

// Delete menghapus CourseType berdasarkan ID dari database.
func (r *CourseTypeRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM course_types WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete course type: %w", err)
	}
	return nil
}

// GetByID mengambil satu CourseType berdasarkan ID.
func (r *CourseTypeRepository) GetByID(ctx context.Context, id uuid.UUID) (*coursetype.CourseType, error) {
	var rec courseTypeRecord
	query := `
		SELECT id, master_course_id, type_name, is_active, price_type, price_min, price_max,
		       price_currency, price_notes, target_audience, extra_docs, certification_type,
		       component_failure_config, created_at, updated_at
		FROM course_types WHERE id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get course type by id: %w", err)
	}
	return rec.toDomain()
}

// ListByMasterCourse mengambil semua CourseType yang terkait dengan satu MasterCourse.
func (r *CourseTypeRepository) ListByMasterCourse(ctx context.Context, masterCourseID uuid.UUID) ([]*coursetype.CourseType, error) {
	var recs []courseTypeRecord
	query := `
		SELECT id, master_course_id, type_name, is_active, price_type, price_min, price_max,
		       price_currency, price_notes, target_audience, extra_docs, certification_type,
		       component_failure_config, created_at, updated_at
		FROM course_types WHERE master_course_id = $1 ORDER BY created_at ASC
	`
	if err := r.db.SelectContext(ctx, &recs, query, masterCourseID); err != nil {
		return nil, fmt.Errorf("failed to list course types by master course: %w", err)
	}

	types := make([]*coursetype.CourseType, 0, len(recs))
	for _, rec := range recs {
		ct, err := rec.toDomain()
		if err != nil {
			return nil, err
		}
		types = append(types, ct)
	}
	return types, nil
}

// GetByMasterCourseAndType mengambil CourseType berdasarkan master_course_id dan type_name.
func (r *CourseTypeRepository) GetByMasterCourseAndType(ctx context.Context, masterCourseID uuid.UUID, typeName string) (*coursetype.CourseType, error) {
	var rec courseTypeRecord
	query := `
		SELECT id, master_course_id, type_name, is_active, price_type, price_min, price_max,
		       price_currency, price_notes, target_audience, extra_docs, certification_type,
		       component_failure_config, created_at, updated_at
		FROM course_types WHERE master_course_id = $1 AND type_name = $2
	`
	if err := r.db.GetContext(ctx, &rec, query, masterCourseID, typeName); err != nil {
		return nil, fmt.Errorf("failed to get course type by master course and type: %w", err)
	}
	return rec.toDomain()
}
