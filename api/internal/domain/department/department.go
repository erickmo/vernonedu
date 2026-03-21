package department

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName        = errors.New("invalid department name")
	ErrDepartmentNotFound = errors.New("department not found")
)

type Department struct {
	ID          uuid.UUID
	Name        string
	Description string
	LeaderID    *uuid.UUID
	IsActive    bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

func NewDepartment(name, description string, isActive bool) (*Department, error) {
	if name == "" {
		return nil, ErrInvalidName
	}

	return &Department{
		ID:          uuid.New(),
		Name:        name,
		Description: description,
		IsActive:    isActive,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}, nil
}

func (d *Department) UpdateName(name string) error {
	if name == "" {
		return ErrInvalidName
	}
	d.Name = name
	d.UpdatedAt = time.Now()
	return nil
}

// DepartmentSummary holds aggregated stats for the department list page.
type DepartmentSummary struct {
	ID                  uuid.UUID
	Name                string
	Description         string
	CourseCount         int
	BatchUpcoming       int
	BatchOngoing        int
	BatchCompleted      int
	PaidEnrollmentCount int
}

// DepartmentBatch is used for the Calendar tab in the department dashboard.
type DepartmentBatch struct {
	BatchID         uuid.UUID
	BatchName       string
	StartDate       string
	EndDate         string
	MaxParticipants int
	IsActive        bool
	CourseName      string
	FacilitatorID   string
	FacilitatorName string
	EnrollmentCount int
}

// DepartmentCourse is used for the Course tab in the department dashboard.
type DepartmentCourse struct {
	CourseID    string
	CourseName  string
	Description string
	IsActive    bool
	BatchCount  int
}

// DepartmentStudent is used for the Student tab in the department dashboard.
type DepartmentStudent struct {
	StudentID          uuid.UUID
	StudentName        string
	Email              string
	Phone              string
	IsActive           bool
	JoinedAt           time.Time
	EnrolledBatchCount int
}

// DepartmentTalentPoolEntry is used for the Talent Pool tab in the department dashboard.
type DepartmentTalentPoolEntry struct {
	ID               uuid.UUID
	ParticipantID    uuid.UUID
	ParticipantName  string
	ParticipantEmail string
	Status           string
	JoinedAt         time.Time
	TestScore        *float64
}

type WriteRepository interface {
	Save(ctx context.Context, d *Department) error
	Update(ctx context.Context, d *Department) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Department, error)
	List(ctx context.Context, offset, limit int) ([]*Department, int, error)
	GetSummaries(ctx context.Context) ([]*DepartmentSummary, error)
	GetBatches(ctx context.Context, departmentID uuid.UUID) ([]*DepartmentBatch, error)
	GetCourses(ctx context.Context, departmentID uuid.UUID) ([]*DepartmentCourse, error)
	GetStudents(ctx context.Context, departmentID uuid.UUID, status string) ([]*DepartmentStudent, error)
	GetTalentPoolEntries(ctx context.Context, departmentID uuid.UUID) ([]*DepartmentTalentPoolEntry, error)
}
