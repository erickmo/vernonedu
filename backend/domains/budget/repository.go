package budget

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// SQL table constants — no magic strings.
const (
	tableTemplateItems = "budget.template_items"
	tableBatchItems    = "budget.batch_items"
	tableRealizations  = "budget.realizations"
)

// Repository defines all budget persistence operations.
type Repository interface {
	// Template items
	CreateTemplateItem(ctx context.Context, item *CourseBudgetTemplateItem) error
	GetTemplateItem(ctx context.Context, id uuid.UUID) (*CourseBudgetTemplateItem, error)
	ListTemplateItems(ctx context.Context, courseID uuid.UUID) ([]*CourseBudgetTemplateItem, error)
	UpdateTemplateItem(ctx context.Context, item *CourseBudgetTemplateItem) error
	DeleteTemplateItem(ctx context.Context, id uuid.UUID) error

	// Batch items
	CreateBatchItem(ctx context.Context, item *BatchBudgetItem) error
	GetBatchItem(ctx context.Context, id uuid.UUID) (*BatchBudgetItem, error)
	ListBatchItems(ctx context.Context, batchID uuid.UUID) ([]*BatchBudgetItem, error)
	UpdateBatchItem(ctx context.Context, item *BatchBudgetItem) error
	DeleteBatchItem(ctx context.Context, id uuid.UUID) error

	// Realizations
	CreateRealization(ctx context.Context, r *BudgetRealization) error
	GetRealization(ctx context.Context, id uuid.UUID) (*BudgetRealization, error)
	ListRealizations(ctx context.Context, batchItemID uuid.UUID) ([]*BudgetRealization, error)
	UpdateRealization(ctx context.Context, r *BudgetRealization) error
	DeleteRealization(ctx context.Context, id uuid.UUID) error

	// Summary
	GetBatchSummary(ctx context.Context, batchID uuid.UUID) (*BatchBudgetSummary, error)
}

type pgRepository struct {
	db *pgxpool.Pool
}

// NewRepository constructs the pgx-backed Repository (FX-injectable).
func NewRepository(db *pgxpool.Pool) Repository {
	return &pgRepository{db: db}
}

// ─── Template Items ───────────────────────────────────────────────────────────

func (r *pgRepository) CreateTemplateItem(ctx context.Context, item *CourseBudgetTemplateItem) error {
	const q = `
		INSERT INTO budget.template_items
			(id, course_id, label, category, preset_amount, overridable, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`
	_, err := r.db.Exec(ctx, q,
		item.ID, item.CourseID, item.Label, item.Category,
		item.PresetAmount, item.Overridable, item.CreatedAt, item.UpdatedAt)
	return err
}

func (r *pgRepository) GetTemplateItem(ctx context.Context, id uuid.UUID) (*CourseBudgetTemplateItem, error) {
	const q = `
		SELECT id, course_id, label, category, preset_amount, overridable, created_at, updated_at
		FROM budget.template_items WHERE id = $1`
	item := &CourseBudgetTemplateItem{}
	err := r.db.QueryRow(ctx, q, id).Scan(
		&item.ID, &item.CourseID, &item.Label, &item.Category,
		&item.PresetAmount, &item.Overridable, &item.CreatedAt, &item.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperrors.ErrNotFound
	}
	return item, err
}

