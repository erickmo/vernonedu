package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/approval"
)

type approvalRecord struct {
	ID          uuid.UUID `db:"id"`
	Type        string    `db:"type"`
	EntityType  string    `db:"entity_type"`
	EntityID    uuid.UUID `db:"entity_id"`
	InitiatorID uuid.UUID `db:"initiator_id"`
	CurrentStep int       `db:"current_step"`
	TotalSteps  int       `db:"total_steps"`
	Status      string    `db:"status"`
	Reason      string    `db:"reason"`
	CreatedAt   time.Time `db:"created_at"`
	UpdatedAt   time.Time `db:"updated_at"`
}

type approvalStepRecord struct {
	ID           uuid.UUID  `db:"id"`
	ApprovalID   uuid.UUID  `db:"approval_id"`
	StepNumber   int        `db:"step_number"`
	ApproverID   uuid.UUID  `db:"approver_id"`
	ApproverRole string     `db:"approver_role"`
	Status       string     `db:"status"`
	Comment      string     `db:"comment"`
	ActedAt      *time.Time `db:"acted_at"`
	CreatedAt    time.Time  `db:"created_at"`
}

type ApprovalRepository struct {
	db *sqlx.DB
}

func NewApprovalRepository(db *sqlx.DB) *ApprovalRepository {
	return &ApprovalRepository{db: db}
}

func (r *ApprovalRepository) Save(ctx context.Context, a *approval.ApprovalRequest) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	query := `
		INSERT INTO approval_requests
			(id, type, entity_type, entity_id, initiator_id, current_step, total_steps, status, reason, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
	`
	_, err = tx.ExecContext(ctx, query,
		a.ID, string(a.Type), a.EntityType, a.EntityID, a.InitiatorID,
		a.CurrentStep, a.TotalSteps, string(a.Status), a.Reason,
		a.CreatedAt, a.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to insert approval request: %w", err)
	}

	stepQuery := `
		INSERT INTO approval_steps
			(id, approval_id, step_number, approver_id, approver_role, status, comment, acted_at, created_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
	`
	for _, s := range a.Steps {
		_, err = tx.ExecContext(ctx, stepQuery,
			s.ID, s.ApprovalID, s.StepNumber, s.ApproverID, s.ApproverRole,
			string(s.Status), s.Comment, s.ActedAt, s.CreatedAt,
		)
		if err != nil {
			return fmt.Errorf("failed to insert approval step: %w", err)
		}
	}

	return tx.Commit()
}

func (r *ApprovalRepository) Update(ctx context.Context, a *approval.ApprovalRequest) error {
	query := `
		UPDATE approval_requests
		SET current_step=$2, status=$3, updated_at=$4
		WHERE id=$1
	`
	_, err := r.db.ExecContext(ctx, query, a.ID, a.CurrentStep, string(a.Status), a.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to update approval request: %w", err)
	}
	return nil
}

func (r *ApprovalRepository) UpdateStep(ctx context.Context, step *approval.ApprovalStep) error {
	query := `
		UPDATE approval_steps
		SET status=$2, comment=$3, acted_at=$4
		WHERE id=$1
	`
	_, err := r.db.ExecContext(ctx, query, step.ID, string(step.Status), step.Comment, step.ActedAt)
	if err != nil {
		return fmt.Errorf("failed to update approval step: %w", err)
	}
	return nil
}

func (r *ApprovalRepository) GetByID(ctx context.Context, id uuid.UUID) (*approval.ApprovalRequest, error) {
	var rec approvalRecord
	err := r.db.GetContext(ctx, &rec, `
		SELECT id, type, entity_type, entity_id, initiator_id, current_step, total_steps, status, COALESCE(reason,'') AS reason, created_at, updated_at
		FROM approval_requests WHERE id=$1
	`, id)
	if err == sql.ErrNoRows {
		return nil, approval.ErrApprovalNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get approval: %w", err)
	}

	steps, err := r.getSteps(ctx, id)
	if err != nil {
		return nil, err
	}

	return recordToApprovalEntity(&rec, steps), nil
}

