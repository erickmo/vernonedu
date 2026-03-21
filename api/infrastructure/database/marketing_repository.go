package database

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
)

type MarketingRepository struct {
	db *sqlx.DB
}

func NewMarketingRepository(db *sqlx.DB) *MarketingRepository {
	return &MarketingRepository{db: db}
}

// ---- DB records ----

type socialMediaPostRecord struct {
	ID          uuid.UUID      `db:"id"`
	Platforms   pq.StringArray `db:"platforms"`
	ScheduledAt time.Time      `db:"scheduled_at"`
	ContentType string         `db:"content_type"`
	Caption     string         `db:"caption"`
	MediaURL    string         `db:"media_url"`
	BatchID     *uuid.UUID     `db:"batch_id"`
	BatchName   string         `db:"batch_name"`
	Status      string         `db:"status"`
	PostURL     string         `db:"post_url"`
	CreatedBy   uuid.UUID      `db:"created_by"`
	CreatedAt   time.Time      `db:"created_at"`
	UpdatedAt   time.Time      `db:"updated_at"`
}

func (rec *socialMediaPostRecord) toDomain() *marketing.SocialMediaPost {
	platforms := []string(rec.Platforms)
	if platforms == nil {
		platforms = []string{}
	}
	return &marketing.SocialMediaPost{
		ID:          rec.ID,
		Platforms:   platforms,
		ScheduledAt: rec.ScheduledAt,
		ContentType: rec.ContentType,
		Caption:     rec.Caption,
		MediaURL:    rec.MediaURL,
		BatchID:     rec.BatchID,
		BatchName:   rec.BatchName,
		Status:      rec.Status,
		PostURL:     rec.PostURL,
		CreatedBy:   rec.CreatedBy,
		CreatedAt:   rec.CreatedAt,
		UpdatedAt:   rec.UpdatedAt,
	}
}

type classDocPostRecord struct {
	ID                uuid.UUID `db:"id"`
	BatchID           uuid.UUID `db:"batch_id"`
	SessionID         uuid.UUID `db:"session_id"`
	ModuleName        string    `db:"module_name"`
	BatchName         string    `db:"batch_name"`
	ClassDate         time.Time `db:"class_date"`
	ScheduledPostDate time.Time `db:"scheduled_post_date"`
	Status            string    `db:"status"`
	PostURL           string    `db:"post_url"`
	CreatedAt         time.Time `db:"created_at"`
	UpdatedAt         time.Time `db:"updated_at"`
}

func (rec *classDocPostRecord) toDomain() *marketing.ClassDocPost {
	return &marketing.ClassDocPost{
		ID:                rec.ID,
		BatchID:           rec.BatchID,
		SessionID:         rec.SessionID,
		ModuleName:        rec.ModuleName,
		BatchName:         rec.BatchName,
		ClassDate:         rec.ClassDate,
		ScheduledPostDate: rec.ScheduledPostDate,
		Status:            rec.Status,
		PostURL:           rec.PostURL,
		CreatedAt:         rec.CreatedAt,
		UpdatedAt:         rec.UpdatedAt,
	}
}

type prScheduleRecord struct {
	ID          uuid.UUID  `db:"id"`
	Title       string     `db:"title"`
	Type        string     `db:"type"`
	ScheduledAt time.Time  `db:"scheduled_at"`
	MediaVenue  string     `db:"media_venue"`
	PicID       *uuid.UUID `db:"pic_id"`
	PicName     string     `db:"pic_name"`
	Status      string     `db:"status"`
	Notes       string     `db:"notes"`
	CreatedAt   time.Time  `db:"created_at"`
	UpdatedAt   time.Time  `db:"updated_at"`
}

func (rec *prScheduleRecord) toDomain() *marketing.PrSchedule {
	return &marketing.PrSchedule{
		ID:          rec.ID,
		Title:       rec.Title,
		Type:        rec.Type,
		ScheduledAt: rec.ScheduledAt,
		MediaVenue:  rec.MediaVenue,
		PicID:       rec.PicID,
		PicName:     rec.PicName,
		Status:      rec.Status,
		Notes:       rec.Notes,
		CreatedAt:   rec.CreatedAt,
		UpdatedAt:   rec.UpdatedAt,
	}
}

