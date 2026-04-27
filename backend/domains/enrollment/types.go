package enrollment

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// Batch status constants used by the enrollment service when validating
// whether a batch may accept enrollments.
const (
	BatchStatusDraft   = "draft"
	BatchStatusOpen    = "open"
	BatchStatusOngoing = "ongoing"
	BatchStatusClosed  = "closed"
)

// Source values describing the origin of an enrollment request.
const (
	SourceB2C              = "b2c"
	SourceB2B              = "b2b"
	SourceInhouseTraining  = "inhouse_training"
	SourceInschoolProgram  = "inschool_program"
)

// CatalogBatch is the projection of a course batch needed by enrollment.
// Defined locally to avoid importing the catalog package directly.
type CatalogBatch struct {
	ID                  uuid.UUID
	CourseID            uuid.UUID
	CourseTitle         string
	Price               decimal.Decimal
	BatchBulkPrice      *decimal.Decimal
	Status              string
	WebRegistrationOpen bool
	RegistrationOpenAt  *time.Time
	RegistrationCloseAt *time.Time
	MaxStudents         *int
}

// CatalogFormatConfig describes per-format toggles + capacity for a course.
type CatalogFormatConfig struct {
	Format      EnrollmentFormat
	IsEnabled   bool
	MaxStudents *int
	MinStudents *int
}

// Agreement is the projection of a partnership agreement needed by enrollment.
type Agreement struct {
	ID        uuid.UUID
	PartnerID uuid.UUID
	Payer     Payer
	BulkPrice *decimal.Decimal
	IsActive  bool
}

// CatalogReader exposes read-only catalog data the enrollment service needs.
// Production wiring connects this to the catalog domain; tests use a fake.
type CatalogReader interface {
	GetBatch(ctx context.Context, batchID uuid.UUID) (*CatalogBatch, error)
	GetFormatConfig(ctx context.Context, courseID uuid.UUID, format EnrollmentFormat) (*CatalogFormatConfig, error)
	CountEnrollments(ctx context.Context, batchID uuid.UUID, format EnrollmentFormat) (int, error)
}

// PartnershipsReader exposes read-only partnership agreement data.
// May be nil — service treats absence as "no active agreement".
type PartnershipsReader interface {
	GetActiveAgreement(ctx context.Context, partnerID uuid.UUID) (*Agreement, error)
}

// StudentCredit is the projection of a finance-domain student credit balance
// the enrollment service needs when applying credit at enrollment time.
type StudentCredit struct {
	ID        uuid.UUID
	StudentID uuid.UUID
	Balance   decimal.Decimal
	IsActive  bool
}

// FinanceReader exposes read+debit operations on student credits.
// May be nil — when absent the service skips credit application entirely.
type FinanceReader interface {
	GetStudentCredit(ctx context.Context, creditID uuid.UUID) (*StudentCredit, error)
	DebitStudentCredit(ctx context.Context, creditID uuid.UUID, amount decimal.Decimal, refEnrollmentID uuid.UUID) error
}
