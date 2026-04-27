package credentialing

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// pgUniqueViolation is the SQLSTATE code for unique constraint violations.
const pgUniqueViolation = "23505"

// Repository defines credentialing data access.
type Repository interface {
	CreateCertificateType(ctx context.Context, ct *CertificateType) error
	GetCertificateTypeByID(ctx context.Context, id uuid.UUID) (*CertificateType, error)
	ListActiveCertificateTypes(ctx context.Context) ([]*CertificateType, error)
	DeactivateCertificateType(ctx context.Context, id uuid.UUID) error

	CreateCertificateConfig(ctx context.Context, cc *CertificateConfig) error
	GetCertificateConfigByID(ctx context.Context, id uuid.UUID) (*CertificateConfig, error)
	GetCertificateConfigByCourse(ctx context.Context, courseID uuid.UUID) ([]*CertificateConfig, error)

	CreateCertificate(ctx context.Context, c *Certificate) error
	GetCertificateByID(ctx context.Context, id uuid.UUID) (*Certificate, error)
	GetCertificateByNumber(ctx context.Context, number string) (*Certificate, error)
	UpdateCertificateStatus(ctx context.Context, id uuid.UUID, status CertStatus) error
	ListCertificatesByEnrollment(ctx context.Context, enrollmentID uuid.UUID) ([]*Certificate, error)

	// ListExpiringCertificates returns issued certificates whose expires_at
	// falls within [today, today + days]. Used by the daily expiry-flag worker.
	ListExpiringCertificates(ctx context.Context, days int) ([]*Certificate, error)

	CreateActionRequest(ctx context.Context, req *CertificateActionRequest) error
	GetActionRequestByID(ctx context.Context, id uuid.UUID) (*CertificateActionRequest, error)
	UpdateActionRequestStatus(ctx context.Context, id uuid.UUID, status ActionStatus, approvedBy *uuid.UUID) error

	// RevokeCertificate marks a certificate as revoked, recording revoked_at
	// (now()) and revoked_by. Returns ErrNotFound when the certificate does
	// not exist.
	RevokeCertificate(ctx context.Context, certID, revokerID uuid.UUID) error

	// ReissueCertificate atomically revokes the existing certificate and issues
	// a new one with a freshly allocated number, preserving (enrollment,
	// certificate_type, certificate_config) and setting reissued_from to the
	// old id. Returns the newly issued Certificate.
	ReissueCertificate(ctx context.Context, oldCertID, approverID uuid.UUID) (*Certificate, error)

	NextCertificateNumber(ctx context.Context, year int) (string, error)
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
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgUniqueViolation {
			return apperrors.ErrConflict
		}
		return fmt.Errorf("credentialing.CreateCertificateConfig: %w", err)
	}
	return nil
}

