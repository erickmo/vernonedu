package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
)

type PartnerRepository struct {
	db *sqlx.DB
}

func NewPartnerRepository(db *sqlx.DB) *PartnerRepository {
	return &PartnerRepository{db: db}
}

type partnerRecord struct {
	ID            uuid.UUID  `db:"id"`
	Name          string     `db:"name"`
	Industry      string     `db:"industry"`
	Address       string     `db:"address"`
	ContactPerson string     `db:"contact_person"`
	ContactEmail  string     `db:"contact_email"`
	ContactPhone  string     `db:"contact_phone"`
	Website       string     `db:"website"`
	LogoURL       string     `db:"logo_url"`
	GroupID       *uuid.UUID `db:"group_id"`
	GroupName     string     `db:"group_name"`
	Status        string     `db:"status"`
	PartnerSince  *time.Time `db:"partner_since"`
	Notes         string     `db:"notes"`
	CreatedAt     time.Time  `db:"created_at"`
	UpdatedAt     time.Time  `db:"updated_at"`
}

func (rec *partnerRecord) toDomain() *partner.Partner {
	return &partner.Partner{
		ID:            rec.ID,
		Name:          rec.Name,
		Industry:      rec.Industry,
		Address:       rec.Address,
		ContactPerson: rec.ContactPerson,
		ContactEmail:  rec.ContactEmail,
		ContactPhone:  rec.ContactPhone,
		Website:       rec.Website,
		LogoURL:       rec.LogoURL,
		GroupID:       rec.GroupID,
		GroupName:     rec.GroupName,
		Status:        rec.Status,
		PartnerSince:  rec.PartnerSince,
		Notes:         rec.Notes,
		CreatedAt:     rec.CreatedAt,
		UpdatedAt:     rec.UpdatedAt,
	}
}

type partnerGroupRecord struct {
	ID          uuid.UUID `db:"id"`
	Name        string    `db:"name"`
	Description string    `db:"description"`
	CreatedAt   time.Time `db:"created_at"`
	UpdatedAt   time.Time `db:"updated_at"`
}

type mouRecord struct {
	ID             uuid.UUID `db:"id"`
	PartnerID      uuid.UUID `db:"partner_id"`
	PartnerName    string    `db:"partner_name"`
	DocumentNumber string    `db:"document_number"`
	Title          string    `db:"title"`
	StartDate      string    `db:"start_date"`
	EndDate        string    `db:"end_date"`
	Status         string    `db:"status"`
	DocumentURL    string    `db:"document_url"`
	Notes          string    `db:"notes"`
	CreatedAt      time.Time `db:"created_at"`
	UpdatedAt      time.Time `db:"updated_at"`
}

type partnershipLogRecord struct {
	ID         uuid.UUID `db:"id"`
	PartnerID  uuid.UUID `db:"partner_id"`
	LogDate    string    `db:"log_date"`
	EntityName string    `db:"entity_name"`
	EntityType string    `db:"entity_type"`
	Status     string    `db:"status"`
	Notes      string    `db:"notes"`
	CreatedAt  time.Time `db:"created_at"`
	UpdatedAt  time.Time `db:"updated_at"`
}

type partnerStatsRecord struct {
	ActiveCount      int `db:"active_count"`
	ExpiringCount    int `db:"expiring_count"`
	NegotiatingCount int `db:"negotiating_count"`
	UncontactedCount int `db:"uncontacted_count"`
}

func (r *PartnerRepository) Save(ctx context.Context, p *partner.Partner) error {
	query := `
		INSERT INTO partners (id, name, industry, address, contact_person, contact_email, contact_phone, website, logo_url, group_id, group_name, status, partner_since, notes, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
	`
	_, err := r.db.ExecContext(ctx, query,
		p.ID, p.Name, p.Industry, p.Address, p.ContactPerson, p.ContactEmail, p.ContactPhone,
		p.Website, p.LogoURL, p.GroupID, p.GroupName, p.Status, p.PartnerSince, p.Notes,
		p.CreatedAt, p.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save partner: %w", err)
	}
	return nil
}

