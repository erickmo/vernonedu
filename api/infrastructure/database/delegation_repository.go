package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/delegation"
)

type DelegationRepository struct {
	db *sqlx.DB
}

func NewDelegationRepository(db *sqlx.DB) *DelegationRepository {
	return &DelegationRepository{db: db}
}

type delegationRecord struct {
	ID               uuid.UUID      `db:"id"`
	Title            string         `db:"title"`
	Type             string         `db:"type"`
	Description      string         `db:"description"`
	RequestedByID    uuid.UUID      `db:"requested_by_id"`
	RequestedByName  string         `db:"requested_by_name"`
	AssignedToID     *uuid.UUID     `db:"assigned_to_id"`
	AssignedToName   string         `db:"assigned_to_name"`
	AssignedToRole   string         `db:"assigned_to_role"`
	DueDate          *time.Time     `db:"due_date"`
	Priority         string         `db:"priority"`
	Status           string         `db:"status"`
	LinkedEntityType sql.NullString `db:"linked_entity_type"`
	LinkedEntityID   *uuid.UUID     `db:"linked_entity_id"`
	Notes            sql.NullString `db:"notes"`
	CreatedAt        time.Time      `db:"created_at"`
	UpdatedAt        time.Time      `db:"updated_at"`
}

func (rec *delegationRecord) toDomain() *delegation.Delegation {
	d := &delegation.Delegation{
		ID:              rec.ID,
		Title:           rec.Title,
		Type:            delegation.DelegationType(rec.Type),
		Description:     rec.Description,
		RequestedByID:   rec.RequestedByID,
		RequestedByName: rec.RequestedByName,
		AssignedToID:    rec.AssignedToID,
		AssignedToName:  rec.AssignedToName,
		AssignedToRole:  rec.AssignedToRole,
		DueDate:         rec.DueDate,
		Priority:        delegation.Priority(rec.Priority),
		Status:          delegation.Status(rec.Status),
		LinkedEntityID:  rec.LinkedEntityID,
		CreatedAt:       rec.CreatedAt,
		UpdatedAt:       rec.UpdatedAt,
	}
	if rec.LinkedEntityType.Valid {
		d.LinkedEntityType = &rec.LinkedEntityType.String
	}
	if rec.Notes.Valid {
		d.Notes = &rec.Notes.String
	}
	return d
}

type delegationStatsRecord struct {
	ActiveCount             int `db:"active_count"`
	PendingCount            int `db:"pending_count"`
	InProgressCount         int `db:"in_progress_count"`
	CompletedThisMonthCount int `db:"completed_this_month_count"`
}

// ---- WriteRepository ----

func (r *DelegationRepository) Save(ctx context.Context, d *delegation.Delegation) error {
	query := `
		INSERT INTO delegations (
			id, title, type, description,
			requested_by_id, requested_by_name,
			assigned_to_id, assigned_to_name, assigned_to_role,
			due_date, priority, status,
			linked_entity_type, linked_entity_id, notes,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4,
			$5, $6,
			$7, $8, $9,
			$10, $11, $12,
			$13, $14, $15,
			$16, $17
		)
	`
	var linkedEntityType interface{}
	if d.LinkedEntityType != nil {
		linkedEntityType = *d.LinkedEntityType
	}
	var linkedEntityID interface{}
	if d.LinkedEntityID != nil {
		linkedEntityID = *d.LinkedEntityID
	}
	var notes interface{}
	if d.Notes != nil {
		notes = *d.Notes
	}

	_, err := r.db.ExecContext(ctx, query,
		d.ID, d.Title, string(d.Type), d.Description,
		d.RequestedByID, d.RequestedByName,
		d.AssignedToID, d.AssignedToName, d.AssignedToRole,
		d.DueDate, string(d.Priority), string(d.Status),
		linkedEntityType, linkedEntityID, notes,
		d.CreatedAt, d.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save delegation: %w", err)
	}
	return nil
}

