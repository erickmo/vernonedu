package student

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName     = errors.New("invalid student name")
	ErrInvalidEmail    = errors.New("invalid student email")
	ErrStudentNotFound = errors.New("student not found")
)

type Student struct {
	ID           uuid.UUID
	Name         string
	Email        string
	Phone        string
	DepartmentID *uuid.UUID
	JoinedAt     time.Time
	IsActive     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func NewStudent(name, email, phone string, departmentID *uuid.UUID) (*Student, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if email == "" {
		return nil, ErrInvalidEmail
	}
	now := time.Now()
	return &Student{
		ID:           uuid.New(),
		Name:         name,
		Email:        email,
		Phone:        phone,
		DepartmentID: departmentID,
		JoinedAt:     now,
		IsActive:     true,
		CreatedAt:    now,
		UpdatedAt:    now,
	}, nil
}

// StudentListEntry is a read model for the list endpoint with enrollment counts.
type StudentListEntry struct {
	Student
	ActiveBatchCount     int
	CompletedCourseCount int
}

// StudentDetail is an enriched read model for the student detail endpoint.
type StudentDetail struct {
	Student
	DepartmentName   string
	TotalEnrollments int
	CompletedCourses int
}

// StudentEnrollmentHistoryItem represents a student's enrollment in a course batch.
type StudentEnrollmentHistoryItem struct {
	ID               uuid.UUID
	BatchID          uuid.UUID
	BatchCode        string
	BatchName        string
	BatchType        string
	CourseName       string
	CourseCode       string
	MasterCourseName string
	EnrolledAt       time.Time
	TotalAttendance  int
	TotalSessions    int
	FinalScore       *float64
	Grade            *string
	Status           string
	PaymentStatus    string
}

// StudentRecommendationItem represents a course recommendation for a student.
type StudentRecommendationItem struct {
	MasterCourseID uuid.UUID
	CourseName     string
	CourseCode     string
	Field          string
	Reason         string
	HasActiveBatch bool
}

// StudentNoteItem represents a note written about a student.
type StudentNoteItem struct {
	ID         uuid.UUID
	StudentID  uuid.UUID
	AuthorID   string
	AuthorName string
	Content    string
	CreatedAt  time.Time
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Student, error)
	GetDetail(ctx context.Context, id uuid.UUID) (*StudentDetail, error)
	List(ctx context.Context, offset, limit int) ([]*Student, int, error)
	ListWithCounts(ctx context.Context, offset, limit int) ([]*StudentListEntry, int, error)
	GetEnrollmentHistory(ctx context.Context, id uuid.UUID) ([]*StudentEnrollmentHistoryItem, error)
	GetRecommendations(ctx context.Context, id uuid.UUID) ([]*StudentRecommendationItem, error)
	GetNotes(ctx context.Context, id uuid.UUID) ([]*StudentNoteItem, error)
}

type WriteRepository interface {
	Save(ctx context.Context, s *Student) error
	Update(ctx context.Context, s *Student) error
	Delete(ctx context.Context, id uuid.UUID) error
	AddNote(ctx context.Context, studentID uuid.UUID, authorID, authorName, content string) (*StudentNoteItem, error)
}
