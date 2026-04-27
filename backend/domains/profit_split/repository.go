package profit_split

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines profit_split data access.
type Repository interface {
	// GlobalSettings
	UpsertGlobalSettings(ctx context.Context, s *GlobalSettings) error
	GetGlobalSettings(ctx context.Context) (*GlobalSettings, error)

	// CourseOverride
	UpsertCourseOverride(ctx context.Context, co *CourseOverride) error
	GetCourseOverride(ctx context.Context, courseID uuid.UUID) (*CourseOverride, error)

	// ExtraRevenue
	CreateExtraRevenue(ctx context.Context, er *ExtraRevenue) error
	GetExtraRevenue(ctx context.Context, id uuid.UUID) (*ExtraRevenue, error)
	UpdateExtraRevenueStatus(ctx context.Context, id uuid.UUID, status ApprovalStatus, approvedBy *uuid.UUID) error
	ListApprovedExtraRevenues(ctx context.Context, batchID uuid.UUID) ([]*ExtraRevenue, error)

	// BatchCostLineItem
	CreateBatchCostLineItem(ctx context.Context, item *BatchCostLineItem) error
	GetBatchCostLineItem(ctx context.Context, id uuid.UUID) (*BatchCostLineItem, error)
	RemoveBatchCostLineItem(ctx context.Context, id uuid.UUID) error
	ListActiveBatchCostLineItems(ctx context.Context, batchID uuid.UUID) ([]*BatchCostLineItem, error)

	// BatchSplitRecord
	CreateBatchSplitRecord(ctx context.Context, r *BatchSplitRecord) error
	GetBatchSplitRecord(ctx context.Context, batchID uuid.UUID) (*BatchSplitRecord, error)

	// PeriodBonus
	UpsertPeriodBonus(ctx context.Context, pb *PeriodBonus) error
	GetPeriodBonus(ctx context.Context, period string) (*PeriodBonus, error)
	ListClosedBatchesInPeriod(ctx context.Context, period string) ([]*BatchSplitRecord, error)
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository constructs profit_split repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

// ─── GlobalSettings ──────────────────────────────────────────────────────────

func (r *repository) UpsertGlobalSettings(ctx context.Context, s *GlobalSettings) error {
	query := `
		INSERT INTO profit_split.global_settings
		  (id, vernonedu_pct, course_creator_pct, dept_leader_pct, updated_by, updated_at)
		VALUES ($1, $2, $3, $4, $5, now())
		ON CONFLICT (id) DO UPDATE SET
		  vernonedu_pct      = EXCLUDED.vernonedu_pct,
		  course_creator_pct = EXCLUDED.course_creator_pct,
		  dept_leader_pct    = EXCLUDED.dept_leader_pct,
		  updated_by         = EXCLUDED.updated_by,
		  updated_at         = now()
		RETURNING updated_at`

	return r.pool.QueryRow(ctx, query,
		s.ID, s.VernonEduPct, s.CourseCreatorPct, s.DeptLeaderPct, s.UpdatedBy,
	).Scan(&s.UpdatedAt)
}

func (r *repository) GetGlobalSettings(ctx context.Context) (*GlobalSettings, error) {
	query := `
		SELECT id, vernonedu_pct, course_creator_pct, dept_leader_pct, updated_by, updated_at
		FROM profit_split.global_settings LIMIT 1`

	s := &GlobalSettings{}
	err := r.pool.QueryRow(ctx, query).Scan(
		&s.ID, &s.VernonEduPct, &s.CourseCreatorPct, &s.DeptLeaderPct, &s.UpdatedBy, &s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("profit_split.GetGlobalSettings: %w", err)
	}
	return s, nil
}

// ─── CourseOverride ───────────────────────────────────────────────────────────

func (r *repository) UpsertCourseOverride(ctx context.Context, co *CourseOverride) error {
	query := `
		INSERT INTO profit_split.course_overrides
		  (id, course_id, vernonedu_pct, course_creator_pct, dept_leader_pct, overridden_by, overridden_at)
		VALUES ($1, $2, $3, $4, $5, $6, now())
		ON CONFLICT (course_id) DO UPDATE SET
		  vernonedu_pct      = EXCLUDED.vernonedu_pct,
		  course_creator_pct = EXCLUDED.course_creator_pct,
		  dept_leader_pct    = EXCLUDED.dept_leader_pct,
		  overridden_by      = EXCLUDED.overridden_by,
		  overridden_at      = now()
		RETURNING overridden_at, created_at, updated_at`

	return r.pool.QueryRow(ctx, query,
		co.ID, co.CourseID, co.VernonEduPct, co.CourseCreatorPct, co.DeptLeaderPct, co.OverriddenBy,
	).Scan(&co.OverriddenAt, &co.CreatedAt, &co.UpdatedAt)
}

func (r *repository) GetCourseOverride(ctx context.Context, courseID uuid.UUID) (*CourseOverride, error) {
	query := `
		SELECT id, course_id, vernonedu_pct, course_creator_pct, dept_leader_pct,
		       overridden_by, overridden_at, created_at, updated_at
		FROM profit_split.course_overrides WHERE course_id = $1`

	co := &CourseOverride{}
	err := r.pool.QueryRow(ctx, query, courseID).Scan(
		&co.ID, &co.CourseID, &co.VernonEduPct, &co.CourseCreatorPct, &co.DeptLeaderPct,
		&co.OverriddenBy, &co.OverriddenAt, &co.CreatedAt, &co.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("profit_split.GetCourseOverride: %w", err)
	}
	return co, nil
}

// ─── ExtraRevenue ─────────────────────────────────────────────────────────────

func (r *repository) CreateExtraRevenue(ctx context.Context, er *ExtraRevenue) error {
	query := `
		INSERT INTO profit_split.extra_revenues
		  (id, course_batch_id, label, amount, added_by, approval_status)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	return r.pool.QueryRow(ctx, query,
		er.ID, er.CourseBatchID, er.Label, er.Amount, er.AddedBy, er.ApprovalStatus,
	).Scan(&er.CreatedAt, &er.UpdatedAt)
}

func (r *repository) GetExtraRevenue(ctx context.Context, id uuid.UUID) (*ExtraRevenue, error) {
	query := `
		SELECT id, course_batch_id, label, amount, added_by,
		       approval_status, approved_by, approved_at, created_at, updated_at
		FROM profit_split.extra_revenues WHERE id = $1`

	er := &ExtraRevenue{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&er.ID, &er.CourseBatchID, &er.Label, &er.Amount, &er.AddedBy,
		&er.ApprovalStatus, &er.ApprovedBy, &er.ApprovedAt, &er.CreatedAt, &er.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("profit_split.GetExtraRevenue: %w", err)
	}
	return er, nil
}

func (r *repository) UpdateExtraRevenueStatus(
	ctx context.Context, id uuid.UUID, status ApprovalStatus, approvedBy *uuid.UUID,
) error {
	query := `
		UPDATE profit_split.extra_revenues
		SET approval_status = $1,
		    approved_by     = $2,
		    approved_at     = CASE WHEN $1 IN ('approved','rejected') THEN now() ELSE NULL END
		WHERE id = $3`

	ct, err := r.pool.Exec(ctx, query, status, approvedBy, id)
	if err != nil {
		return fmt.Errorf("profit_split.UpdateExtraRevenueStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListApprovedExtraRevenues(ctx context.Context, batchID uuid.UUID) ([]*ExtraRevenue, error) {
	query := `
		SELECT id, course_batch_id, label, amount, added_by,
		       approval_status, approved_by, approved_at, created_at, updated_at
		FROM profit_split.extra_revenues
		WHERE course_batch_id = $1 AND approval_status = 'approved'`

	rows, err := r.pool.Query(ctx, query, batchID)
	if err != nil {
		return nil, fmt.Errorf("profit_split.ListApprovedExtraRevenues: %w", err)
	}
	defer rows.Close()

	var list []*ExtraRevenue
	for rows.Next() {
		er := &ExtraRevenue{}
		if err := rows.Scan(
			&er.ID, &er.CourseBatchID, &er.Label, &er.Amount, &er.AddedBy,
			&er.ApprovalStatus, &er.ApprovedBy, &er.ApprovedAt, &er.CreatedAt, &er.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("profit_split.ListApprovedExtraRevenues scan: %w", err)
		}
		list = append(list, er)
	}
	return list, rows.Err()
}

// ─── BatchCostLineItem ────────────────────────────────────────────────────────

func (r *repository) CreateBatchCostLineItem(ctx context.Context, item *BatchCostLineItem) error {
	query := `
		INSERT INTO profit_split.batch_cost_line_items
		  (id, course_batch_id, template_ref, label, amount, cost_type, is_removed, reference_type, reference_id, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING created_at, updated_at`

	return r.pool.QueryRow(ctx, query,
		item.ID, item.CourseBatchID, item.TemplateRef, item.Label, item.Amount,
		item.CostType, item.IsRemoved, item.ReferenceType, item.ReferenceID, item.CreatedBy,
	).Scan(&item.CreatedAt, &item.UpdatedAt)
}

func (r *repository) GetBatchCostLineItem(ctx context.Context, id uuid.UUID) (*BatchCostLineItem, error) {
	query := `
		SELECT id, course_batch_id, template_ref, label, amount, cost_type,
		       is_removed, reference_type, reference_id, created_by, created_at, updated_at
		FROM profit_split.batch_cost_line_items WHERE id = $1`

	item := &BatchCostLineItem{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&item.ID, &item.CourseBatchID, &item.TemplateRef, &item.Label, &item.Amount,
		&item.CostType, &item.IsRemoved, &item.ReferenceType, &item.ReferenceID,
		&item.CreatedBy, &item.CreatedAt, &item.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("profit_split.GetBatchCostLineItem: %w", err)
	}
	return item, nil
}

func (r *repository) RemoveBatchCostLineItem(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE profit_split.batch_cost_line_items SET is_removed = TRUE WHERE id = $1`
	ct, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("profit_split.RemoveBatchCostLineItem: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListActiveBatchCostLineItems(ctx context.Context, batchID uuid.UUID) ([]*BatchCostLineItem, error) {
	query := `
		SELECT id, course_batch_id, template_ref, label, amount, cost_type,
		       is_removed, reference_type, reference_id, created_by, created_at, updated_at
		FROM profit_split.batch_cost_line_items
		WHERE course_batch_id = $1 AND is_removed = FALSE`

	rows, err := r.pool.Query(ctx, query, batchID)
	if err != nil {
		return nil, fmt.Errorf("profit_split.ListActiveBatchCostLineItems: %w", err)
	}
	defer rows.Close()

	var list []*BatchCostLineItem
	for rows.Next() {
		item := &BatchCostLineItem{}
		if err := rows.Scan(
			&item.ID, &item.CourseBatchID, &item.TemplateRef, &item.Label, &item.Amount,
			&item.CostType, &item.IsRemoved, &item.ReferenceType, &item.ReferenceID,
			&item.CreatedBy, &item.CreatedAt, &item.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("profit_split.ListActiveBatchCostLineItems scan: %w", err)
		}
		list = append(list, item)
	}
	return list, rows.Err()
}

// ─── BatchSplitRecord ─────────────────────────────────────────────────────────

func (r *repository) CreateBatchSplitRecord(ctx context.Context, rec *BatchSplitRecord) error {
	query := `
		INSERT INTO profit_split.batch_split_records
		  (id, course_batch_id, gross_revenue, total_costs, net_profit,
		   vernonedu_pct, course_creator_pct, dept_leader_pct,
		   vernonedu_amount, course_creator_amount, dept_leader_amount,
		   calculated_at, calculated_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,now(),$12)
		RETURNING calculated_at`

	return r.pool.QueryRow(ctx, query,
		rec.ID, rec.CourseBatchID, rec.GrossRevenue, rec.TotalCosts, rec.NetProfit,
		rec.VernonEduPct, rec.CourseCreatorPct, rec.DeptLeaderPct,
		rec.VernonEduAmount, rec.CourseCreatorAmount, rec.DeptLeaderAmount,
		rec.CalculatedBy,
	).Scan(&rec.CalculatedAt)
}

func (r *repository) GetBatchSplitRecord(ctx context.Context, batchID uuid.UUID) (*BatchSplitRecord, error) {
	query := `
		SELECT id, course_batch_id, gross_revenue, total_costs, net_profit,
		       vernonedu_pct, course_creator_pct, dept_leader_pct,
		       vernonedu_amount, course_creator_amount, dept_leader_amount,
		       calculated_at, calculated_by
		FROM profit_split.batch_split_records WHERE course_batch_id = $1`

	rec := &BatchSplitRecord{}
	err := r.pool.QueryRow(ctx, query, batchID).Scan(
		&rec.ID, &rec.CourseBatchID, &rec.GrossRevenue, &rec.TotalCosts, &rec.NetProfit,
		&rec.VernonEduPct, &rec.CourseCreatorPct, &rec.DeptLeaderPct,
		&rec.VernonEduAmount, &rec.CourseCreatorAmount, &rec.DeptLeaderAmount,
		&rec.CalculatedAt, &rec.CalculatedBy,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("profit_split.GetBatchSplitRecord: %w", err)
	}
	return rec, nil
}

// ─── PeriodBonus ─────────────────────────────────────────────────────────────

func (r *repository) UpsertPeriodBonus(ctx context.Context, pb *PeriodBonus) error {
	batchRefsStr := uuidSliceToArray(pb.BatchRefs)
	query := `
		INSERT INTO profit_split.period_bonuses
		  (id, period, period_type, vernonedu_amount, course_creator_amount, dept_leader_amount,
		   batch_refs, calculated_at, calculated_by, status)
		VALUES ($1,$2,$3,$4,$5,$6,$7::uuid[],$8,$9,$10)
		ON CONFLICT (period, period_type) DO UPDATE SET
		  vernonedu_amount      = EXCLUDED.vernonedu_amount,
		  course_creator_amount = EXCLUDED.course_creator_amount,
		  dept_leader_amount    = EXCLUDED.dept_leader_amount,
		  batch_refs            = EXCLUDED.batch_refs,
		  calculated_at         = EXCLUDED.calculated_at,
		  calculated_by         = EXCLUDED.calculated_by,
		  status                = EXCLUDED.status
		RETURNING created_at, updated_at`

	return r.pool.QueryRow(ctx, query,
		pb.ID, pb.Period, pb.PeriodType, pb.VernonEduAmount, pb.CourseCreatorAmount,
		pb.DeptLeaderAmount, batchRefsStr, pb.CalculatedAt, pb.CalculatedBy, pb.Status,
	).Scan(&pb.CreatedAt, &pb.UpdatedAt)
}

func (r *repository) GetPeriodBonus(ctx context.Context, period string) (*PeriodBonus, error) {
	query := `
		SELECT id, period, period_type, vernonedu_amount, course_creator_amount,
		       dept_leader_amount, batch_refs, calculated_at, calculated_by, status, created_at, updated_at
		FROM profit_split.period_bonuses WHERE period = $1 AND period_type = 'monthly'`

	pb := &PeriodBonus{}
	err := r.pool.QueryRow(ctx, query, period).Scan(
		&pb.ID, &pb.Period, &pb.PeriodType, &pb.VernonEduAmount, &pb.CourseCreatorAmount,
		&pb.DeptLeaderAmount, &pb.BatchRefs, &pb.CalculatedAt, &pb.CalculatedBy,
		&pb.Status, &pb.CreatedAt, &pb.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("profit_split.GetPeriodBonus: %w", err)
	}
	return pb, nil
}

func (r *repository) ListClosedBatchesInPeriod(ctx context.Context, period string) ([]*BatchSplitRecord, error) {
	// period format: YYYY-MM
	query := `
		SELECT id, course_batch_id, gross_revenue, total_costs, net_profit,
		       vernonedu_pct, course_creator_pct, dept_leader_pct,
		       vernonedu_amount, course_creator_amount, dept_leader_amount,
		       calculated_at, calculated_by
		FROM profit_split.batch_split_records
		WHERE to_char(calculated_at AT TIME ZONE 'UTC', 'YYYY-MM') = $1`

	rows, err := r.pool.Query(ctx, query, period)
	if err != nil {
		return nil, fmt.Errorf("profit_split.ListClosedBatchesInPeriod: %w", err)
	}
	defer rows.Close()

	var list []*BatchSplitRecord
	for rows.Next() {
		rec := &BatchSplitRecord{}
		if err := rows.Scan(
			&rec.ID, &rec.CourseBatchID, &rec.GrossRevenue, &rec.TotalCosts, &rec.NetProfit,
			&rec.VernonEduPct, &rec.CourseCreatorPct, &rec.DeptLeaderPct,
			&rec.VernonEduAmount, &rec.CourseCreatorAmount, &rec.DeptLeaderAmount,
			&rec.CalculatedAt, &rec.CalculatedBy,
		); err != nil {
			return nil, fmt.Errorf("profit_split.ListClosedBatchesInPeriod scan: %w", err)
		}
		list = append(list, rec)
	}
	return list, rows.Err()
}

// uuidSliceToArray converts []uuid.UUID to a PostgreSQL array literal string.
func uuidSliceToArray(ids []uuid.UUID) string {
	if len(ids) == 0 {
		return "{}"
	}
	out := "{"
	for i, id := range ids {
		if i > 0 {
			out += ","
		}
		out += id.String()
	}
	return out + "}"
}