func (r *repository) DeactivateCertificateType(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE credentialing.certificate_types SET is_active=false, updated_at=now() WHERE id=$1`
	ct, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("credentialing.DeactivateCertificateType: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) GetCertificateConfigByID(ctx context.Context, id uuid.UUID) (*CertificateConfig, error) {
	query := `SELECT id, course_id, certificate_type_id, issued_on, created_at, updated_at
	          FROM credentialing.certificate_configs WHERE id = $1`

	cc := &CertificateConfig{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&cc.ID, &cc.CourseID, &cc.CertificateTypeID, &cc.IssuedOn, &cc.CreatedAt, &cc.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.GetCertificateConfigByID: %w", err)
	}
	return cc, nil
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
		  (id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number, status, expires_at, qr_code_url)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING issued_at, created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		c.ID, c.EnrollmentID, c.CertificateTypeID, c.CertificateConfigID, c.CertificateNumber, c.Status, c.ExpiresAt, c.QRCodeURL,
	).Scan(&c.IssuedAt, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgUniqueViolation {
			return apperrors.ErrConflict
		}
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

// ListExpiringCertificates returns issued certificates whose expires_at falls
// within the window [current_date, current_date + days days].
func (r *repository) ListExpiringCertificates(ctx context.Context, days int) ([]*Certificate, error) {
	query := `SELECT id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number,
	                 issued_at, status, qr_code_url, expires_at, revoked_at, revoked_by, reissued_from, created_at, updated_at
	          FROM credentialing.student_certificates
	          WHERE status = 'issued'
	            AND expires_at IS NOT NULL
	            AND expires_at >= current_date
	            AND expires_at <= current_date + ($1 || ' days')::interval
	          ORDER BY expires_at`

	rows, err := r.pool.Query(ctx, query, days)
	if err != nil {
		return nil, fmt.Errorf("credentialing.ListExpiringCertificates: %w", err)
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
			return nil, fmt.Errorf("credentialing.ListExpiringCertificates scan: %w", err)
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

// NextCertificateNumber atomically increments and returns the next per-year
// certificate number, formatted as "VE-YYYY-NNNNN" with zero-padded sequence.
func (r *repository) NextCertificateNumber(ctx context.Context, year int) (string, error) {
	var v int
	err := r.pool.QueryRow(ctx,
		`INSERT INTO credentialing.certificate_number_sequences (year, last_value)
		 VALUES ($1, 1)
		 ON CONFLICT (year) DO UPDATE SET last_value = credentialing.certificate_number_sequences.last_value + 1
		 RETURNING last_value`, year).Scan(&v)
	if err != nil {
		return "", fmt.Errorf("credentialing.NextCertificateNumber: %w", err)
	}
	return fmt.Sprintf("VE-%d-%05d", year, v), nil
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

// RevokeCertificate marks a certificate as revoked, recording revoked_at and
// revoked_by. ErrNotFound when the certificate id does not exist.
func (r *repository) RevokeCertificate(ctx context.Context, certID, revokerID uuid.UUID) error {
	query := `UPDATE credentialing.student_certificates
	          SET status='revoked', revoked_at=now(), revoked_by=$2, updated_at=now()
	          WHERE id=$1`
	ct, err := r.pool.Exec(ctx, query, certID, revokerID)
	if err != nil {
		return fmt.Errorf("credentialing.RevokeCertificate: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// ReissueCertificate atomically revokes the existing certificate and inserts a
// new issued certificate with a freshly allocated number, preserving the
// enrollment/type/config and setting reissued_from to the old id.
func (r *repository) ReissueCertificate(ctx context.Context, oldCertID, approverID uuid.UUID) (*Certificate, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("credentialing.ReissueCertificate begin: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	var (
		enrollmentID, certTypeID, certConfigID uuid.UUID
		expiresAt                              *time.Time
	)
	err = tx.QueryRow(ctx,
		`SELECT enrollment_id, certificate_type_id, certificate_config_id, expires_at
		 FROM credentialing.student_certificates WHERE id=$1 FOR UPDATE`, oldCertID,
	).Scan(&enrollmentID, &certTypeID, &certConfigID, &expiresAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("credentialing.ReissueCertificate select: %w", err)
	}

	if _, err := tx.Exec(ctx,
		`UPDATE credentialing.student_certificates
		 SET status='revoked', revoked_at=now(), revoked_by=$2, updated_at=now()
		 WHERE id=$1`, oldCertID, approverID); err != nil {
		return nil, fmt.Errorf("credentialing.ReissueCertificate revoke old: %w", err)
	}

	year := time.Now().UTC().Year()
	var seq int
	err = tx.QueryRow(ctx,
		`INSERT INTO credentialing.certificate_number_sequences (year, last_value)
		 VALUES ($1, 1)
		 ON CONFLICT (year) DO UPDATE SET last_value = credentialing.certificate_number_sequences.last_value + 1
		 RETURNING last_value`, year).Scan(&seq)
	if err != nil {
		return nil, fmt.Errorf("credentialing.ReissueCertificate seq: %w", err)
	}
	number := fmt.Sprintf("VE-%d-%05d", year, seq)
	qrURL := verifyEndpointPrefix + number
	newID := uuid.New()

	newCert := &Certificate{
		ID:                  newID,
		EnrollmentID:        enrollmentID,
		CertificateTypeID:   certTypeID,
		CertificateConfigID: certConfigID,
		CertificateNumber:   number,
		Status:              CertIssued,
		QRCodeURL:           &qrURL,
		ExpiresAt:           expiresAt,
		ReissuedFrom:        &oldCertID,
	}
	err = tx.QueryRow(ctx,
		`INSERT INTO credentialing.student_certificates
		   (id, enrollment_id, certificate_type_id, certificate_config_id,
		    certificate_number, status, qr_code_url, expires_at, reissued_from)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		 RETURNING issued_at, created_at, updated_at`,
		newCert.ID, newCert.EnrollmentID, newCert.CertificateTypeID, newCert.CertificateConfigID,
		newCert.CertificateNumber, newCert.Status, newCert.QRCodeURL, newCert.ExpiresAt, newCert.ReissuedFrom,
	).Scan(&newCert.IssuedAt, &newCert.CreatedAt, &newCert.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("credentialing.ReissueCertificate insert new: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("credentialing.ReissueCertificate commit: %w", err)
	}
	return newCert, nil
}
