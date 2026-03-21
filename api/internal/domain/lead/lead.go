package lead

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName  = errors.New("invalid lead name")
	ErrLeadNotFound = errors.New("lead not found")
)

type Lead struct {
	ID        uuid.UUID
	Name      string
	Email     string
	Phone     string
	Interest  string
	Source    string
	Notes     string
	Status    string
	PicID     *uuid.UUID
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewLead(name, email, phone, interest, source, notes string, picID *uuid.UUID) (*Lead, error) {
	if name == "" {
		return nil, ErrInvalidName
	}

	if source == "" {
		source = "other"
	}

	return &Lead{
		ID:        uuid.New(),
		Name:      name,
		Email:     email,
		Phone:     phone,
		Interest:  interest,
		Source:    source,
		Notes:     notes,
		Status:    "new",
		PicID:     picID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

type CrmLog struct {
	ID            uuid.UUID
	LeadID        uuid.UUID
	ContactedByID uuid.UUID
	ContactMethod string // phone, email, whatsapp
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
	List(ctx context.Context, offset, limit int, status, source, interest string) ([]*Lead, int, error)
}

type CrmLogWriteRepository interface {
	SaveCrmLog(ctx context.Context, log *CrmLog) error
}

type CrmLogReadRepository interface {
	ListCrmLogs(ctx context.Context, leadID uuid.UUID) ([]*CrmLog, error)
}
