package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/courseversion"
)

// CourseVersionRepository mengimplementasikan courseversion.WriteRepository dan courseversion.ReadRepository.
// Menggunakan PostgreSQL dengan sqlx untuk operasi database.
type CourseVersionRepository struct {
	db *sqlx.DB
}

// NewCourseVersionRepository membuat instance baru CourseVersionRepository.
func NewCourseVersionRepository(db *sqlx.DB) *CourseVersionRepository {
	return &CourseVersionRepository{db: db}
}

// courseVersionRecord adalah representasi row dari tabel course_versions.
type courseVersionRecord struct {
	ID                 uuid.UUID  `db:"id"`
	CourseTypeID       uuid.UUID  `db:"course_type_id"`
	VersionNumber      string     `db:"version_number"`
	Status             string     `db:"status"`
	ChangeType         string     `db:"change_type"`
	Changelog          string     `db:"changelog"`
	CreatedBy          *uuid.UUID `db:"created_by"`
	ApprovedBy         *uuid.UUID `db:"approved_by"`
	CreatedAt          time.Time  `db:"created_at"`
	UpdatedAt          time.Time  `db:"updated_at"`
	ApprovedAt         *time.Time `db:"approved_at"`
	ArchivedAt         *time.Time `db:"archived_at"`
	ApprovalStatus     string     `db:"approval_status"`
	SubmittedAt        *time.Time `db:"submitted_at"`
	SubmittedBy        *uuid.UUID `db:"submitted_by"`
	ApprovalApprovedBy *uuid.UUID `db:"approval_approved_by"`
	ApprovalApprovedAt *time.Time `db:"approval_approved_at"`
	RejectionReason    *string    `db:"rejection_reason"`
}

// courseVersionSelectColumns adalah daftar kolom yang dibaca dari course_versions.
const courseVersionSelectColumns = `id, course_type_id, version_number, status, change_type, changelog,
	created_by, approved_by, created_at, updated_at, approved_at, archived_at,
	approval_status, submitted_at, submitted_by, approval_approved_by, approval_approved_at, rejection_reason`

// toDomain mengonversi record database ke domain entity CourseVersion.
func (rec *courseVersionRecord) toDomain() *courseversion.CourseVersion {
	reason := ""
	if rec.RejectionReason != nil {
		reason = *rec.RejectionReason
	}
	approvalStatus := rec.ApprovalStatus
	if approvalStatus == "" {
		approvalStatus = courseversion.ApprovalStatusDraft
	}
	return &courseversion.CourseVersion{
		ID:                 rec.ID,
		CourseTypeID:       rec.CourseTypeID,
		VersionNumber:      rec.VersionNumber,
		Status:             rec.Status,
		ChangeType:         rec.ChangeType,
		Changelog:          rec.Changelog,
		CreatedBy:          rec.CreatedBy,
		ApprovedBy:         rec.ApprovedBy,
		CreatedAt:          rec.CreatedAt,
		UpdatedAt:          rec.UpdatedAt,
		ApprovedAt:         rec.ApprovedAt,
		ArchivedAt:         rec.ArchivedAt,
		ApprovalStatus:     approvalStatus,
		SubmittedAt:        rec.SubmittedAt,
		SubmittedBy:        rec.SubmittedBy,
		ApprovalApprovedBy: rec.ApprovalApprovedBy,
		ApprovalApprovedAt: rec.ApprovalApprovedAt,
		RejectionReason:    reason,
	}
}

// Save menyimpan entitas CourseVersion baru ke database.
func (r *CourseVersionRepository) Save(ctx context.Context, cv *courseversion.CourseVersion) error {
	query := `
		INSERT INTO course_versions (id, course_type_id, version_number, status, change_type, changelog,
		                             created_by, approved_by, created_at, updated_at, approved_at, archived_at,
		                             approval_status, submitted_at, submitted_by,
		                             approval_approved_by, approval_approved_at, rejection_reason)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
	`
	approvalStatus := cv.ApprovalStatus
	if approvalStatus == "" {
		approvalStatus = courseversion.ApprovalStatusDraft
	}
	_, err := r.db.ExecContext(ctx, query,
		cv.ID, cv.CourseTypeID, cv.VersionNumber, cv.Status, cv.ChangeType, cv.Changelog,
		cv.CreatedBy, cv.ApprovedBy, cv.CreatedAt, cv.UpdatedAt, cv.ApprovedAt, cv.ArchivedAt,
		approvalStatus, cv.SubmittedAt, cv.SubmittedBy,
		cv.ApprovalApprovedBy, cv.ApprovalApprovedAt, nullableString(cv.RejectionReason),
	)
	if err != nil {
		return fmt.Errorf("failed to save course version: %w", err)
	}
	return nil
}