type referralPartnerRecord struct {
	ID               uuid.UUID `db:"id"`
	Name             string    `db:"name"`
	ContactEmail     string    `db:"contact_email"`
	ReferralCode     string    `db:"referral_code"`
	CommissionType   string    `db:"commission_type"`
	CommissionValue  float64   `db:"commission_value"`
	IsActive         bool      `db:"is_active"`
	TotalReferrals   int       `db:"total_referrals"`
	TotalEnrolled    int       `db:"total_enrolled"`
	TotalCommission  float64   `db:"total_commission"`
	PendingCommission float64  `db:"pending_commission"`
	CreatedAt        time.Time `db:"created_at"`
	UpdatedAt        time.Time `db:"updated_at"`
}

func (rec *referralPartnerRecord) toDomain() *marketing.ReferralPartner {
	return &marketing.ReferralPartner{
		ID:               rec.ID,
		Name:             rec.Name,
		ContactEmail:     rec.ContactEmail,
		ReferralCode:     rec.ReferralCode,
		CommissionType:   rec.CommissionType,
		CommissionValue:  rec.CommissionValue,
		IsActive:         rec.IsActive,
		TotalReferrals:   rec.TotalReferrals,
		TotalEnrolled:    rec.TotalEnrolled,
		TotalCommission:  rec.TotalCommission,
		PendingCommission: rec.PendingCommission,
		CreatedAt:        rec.CreatedAt,
		UpdatedAt:        rec.UpdatedAt,
	}
}

type referralRecord struct {
	ID                uuid.UUID  `db:"id"`
	ReferralPartnerID uuid.UUID  `db:"referral_partner_id"`
	PartnerName       string     `db:"partner_name"`
	LeadID            *uuid.UUID `db:"lead_id"`
	StudentID         *uuid.UUID `db:"student_id"`
	BatchID           *uuid.UUID `db:"batch_id"`
	Status            string     `db:"status"`
	Commission        float64    `db:"commission"`
	CreatedAt         time.Time  `db:"created_at"`
	UpdatedAt         time.Time  `db:"updated_at"`
}

func (rec *referralRecord) toDomain() *marketing.Referral {
	return &marketing.Referral{
		ID:                rec.ID,
		ReferralPartnerID: rec.ReferralPartnerID,
		PartnerName:       rec.PartnerName,
		LeadID:            rec.LeadID,
		StudentID:         rec.StudentID,
		BatchID:           rec.BatchID,
		Status:            rec.Status,
		Commission:        rec.Commission,
		CreatedAt:         rec.CreatedAt,
		UpdatedAt:         rec.UpdatedAt,
	}
}

// ---- WriteRepository ----

func (r *MarketingRepository) SavePost(ctx context.Context, p *marketing.SocialMediaPost) error {
	query := `
		INSERT INTO social_media_posts
			(id, platforms, scheduled_at, content_type, caption, media_url, batch_id, status, post_url, created_by, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		p.ID, pq.Array(p.Platforms), p.ScheduledAt, p.ContentType,
		p.Caption, p.MediaURL, p.BatchID, p.Status, p.PostURL,
		p.CreatedBy, p.CreatedAt, p.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save post: %w", err)
	}
	return nil
}

func (r *MarketingRepository) UpdatePost(ctx context.Context, p *marketing.SocialMediaPost) error {
	query := `
		UPDATE social_media_posts
		SET platforms=$1, scheduled_at=$2, content_type=$3, caption=$4,
		    media_url=$5, batch_id=$6, status=$7, post_url=$8, updated_at=$9
		WHERE id=$10
	`
	_, err := r.db.ExecContext(ctx, query,
		pq.Array(p.Platforms), p.ScheduledAt, p.ContentType, p.Caption,
		p.MediaURL, p.BatchID, p.Status, p.PostURL, p.UpdatedAt, p.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update post: %w", err)
	}
	return nil
}

func (r *MarketingRepository) DeletePost(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM social_media_posts WHERE id=$1`, id)
	if err != nil {
		return fmt.Errorf("failed to delete post: %w", err)
	}
	return nil
}