func (r *ApprovalRepository) List(ctx context.Context, offset, limit int, status string, approverID *uuid.UUID) ([]*approval.ApprovalRequest, int, error) {
	var total int

	if approverID != nil {
		countQuery := `SELECT COUNT(*) FROM approval_requests WHERE ($1='' OR status=$1) AND id IN (SELECT approval_id FROM approval_steps WHERE approver_id=$2)`
		if err := r.db.GetContext(ctx, &total, countQuery, status, *approverID); err != nil {
			return nil, 0, fmt.Errorf("failed to count approvals: %w", err)
		}

		listQuery := `
			SELECT id, type, entity_type, entity_id, initiator_id, current_step, total_steps, status, COALESCE(reason,'') AS reason, created_at, updated_at
			FROM approval_requests
			WHERE ($1='' OR status=$1) AND id IN (SELECT approval_id FROM approval_steps WHERE approver_id=$2)
			ORDER BY created_at DESC
			LIMIT $3 OFFSET $4
		`
		var rows []approvalRecord
		if err := r.db.SelectContext(ctx, &rows, listQuery, status, *approverID, limit, offset); err != nil {
			return nil, 0, fmt.Errorf("failed to list approvals: %w", err)
		}

		out := make([]*approval.ApprovalRequest, len(rows))
		for i, row := range rows {
			steps, err := r.getSteps(ctx, row.ID)
			if err != nil {
				return nil, 0, err
			}
			out[i] = recordToApprovalEntity(&row, steps)
		}
		return out, total, nil
	}

	countQuery := `SELECT COUNT(*) FROM approval_requests WHERE ($1='' OR status=$1)`
	if err := r.db.GetContext(ctx, &total, countQuery, status); err != nil {
		return nil, 0, fmt.Errorf("failed to count approvals: %w", err)
	}

	listQuery := `
		SELECT id, type, entity_type, entity_id, initiator_id, current_step, total_steps, status, COALESCE(reason,'') AS reason, created_at, updated_at
		FROM approval_requests
		WHERE ($1='' OR status=$1)
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	var rows []approvalRecord
	if err := r.db.SelectContext(ctx, &rows, listQuery, status, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list approvals: %w", err)
	}

	out := make([]*approval.ApprovalRequest, len(rows))
	for i, row := range rows {
		steps, err := r.getSteps(ctx, row.ID)
		if err != nil {
			return nil, 0, err
		}
		out[i] = recordToApprovalEntity(&row, steps)
	}
	return out, total, nil
}

func (r *ApprovalRepository) getSteps(ctx context.Context, approvalID uuid.UUID) ([]*approval.ApprovalStep, error) {
	var rows []approvalStepRecord
	err := r.db.SelectContext(ctx, &rows, `
		SELECT id, approval_id, step_number, approver_id, approver_role, status, COALESCE(comment,'') AS comment, acted_at, created_at
		FROM approval_steps WHERE approval_id=$1 ORDER BY step_number
	`, approvalID)
	if err != nil {
		return nil, fmt.Errorf("failed to get approval steps: %w", err)
	}

	steps := make([]*approval.ApprovalStep, len(rows))
	for i, row := range rows {
		steps[i] = &approval.ApprovalStep{
			ID:           row.ID,
			ApprovalID:   row.ApprovalID,
			StepNumber:   row.StepNumber,
			ApproverID:   row.ApproverID,
			ApproverRole: row.ApproverRole,
			Status:       approval.StepStatus(row.Status),
			Comment:      row.Comment,
			ActedAt:      row.ActedAt,
			CreatedAt:    row.CreatedAt,
		}
	}
	return steps, nil
}

func recordToApprovalEntity(rec *approvalRecord, steps []*approval.ApprovalStep) *approval.ApprovalRequest {
	return &approval.ApprovalRequest{
		ID:          rec.ID,
		Type:        approval.Type(rec.Type),
		EntityType:  rec.EntityType,
		EntityID:    rec.EntityID,
		InitiatorID: rec.InitiatorID,
		CurrentStep: rec.CurrentStep,
		TotalSteps:  rec.TotalSteps,
		Status:      approval.Status(rec.Status),
		Reason:      rec.Reason,
		Steps:       steps,
		CreatedAt:   rec.CreatedAt,
		UpdatedAt:   rec.UpdatedAt,
	}
}
