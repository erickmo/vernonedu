package coursebatch

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

const (
	PaymentMethodUpfront    = "upfront"
	PaymentMethodScheduled  = "scheduled"
	PaymentMethodMonthly    = "monthly"
	PaymentMethodBatchLump  = "batch_lump"
	PaymentMethodPerSession = "per_session"

	CourseBatchStatusPending = "pending_approval"
	CourseBatchStatusActive  = "active"
)

var ValidPaymentMethods = map[string]bool{
	PaymentMethodUpfront:    true,
	PaymentMethodScheduled:  true,
	PaymentMethodMonthly:    true,
	PaymentMethodBatchLump:  true,
	PaymentMethodPerSession: true,
}

var (
	ErrInvalidName          = errors.New("invalid course batch name")
	ErrInvalidDates         = errors.New("invalid course batch dates")
	ErrCourseBatchNotFound  = errors.New("course batch not found")
	ErrInvalidPaymentMethod = errors.New("invalid payment method")
)

type CourseBatch struct {
	ID              uuid.UUID
	CourseID        uuid.UUID
	MasterCourseID  *uuid.UUID
	BranchID        *uuid.UUID // optional branch this batch belongs to
	Name            string
	Code            string
	MinParticipants int
	WebsiteVisible  bool
	Price           int64  // in smallest currency unit (cents/rupiah)
	PaymentMethod   string // upfront|scheduled|monthly|batch_lump|per_session
	StartDate       time.Time
	EndDate         time.Time
	FacilitatorID   *uuid.UUID
	MaxParticipants int
	IsActive        bool
	Status          string
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type EnrichedCourseBatch struct {
	CourseBatch
	FacilitatorName string
	EnrollmentCount int
}

func NewCourseBatch(courseID uuid.UUID, name string, startDate, endDate time.Time, minParticipants, maxParticipants int) (*CourseBatch, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if endDate.Before(startDate) {
		return nil, ErrInvalidDates
	}

	return &CourseBatch{
		ID:              uuid.New(),
		CourseID:        courseID,
		Name:            name,
		MinParticipants: minParticipants,
		MaxParticipants: maxParticipants,
		WebsiteVisible:  true,
		PaymentMethod:   PaymentMethodUpfront,
		IsActive:        true,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}, nil
}

func (cb *CourseBatch) UpdateName(name string) error {
	if name == "" {
		return ErrInvalidName
	}
	cb.Name = name
	cb.UpdatedAt = time.Now()
	return nil
}

type WriteRepository interface {
	Save(ctx context.Context, cb *CourseBatch) error
	Update(ctx context.Context, cb *CourseBatch) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type BatchEnrollmentItem struct {
	EnrollmentID  uuid.UUID
	StudentID     uuid.UUID
	StudentName   string
	StudentEmail  string
	StudentPhone  string
	EnrolledAt    time.Time
	Status        string
	PaymentStatus string
}

type BatchDetailInfo struct {
	ID                uuid.UUID
	Name              string
	StartDate         time.Time
	EndDate           time.Time
	MaxParticipants   int
	IsActive          bool
	CourseID          string
	CourseName        string
	CourseDescription string
	DepartmentID      string
	DepartmentName    string
	FacilitatorID     string
	FacilitatorName   string
	FacilitatorEmail  string
	CreatedAt         time.Time
	Enrollments       []*BatchEnrollmentItem
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*CourseBatch, error)
	List(ctx context.Context, offset, limit int) ([]*CourseBatch, int, error)
	ListEnriched(ctx context.Context, offset, limit int) ([]*EnrichedCourseBatch, int, error)
	GetBatchDetail(ctx context.Context, batchID uuid.UUID) (*BatchDetailInfo, error)
}