func (r *DelegationRepository) Update(ctx context.Context, d *delegation.Delegation) error {
	query := `
		UPDATE delegations SET
			title=$1, type=$2, description=$3,
			requested_by_id=$4, requested_by_name=$5,
			assigned_to_id=$6, assigned_to_name=$7, assigned_to_role=$8,
			due_date=$9, priority=$10, status=$11,
			linked_entity_type=$12, linked_entity_id=$13, notes=$14,
			updated_at=$15
		WHERE id=$16
	`
	var linkedEntityType interface{}
	if d.LinkedEntityType != nil {
		linkedEntityType = *d.LinkedEntityType
	}
	var linkedEntityID interface{}
	if d.LinkedEntityID != nil {
		linkedEntityID = *d.LinkedEntityID
	}
	var notes interface{}
	if d.Notes != nil {
		notes = *d.Notes
	}

	_, err := r.db.ExecContext(ctx, query,
		d.Title, string(d.Type), d.Description,
		d.RequestedByID, d.RequestedByName,
		d.AssignedToID, d.AssignedToName, d.AssignedToRole,
		d.DueDate, string(d.Priority), string(d.Status),
		linkedEntityType, linkedEntityID, notes,
		time.Now(), d.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update delegation: %w", err)
	}
	return nil
}

func (r *DelegationRepository) GetByID(ctx context.Context, id uuid.UUID) (*delegation.Delegation, error) {
	var rec delegationRecord
	query := `
		SELECT id, title, type, description,
		       requested_by_id, requested_by_name,
		       assigned_to_id, assigned_to_name, assigned_to_role,
		       due_date, priority, status,
		       linked_entity_type, linked_entity_id, notes,
		       created_at, updated_at
		FROM delegations WHERE id=$1
	`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		if err == sql.ErrNoRows {
			return nil, delegation.ErrDelegationNotFound
		}
		return nil, fmt.Errorf("failed to get delegation: %w", err)
	}
	return rec.toDomain(), nil
}

// ---- ReadRepository ----

func (r *DelegationRepository) List(ctx context.Context, filter delegation.ListFilter) ([]*delegation.Delegation, int, error) {
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if filter.Status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIdx))
		args = append(args, filter.Status)
		argIdx++
	}
	if filter.Type != "" {
		conditions = append(conditions, fmt.Sprintf("type = $%d", argIdx))
		args = append(args, filter.Type)
		argIdx++
	}
	if filter.AssignedToID != nil {
		conditions = append(conditions, fmt.Sprintf("assigned_to_id = $%d", argIdx))
		args = append(args, *filter.AssignedToID)
		argIdx++
	}
	if filter.RequestedByID != nil {
		conditions = append(conditions, fmt.Sprintf("requested_by_id = $%d", argIdx))
		args = append(args, *filter.RequestedByID)
		argIdx++
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = " WHERE "
		for i, c := range conditions {
			if i > 0 {
				whereClause += " AND "
			}
			whereClause += c
		}
	}

	var total int
	if err := r.db.GetContext(ctx, &total, `SELECT COUNT(*) FROM delegations`+whereClause, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count delegations: %w", err)
	}

	limit := filter.Limit
	if limit == 0 {
		limit = 20
	}
	listArgs := append(args, limit, filter.Offset)
	query := fmt.Sprintf(
		`SELECT id, title, type, description,
		        requested_by_id, requested_by_name,
		        assigned_to_id, assigned_to_name, assigned_to_role,
		        due_date, priority, status,
		        linked_entity_type, linked_entity_id, notes,
		        created_at, updated_at
		 FROM delegations%s ORDER BY created_at DESC LIMIT $%d OFFSET $%d`,
		whereClause, argIdx, argIdx+1,
	)

	var recs []delegationRecord
	if err := r.db.SelectContext(ctx, &recs, query, listArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list delegations: %w", err)
	}

	delegations := make([]*delegation.Delegation, len(recs))
	for i, rec := range recs {
		delegations[i] = rec.toDomain()
	}
	return delegations, total, nil
}

func (r *DelegationRepository) Stats(ctx context.Context) (*delegation.DelegationStats, error) {
	var rec delegationStatsRecord
	query := `
		SELECT
		  COUNT(CASE WHEN status IN ('pending', 'accepted', 'in_progress') THEN 1 END) AS active_count,
		  COUNT(CASE WHEN status = 'pending' THEN 1 END) AS pending_count,
		  COUNT(CASE WHEN status = 'in_progress' THEN 1 END) AS in_progress_count,
		  COUNT(CASE WHEN status = 'completed' AND DATE_TRUNC('month', updated_at) = DATE_TRUNC('month', NOW()) THEN 1 END) AS completed_this_month_count
		FROM delegations
	`
	if err := r.db.GetContext(ctx, &rec, query); err != nil {
		return nil, fmt.Errorf("failed to get delegation stats: %w", err)
	}
	return &delegation.DelegationStats{
		ActiveCount:             rec.ActiveCount,
		PendingCount:            rec.PendingCount,
		InProgressCount:         rec.InProgressCount,
		CompletedThisMonthCount: rec.CompletedThisMonthCount,
	}, nil
}