func (r *PartnerRepository) Update(ctx context.Context, p *partner.Partner) error {
	query := `
		UPDATE partners SET name=$1, industry=$2, address=$3, contact_person=$4, contact_email=$5,
		contact_phone=$6, website=$7, logo_url=$8, group_id=$9, group_name=$10, status=$11,
		partner_since=$12, notes=$13, updated_at=$14
		WHERE id=$15
	`
	_, err := r.db.ExecContext(ctx, query,
		p.Name, p.Industry, p.Address, p.ContactPerson, p.ContactEmail, p.ContactPhone,
		p.Website, p.LogoURL, p.GroupID, p.GroupName, p.Status, p.PartnerSince, p.Notes,
		time.Now(), p.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update partner: %w", err)
	}
	return nil
}

func (r *PartnerRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM partners WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("failed to delete partner: %w", err)
	}
	return nil
}

func (r *PartnerRepository) SaveGroup(ctx context.Context, g *partner.PartnerGroup) error {
	query := `
		INSERT INTO partner_groups (id, name, description, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err := r.db.ExecContext(ctx, query, g.ID, g.Name, g.Description, g.CreatedAt, g.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save partner group: %w", err)
	}
	return nil
}

func (r *PartnerRepository) SaveMOU(ctx context.Context, m *partner.MOU) error {
	query := `
		INSERT INTO mous (id, partner_id, document_number, title, start_date, end_date, status, document_url, notes, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`
	_, err := r.db.ExecContext(ctx, query,
		m.ID, m.PartnerID, m.DocumentNumber, m.Title, m.StartDate, m.EndDate,
		m.Status, m.DocumentURL, m.Notes, m.CreatedAt, m.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save MOU: %w", err)
	}
	return nil
}

func (r *PartnerRepository) UpdateMOU(ctx context.Context, m *partner.MOU) error {
	query := `
		UPDATE mous SET document_number=$1, title=$2, start_date=$3, end_date=$4, status=$5,
		document_url=$6, notes=$7, updated_at=$8
		WHERE id=$9
	`
	_, err := r.db.ExecContext(ctx, query,
		m.DocumentNumber, m.Title, m.StartDate, m.EndDate, m.Status,
		m.DocumentURL, m.Notes, time.Now(), m.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update MOU: %w", err)
	}
	return nil
}

func (r *PartnerRepository) DeleteMOU(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM mous WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("failed to delete MOU: %w", err)
	}
	return nil
}

func (r *PartnerRepository) UpdateGroup(ctx context.Context, g *partner.PartnerGroup) error {
	query := `
		UPDATE partner_groups SET name=$1, description=$2, updated_at=$3
		WHERE id=$4
	`
	_, err := r.db.ExecContext(ctx, query, g.Name, g.Description, time.Now(), g.ID)
	if err != nil {
		return fmt.Errorf("failed to update partner group: %w", err)
	}
	return nil
}

func (r *PartnerRepository) DeleteGroup(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM partner_groups WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("failed to delete partner group: %w", err)
	}
	return nil
}

func (r *PartnerRepository) SaveLog(ctx context.Context, l *partner.PartnershipLog) error {
	query := `
		INSERT INTO partnership_logs (id, partner_id, log_date, entity_name, entity_type, status, notes, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.db.ExecContext(ctx, query,
		l.ID, l.PartnerID, l.LogDate, l.EntityName, l.EntityType, l.Status, l.Notes,
		l.CreatedAt, l.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save partnership log: %w", err)
	}
	return nil
}

func (r *PartnerRepository) GetByID(ctx context.Context, id uuid.UUID) (*partner.Partner, error) {
	var rec partnerRecord
	query := `
		SELECT p.id, p.name, p.industry, p.address, p.contact_person, p.contact_email, p.contact_phone,
		       p.website, p.logo_url, p.group_id, COALESCE(pg.name, '') AS group_name, p.status,
		       p.partner_since, p.notes, p.created_at, p.updated_at
		FROM partners p
		LEFT JOIN partner_groups pg ON pg.id = p.group_id
		WHERE p.id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get partner: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *PartnerRepository) List(ctx context.Context, offset, limit int, status string) ([]*partner.Partner, int, error) {
	var total int
	countArgs := []interface{}{}
	countQuery := `SELECT COUNT(*) FROM partners`
	if status != "" {
		countQuery += ` WHERE status = $1`
		countArgs = append(countArgs, status)
	}
	if err := r.db.GetContext(ctx, &total, countQuery, countArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to count partners: %w", err)
	}

	var recs []partnerRecord
	var listQuery string
	var listArgs []interface{}
	if status != "" {
		listQuery = `
			SELECT p.id, p.name, p.industry, p.address, p.contact_person, p.contact_email, p.contact_phone,
			       p.website, p.logo_url, p.group_id, COALESCE(pg.name, '') AS group_name, p.status,
			       p.partner_since, p.notes, p.created_at, p.updated_at
			FROM partners p
			LEFT JOIN partner_groups pg ON pg.id = p.group_id
			WHERE p.status = $1
			ORDER BY p.created_at DESC
			LIMIT $2 OFFSET $3
		`
		listArgs = []interface{}{status, limit, offset}
	} else {
		listQuery = `
			SELECT p.id, p.name, p.industry, p.address, p.contact_person, p.contact_email, p.contact_phone,
			       p.website, p.logo_url, p.group_id, COALESCE(pg.name, '') AS group_name, p.status,
			       p.partner_since, p.notes, p.created_at, p.updated_at
			FROM partners p
			LEFT JOIN partner_groups pg ON pg.id = p.group_id
			ORDER BY p.created_at DESC
			LIMIT $1 OFFSET $2
		`
		listArgs = []interface{}{limit, offset}
	}
	if err := r.db.SelectContext(ctx, &recs, listQuery, listArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list partners: %w", err)
	}

	partners := make([]*partner.Partner, len(recs))
	for i, rec := range recs {
		partners[i] = rec.toDomain()
	}
	return partners, total, nil
}

func (r *PartnerRepository) ListGroups(ctx context.Context) ([]*partner.PartnerGroup, error) {
	var recs []partnerGroupRecord
	if err := r.db.SelectContext(ctx, &recs, `SELECT id, name, COALESCE(description, '') AS description, created_at, updated_at FROM partner_groups ORDER BY name ASC`); err != nil {
		return nil, fmt.Errorf("failed to list partner groups: %w", err)
	}
	groups := make([]*partner.PartnerGroup, len(recs))
	for i, rec := range recs {
		groups[i] = &partner.PartnerGroup{
			ID:          rec.ID,
			Name:        rec.Name,
			Description: rec.Description,
			CreatedAt:   rec.CreatedAt,
			UpdatedAt:   rec.UpdatedAt,
		}
	}
	return groups, nil
}

func (r *PartnerRepository) ListMOUs(ctx context.Context, partnerID uuid.UUID) ([]*partner.MOU, error) {
	var recs []mouRecord
	query := `
		SELECT id, partner_id, '' AS partner_name, document_number, COALESCE(title, '') AS title,
		       start_date::text, end_date::text, COALESCE(status, 'active') AS status,
		       COALESCE(document_url, '') AS document_url, notes, created_at, updated_at
		FROM mous WHERE partner_id = $1 ORDER BY start_date DESC
	`
	if err := r.db.SelectContext(ctx, &recs, query, partnerID); err != nil {
		return nil, fmt.Errorf("failed to list MOUs: %w", err)
	}
	mous := make([]*partner.MOU, len(recs))
	for i, rec := range recs {
		mous[i] = mouRecordToDomain(rec)
	}
	return mous, nil
}

func (r *PartnerRepository) GetMOUByID(ctx context.Context, id uuid.UUID) (*partner.MOU, error) {
	var rec mouRecord
	query := `
		SELECT id, partner_id, '' AS partner_name, document_number, COALESCE(title, '') AS title,
		       start_date::text, end_date::text, COALESCE(status, 'active') AS status,
		       COALESCE(document_url, '') AS document_url, notes, created_at, updated_at
		FROM mous WHERE id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get MOU: %w", err)
	}
	return mouRecordToDomain(rec), nil
}

func (r *PartnerRepository) ListExpiringMOUs(ctx context.Context, withinMonths int) ([]*partner.MOU, error) {
	var recs []mouRecord
	query := `
		SELECT m.id, m.partner_id, COALESCE(p.name, '') AS partner_name,
		       m.document_number, COALESCE(m.title, '') AS title,
		       m.start_date::text, m.end_date::text,
		       COALESCE(m.status, 'active') AS status,
		       COALESCE(m.document_url, '') AS document_url,
		       m.notes, m.created_at, m.updated_at
		FROM mous m
		JOIN partners p ON p.id = m.partner_id
		WHERE m.end_date <= CURRENT_DATE + ($1 * INTERVAL '1 month')
		  AND m.end_date >= CURRENT_DATE
		  AND COALESCE(m.status, 'active') = 'active'
		ORDER BY m.end_date ASC
	`
	if err := r.db.SelectContext(ctx, &recs, query, withinMonths); err != nil {
		return nil, fmt.Errorf("failed to list expiring MOUs: %w", err)
	}
	mous := make([]*partner.MOU, len(recs))
	for i, rec := range recs {
		mous[i] = mouRecordToDomain(rec)
	}
	return mous, nil
}

func mouRecordToDomain(rec mouRecord) *partner.MOU {
	return &partner.MOU{
		ID:             rec.ID,
		PartnerID:      rec.PartnerID,
		PartnerName:    rec.PartnerName,
		DocumentNumber: rec.DocumentNumber,
		Title:          rec.Title,
		StartDate:      rec.StartDate,
		EndDate:        rec.EndDate,
		Status:         rec.Status,
		DocumentURL:    rec.DocumentURL,
		Notes:          rec.Notes,
		CreatedAt:      rec.CreatedAt,
		UpdatedAt:      rec.UpdatedAt,
	}
}

func (r *PartnerRepository) ListLogs(ctx context.Context, partnerID uuid.UUID) ([]*partner.PartnershipLog, error) {
	var recs []partnershipLogRecord
	query := `
		SELECT id, partner_id, log_date::text, entity_name, entity_type, status, notes, created_at, updated_at
		FROM partnership_logs WHERE partner_id = $1 ORDER BY log_date DESC
	`
	if err := r.db.SelectContext(ctx, &recs, query, partnerID); err != nil {
		return nil, fmt.Errorf("failed to list partnership logs: %w", err)
	}
	logs := make([]*partner.PartnershipLog, len(recs))
	for i, rec := range recs {
		logs[i] = &partner.PartnershipLog{
			ID:         rec.ID,
			PartnerID:  rec.PartnerID,
			LogDate:    rec.LogDate,
			EntityName: rec.EntityName,
			EntityType: rec.EntityType,
			Status:     rec.Status,
			Notes:      rec.Notes,
			CreatedAt:  rec.CreatedAt,
			UpdatedAt:  rec.UpdatedAt,
		}
	}
	return logs, nil
}

func (r *PartnerRepository) Stats(ctx context.Context) (*partner.PartnerStats, error) {
	var rec partnerStatsRecord
	query := `
		SELECT
		  COUNT(CASE WHEN status = 'active' THEN 1 END) AS active_count,
		  COUNT(CASE WHEN status = 'negotiating' THEN 1 END) AS negotiating_count,
		  COUNT(CASE WHEN status = 'prospect' THEN 1 END) AS uncontacted_count,
		  COUNT(CASE WHEN status = 'active' AND id IN (
		    SELECT partner_id FROM mous WHERE end_date <= CURRENT_DATE + INTERVAL '90 days' AND end_date >= CURRENT_DATE
		  ) THEN 1 END) AS expiring_count
		FROM partners
	`
	if err := r.db.GetContext(ctx, &rec, query); err != nil {
		return nil, fmt.Errorf("failed to get partner stats: %w", err)
	}
	return &partner.PartnerStats{
		ActiveCount:      rec.ActiveCount,
		ExpiringCount:    rec.ExpiringCount,
		NegotiatingCount: rec.NegotiatingCount,
		UncontactedCount: rec.UncontactedCount,
	}, nil
}
