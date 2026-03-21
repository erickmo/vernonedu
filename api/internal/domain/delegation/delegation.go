package delegation

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrDelegationNotFound    = errors.New("delegation not found")
	ErrInvalidType           = errors.New("invalid delegation type")
	ErrInvalidPriority       = errors.New("invalid delegation priority")
	ErrInvalidStatus         = errors.New("invalid delegation status")
	ErrInvalidStatusTransition = errors.New("invalid delegation status transition")
)

type DelegationType string

const (
	TypeRequestCourse  DelegationType = "request_course"
	TypeRequestProject DelegationType = "request_project"
	TypeDelegateTask   DelegationType = "delegate_task"
)

type Priority string

const (
	PriorityLow    Priority = "low"
	PriorityMedium Priority = "medium"
	PriorityHigh   Priority = "high"
	PriorityUrgent Priority = "urgent"
)

type Status string

const (
	StatusPending    Status = "pending"
	StatusAccepted   Status = "accepted"
	StatusInProgress Status = "in_progress"
	StatusCompleted  Status = "completed"
	StatusCancelled  Status = "cancelled"
)

func ValidType(t string) bool {
	switch DelegationType(t) {
	case TypeRequestCourse, TypeRequestProject, TypeDelegateTask:
		return true
	}
	return false
}

func ValidPriority(p string) bool {
	switch Priority(p) {
	case PriorityLow, PriorityMedium, PriorityHigh, PriorityUrgent:
		return true
	}
	return false
}

func ValidStatus(s string) bool {
	switch Status(s) {
	case StatusPending, StatusAccepted, StatusInProgress, StatusCompleted, StatusCancelled:
		return true
	}
	return false
}

type Delegation struct {
	ID               uuid.UUID
	Title            string
	Type             DelegationType
	Description      string
	RequestedByID    uuid.UUID
	RequestedByName  string
	AssignedToID     *uuid.UUID
	AssignedToName   string
	AssignedToRole   string
	DueDate          *time.Time
	Priority         Priority
	Status           Status
	LinkedEntityType *string
	LinkedEntityID   *uuid.UUID
	Notes            *string
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

func NewDelegation(
	title, description string,
	delegationType DelegationType,
	requestedByID uuid.UUID,
	requestedByName string,
	assignedToID *uuid.UUID,
	assignedToName, assignedToRole string,
	priority Priority,
	dueDate *time.Time,
	linkedEntityType *string,
	linkedEntityID *uuid.UUID,
	notes *string,
) (*Delegation, error) {
	if title == "" {
		return nil, errors.New("title is required")
	}
	if !ValidType(string(delegationType)) {
		return nil, ErrInvalidType
	}
	if !ValidPriority(string(priority)) {
		return nil, ErrInvalidPriority
	}
	now := time.Now()
	return &Delegation{
		ID:               uuid.New(),
		Title:            title,
		Type:             delegationType,
		Description:      description,
		RequestedByID:    requestedByID,
		RequestedByName:  requestedByName,
		AssignedToID:     assignedToID,
		AssignedToName:   assignedToName,
		AssignedToRole:   assignedToRole,
		DueDate:          dueDate,
		Priority:         priority,
		Status:           StatusPending,
		LinkedEntityType: linkedEntityType,
		LinkedEntityID:   linkedEntityID,
		Notes:            notes,
		CreatedAt:        now,
		UpdatedAt:        now,
	}, nil
}

func (d *Delegation) Accept() error {
	if d.Status != StatusPending {
		return ErrInvalidStatusTransition
	}
	d.Status = StatusAccepted
	d.UpdatedAt = time.Now()
	return nil
}

func (d *Delegation) Complete(notes *string) error {
	if d.Status != StatusAccepted && d.Status != StatusInProgress {
		return ErrInvalidStatusTransition
	}
	d.Status = StatusCompleted
	if notes != nil && *notes != "" {
		d.Notes = notes
	}
	d.UpdatedAt = time.Now()
	return nil
}

func (d *Delegation) Cancel(notes *string) error {
	if d.Status == StatusCompleted || d.Status == StatusCancelled {
		return ErrInvalidStatusTransition
	}
	d.Status = StatusCancelled
	if notes != nil && *notes != "" {
		d.Notes = notes
	}
	d.UpdatedAt = time.Now()
	return nil
}

type WriteRepository interface {
	Save(ctx context.Context, d *Delegation) error
	Update(ctx context.Context, d *Delegation) error
	GetByID(ctx context.Context, id uuid.UUID) (*Delegation, error)
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Delegation, error)
	List(ctx context.Context, filter ListFilter) ([]*Delegation, int, error)
	Stats(ctx context.Context) (*DelegationStats, error)
}

type ListFilter struct {
	Type            string
	Status          string
	AssignedToID    *uuid.UUID
	RequestedByID   *uuid.UUID
	Offset          int
	Limit           int
}

type DelegationStats struct {
	ActiveCount             int
	PendingCount            int
	InProgressCount         int
	CompletedThisMonthCount int
}