func (r *pgRepository) ListTemplateItems(ctx context.Context, courseID uuid.UUID) ([]*CourseBudgetTemplateItem, error) {
	const q = `
		SELECT id, course_id, label, category, preset_amount, overridable, created_at, updated_at
		FROM budget.template_items WHERE course_id = $1 ORDER BY created_at ASC`
	rows, err := r.db.Query(ctx, q, courseID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanTemplateItems(rows)
}

func (r *pgRepository) UpdateTemplateItem(ctx context.Context, item *CourseBudgetTemplateItem) error {
	const q = `
		UPDATE budget.template_items
		SET label=$1, category=$2, preset_amount=$3, overridable=$4, updated_at=now()
		WHERE id=$5`
	tag, err := r.db.Exec(ctx, q, item.Label, item.Category, item.PresetAmount, item.Overridable, item.ID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *pgRepository) DeleteTemplateItem(ctx context.Context, id uuid.UUID) error {
	tag, err := r.db.Exec(ctx, `DELETE FROM budget.template_items WHERE id=$1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// ─── Batch Items ──────────────────────────────────────────────────────────────

func (r *pgRepository) CreateBatchItem(ctx context.Context, item *BatchBudgetItem) error {
	const q = `
		INSERT INTO budget.batch_items
			(id, course_batch_id, template_ref_id, label, category, planned_amount, overridable, class_id, created_by, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`
	_, err := r.db.Exec(ctx, q,
		item.ID, item.CourseBatchID, item.TemplateRefID, item.Label, item.Category,
		item.PlannedAmount, item.Overridable, item.ClassID, item.CreatedBy,
		item.CreatedAt, item.UpdatedAt)
	return err
}

func (r *pgRepository) GetBatchItem(ctx context.Context, id uuid.UUID) (*BatchBudgetItem, error) {
	const q = `
		SELECT id, course_batch_id, template_ref_id, label, category, planned_amount, overridable, class_id, created_by, created_at, updated_at
		FROM budget.batch_items WHERE id=$1`
	item := &BatchBudgetItem{}
	err := r.db.QueryRow(ctx, q, id).Scan(
		&item.ID, &item.CourseBatchID, &item.TemplateRefID, &item.Label, &item.Category,
		&item.PlannedAmount, &item.Overridable, &item.ClassID, &item.CreatedBy,
		&item.CreatedAt, &item.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperrors.ErrNotFound
	}
	return item, err
}

func (r *pgRepository) ListBatchItems(ctx context.Context, batchID uuid.UUID) ([]*BatchBudgetItem, error) {
	const q = `
		SELECT id, course_batch_id, template_ref_id, label, category, planned_amount, overridable, class_id, created_by, created_at, updated_at
		FROM budget.batch_items WHERE course_batch_id=$1 ORDER BY created_at ASC`
	rows, err := r.db.Query(ctx, q, batchID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanBatchItems(rows)
}

func (r *pgRepository) UpdateBatchItem(ctx context.Context, item *BatchBudgetItem) error {
	const q = `
		UPDATE budget.batch_items
		SET label=$1, category=$2, planned_amount=$3, class_id=$4, updated_at=now()
		WHERE id=$5`
	tag, err := r.db.Exec(ctx, q, item.Label, item.Category, item.PlannedAmount, item.ClassID, item.ID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *pgRepository) DeleteBatchItem(ctx context.Context, id uuid.UUID) error {
	tag, err := r.db.Exec(ctx, `DELETE FROM budget.batch_items WHERE id=$1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// ─── Realizations ─────────────────────────────────────────────────────────────

func (r *pgRepository) CreateRealization(ctx context.Context, item *BudgetRealization) error {
	const q = `
		INSERT INTO budget.realizations
			(id, batch_budget_item_id, class_id, actual_amount, description, spent_at, proof_url, recorded_by, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,now())`
	_, err := r.db.Exec(ctx, q,
		item.ID, item.BatchBudgetItemID, item.ClassID, item.ActualAmount,
		item.Description, item.SpentAt, item.ProofURL, item.RecordedBy, item.CreatedAt)
	return err
}

func (r *pgRepository) GetRealization(ctx context.Context, id uuid.UUID) (*BudgetRealization, error) {
	const q = `
		SELECT id, batch_budget_item_id, class_id, actual_amount, description, spent_at, proof_url, recorded_by, created_at, updated_at
		FROM budget.realizations WHERE id=$1`
	item := &BudgetRealization{}
	err := r.db.QueryRow(ctx, q, id).Scan(
		&item.ID, &item.BatchBudgetItemID, &item.ClassID, &item.ActualAmount,
		&item.Description, &item.SpentAt, &item.ProofURL, &item.RecordedBy,
		&item.CreatedAt, &item.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperrors.ErrNotFound
	}
	return item, err
}

func (r *pgRepository) ListRealizations(ctx context.Context, batchItemID uuid.UUID) ([]*BudgetRealization, error) {
	const q = `
		SELECT id, batch_budget_item_id, class_id, actual_amount, description, spent_at, proof_url, recorded_by, created_at, updated_at
		FROM budget.realizations WHERE batch_budget_item_id=$1 ORDER BY spent_at ASC`
	rows, err := r.db.Query(ctx, q, batchItemID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanRealizations(rows)
}

func (r *pgRepository) UpdateRealization(ctx context.Context, item *BudgetRealization) error {
	const q = `
		UPDATE budget.realizations
		SET class_id=$1, actual_amount=$2, description=$3, spent_at=$4, proof_url=$5
		WHERE id=$6`
	tag, err := r.db.Exec(ctx, q,
		item.ClassID, item.ActualAmount, item.Description, item.SpentAt, item.ProofURL, item.ID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *pgRepository) DeleteRealization(ctx context.Context, id uuid.UUID) error {
	tag, err := r.db.Exec(ctx, `DELETE FROM budget.realizations WHERE id=$1`, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// ─── Summary ──────────────────────────────────────────────────────────────────

func (r *pgRepository) GetBatchSummary(ctx context.Context, batchID uuid.UUID) (*BatchBudgetSummary, error) {
	const q = `
		SELECT
			bi.id, bi.course_batch_id, bi.template_ref_id, bi.label, bi.category,
			bi.planned_amount, bi.overridable, bi.class_id, bi.created_by, bi.created_at, bi.updated_at,
			COALESCE(SUM(r.actual_amount), 0) AS actual_amount
		FROM budget.batch_items bi
		LEFT JOIN budget.realizations r ON r.batch_budget_item_id = bi.id
		WHERE bi.course_batch_id = $1
		GROUP BY bi.id
		ORDER BY bi.created_at ASC`

	rows, err := r.db.Query(ctx, q, batchID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return buildBatchSummary(rows)
}

// ─── Scan helpers ─────────────────────────────────────────────────────────────

func scanTemplateItems(rows pgx.Rows) ([]*CourseBudgetTemplateItem, error) {
	var items []*CourseBudgetTemplateItem
	for rows.Next() {
		item := &CourseBudgetTemplateItem{}
		if err := rows.Scan(
			&item.ID, &item.CourseID, &item.Label, &item.Category,
			&item.PresetAmount, &item.Overridable, &item.CreatedAt, &item.UpdatedAt,
		); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func scanBatchItems(rows pgx.Rows) ([]*BatchBudgetItem, error) {
	var items []*BatchBudgetItem
	for rows.Next() {
		item := &BatchBudgetItem{}
		if err := rows.Scan(
			&item.ID, &item.CourseBatchID, &item.TemplateRefID, &item.Label, &item.Category,
			&item.PlannedAmount, &item.Overridable, &item.ClassID, &item.CreatedBy,
			&item.CreatedAt, &item.UpdatedAt,
		); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func scanRealizations(rows pgx.Rows) ([]*BudgetRealization, error) {
	var items []*BudgetRealization
	for rows.Next() {
		item := &BudgetRealization{}
		if err := rows.Scan(
			&item.ID, &item.BatchBudgetItemID, &item.ClassID, &item.ActualAmount,
			&item.Description, &item.SpentAt, &item.ProofURL, &item.RecordedBy,
			&item.CreatedAt, &item.UpdatedAt,
		); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func buildBatchSummary(rows pgx.Rows) (*BatchBudgetSummary, error) {
	summary := &BatchBudgetSummary{}
	for rows.Next() {
		item := &BatchBudgetItem{}
		var actual float64
		if err := rows.Scan(
			&item.ID, &item.CourseBatchID, &item.TemplateRefID, &item.Label, &item.Category,
			&item.PlannedAmount, &item.Overridable, &item.ClassID, &item.CreatedBy,
			&item.CreatedAt, &item.UpdatedAt, &actual,
		); err != nil {
			return nil, err
		}
		summary.Items = append(summary.Items, &BudgetItemSummary{
			Item:     item,
			Actual:   actual,
			Variance: item.PlannedAmount - actual,
		})
		summary.TotalPlanned += item.PlannedAmount
		summary.TotalActual += actual
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	summary.TotalVariance = summary.TotalPlanned - summary.TotalActual
	return summary, nil
}
