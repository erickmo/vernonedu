package database

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
)

type CertificateRepository struct {
	db *sqlx.DB
}

func NewCertificateRepository(db *sqlx.DB) *CertificateRepository {
	return &CertificateRepository{db: db}
}

// ---- row types ----

type certTemplateRow struct {
	ID           string          `db:"id"`
	Name         string          `db:"name"`
	Type         string          `db:"type"`
	TemplateData json.RawMessage `db:"template_data"`
	IsActive     bool            `db:"is_active"`
	CreatedAt    time.Time       `db:"created_at"`
	UpdatedAt    time.Time       `db:"updated_at"`
}

func (row *certTemplateRow) toDomain() (*certificate.CertificateTemplate, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse template id: %w", err)
	}
	var templateData map[string]interface{}
	if err := json.Unmarshal(row.TemplateData, &templateData); err != nil {
		templateData = map[string]interface{}{}
	}
	return &certificate.CertificateTemplate{
		ID:           id,
		Name:         row.Name,
		Type:         certificate.CertType(row.Type),
		TemplateData: templateData,
		IsActive:     row.IsActive,
		CreatedAt:    row.CreatedAt,
		UpdatedAt:    row.UpdatedAt,
	}, nil
}

type certRow struct {
	ID               string         `db:"id"`
	TemplateID       sql.NullString `db:"template_id"`
	StudentID        sql.NullString `db:"student_id"`
	BatchID          sql.NullString `db:"batch_id"`
	CourseID         sql.NullString `db:"course_id"`
	Type             string         `db:"type"`
	CertificateCode  string         `db:"certificate_code"`
	QRCodeURL        string         `db:"qr_code_url"`
	Status           string         `db:"status"`
	RevokedAt        sql.NullTime   `db:"revoked_at"`
	RevocationReason sql.NullString `db:"revocation_reason"`
	IssuedAt         time.Time      `db:"issued_at"`
	CreatedAt        time.Time      `db:"created_at"`
	UpdatedAt        time.Time      `db:"updated_at"`
}

func (row *certRow) toDomain() (*certificate.Certificate, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse certificate id: %w", err)
	}

	c := &certificate.Certificate{
		ID:              id,
		Type:            certificate.CertType(row.Type),
		CertificateCode: row.CertificateCode,
		QRCodeURL:       row.QRCodeURL,
		Status:          certificate.Status(row.Status),
		IssuedAt:        row.IssuedAt,
		CreatedAt:       row.CreatedAt,
		UpdatedAt:       row.UpdatedAt,
	}

	if row.TemplateID.Valid {
		tid, err := uuid.Parse(row.TemplateID.String)
		if err == nil {
			c.TemplateID = &tid
		}
	}
	if row.StudentID.Valid {
		sid, err := uuid.Parse(row.StudentID.String)
		if err == nil {
			c.StudentID = &sid
		}
	}
	if row.BatchID.Valid {
		bid, err := uuid.Parse(row.BatchID.String)
		if err == nil {
			c.BatchID = &bid
		}
	}
	if row.CourseID.Valid {
		cid, err := uuid.Parse(row.CourseID.String)
		if err == nil {
			c.CourseID = &cid
		}
	}
	if row.RevokedAt.Valid {
		t := row.RevokedAt.Time
		c.RevokedAt = &t
	}
	if row.RevocationReason.Valid {
		c.RevocationReason = row.RevocationReason.String
	}

	return c, nil
}

// ---- WriteRepository ----

func (r *CertificateRepository) SaveTemplate(ctx context.Context, t *certificate.CertificateTemplate) error {
	data, err := json.Marshal(t.TemplateData)
	if err != nil {
		return fmt.Errorf("failed to marshal template data: %w", err)
	}
	query := `
		INSERT INTO certificate_templates (id, name, type, template_data, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err = r.db.ExecContext(ctx, query,
		t.ID.String(), t.Name, string(t.Type), string(data), t.IsActive, t.CreatedAt, t.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save certificate template: %w", err)
	}
	return nil
}

func (r *CertificateRepository) UpdateTemplate(ctx context.Context, t *certificate.CertificateTemplate) error {
	data, err := json.Marshal(t.TemplateData)
	if err != nil {
		return fmt.Errorf("failed to marshal template data: %w", err)
	}
	query := `
		UPDATE certificate_templates
		SET name=$1, template_data=$2, is_active=$3, updated_at=$4
		WHERE id=$5
	`
	_, err = r.db.ExecContext(ctx, query,
		t.Name, string(data), t.IsActive, t.UpdatedAt, t.ID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to update certificate template: %w", err)
	}
	return nil
}

func (r *CertificateRepository) Save(ctx context.Context, c *certificate.Certificate) error {
	var templateID, studentID, batchID, courseID interface{}
	if c.TemplateID != nil {
		templateID = c.TemplateID.String()
	}
	if c.StudentID != nil {
		studentID = c.StudentID.String()
	}
	if c.BatchID != nil {
		batchID = c.BatchID.String()
	}
	if c.CourseID != nil {
		courseID = c.CourseID.String()
	}

	query := `
		INSERT INTO certificates (id, template_id, student_id, batch_id, course_id, type, certificate_code, qr_code_url, status, issued_at, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		c.ID.String(), templateID, studentID, batchID, courseID,
		string(c.Type), c.CertificateCode, c.QRCodeURL, string(c.Status),
		c.IssuedAt, c.CreatedAt, c.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save certificate: %w", err)
	}
	return nil
}

