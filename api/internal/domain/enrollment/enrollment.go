package enrollment

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidStudentID     = errors.New("invalid student id")
	ErrInvalidCourseBatchID = errors.New("invalid course batch id")
	ErrEnrollmentNotFound   = errors.New("enrollment not found")
)

type Enrollment struct {
	ID            uuid.UUID
	StudentID     uuid.UUID
	CourseBatchID uuid.UUID
	EnrolledAt    time.Time
	Status        string
	PaymentStatus string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

func NewEnrollment(studentID, courseBatchID uuid.UUID) (*Enrollment, error) {
	now := time.Now()
	return &Enrollment{
		ID:            uuid.New(),
		StudentID:     studentID,
		CourseBatchID: courseBatchID,
		EnrolledAt:    now,
		Status:        "active",
		PaymentStatus: "pending",
		CreatedAt:     now,
		UpdatedAt:     now,
	}, nil
}

type WriteRepository interface {
	Save(ctx context.Context, e *Enrollment) error
	UpdateStatus(ctx context.Context, id uuid.UUID, status string) error
	UpdatePaymentStatus(ctx context.Context, id uuid.UUID, paymentStatus string) error
}

type BatchSummary struct {
	BatchID         uuid.UUID
	BatchName       string
	StartDate       string
	EndDate         string
	MaxParticipants int
	IsActive        bool
	CourseID        string
	CourseName      string
	DepartmentID    string
	DepartmentName  string
	EnrollmentCount int
	PaidCount       int
	LatestEnrolledAt *time.Time
}

type EnrichedEnrollment struct {
	ID            uuid.UUID
	StudentID     uuid.UUID
	StudentName   string
	StudentPhone  string
	CourseBatchID uuid.UUID
	BatchName     string
	CourseName    string
	EnrolledAt    time.Time
	Status        string
	PaymentStatus string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Enrollment, error)
	List(ctx context.Context, offset, limit int) ([]*Enrollment, int, error)
	ListEnriched(ctx context.Context, offset, limit int) ([]*EnrichedEnrollment, int, error)
	ListBatchSummary(ctx context.Context) ([]*BatchSummary, error)
}
