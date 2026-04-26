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
	UpdateCertificateStatus(ctx context.Context, id uuid.UUID, status CertStatus) error
	ListCertificatesByEnrollment(ctx context.Context, enrollmentID uuid.UUID) ([]*Certificate, error)

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

func (r *repository) CreateCertificate(ctx context.Context, c *Certificate) error {
	query := `
		INSERT INTO credentialing.student_certificates
		  (id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number, status, expires_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING issued_at, created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		c.ID, c.EnrollmentID, c.CertificateTypeID, c.CertificateConfigID, c.CertificateNumber, c.Status, c.ExpiresAt,
	).Scan(&c.IssuedAt, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		return fmt.Errorf("credentialing.CreateCertificate: %w", err)
	}
	return nil
}

func (r *repository) GetCertificateByID(ctx context.Context, id uuid.UUID) (*Certificate, error) {
	query := `SELECT id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number,
	                 issued_at, status, qr_code_url, expires_at, revoked_at, revoked_by, reissued_from, created_at, updated_at
	          FROM credentialing.student_certificates WHERE id = $1`

	c := &Certificate{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&c.ID, &c.EnrollmentID, &c.CertificateTypeID, &c.CertificateConfigID, &c.CertificateNumber,
		&c.IssuedAt, &c.Status, &c.QRCodeURL, &c.ExpiresAt, &c.RevokedAt, &c.RevokedBy, &c.ReissuedFrom,
		&c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateByID: %w", err)
	}
	return c, nil
}

func (r *repository) GetCertificateByNumber(ctx context.Context, number string) (*Certificate, error) {
	query := `SELECT id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number,
	                 issued_at, status, qr_code_url, expires_at, revoked_at, revoked_by, reissued_from, created_at, updated_at
	          FROM credentialing.student_certificates WHERE certificate_number = $1`

	c := &Certificate{}
	err := r.pool.QueryRow(ctx, query, number).Scan(
		&c.ID, &c.EnrollmentID, &c.CertificateTypeID, &c.CertificateConfigID, &c.CertificateNumber,
		&c.IssuedAt, &c.Status, &c.QRCodeURL, &c.ExpiresAt, &c.RevokedAt, &c.RevokedBy, &c.ReissuedFrom,
		&c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateByNumber: %w", err)
	}
	return c, nil
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
	query := `SELECT id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number,
	                 issued_at, status, qr_code_url, expires_at, revoked_at, revoked_by, reissued_from, created_at, updated_at
	          FROM credentialing.student_certificates WHERE enrollment_id = $1`

	rows, err := r.pool.Query(ctx, query, enrollmentID)
	if err != nil {
		return nil, fmt.Errorf("credentialing.ListCertificatesByEnrollment: %w", err)
	}
	defer rows.Close()

	var certs []*Certificate
	for rows.Next() {
		c := &Certificate{}
		if err := rows.Scan(
			&c.ID, &c.EnrollmentID, &c.CertificateTypeID, &c.CertificateConfigID, &c.CertificateNumber,
			&c.IssuedAt, &c.Status, &c.QRCodeURL, &c.ExpiresAt, &c.RevokedAt, &c.RevokedBy, &c.ReissuedFrom,
			&c.CreatedAt, &c.UpdatedAt,
		); err != nil {
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