func (r *MarketingRepository) SaveClassDocPost(ctx context.Context, p *marketing.ClassDocPost) error {
	query := `
		INSERT INTO class_doc_posts
			(id, batch_id, session_id, module_name, batch_name, class_date, scheduled_post_date, status, post_url, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`
	_, err := r.db.ExecContext(ctx, query,
		p.ID, p.BatchID, p.SessionID, p.ModuleName, p.BatchName,
		p.ClassDate, p.ScheduledPostDate, p.Status, p.PostURL,
		p.CreatedAt, p.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save class doc post: %w", err)
	}
	return nil
}

func (r *MarketingRepository) UpdateClassDocPostStatus(ctx context.Context, id uuid.UUID, status, postURL string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE class_doc_posts SET status=$1, post_url=$2, updated_at=$3 WHERE id=$4`,
		status, postURL, time.Now(), id,
	)
	if err != nil {
		return fmt.Errorf("failed to update class doc post status: %w", err)
	}
	return nil
}

func (r *MarketingRepository) SavePr(ctx context.Context, p *marketing.PrSchedule) error {
	query := `
		INSERT INTO pr_schedules
			(id, title, type, scheduled_at, media_venue, pic_id, pic_name, status, notes, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`
	_, err := r.db.ExecContext(ctx, query,
		p.ID, p.Title, p.Type, p.ScheduledAt, p.MediaVenue,
		p.PicID, p.PicName, p.Status, p.Notes, p.CreatedAt, p.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save pr schedule: %w", err)
	}
	return nil
}

func (r *MarketingRepository) UpdatePr(ctx context.Context, p *marketing.PrSchedule) error {
	query := `
		UPDATE pr_schedules
		SET title=$1, type=$2, scheduled_at=$3, media_venue=$4, pic_id=$5,
		    pic_name=$6, status=$7, notes=$8, updated_at=$9
		WHERE id=$10
	`
	_, err := r.db.ExecContext(ctx, query,
		p.Title, p.Type, p.ScheduledAt, p.MediaVenue, p.PicID,
		p.PicName, p.Status, p.Notes, p.UpdatedAt, p.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update pr schedule: %w", err)
	}
	return nil
}

func (r *MarketingRepository) DeletePr(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM pr_schedules WHERE id=$1`, id)
	if err != nil {
		return fmt.Errorf("failed to delete pr schedule: %w", err)
	}
	return nil
}

func (r *MarketingRepository) SaveReferralPartner(ctx context.Context, rp *marketing.ReferralPartner) error {
	query := `
		INSERT INTO referral_partners
			(id, name, contact_email, referral_code, commission_type, commission_value, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.db.ExecContext(ctx, query,
		rp.ID, rp.Name, rp.ContactEmail, rp.ReferralCode,
		rp.CommissionType, rp.CommissionValue, rp.IsActive,
		rp.CreatedAt, rp.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save referral partner: %w", err)
	}
	return nil
}

func (r *MarketingRepository) UpdateReferralPartner(ctx context.Context, rp *marketing.ReferralPartner) error {
	query := `
		UPDATE referral_partners
		SET name=$1, contact_email=$2, commission_type=$3, commission_value=$4,
		    is_active=$5, updated_at=$6
		WHERE id=$7
	`
	_, err := r.db.ExecContext(ctx, query,
		rp.Name, rp.ContactEmail, rp.CommissionType, rp.CommissionValue,
		rp.IsActive, rp.UpdatedAt, rp.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update referral partner: %w", err)
	}
	return nil
}

func (r *MarketingRepository) SaveReferral(ctx context.Context, ref *marketing.Referral) error {
	query := `
		INSERT INTO referrals
			(id, referral_partner_id, lead_id, student_id, batch_id, status, commission, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.db.ExecContext(ctx, query,
		ref.ID, ref.ReferralPartnerID, ref.LeadID, ref.StudentID,
		ref.BatchID, ref.Status, ref.Commission, ref.CreatedAt, ref.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save referral: %w", err)
	}
	return nil
}

// ---- ReadRepository ----

func (r *MarketingRepository) GetPostByID(ctx context.Context, id uuid.UUID) (*marketing.SocialMediaPost, error) {
	query := `
		SELECT p.id, p.platforms, p.scheduled_at, p.content_type, p.caption,
		       p.media_url, p.batch_id, COALESCE(cb.name, '') AS batch_name,
		       p.status, p.post_url, p.created_by, p.created_at, p.updated_at
		FROM social_media_posts p
		LEFT JOIN course_batches cb ON cb.id = p.batch_id
		WHERE p.id = $1
	`
	var rec socialMediaPostRecord
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, marketing.ErrPostNotFound
	}
	return rec.toDomain(), nil
}

