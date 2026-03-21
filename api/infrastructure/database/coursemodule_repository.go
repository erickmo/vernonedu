package database

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursemodule"
)

// CourseModuleRepository mengimplementasikan coursemodule.WriteRepository dan coursemodule.ReadRepository.
// Menggunakan PostgreSQL dengan sqlx untuk operasi database.
type CourseModuleRepository struct {
	db *sqlx.DB
}

// NewCourseModuleRepository membuat instance baru CourseModuleRepository.
func NewCourseModuleRepository(db *sqlx.DB) *CourseModuleRepository {
	return &CourseModuleRepository{db: db}
}

// courseModuleRecord adalah representasi row dari tabel course_modules.
type courseModuleRecord struct {
	ID                  uuid.UUID  `db:"id"`
	CourseVersionID     uuid.UUID  `db:"course_version_id"`
	ModuleCode          string     `db:"module_code"`
	ModuleTitle         string     `db:"module_title"`
	DurationHours       float64    `db:"duration_hours"`
	Sequence            int        `db:"sequence"`
	ContentDepth        string     `db:"content_depth"`
	Topics              []byte     `db:"topics"`               // JSONB → []string
	PracticalActivities []byte     `db:"practical_activities"` // JSONB → []string
	AssessmentMethod    string     `db:"assessment_method"`
	ToolsRequired       []byte     `db:"tools_required"` // JSONB → []string
	IsReference         bool       `db:"is_reference"`
	RefModuleID         *uuid.UUID `db:"ref_module_id"`
	CreatedAt           time.Time  `db:"created_at"`
	UpdatedAt           time.Time  `db:"updated_at"`
}

// toDomain mengonversi record database ke domain entity CourseModule.
func (rec *courseModuleRecord) toDomain() (*coursemodule.CourseModule, error) {
	var topics []string
	if len(rec.Topics) > 0 {
		if err := json.Unmarshal(rec.Topics, &topics); err != nil {
			return nil, fmt.Errorf("failed to unmarshal topics: %w", err)
		}
	}
	if topics == nil {
		topics = []string{}
	}

	var practicalActivities []string
	if len(rec.PracticalActivities) > 0 {
		if err := json.Unmarshal(rec.PracticalActivities, &practicalActivities); err != nil {
			return nil, fmt.Errorf("failed to unmarshal practical_activities: %w", err)
		}
	}
	if practicalActivities == nil {
		practicalActivities = []string{}
	}

	var toolsRequired []string
	if len(rec.ToolsRequired) > 0 {
		if err := json.Unmarshal(rec.ToolsRequired, &toolsRequired); err != nil {
			return nil, fmt.Errorf("failed to unmarshal tools_required: %w", err)
		}
	}
	if toolsRequired == nil {
		toolsRequired = []string{}
	}

	return &coursemodule.CourseModule{
		ID:                  rec.ID,
		CourseVersionID:     rec.CourseVersionID,
		ModuleCode:          rec.ModuleCode,
		ModuleTitle:         rec.ModuleTitle,
		DurationHours:       rec.DurationHours,
		Sequence:            rec.Sequence,
		ContentDepth:        rec.ContentDepth,
		Topics:              topics,
		PracticalActivities: practicalActivities,
		AssessmentMethod:    rec.AssessmentMethod,
		ToolsRequired:       toolsRequired,
		IsReference:         rec.IsReference,
		RefModuleID:         rec.RefModuleID,
		CreatedAt:           rec.CreatedAt,
		UpdatedAt:           rec.UpdatedAt,
	}, nil
}

// Save menyimpan entitas CourseModule baru ke database.
func (r *CourseModuleRepository) Save(ctx context.Context, cm *coursemodule.CourseModule) error {
	topicsJSON, err := json.Marshal(cm.Topics)
	if err != nil {
		return fmt.Errorf("failed to marshal topics: %w", err)
	}
	activitiesJSON, err := json.Marshal(cm.PracticalActivities)
	if err != nil {
		return fmt.Errorf("failed to marshal practical_activities: %w", err)
	}
	toolsJSON, err := json.Marshal(cm.ToolsRequired)
	if err != nil {
		return fmt.Errorf("failed to marshal tools_required: %w", err)
	}

	query := `
		INSERT INTO course_modules (id, course_version_id, module_code, module_title, duration_hours, sequence,
		                            content_depth, topics, practical_activities, assessment_method,
		                            tools_required, is_reference, ref_module_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
	`
	_, err = r.db.ExecContext(ctx, query,
		cm.ID, cm.CourseVersionID, cm.ModuleCode, cm.ModuleTitle, cm.DurationHours, cm.Sequence,
		cm.ContentDepth, topicsJSON, activitiesJSON, cm.AssessmentMethod,
		toolsJSON, cm.IsReference, cm.RefModuleID, cm.CreatedAt, cm.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save course module: %w", err)
	}
	return nil
}

