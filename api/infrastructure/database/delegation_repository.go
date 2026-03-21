package database

import (
	"context"
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
	ID               uuid.UUID  `db:"id"`
	Title            string     `db:"title"`
	Type             string     `db:"type"`
	Description      string     `db:"description"`
	AssignedToID     *uuid.UUID `db:"assigned_to_id"`
	AssignedToName   string     `db:"assigned_to_name"`
	AssignedByID     *uuid.UUID `db:"assigned_by_id"`
	AssignedByName   string     `db:"assigned_by_name"`
	Priority         string     `db:"priority"`
	Deadline         *time.Time `db:"deadline"`
	Status           string     `db:"status"`
	LinkedEntityID   string     `db:"linked_entity_id"`
	LinkedEntityType string     `db:"linked_entity_type"`
	CreatedAt        time.Time  `db:"created_at"`
	UpdatedAt        time.Time  `db:"updated_at"`
}

func (rec *delegationRecord) toDomain() *delegation.Delegation {
	return &delegation.Delegation{
		ID:               rec.ID,
		Title:            rec.Title,
		Type:             rec.Type,
		Description:      rec.Description,
		AssignedToID:     rec.AssignedToID,
		AssignedToName:   rec.AssignedToName,
		AssignedByID:     rec.AssignedByID,
		AssignedByName:   rec.AssignedByName,
		Priority:         rec.Priority,
		Deadline:         rec.Deadline,
		Status:           rec.Status,
		LinkedEntityID:   rec.LinkedEntityID,
		LinkedEntityType: rec.LinkedEntityType,
		CreatedAt:        rec.CreatedAt,
		UpdatedAt:        rec.UpdatedAt,
	}
}

type delegationStatsRecord struct {
	ActiveCount             int `db:"active_count"`
	PendingCount            int `db:"pending_count"`
	InProgressCount         int `db:"in_progress_count"`
	CompletedThisMonthCount int `db:"completed_this_month_count"`
}

func (r *DelegationRepository) Save(ctx context.Context, d *delegation.Delegation) error {
	query := `
		INSERT INTO delegations (id, title, type, description, assigned_to_id, assigned_to_name, assigned_by_id, assigned_by_name, priority, deadline, status, linked_entity_id, linked_entity_type, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
	`
	_, err := r.db.ExecContext(ctx, query,
		d.ID, d.Title, d.Type, d.Description, d.AssignedToID, d.AssignedToName,
		d.AssignedByID, d.AssignedByName, d.Priority, d.Deadline, d.Status,
		d.LinkedEntityID, d.LinkedEntityType, d.CreatedAt, d.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save delegation: %w", err)
	}
	return nil
}

func (r *DelegationRepository) Update(ctx context.Context, d *delegation.Delegation) error {
	query := `
		UPDATE delegations SET title=$1, type=$2, description=$3, assigned_to_id=$4, assigned_to_name=$5,
		assigned_by_id=$6, assigned_by_name=$7, priority=$8, deadline=$9, status=$10,
		linked_entity_id=$11, linked_entity_type=$12, updated_at=$13 WHERE id=$14
	`
	_, err := r.db.ExecContext(ctx, query,
		d.Title, d.Type, d.Description, d.AssignedToID, d.AssignedToName,
		d.AssignedByID, d.AssignedByName, d.Priority, d.Deadline, d.Status,
		d.LinkedEntityID, d.LinkedEntityType, time.Now(), d.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update delegation: %w", err)
	}
	return nil
}

func (r *DelegationRepository) List(ctx context.Context, offset, limit int, status, delegationType string) ([]*delegation.Delegation, int, error) {
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	if delegationType != "" {
		conditions = append(conditions, fmt.Sprintf("type = $%d", argIdx))
		args = append(args, delegationType)
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

	listArgs := append(args, limit, offset)
	query := fmt.Sprintf(
		`SELECT id, title, type, description, assigned_to_id, assigned_to_name, assigned_by_id, assigned_by_name, priority, deadline, status, linked_entity_id, linked_entity_type, created_at, updated_at FROM delegations%s ORDER BY created_at DESC LIMIT $%d OFFSET $%d`,
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