func (r *MarketingRepository) ListPosts(ctx context.Context, offset, limit int, platform, status, month string) ([]*marketing.SocialMediaPost, int, error) {
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if platform != "" {
		conditions = append(conditions, fmt.Sprintf("p.platforms @> ARRAY[$%d::text]", argIdx))
		args = append(args, platform)
		argIdx++
	}
	if status != "" {
		conditions = append(conditions, fmt.Sprintf("p.status = $%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	if month != "" {
		conditions = append(conditions, fmt.Sprintf("to_char(p.scheduled_at, 'YYYY-MM') = $%d", argIdx))
		args = append(args, month)
		argIdx++
	}

	where := ""
	if len(conditions) > 0 {
		where = "WHERE " + strings.Join(conditions, " AND ")
	}

	countQuery := fmt.Sprintf(`
		SELECT COUNT(*) FROM social_media_posts p %s
	`, where)

	var total int
	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)
	if err := r.db.QueryRowContext(ctx, countQuery, countArgs...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("failed to count posts: %w", err)
	}

	if limit <= 0 {
		limit = 20
	}

	dataQuery := fmt.Sprintf(`
		SELECT p.id, p.platforms, p.scheduled_at, p.content_type, p.caption,
		       p.media_url, p.batch_id, COALESCE(cb.name, '') AS batch_name,
		       p.status, p.post_url, p.created_by, p.created_at, p.updated_at
		FROM social_media_posts p
		LEFT JOIN course_batches cb ON cb.id = p.batch_id
		%s
		ORDER BY p.scheduled_at DESC
		LIMIT $%d OFFSET $%d
	`, where, argIdx, argIdx+1)

	args = append(args, limit, offset)
	rows, err := r.db.QueryxContext(ctx, dataQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list posts: %w", err)
	}
	defer rows.Close()

	var posts []*marketing.SocialMediaPost
	for rows.Next() {
		var rec socialMediaPostRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, 0, fmt.Errorf("failed to scan post: %w", err)
		}
		posts = append(posts, rec.toDomain())
	}
	if posts == nil {
		posts = []*marketing.SocialMediaPost{}
	}
	return posts, total, nil
}

func (r *MarketingRepository) ListClassDocs(ctx context.Context, offset, limit int, status string) ([]*marketing.ClassDocPost, int, error) {
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIdx))
		args = append(args, status)
		argIdx++
	}

	where := ""
	if len(conditions) > 0 {
		where = "WHERE " + strings.Join(conditions, " AND ")
	}

	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM class_doc_posts %s`, where)
	var total int
	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)
	if err := r.db.QueryRowContext(ctx, countQuery, countArgs...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("failed to count class docs: %w", err)
	}

	if limit <= 0 {
		limit = 20
	}

	dataQuery := fmt.Sprintf(`
		SELECT id, batch_id, session_id, module_name, batch_name, class_date,
		       scheduled_post_date, status, post_url, created_at, updated_at
		FROM class_doc_posts
		%s
		ORDER BY scheduled_post_date ASC
		LIMIT $%d OFFSET $%d
	`, where, argIdx, argIdx+1)

	args = append(args, limit, offset)
	rows, err := r.db.QueryxContext(ctx, dataQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list class docs: %w", err)
	}
	defer rows.Close()

	var docs []*marketing.ClassDocPost
	for rows.Next() {
		var rec classDocPostRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, 0, fmt.Errorf("failed to scan class doc: %w", err)
		}
		docs = append(docs, rec.toDomain())
	}
	if docs == nil {
		docs = []*marketing.ClassDocPost{}
	}
	return docs, total, nil
}

func (r *MarketingRepository) GetPrByID(ctx context.Context, id uuid.UUID) (*marketing.PrSchedule, error) {
	var rec prScheduleRecord
	if err := r.db.GetContext(ctx, &rec,
		`SELECT id, title, type, scheduled_at, media_venue, pic_id, pic_name, status, notes, created_at, updated_at
		 FROM pr_schedules WHERE id=$1`, id); err != nil {
		return nil, marketing.ErrPrNotFound
	}
	return rec.toDomain(), nil
}

func (r *MarketingRepository) ListPr(ctx context.Context, offset, limit int, status, prType string) ([]*marketing.PrSchedule, int, error) {
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	if prType != "" {
		conditions = append(conditions, fmt.Sprintf("type = $%d", argIdx))
		args = append(args, prType)
		argIdx++
	}

	where := ""
	if len(conditions) > 0 {
		where = "WHERE " + strings.Join(conditions, " AND ")
	}

	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM pr_schedules %s`, where)
	var total int
	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)
	if err := r.db.QueryRowContext(ctx, countQuery, countArgs...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("failed to count pr schedules: %w", err)
	}

	if limit <= 0 {
		limit = 20
	}

	dataQuery := fmt.Sprintf(`
		SELECT id, title, type, scheduled_at, media_venue, pic_id, pic_name, status, notes, created_at, updated_at
		FROM pr_schedules
		%s
		ORDER BY scheduled_at ASC
		LIMIT $%d OFFSET $%d
	`, where, argIdx, argIdx+1)

	args = append(args, limit, offset)
	rows, err := r.db.QueryxContext(ctx, dataQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list pr schedules: %w", err)
	}
	defer rows.Close()

	var prs []*marketing.PrSchedule
	for rows.Next() {
		var rec prScheduleRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, 0, fmt.Errorf("failed to scan pr schedule: %w", err)
		}
		prs = append(prs, rec.toDomain())
	}
	if prs == nil {
		prs = []*marketing.PrSchedule{}
	}
	return prs, total, nil
}

