package lead

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName      = errors.New("invalid lead name")
	ErrPhoneRequired    = errors.New("phone is required")
	ErrLeadNotFound     = errors.New("lead not found")
	ErrSourceNotFound   = errors.New("lead source not found")
	ErrInterestNotFound = errors.New("lead interest not found")
)

type Lead struct {
	ID        uuid.UUID
	Name      string
	Email     string
	Phone     string
	SourceID  *uuid.UUID
	Notes     string
	Status    string
	PicID     *uuid.UUID
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewLead(name, email, phone string, sourceID *uuid.UUID, notes string, picID *uuid.UUID) (*Lead, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if phone == "" {
		return nil, ErrPhoneRequired
	}
	return &Lead{
		ID:        uuid.New(),
		Name:      name,
		Email:     email,
		Phone:     phone,
		SourceID:  sourceID,
		Notes:     notes,
		Status:    "new",
		PicID:     picID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

type LeadSource struct {
	ID        uuid.UUID
	Name      string
	IsActive  bool
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewLeadSource(name string) *LeadSource {
	return &LeadSource{
		ID:        uuid.New(),
		Name:      name,
		IsActive:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

type LeadInterest struct {
	ID         uuid.UUID
	LeadID     uuid.UUID
	EntityType string
	EntityID   uuid.UUID
	EntityName string
	CreatedAt  time.Time
}

func NewLeadInterest(leadID uuid.UUID, entityType string, entityID uuid.UUID) *LeadInterest {
	return &LeadInterest{
		ID:         uuid.New(),
		LeadID:     leadID,
		EntityType: entityType,
		EntityID:   entityID,
		CreatedAt:  time.Now(),
	}
}

type CrmLog struct {
	ID            uuid.UUID
	LeadID        uuid.UUID
	ContactedByID uuid.UUID
	ContactMethod string
	Response      string
	FollowUpDate  *time.Time
	CreatedAt     time.Time
}

func NewCrmLog(leadID, contactedByID uuid.UUID, contactMethod, response string, followUpDate *time.Time) *CrmLog {
	return &CrmLog{
		ID:            uuid.New(),
		LeadID:        leadID,
		ContactedByID: contactedByID,
		ContactMethod: contactMethod,
		Response:      response,
		FollowUpDate:  followUpDate,
		CreatedAt:     time.Now(),
	}
}

type WriteRepository interface {
	Save(ctx context.Context, l *Lead) error
	Update(ctx context.Context, l *Lead) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Lead, error)
	List(ctx context.Context, offset, limit int, status, sourceID, search, sortBy, sortDir string) ([]*Lead, int, error)
}

type SourceWriteRepository interface {
	SaveSource(ctx context.Context, s *LeadSource) error
	UpdateSource(ctx context.Context, s *LeadSource) error
	DeleteSource(ctx context.Context, id uuid.UUID) error
}

type SourceReadRepository interface {
	GetSourceByID(ctx context.Context, id uuid.UUID) (*LeadSource, error)
	ListSources(ctx context.Context) ([]*LeadSource, error)
}

type InterestWriteRepository interface {
	SaveInterest(ctx context.Context, i *LeadInterest) error
	DeleteInterest(ctx context.Context, leadID, interestID uuid.UUID) error
}

type InterestReadRepository interface {
	ListInterests(ctx context.Context, leadID uuid.UUID) ([]*LeadInterest, error)
}

type CrmLogWriteRepository interface {
	SaveCrmLog(ctx context.Context, log *CrmLog) error
}

type CrmLogReadRepository interface {
	ListCrmLogs(ctx context.Context, leadID uuid.UUID) ([]*CrmLog, error)
}
