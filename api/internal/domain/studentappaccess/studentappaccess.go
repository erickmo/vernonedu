package studentappaccess

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var ErrAccessNotFound = errors.New("student app access not found")

type Status string

const (
	StatusActive  Status = "active"
	StatusRevoked Status = "revoked"
)

type StudentAppAccess struct {
	ID        uuid.UUID
	StudentID uuid.UUID
	AppName   string
	BatchID   uuid.UUID
	GrantedAt time.Time
	RevokedAt *time.Time
	Status    Status
}

func NewStudentAppAccess(studentID uuid.UUID, appName string, batchID uuid.UUID) *StudentAppAccess {
	return &StudentAppAccess{
		ID:        uuid.New(),
		StudentID: studentID,
		AppName:   appName,
		BatchID:   batchID,
		GrantedAt: time.Now(),
		Status:    StatusActive,
	}
}

type WriteRepository interface {
	Save(ctx context.Context, a *StudentAppAccess) error
	RevokeByStudentAndBatch(ctx context.Context, studentID, batchID uuid.UUID) error
	RevokeAllByBatch(ctx context.Context, batchID uuid.UUID) error
}

type ReadRepository interface {
	GetActiveByStudentAndBatch(ctx context.Context, studentID, batchID uuid.UUID) (*StudentAppAccess, error)
	ListByStudent(ctx context.Context, studentID uuid.UUID) ([]*StudentAppAccess, error)
}
