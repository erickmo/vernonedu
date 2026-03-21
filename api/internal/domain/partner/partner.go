package partner

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var ErrPartnerNotFound = errors.New("partner not found")

type Partner struct {
	ID            uuid.UUID
	Name          string
	Industry      string
	Address       string
	ContactPerson string
	ContactEmail  string
	ContactPhone  string
	Website       string
	LogoURL       string
	GroupID       *uuid.UUID
	GroupName     string
	Status        string
	PartnerSince  *time.Time
	Notes         string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type PartnerGroup struct {
	ID          uuid.UUID
	Name        string
	Description string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type MOU struct {
	ID             uuid.UUID
	PartnerID      uuid.UUID
	PartnerName    string
	DocumentNumber string
	Title          string
	StartDate      string
	EndDate        string
	Status         string
	DocumentURL    string
	Notes          string
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

type PartnershipLog struct {
	ID         uuid.UUID
	PartnerID  uuid.UUID
	LogDate    string
	EntityName string
	EntityType string
	Status     string
	Notes      string
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type WriteRepository interface {
	Save(ctx context.Context, p *Partner) error
	Update(ctx context.Context, p *Partner) error
	Delete(ctx context.Context, id uuid.UUID) error
	SaveGroup(ctx context.Context, g *PartnerGroup) error
	UpdateGroup(ctx context.Context, g *PartnerGroup) error
	DeleteGroup(ctx context.Context, id uuid.UUID) error
	SaveMOU(ctx context.Context, m *MOU) error
	UpdateMOU(ctx context.Context, m *MOU) error
	DeleteMOU(ctx context.Context, id uuid.UUID) error
	SaveLog(ctx context.Context, l *PartnershipLog) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Partner, error)
	List(ctx context.Context, offset, limit int, status string) ([]*Partner, int, error)
	ListGroups(ctx context.Context) ([]*PartnerGroup, error)
	ListMOUs(ctx context.Context, partnerID uuid.UUID) ([]*MOU, error)
	GetMOUByID(ctx context.Context, id uuid.UUID) (*MOU, error)
	ListExpiringMOUs(ctx context.Context, withinMonths int) ([]*MOU, error)
	ListLogs(ctx context.Context, partnerID uuid.UUID) ([]*PartnershipLog, error)
	Stats(ctx context.Context) (*PartnerStats, error)
}

type PartnerStats struct {
	ActiveCount      int
	ExpiringCount    int
	NegotiatingCount int
	UncontactedCount int
}