// nullableString mengembalikan *string nil jika string kosong, untuk kolom NULL-able.
func nullableString(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

// Update memperbarui data CourseVersion yang sudah ada di database.
func (r *CourseVersionRepository) Update(ctx context.Context, cv *courseversion.CourseVersion) error {
	query := `
		UPDATE course_versions
		SET status = $1, approved_by = $2, updated_at = $3, approved_at = $4, archived_at = $5
		WHERE id = $6
	`
	_, err := r.db.ExecContext(ctx, query,
		cv.Status, cv.ApprovedBy, cv.UpdatedAt, cv.ApprovedAt, cv.ArchivedAt, cv.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update course version: %w", err)
	}
	return nil
}

// ArchiveAllApproved mengarsipkan semua versi yang berstatus "approved" untuk satu CourseType.
// Dipanggil saat versi baru di-approve agar hanya ada satu versi aktif.
func (r *CourseVersionRepository) ArchiveAllApproved(ctx context.Context, courseTypeID uuid.UUID) error {
	query := `
		UPDATE course_versions
		SET status = 'archived', archived_at = NOW(), updated_at = NOW()
		WHERE course_type_id = $1 AND status = 'approved'
	`
	_, err := r.db.ExecContext(ctx, query, courseTypeID)
	if err != nil {
		return fmt.Errorf("failed to archive approved course versions: %w", err)
	}
	return nil
}

// GetByID mengambil satu CourseVersion berdasarkan ID.
func (r *CourseVersionRepository) GetByID(ctx context.Context, id uuid.UUID) (*courseversion.CourseVersion, error) {
	var rec courseVersionRecord
	query := `SELECT ` + courseVersionSelectColumns + ` FROM course_versions WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get course version by id: %w", err)
	}
	return rec.toDomain(), nil
}

// ListByType mengambil semua CourseVersion yang terkait dengan satu CourseType.
func (r *CourseVersionRepository) ListByType(ctx context.Context, courseTypeID uuid.UUID) ([]*courseversion.CourseVersion, error) {
	var recs []courseVersionRecord
	query := `SELECT ` + courseVersionSelectColumns + ` FROM course_versions
		WHERE course_type_id = $1 ORDER BY created_at DESC`
	if err := r.db.SelectContext(ctx, &recs, query, courseTypeID); err != nil {
		return nil, fmt.Errorf("failed to list course versions by type: %w", err)
	}
	return recordsToDomain(recs), nil
}

// GetApproved mengambil versi yang sedang aktif (status "approved") untuk satu CourseType.
func (r *CourseVersionRepository) GetApproved(ctx context.Context, courseTypeID uuid.UUID) (*courseversion.CourseVersion, error) {
	var rec courseVersionRecord
	query := `SELECT ` + courseVersionSelectColumns + ` FROM course_versions
		WHERE course_type_id = $1 AND status = 'approved'
		ORDER BY approved_at DESC LIMIT 1`
	if err := r.db.GetContext(ctx, &rec, query, courseTypeID); err != nil {
		return nil, fmt.Errorf("failed to get approved course version: %w", err)
	}
	return rec.toDomain(), nil
}

// UpdateApprovalWorkflow memperbarui kolom approval workflow saja.
func (r *CourseVersionRepository) UpdateApprovalWorkflow(ctx context.Context, cv *courseversion.CourseVersion) error {
	query := `
		UPDATE course_versions
		SET approval_status = $1, submitted_at = $2, submitted_by = $3,
		    approval_approved_by = $4, approval_approved_at = $5, rejection_reason = $6,
		    updated_at = $7
		WHERE id = $8
	`
	_, err := r.db.ExecContext(ctx, query,
		cv.ApprovalStatus, cv.SubmittedAt, cv.SubmittedBy,
		cv.ApprovalApprovedBy, cv.ApprovalApprovedAt, nullableString(cv.RejectionReason),
		cv.UpdatedAt, cv.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update course version approval workflow: %w", err)
	}
	return nil
}

// ListPending mengembalikan semua course version dengan approval_status='submitted'.
// departmentID saat ini di-accept namun tidak digunakan untuk filter (master_courses
// belum punya kolom department_id pada skema saat ini); parameter dipertahankan
// agar future migration tinggal mengaktifkan JOIN tanpa breaking signature.
func (r *CourseVersionRepository) ListPending(ctx context.Context, departmentID *uuid.UUID) ([]*courseversion.CourseVersion, error) {
	_ = departmentID // reserved for future department filter
	var recs []courseVersionRecord
	query := `SELECT ` + courseVersionSelectColumns + ` FROM course_versions
		WHERE approval_status = $1 ORDER BY submitted_at DESC NULLS LAST`
	if err := r.db.SelectContext(ctx, &recs, query, courseversion.ApprovalStatusSubmitted); err != nil {
		return nil, fmt.Errorf("failed to list pending course versions: %w", err)
	}
	return recordsToDomain(recs), nil
}

// recordsToDomain converts a slice of records to a slice of domain entities.
func recordsToDomain(recs []courseVersionRecord) []*courseversion.CourseVersion {
	versions := make([]*courseversion.CourseVersion, len(recs))
	for i := range recs {
		versions[i] = recs[i].toDomain()
	}
	return versions
}
