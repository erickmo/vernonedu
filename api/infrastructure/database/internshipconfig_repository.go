package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/internship"
)

// InternshipConfigRepository mengimplementasikan internship.WriteRepository dan internship.ReadRepository.
// Menggunakan PostgreSQL dengan sqlx untuk operasi database.
type InternshipConfigRepository struct {
	db *sqlx.DB
}

// NewInternshipConfigRepository membuat instance baru InternshipConfigRepository.
func NewInternshipConfigRepository(db *sqlx.DB) *InternshipConfigRepository {
	return &InternshipConfigRepository{db: db}
}

// internshipConfigRecord adalah representasi row dari tabel internship_configs.
type internshipConfigRecord struct {
	ID                 uuid.UUID  `db:"id"`
	CourseVersionID    uuid.UUID  `db:"course_version_id"`
	PartnerCompanyName string     `db:"partner_company_name"`
	PartnerCompanyID   *uuid.UUID `db:"partner_company_id"`
	PositionTitle      string     `db:"position_title"`
	DurationWeeks      int        `db:"duration_weeks"`
	SupervisorName     string     `db:"supervisor_name"`
	SupervisorContact  string     `db:"supervisor_contact"`
	MOUDocumentURL     string     `db:"mou_document_url"`
	IsCompanyProvided  bool       `db:"is_company_provided"`
	CreatedAt          time.Time  `db:"created_at"`
	UpdatedAt          time.Time  `db:"updated_at"`
}

// toDomain mengonversi record database ke domain entity InternshipConfig.
func (rec *internshipConfigRecord) toDomain() *internship.InternshipConfig {
	return &internship.InternshipConfig{
		ID:                 rec.ID,
		CourseVersionID:    rec.CourseVersionID,
		PartnerCompanyName: rec.PartnerCompanyName,
		PartnerCompanyID:   rec.PartnerCompanyID,
		PositionTitle:      rec.PositionTitle,
		DurationWeeks:      rec.DurationWeeks,
		SupervisorName:     rec.SupervisorName,
		SupervisorContact:  rec.SupervisorContact,
		MOUDocumentURL:     rec.MOUDocumentURL,
		IsCompanyProvided:  rec.IsCompanyProvided,
		CreatedAt:          rec.CreatedAt,
		UpdatedAt:          rec.UpdatedAt,
	}
}

// Save menyimpan entitas InternshipConfig baru ke database.
func (r *InternshipConfigRepository) Save(ctx context.Context, ic *internship.InternshipConfig) error {
	query := `
		INSERT INTO internship_configs (id, course_version_id, partner_company_name, partner_company_id,
		                                position_title, duration_weeks, supervisor_name, supervisor_contact,
		                                mou_document_url, is_company_provided, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		ic.ID, ic.CourseVersionID, ic.PartnerCompanyName, ic.PartnerCompanyID,
		ic.PositionTitle, ic.DurationWeeks, ic.SupervisorName, ic.SupervisorContact,
		ic.MOUDocumentURL, ic.IsCompanyProvided, ic.CreatedAt, ic.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save internship config: %w", err)
	}
	return nil
}

// Update memperbarui data InternshipConfig yang sudah ada di database.
func (r *InternshipConfigRepository) Update(ctx context.Context, ic *internship.InternshipConfig) error {
	query := `
		UPDATE internship_configs
		SET partner_company_name = $1, partner_company_id = $2, position_title = $3,
		    duration_weeks = $4, supervisor_name = $5, supervisor_contact = $6,
		    mou_document_url = $7, is_company_provided = $8, updated_at = $9
		WHERE id = $10
	`
	_, err := r.db.ExecContext(ctx, query,
		ic.PartnerCompanyName, ic.PartnerCompanyID, ic.PositionTitle,
		ic.DurationWeeks, ic.SupervisorName, ic.SupervisorContact,
		ic.MOUDocumentURL, ic.IsCompanyProvided, ic.UpdatedAt, ic.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update internship config: %w", err)
	}
	return nil
}

// GetByVersionID mengambil InternshipConfig berdasarkan course_version_id.
func (r *InternshipConfigRepository) GetByVersionID(ctx context.Context, courseVersionID uuid.UUID) (*internship.InternshipConfig, error) {
	var rec internshipConfigRecord
	query := `
		SELECT id, course_version_id, partner_company_name, partner_company_id,
		       position_title, duration_weeks, supervisor_name, supervisor_contact,
		       mou_document_url, is_company_provided, created_at, updated_at
		FROM internship_configs WHERE course_version_id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, courseVersionID); err != nil {
		return nil, fmt.Errorf("failed to get internship config by version id: %w", err)
	}
	return rec.toDomain(), nil
}
