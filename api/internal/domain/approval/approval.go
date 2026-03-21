package approval

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrApprovalNotFound   = errors.New("approval not found")
	ErrInvalidStatus      = errors.New("invalid approval status")
	ErrNotCurrentApprover = errors.New("not the current approver")
	ErrAlreadyFinalized   = errors.New("approval already finalized")
)

type Status string

const (
	StatusPending   Status = "pending"
	StatusApproved  Status = "approved"
	StatusRejected  Status = "rejected"
	StatusCancelled Status = "cancelled"
)

type StepStatus string

const (
	StepPending  StepStatus = "pending"
	StepApproved StepStatus = "approved"
	StepRejected StepStatus = "rejected"
)

type Type string

const (
	TypeAssignDeptLeader    Type = "assign_dept_leader"
	TypeProposeCourse       Type = "propose_course"
	TypeVersionChange       Type = "version_change"
	TypeCreateBatch         Type = "create_batch"
	TypeBatchMinMaxOverride Type = "batch_min_max_override"
	TypeScheduleOverlap     Type = "schedule_overlap"
	TypeRevokeCertificate   Type = "revoke_certificate"
)

type ApprovalStep struct {
	ID           uuid.UUID
	ApprovalID   uuid.UUID
	StepNumber   int
	ApproverID   uuid.UUID
	ApproverRole string
	Status       StepStatus
	Comment      string
	ActedAt      *time.Time
	CreatedAt    time.Time
}

type ApprovalRequest struct {
	ID          uuid.UUID
	Type        Type
	EntityType  string
	EntityID    uuid.UUID
	InitiatorID uuid.UUID
	CurrentStep int
	TotalSteps  int
	Status      Status
	Reason      string
	Steps       []*ApprovalStep
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

func NewApprovalRequest(approvalType Type, entityType string, entityID, initiatorID uuid.UUID, reason string, steps []StepInput) (*ApprovalRequest, error) {
	if approvalType == "" {
		return nil, errors.New("approval type is required")
	}
	if entityType == "" {
		return nil, errors.New("entity type is required")
	}
	if len(steps) == 0 {
		return nil, errors.New("at least one approval step is required")
	}

	now := time.Now()
	approvalID := uuid.New()

	approvalSteps := make([]*ApprovalStep, len(steps))
	for i, s := range steps {
		approvalSteps[i] = &ApprovalStep{
			ID:           uuid.New(),
			ApprovalID:   approvalID,
			StepNumber:   i + 1,
			ApproverID:   s.ApproverID,
			ApproverRole: s.ApproverRole,
			Status:       StepPending,
			CreatedAt:    now,
		}
	}

	return &ApprovalRequest{
		ID:          approvalID,
		Type:        approvalType,
		EntityType:  entityType,
		EntityID:    entityID,
		InitiatorID: initiatorID,
		CurrentStep: 1,
		TotalSteps:  len(steps),
		Status:      StatusPending,
		Reason:      reason,
		Steps:       approvalSteps,
		CreatedAt:   now,
		UpdatedAt:   now,
	}, nil
}

type StepInput struct {
	ApproverID   uuid.UUID
	ApproverRole string
}

type WriteRepository interface {
	Save(ctx context.Context, a *ApprovalRequest) error
	Update(ctx context.Context, a *ApprovalRequest) error
	UpdateStep(ctx context.Context, step *ApprovalStep) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*ApprovalRequest, error)
	List(ctx context.Context, offset, limit int, status string, approverID *uuid.UUID) ([]*ApprovalRequest, int, error)
}