func (r *CertificateRepository) Revoke(ctx context.Context, id uuid.UUID, reason string, revokedAt time.Time) error {
	query := `
		UPDATE certificates
		SET status='revoked', revoked_at=$1, revocation_reason=$2, updated_at=$3
		WHERE id=$4
	`
	_, err := r.db.ExecContext(ctx, query, revokedAt, reason, time.Now(), id.String())
	if err != nil {
		return fmt.Errorf("failed to revoke certificate: %w", err)
	}
	return nil
}

// ---- ReadRepository ----

func (r *CertificateRepository) GetTemplateByID(ctx context.Context, id uuid.UUID) (*certificate.CertificateTemplate, error) {
	var row certTemplateRow
	query := `SELECT id, name, type, template_data, is_active, created_at, updated_at FROM certificate_templates WHERE id=$1`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get certificate template: %w", err)
	}
	return row.toDomain()
}

func (r *CertificateRepository) ListTemplates(ctx context.Context) ([]*certificate.CertificateTemplate, error) {
	var rows []certTemplateRow
	query := `SELECT id, name, type, template_data, is_active, created_at, updated_at FROM certificate_templates ORDER BY created_at DESC`
	if err := r.db.SelectContext(ctx, &rows, query); err != nil {
		return nil, fmt.Errorf("failed to list certificate templates: %w", err)
	}

	templates := make([]*certificate.CertificateTemplate, 0, len(rows))
	for _, row := range rows {
		t, err := row.toDomain()
		if err != nil {
			return nil, err
		}
		templates = append(templates, t)
	}
	return templates, nil
}

func (r *CertificateRepository) GetByID(ctx context.Context, id uuid.UUID) (*certificate.Certificate, error) {
	var row certRow
	query := `
		SELECT id, template_id, student_id, batch_id, course_id, type, certificate_code, qr_code_url, status, revoked_at, revocation_reason, issued_at, created_at, updated_at
		FROM certificates WHERE id=$1
	`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get certificate: %w", err)
	}
	return row.toDomain()
}

func (r *CertificateRepository) GetByCode(ctx context.Context, code string) (*certificate.Certificate, error) {
	var row certRow
	query := `
		SELECT id, template_id, student_id, batch_id, course_id, type, certificate_code, qr_code_url, status, revoked_at, revocation_reason, issued_at, created_at, updated_at
		FROM certificates WHERE certificate_code=$1
	`
	if err := r.db.GetContext(ctx, &row, query, code); err != nil {
		return nil, fmt.Errorf("failed to get certificate by code: %w", err)
	}
	return row.toDomain()
}

func (r *CertificateRepository) List(ctx context.Context, studentID, batchID *uuid.UUID, certType, status string, offset, limit int) ([]*certificate.Certificate, int, error) {
	args := []interface{}{}
	conditions := []string{}
	argIdx := 1

	if studentID != nil {
		conditions = append(conditions, fmt.Sprintf("student_id=$%d", argIdx))
		args = append(args, studentID.String())
		argIdx++
	}
	if batchID != nil {
		conditions = append(conditions, fmt.Sprintf("batch_id=$%d", argIdx))
		args = append(args, batchID.String())
		argIdx++
	}
	if certType != "" {
		conditions = append(conditions, fmt.Sprintf("type=$%d", argIdx))
		args = append(args, certType)
		argIdx++
	}
	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status=$%d", argIdx))
		args = append(args, status)
		argIdx++
	}

	where := ""
	if len(conditions) > 0 {
		where = "WHERE "
		for i, c := range conditions {
			if i > 0 {
				where += " AND "
			}
			where += c
		}
	}

	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM certificates %s", where)
	var total int
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count certificates: %w", err)
	}

	args = append(args, limit, offset)
	listQuery := fmt.Sprintf(`
		SELECT id, template_id, student_id, batch_id, course_id, type, certificate_code, qr_code_url, status, revoked_at, revocation_reason, issued_at, created_at, updated_at
		FROM certificates %s
		ORDER BY issued_at DESC
		LIMIT $%d OFFSET $%d
	`, where, argIdx, argIdx+1)

	var rows []certRow
	if err := r.db.SelectContext(ctx, &rows, listQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to list certificates: %w", err)
	}

	certs := make([]*certificate.Certificate, 0, len(rows))
	for _, row := range rows {
		c, err := row.toDomain()
		if err != nil {
			return nil, 0, err
		}
		certs = append(certs, c)
	}
	return certs, total, nil
}