// Update memperbarui data CourseModule yang sudah ada di database.
func (r *CourseModuleRepository) Update(ctx context.Context, cm *coursemodule.CourseModule) error {
	topicsJSON, err := json.Marshal(cm.Topics)
	if err != nil {
		return fmt.Errorf("failed to marshal topics: %w", err)
	}
	activitiesJSON, err := json.Marshal(cm.PracticalActivities)
	if err != nil {
		return fmt.Errorf("failed to marshal practical_activities: %w", err)
	}
	toolsJSON, err := json.Marshal(cm.ToolsRequired)
	if err != nil {
		return fmt.Errorf("failed to marshal tools_required: %w", err)
	}

	query := `
		UPDATE course_modules
		SET module_title = $1, duration_hours = $2, sequence = $3, content_depth = $4,
		    topics = $5, practical_activities = $6, assessment_method = $7,
		    tools_required = $8, updated_at = $9
		WHERE id = $10
	`
	_, err = r.db.ExecContext(ctx, query,
		cm.ModuleTitle, cm.DurationHours, cm.Sequence, cm.ContentDepth,
		topicsJSON, activitiesJSON, cm.AssessmentMethod,
		toolsJSON, cm.UpdatedAt, cm.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update course module: %w", err)
	}
	return nil
}

// Delete menghapus CourseModule berdasarkan ID dari database.
func (r *CourseModuleRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM course_modules WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete course module: %w", err)
	}
	return nil
}

// DeleteAllByVersion menghapus semua modul yang terkait dengan satu CourseVersion.
func (r *CourseModuleRepository) DeleteAllByVersion(ctx context.Context, courseVersionID uuid.UUID) error {
	query := `DELETE FROM course_modules WHERE course_version_id = $1`
	_, err := r.db.ExecContext(ctx, query, courseVersionID)
	if err != nil {
		return fmt.Errorf("failed to delete course modules by version: %w", err)
	}
	return nil
}

// GetByID mengambil satu CourseModule berdasarkan ID.
func (r *CourseModuleRepository) GetByID(ctx context.Context, id uuid.UUID) (*coursemodule.CourseModule, error) {
	var rec courseModuleRecord
	query := `
		SELECT id, course_version_id, module_code, module_title, duration_hours, sequence,
		       content_depth, topics, practical_activities, assessment_method,
		       tools_required, is_reference, ref_module_id, created_at, updated_at
		FROM course_modules WHERE id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get course module by id: %w", err)
	}
	return rec.toDomain()
}

// ListByVersion mengambil semua modul yang terkait dengan satu CourseVersion, diurut berdasarkan sequence ASC.
func (r *CourseModuleRepository) ListByVersion(ctx context.Context, courseVersionID uuid.UUID) ([]*coursemodule.CourseModule, error) {
	var recs []courseModuleRecord
	query := `
		SELECT id, course_version_id, module_code, module_title, duration_hours, sequence,
		       content_depth, topics, practical_activities, assessment_method,
		       tools_required, is_reference, ref_module_id, created_at, updated_at
		FROM course_modules WHERE course_version_id = $1 ORDER BY sequence ASC
	`
	if err := r.db.SelectContext(ctx, &recs, query, courseVersionID); err != nil {
		return nil, fmt.Errorf("failed to list course modules by version: %w", err)
	}

	modules := make([]*coursemodule.CourseModule, 0, len(recs))
	for _, rec := range recs {
		m, err := rec.toDomain()
		if err != nil {
			return nil, err
		}
		modules = append(modules, m)
	}
	return modules, nil
}

// GetByCode mengambil satu CourseModule berdasarkan course_version_id dan module_code.
func (r *CourseModuleRepository) GetByCode(ctx context.Context, courseVersionID uuid.UUID, moduleCode string) (*coursemodule.CourseModule, error) {
	var rec courseModuleRecord
	query := `
		SELECT id, course_version_id, module_code, module_title, duration_hours, sequence,
		       content_depth, topics, practical_activities, assessment_method,
		       tools_required, is_reference, ref_module_id, created_at, updated_at
		FROM course_modules WHERE course_version_id = $1 AND module_code = $2
	`
	if err := r.db.GetContext(ctx, &rec, query, courseVersionID, moduleCode); err != nil {
		return nil, fmt.Errorf("failed to get course module by code: %w", err)
	}
	return rec.toDomain()
}
