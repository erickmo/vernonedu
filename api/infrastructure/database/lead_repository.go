package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadRepository struct {
	db *sqlx.DB
}

func NewLeadRepository(db *sqlx.DB) *LeadRepository {
	return &LeadRepository{db: db}
}

type leadRow struct {
	ID        string         `db:"id"`
	Name      string         `db:"name"`
	Email     string         `db:"email"`
	Phone     string         `db:"phone"`
	SourceID  sql.NullString `db:"source_id"`
	Notes     string         `db:"notes"`
	Status    string         `db:"status"`
	PicID     sql.NullString `db:"pic_id"`
	CreatedAt time.Time      `db:"created_at"`
	UpdatedAt time.Time      `db:"updated_at"`
}

func (row *leadRow) toDomain() (*lead.Lead, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse lead id: %w", err)
	}

	var sourceID *uuid.UUID
	if row.SourceID.Valid && row.SourceID.String != "" {
		parsed, err := uuid.Parse(row.SourceID.String)
		if err != nil {
			return nil, fmt.Errorf("failed to parse lead source_id: %w", err)
		}
		sourceID = &parsed
	}

	var picID *uuid.UUID
	if row.PicID.Valid && row.PicID.String != "" {
		parsed, err := uuid.Parse(row.PicID.String)
		if err != nil {
			return nil, fmt.Errorf("failed to parse lead pic_id: %w", err)
		}
		picID = &parsed
	}

	return &lead.Lead{
		ID:        id,
		Name:      row.Name,
		Email:     row.Email,
		Phone:     row.Phone,
		SourceID:  sourceID,
		Notes:     row.Notes,
		Status:    row.Status,
		PicID:     picID,
		CreatedAt: row.CreatedAt,
		UpdatedAt: row.UpdatedAt,
	}, nil
}

func (r *LeadRepository) Save(ctx context.Context, l *lead.Lead) error {
	var sourceID, picID any
	if l.SourceID != nil {
		sourceID = l.SourceID.String()
	}
	if l.PicID != nil {
		picID = l.PicID.String()
	}
	query := `
		INSERT INTO leads (id, name, email, phone, source_id, notes, status, pic_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err := r.db.ExecContext(ctx, query,
		l.ID.String(), l.Name, l.Email, l.Phone, sourceID, l.Notes, l.Status, picID,
		l.CreatedAt, l.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) Update(ctx context.Context, l *lead.Lead) error {
	var sourceID, picID any
	if l.SourceID != nil {
		sourceID = l.SourceID.String()
	}
	if l.PicID != nil {
		picID = l.PicID.String()
	}
	query := `
		UPDATE leads
		SET name=$1, email=$2, phone=$3, source_id=$4, notes=$5, status=$6, pic_id=$7, updated_at=$8
		WHERE id=$9
	`
	_, err := r.db.ExecContext(ctx, query,
		l.Name, l.Email, l.Phone, sourceID, l.Notes, l.Status, picID, l.UpdatedAt,
		l.ID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to update lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM leads WHERE id=$1`, id.String())
	if err != nil {
		return fmt.Errorf("failed to delete lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) GetByID(ctx context.Context, id uuid.UUID) (*lead.Lead, error) {
	var row leadRow
	query := `SELECT id, name, email, phone, source_id, notes, status, pic_id, created_at, updated_at FROM leads WHERE id=$1`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get lead: %w", err)
	}
	return row.toDomain()
}

var leadListSortCols = map[string]string{
	"name":       "name",
	"status":     "status",
	"created_at": "created_at",
	"updated_at": "updated_at",
}

func (r *LeadRepository) List(ctx context.Context, offset, limit int, status, sourceID, search, sortBy, sortDir string) ([]*lead.Lead, int, error) {
	searchPattern := ""
	if search != "" {
		searchPattern = "%" + search + "%"
	}

	var total int
	countQuery := `
		SELECT COUNT(*) FROM leads
		WHERE ($1='' OR status=$1)
		AND ($2='' OR source_id::text=$2)
		AND ($3='' OR name ILIKE $3)
	`
	if err := r.db.GetContext(ctx, &total, countQuery, status, sourceID, searchPattern); err != nil {
		return nil, 0, fmt.Errorf("failed to count leads: %w", err)
	}

	var rows []leadRow
	orderBy := buildOrderBy(sortBy, sortDir, leadListSortCols, "created_at DESC")
	query := fmt.Sprintf(`
		SELECT id, name, email, phone, source_id, notes, status, pic_id, created_at, updated_at
		FROM leads
		WHERE ($1='' OR status=$1)
		AND ($2='' OR source_id::text=$2)
		AND ($3='' OR name ILIKE $3)
		%s
		LIMIT $4 OFFSET $5
	`, orderBy)
	if err := r.db.SelectContext(ctx, &rows, query, status, sourceID, searchPattern, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list leads: %w", err)
	}

	leads := make([]*lead.Lead, 0, len(rows))
	for _, row := range rows {
		l, err := row.toDomain()
		if err != nil {
			return nil, 0, err
		}
		leads = append(leads, l)
	}
	return leads, total, nil
}

// ─── CRM Logs ──────────────────────────────────────────────────────────────

type leadCrmLogRow struct {
	ID            string       `db:"id"`
	LeadID        string       `db:"lead_id"`
	ContactedByID string       `db:"contacted_by_id"`
	ContactMethod string       `db:"contact_method"`
	Response      string       `db:"response"`
	FollowUpDate  sql.NullTime `db:"follow_up_date"`
	CreatedAt     time.Time    `db:"created_at"`
}

func (row *leadCrmLogRow) toDomain() (*lead.CrmLog, error) {
	id, _ := uuid.Parse(row.ID)
	leadID, _ := uuid.Parse(row.LeadID)
	contactedByID, _ := uuid.Parse(row.ContactedByID)

	var followUpDate *time.Time
	if row.FollowUpDate.Valid {
		t := row.FollowUpDate.Time
		followUpDate = &t
	}

	return &lead.CrmLog{
		ID:            id,
		LeadID:        leadID,
		ContactedByID: contactedByID,
		ContactMethod: row.ContactMethod,
		Response:      row.Response,
		FollowUpDate:  followUpDate,
		CreatedAt:     row.CreatedAt,
	}, nil
}

func (r *LeadRepository) SaveCrmLog(ctx context.Context, l *lead.CrmLog) error {
	var followUpDate any
	if l.FollowUpDate != nil {
		followUpDate = *l.FollowUpDate
	}
	query := `
		INSERT INTO lead_crm_logs (id, lead_id, contacted_by_id, contact_method, response, follow_up_date, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := r.db.ExecContext(ctx, query,
		l.ID.String(), l.LeadID.String(), l.ContactedByID.String(),
		l.ContactMethod, l.Response, followUpDate, l.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save crm log: %w", err)
	}
	return nil
}

func (r *LeadRepository) ListCrmLogs(ctx context.Context, leadID uuid.UUID) ([]*lead.CrmLog, error) {
	var rows []leadCrmLogRow
	query := `
		SELECT id, lead_id, contacted_by_id, contact_method, response, follow_up_date, created_at
		FROM lead_crm_logs
		WHERE lead_id=$1
		ORDER BY created_at DESC
	`
	if err := r.db.SelectContext(ctx, &rows, query, leadID.String()); err != nil {
		return nil, fmt.Errorf("failed to list crm logs: %w", err)
	}

	logs := make([]*lead.CrmLog, 0, len(rows))
	for _, row := range rows {
		l, err := row.toDomain()
		if err != nil {
			return nil, err
		}
		logs = append(logs, l)
	}
	return logs, nil
}
