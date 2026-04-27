package credentialing

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines credentialing data access.
type Repository interface {
	CreateCertificateType(ctx context.Context, ct *CertificateType) error
	GetCertificateTypeByID(ctx context.Context, id uuid.UUID) (*CertificateType, error)
	ListActiveCertificateTypes(ctx context.Context) ([]*CertificateType, error)

	CreateCertificateConfig(ctx context.Context, cc *CertificateConfig) error
	GetCertificateConfigByCourse(ctx context.Context, courseID uuid.UUID) ([]*CertificateConfig, error)

	CreateCertificate(ctx context.Context, c *Certificate) error
	GetCertificateByID(ctx context.Context, id uuid.UUID) (*Certificate, error)
	GetCertificateByNumber(ctx context.Context, number string) (*Certificate, error)
	GetCertificateByHash(ctx context.Context, hash string) (*Certificate, error)
	GetActiveCertificateByEnrollment(ctx context.Context, enrollmentID uuid.UUID) (*Certificate, error)
	UpdateCertificateStatus(ctx context.Context, id uuid.UUID, status CertStatus) error
	UpdateCertificatePDF(ctx context.Context, id uuid.UUID, path, hash string) error
	ListCertificatesByEnrollment(ctx context.Context, enrollmentID uuid.UUID) ([]*Certificate, error)
	GetCertificateContext(ctx context.Context, enrollmentID uuid.UUID) (*CertificateContext, error)
	GetCertificateConfigForEnrollment(ctx context.Context, enrollmentID uuid.UUID) (*CertificateConfig, error)

	CreateActionRequest(ctx context.Context, req *CertificateActionRequest) error
	GetActionRequestByID(ctx context.Context, id uuid.UUID) (*CertificateActionRequest, error)
	UpdateActionRequestStatus(ctx context.Context, id uuid.UUID, status ActionStatus, approvedBy *uuid.UUID) error
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates credentialing repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreateCertificateType(ctx context.Context, ct *CertificateType) error {
	query := `
		INSERT INTO credentialing.certificate_types (id, name, category, validity_months, is_active, created_by)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query, ct.ID, ct.Name, ct.Category, ct.ValidityMonths, ct.IsActive, ct.CreatedBy).
		Scan(&ct.CreatedAt, &ct.UpdatedAt)
	if err != nil {
		return fmt.Errorf("credentialing.CreateCertificateType: %w", err)
	}
	return nil
}

func (r *repository) GetCertificateTypeByID(ctx context.Context, id uuid.UUID) (*CertificateType, error) {
	query := `SELECT id, name, category, validity_months, is_active, created_by, created_at, updated_at
	          FROM credentialing.certificate_types WHERE id = $1`

	ct := &CertificateType{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&ct.ID, &ct.Name, &ct.Category, &ct.ValidityMonths, &ct.IsActive, &ct.CreatedBy, &ct.CreatedAt, &ct.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateTypeByID: %w", err)
	}
	return ct, nil
}

func (r *repository) ListActiveCertificateTypes(ctx context.Context) ([]*CertificateType, error) {
	query := `SELECT id, name, category, validity_months, is_active, created_by, created_at, updated_at
	          FROM credentialing.certificate_types WHERE is_active=true ORDER BY name`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("credentialing.ListActiveCertificateTypes: %w", err)
	}
	defer rows.Close()

	var types []*CertificateType
	for rows.Next() {
		ct := &CertificateType{}
		if err := rows.Scan(&ct.ID, &ct.Name, &ct.Category, &ct.ValidityMonths, &ct.IsActive, &ct.CreatedBy, &ct.CreatedAt, &ct.UpdatedAt); err != nil {
			return nil, fmt.Errorf("credentialing.ListActiveCertificateTypes scan: %w", err)
		}
		types = append(types, ct)
	}
	return types, rows.Err()
}

func (r *repository) CreateCertificateConfig(ctx context.Context, cc *CertificateConfig) error {
	query := `
		INSERT INTO credentialing.certificate_configs (id, course_id, certificate_type_id, issued_on)
		VALUES ($1, $2, $3, $4)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query, cc.ID, cc.CourseID, cc.CertificateTypeID, cc.IssuedOn).
		Scan(&cc.CreatedAt, &cc.UpdatedAt)
	if err != nil {
		return fmt.Errorf("credentialing.CreateCertificateConfig: %w", err)
	}
	return nil
}

