package job_vacancy

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidTitle            = errors.New("invalid job vacancy title")
	ErrInvalidPartner          = errors.New("partner_id is required")
	ErrInvalidCreatedBy        = errors.New("created_by is required")
	ErrJobVacancyNotFound      = errors.New("job vacancy not found")
	ErrInvalidStatusTransition = errors.New("invalid status transition")
)

// Valid status transitions: draft→open, open→closed
var validTransitions = map[string]map[string]bool{
	"draft":  {"open": true},
	"open":   {"closed": true},
	"closed": {},
}

type JobVacancy struct {
	ID              uuid.UUID
	Title           string
	Description     string
	PartnerID       uuid.UUID
	DepartmentID    *uuid.UUID
	Location        string
	Type            string // full_time|part_time|contract|internship
	Status          string // draft|open|closed
	ExperienceLevel string // fresh_graduate|junior|mid|senior
	Slots           int
	MinSalary       *int64
	MaxSalary       *int64
	RequiredSkills  []string
	Deadline        *time.Time
	CreatedBy       uuid.UUID
	DeletedAt       *time.Time
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

func NewJobVacancy(title, description string, partnerID uuid.UUID, departmentID *uuid.UUID,
	location, vacancyType, experienceLevel string, slots int, minSalary, maxSalary *int64,
	requiredSkills []string, deadline *time.Time, createdBy uuid.UUID) (*JobVacancy, error) {
	if title == "" {
		return nil, ErrInvalidTitle
	}
	if partnerID == uuid.Nil {
		return nil, ErrInvalidPartner
	}
	if createdBy == uuid.Nil {
		return nil, ErrInvalidCreatedBy
	}
	if vacancyType == "" {
		vacancyType = "full_time"
	}
	if experienceLevel == "" {
		experienceLevel = "fresh_graduate"
	}
	if slots <= 0 {
		slots = 1
	}
	if requiredSkills == nil {
		requiredSkills = []string{}
	}
	return &JobVacancy{
		ID: uuid.New(),
		Title: title, Description: description,
		PartnerID: partnerID, DepartmentID: departmentID,
		Location: location, Type: vacancyType,
		Status: "draft", ExperienceLevel: experienceLevel,
		Slots: slots, MinSalary: minSalary, MaxSalary: maxSalary,
		RequiredSkills: requiredSkills, Deadline: deadline,
		CreatedBy: createdBy,
		CreatedAt: time.Now(), UpdatedAt: time.Now(),
	}, nil
}

func (v *JobVacancy) CanTransitionTo(newStatus string) bool {
	allowed, ok := validTransitions[v.Status]
	if !ok {
		return false
	}
	return allowed[newStatus]
}

type WriteRepository interface {
	Save(ctx context.Context, v *JobVacancy) error
	Update(ctx context.Context, v *JobVacancy) error
	Delete(ctx context.Context, id uuid.UUID) error
	GetByIDForWrite(ctx context.Context, id uuid.UUID) (*JobVacancy, error)
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*JobVacancy, error)
	List(ctx context.Context, offset, limit int, status, partnerID, vacancyType, search, sortBy, sortDir string) ([]*JobVacancy, int, error)
}