func (r *MarketingRepository) GetReferralPartnerByID(ctx context.Context, id uuid.UUID) (*marketing.ReferralPartner, error) {
	query := `
		SELECT rp.id, rp.name, rp.contact_email, rp.referral_code, rp.commission_type,
		       rp.commission_value, rp.is_active, rp.created_at, rp.updated_at,
		       COUNT(ref.id) AS total_referrals,
		       COUNT(ref.id) FILTER (WHERE ref.status IN ('enrolled','paid')) AS total_enrolled,
		       COALESCE(SUM(ref.commission) FILTER (WHERE ref.status = 'paid'), 0) AS total_commission,
		       COALESCE(SUM(ref.commission) FILTER (WHERE ref.status = 'enrolled'), 0) AS pending_commission
		FROM referral_partners rp
		LEFT JOIN referrals ref ON ref.referral_partner_id = rp.id
		WHERE rp.id = $1
		GROUP BY rp.id
	`
	var rec referralPartnerRecord
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, marketing.ErrReferralPartnerNotFound
	}
	return rec.toDomain(), nil
}

func (r *MarketingRepository) ListReferralPartners(ctx context.Context, offset, limit int, isActive *bool) ([]*marketing.ReferralPartner, int, error) {
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if isActive != nil {
		conditions = append(conditions, fmt.Sprintf("rp.is_active = $%d", argIdx))
		args = append(args, *isActive)
		argIdx++
	}

	where := ""
	if len(conditions) > 0 {
		where = "WHERE " + strings.Join(conditions, " AND ")
	}

	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM referral_partners rp %s`, where)
	var total int
	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)
	if err := r.db.QueryRowContext(ctx, countQuery, countArgs...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("failed to count referral partners: %w", err)
	}

	if limit <= 0 {
		limit = 20
	}

	dataQuery := fmt.Sprintf(`
		SELECT rp.id, rp.name, rp.contact_email, rp.referral_code, rp.commission_type,
		       rp.commission_value, rp.is_active, rp.created_at, rp.updated_at,
		       COUNT(ref.id) AS total_referrals,
		       COUNT(ref.id) FILTER (WHERE ref.status IN ('enrolled','paid')) AS total_enrolled,
		       COALESCE(SUM(ref.commission) FILTER (WHERE ref.status = 'paid'), 0) AS total_commission,
		       COALESCE(SUM(ref.commission) FILTER (WHERE ref.status = 'enrolled'), 0) AS pending_commission
		FROM referral_partners rp
		LEFT JOIN referrals ref ON ref.referral_partner_id = rp.id
		%s
		GROUP BY rp.id
		ORDER BY rp.created_at DESC
		LIMIT $%d OFFSET $%d
	`, where, argIdx, argIdx+1)

	args = append(args, limit, offset)
	rows, err := r.db.QueryxContext(ctx, dataQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list referral partners: %w", err)
	}
	defer rows.Close()

	var partners []*marketing.ReferralPartner
	for rows.Next() {
		var rec referralPartnerRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, 0, fmt.Errorf("failed to scan referral partner: %w", err)
		}
		partners = append(partners, rec.toDomain())
	}
	if partners == nil {
		partners = []*marketing.ReferralPartner{}
	}
	return partners, total, nil
}

func (r *MarketingRepository) ListReferrals(ctx context.Context, partnerID uuid.UUID) ([]*marketing.Referral, error) {
	query := `
		SELECT r.id, r.referral_partner_id, rp.name AS partner_name,
		       r.lead_id, r.student_id, r.batch_id,
		       r.status, r.commission, r.created_at, r.updated_at
		FROM referrals r
		JOIN referral_partners rp ON rp.id = r.referral_partner_id
		WHERE r.referral_partner_id = $1
		ORDER BY r.created_at DESC
	`
	rows, err := r.db.QueryxContext(ctx, query, partnerID)
	if err != nil {
		return nil, fmt.Errorf("failed to list referrals: %w", err)
	}
	defer rows.Close()

	var referrals []*marketing.Referral
	for rows.Next() {
		var rec referralRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, fmt.Errorf("failed to scan referral: %w", err)
		}
		referrals = append(referrals, rec.toDomain())
	}
	if referrals == nil {
		referrals = []*marketing.Referral{}
	}
	return referrals, nil
}

type marketingStatsRow struct {
	TotalLeads               int     `db:"total_leads"`
	LeadsThisMonth           int     `db:"leads_this_month"`
	LeadsPrevMonth           int     `db:"leads_prev_month"`
	LeadToStudentPct         float64 `db:"lead_to_student_pct"`
	ScheduledPosts           int     `db:"scheduled_posts"`
	PostedThisMonth          int     `db:"posted_this_month"`
	ActiveReferralPartners   int     `db:"active_referral_partners"`
	ReferralRevenueThisMonth float64 `db:"referral_revenue_this_month"`
}

func (r *MarketingRepository) GetStats(ctx context.Context) (*marketing.MarketingStats, error) {
	query := `
		SELECT
			(SELECT COUNT(*) FROM leads) AS total_leads,
			(SELECT COUNT(*) FROM leads WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW())) AS leads_this_month,
			(SELECT COUNT(*) FROM leads WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW() - INTERVAL '1 month')) AS leads_prev_month,
			(SELECT CASE WHEN COUNT(*) = 0 THEN 0.0 ELSE (COUNT(*) FILTER (WHERE student_id IS NOT NULL)::float / COUNT(*)) * 100 END FROM leads) AS lead_to_student_pct,
			(SELECT COUNT(*) FROM social_media_posts WHERE status = 'scheduled' AND scheduled_at >= NOW()) AS scheduled_posts,
			(SELECT COUNT(*) FROM social_media_posts WHERE status = 'posted' AND DATE_TRUNC('month', scheduled_at) = DATE_TRUNC('month', NOW())) AS posted_this_month,
			(SELECT COUNT(*) FROM referral_partners WHERE is_active = TRUE) AS active_referral_partners,
			(SELECT COALESCE(SUM(commission), 0) FROM referrals WHERE status = 'paid' AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NOW())) AS referral_revenue_this_month
	`
	var row marketingStatsRow
	if err := r.db.GetContext(ctx, &row, query); err != nil {
		return nil, fmt.Errorf("failed to get marketing stats: %w", err)
	}

	return &marketing.MarketingStats{
		TotalLeads:               row.TotalLeads,
		LeadsThisMonth:           row.LeadsThisMonth,
		LeadsPrevMonth:           row.LeadsPrevMonth,
		LeadToStudentPct:         row.LeadToStudentPct,
		ScheduledPosts:           row.ScheduledPosts,
		PostedThisMonth:          row.PostedThisMonth,
		ActiveReferralPartners:   row.ActiveReferralPartners,
		ReferralRevenueThisMonth: row.ReferralRevenueThisMonth,
	}, nil
}