func (r *repository) GetCertificateConfigByCourse(ctx context.Context, courseID uuid.UUID) ([]*CertificateConfig, error) {
	query := `SELECT id, course_id, certificate_type_id, issued_on, created_at, updated_at
	          FROM credentialing.certificate_configs WHERE course_id = $1`

	rows, err := r.pool.Query(ctx, query, courseID)
	if err != nil {
		return nil, fmt.Errorf("credentialing.GetCertificateConfigByCourse: %w", err)
	}
	defer rows.Close()

	var configs []*CertificateConfig
	for rows.Next() {
		cc := &CertificateConfig{}
		if err := rows.Scan(&cc.ID, &cc.CourseID, &cc.CertificateTypeID, &cc.IssuedOn, &cc.CreatedAt, &cc.UpdatedAt); err != nil {
			return nil, fmt.Errorf("credentialing.GetCertificateConfigByCourse scan: %w", err)
		}
		configs = append(configs, cc)
	}
	return configs, rows.Err()
}

const certColumns = `id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number,
	issued_at, status, qr_code_url, expires_at, revoked_at, revoked_by, reissued_from,
	pdf_path, pdf_hash, created_at, updated_at`

func scanCertificate(row pgx.Row, c *Certificate) error {
	return row.Scan(
		&c.ID, &c.EnrollmentID, &c.CertificateTypeID, &c.CertificateConfigID, &c.CertificateNumber,
		&c.IssuedAt, &c.Status, &c.QRCodeURL, &c.ExpiresAt, &c.RevokedAt, &c.RevokedBy, &c.ReissuedFrom,
		&c.PDFPath, &c.PDFHash, &c.CreatedAt, &c.UpdatedAt,
	)
}

func (r *repository) CreateCertificate(ctx context.Context, c *Certificate) error {
	query := `
		INSERT INTO credentialing.student_certificates
		  (id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number, status, expires_at, pdf_path, pdf_hash)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING issued_at, created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		c.ID, c.EnrollmentID, c.CertificateTypeID, c.CertificateConfigID, c.CertificateNumber, c.Status, c.ExpiresAt, c.PDFPath, c.PDFHash,
	).Scan(&c.IssuedAt, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		return fmt.Errorf("credentialing.CreateCertificate: %w", err)
	}
	return nil
}

func (r *repository) GetCertificateByID(ctx context.Context, id uuid.UUID) (*Certificate, error) {
	query := `SELECT ` + certColumns + ` FROM credentialing.student_certificates WHERE id = $1`
	c := &Certificate{}
	if err := scanCertificate(r.pool.QueryRow(ctx, query, id), c); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateByID: %w", err)
	}
	return c, nil
}

func (r *repository) GetCertificateByNumber(ctx context.Context, number string) (*Certificate, error) {
	query := `SELECT ` + certColumns + ` FROM credentialing.student_certificates WHERE certificate_number = $1`
	c := &Certificate{}
	if err := scanCertificate(r.pool.QueryRow(ctx, query, number), c); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateByNumber: %w", err)
	}
	return c, nil
}

func (r *repository) GetCertificateByHash(ctx context.Context, hash string) (*Certificate, error) {
	query := `SELECT ` + certColumns + ` FROM credentialing.student_certificates WHERE pdf_hash = $1`
	c := &Certificate{}
	if err := scanCertificate(r.pool.QueryRow(ctx, query, hash), c); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateByHash: %w", err)
	}
	return c, nil
}

func (r *repository) GetActiveCertificateByEnrollment(ctx context.Context, enrollmentID uuid.UUID) (*Certificate, error) {
	query := `SELECT ` + certColumns + ` FROM credentialing.student_certificates
	          WHERE enrollment_id = $1 AND status <> 'revoked' LIMIT 1`
	c := &Certificate{}
	if err := scanCertificate(r.pool.QueryRow(ctx, query, enrollmentID), c); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetActiveCertificateByEnrollment: %w", err)
	}
	return c, nil
}

func (r *repository) UpdateCertificatePDF(ctx context.Context, id uuid.UUID, path, hash string) error {
	query := `UPDATE credentialing.student_certificates SET pdf_path=$1, pdf_hash=$2, status=$3 WHERE id=$4`
	ct, err := r.pool.Exec(ctx, query, path, hash, CertIssued, id)
	if err != nil {
		return fmt.Errorf("credentialing.UpdateCertificatePDF: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) GetCertificateContext(ctx context.Context, enrollmentID uuid.UUID) (*CertificateContext, error) {
	query := `
		SELECT e.id, s.name, c.name, now()
		FROM enrollment.enrollments e
		JOIN identity.students s ON s.id = e.student_id
		JOIN catalog.course_batches cb ON cb.id = e.course_batch_id
		JOIN catalog.courses c ON c.id = cb.course_id
		WHERE e.id = $1`
	cc := &CertificateContext{}
	err := r.pool.QueryRow(ctx, query, enrollmentID).Scan(&cc.EnrollmentID, &cc.StudentName, &cc.CourseName, &cc.CompletedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateContext: %w", err)
	}
	return cc, nil
}

func (r *repository) GetCertificateConfigForEnrollment(ctx context.Context, enrollmentID uuid.UUID) (*CertificateConfig, error) {
	query := `
		SELECT cc.id, cc.course_id, cc.certificate_type_id, cc.issued_on, cc.created_at, cc.updated_at
		FROM credentialing.certificate_configs cc
		JOIN catalog.course_batches cb ON cb.course_id = cc.course_id
		JOIN enrollment.enrollments e ON e.course_batch_id = cb.id
		WHERE e.id = $1
		LIMIT 1`
	out := &CertificateConfig{}
	err := r.pool.QueryRow(ctx, query, enrollmentID).Scan(
		&out.ID, &out.CourseID, &out.CertificateTypeID, &out.IssuedOn, &out.CreatedAt, &out.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateConfigForEnrollment: %w", err)
	}
	return out, nil
}

func (r *repository) UpdateCertificateStatus(ctx context.Context, id uuid.UUID, status CertStatus) error {
	query := `UPDATE credentialing.student_certificates SET status=$1 WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("credentialing.UpdateCertificateStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListCertificatesByEnrollment(ctx context.Context, enrollmentID uuid.UUID) ([]*Certificate, error) {
	query := `SELECT ` + certColumns + ` FROM credentialing.student_certificates WHERE enrollment_id = $1`
	rows, err := r.pool.Query(ctx, query, enrollmentID)
	if err != nil {
		return nil, fmt.Errorf("credentialing.ListCertificatesByEnrollment: %w", err)
	}
	defer rows.Close()

	var certs []*Certificate
	for rows.Next() {
		c := &Certificate{}
		if err := scanCertificate(rows, c); err != nil {
			return nil, fmt.Errorf("credentialing.ListCertificatesByEnrollment scan: %w", err)
		}
		certs = append(certs, c)
	}
	return certs, rows.Err()
}

func (r *repository) CreateActionRequest(ctx context.Context, req *CertificateActionRequest) error {
	query := `
		INSERT INTO credentialing.certificate_action_requests
		  (id, student_certificate_id, action, reason, requested_by, status)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		req.ID, req.StudentCertificateID, req.Action, req.Reason, req.RequestedBy, ActionPending,
	).Scan(&req.CreatedAt, &req.UpdatedAt)
	if err != nil {
		return fmt.Errorf("credentialing.CreateActionRequest: %w", err)
	}
	return nil
}

func (r *repository) GetActionRequestByID(ctx context.Context, id uuid.UUID) (*CertificateActionRequest, error) {
	query := `SELECT id, student_certificate_id, action, reason, requested_by, approved_by, status, created_at, updated_at, resolved_at
	          FROM credentialing.certificate_action_requests WHERE id = $1`

	req := &CertificateActionRequest{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&req.ID, &req.StudentCertificateID, &req.Action, &req.Reason, &req.RequestedBy,
		&req.ApprovedBy, &req.Status, &req.CreatedAt, &req.UpdatedAt, &req.ResolvedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetActionRequestByID: %w", err)
	}
	return req, nil
}

func (r *repository) UpdateActionRequestStatus(ctx context.Context, id uuid.UUID, status ActionStatus, approvedBy *uuid.UUID) error {
	query := `UPDATE credentialing.certificate_action_requests SET status=$1, approved_by=$2, resolved_at=now() WHERE id=$3`
	ct, err := r.pool.Exec(ctx, query, status, approvedBy, id)
	if err != nil {
		return fmt.Errorf("credentialing.UpdateActionRequestStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}
