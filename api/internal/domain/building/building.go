package building

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName      = errors.New("building name is required")
	ErrInvalidOwnership = errors.New("ownership must be 'self' or 'partner'")
	ErrPartnerRequired  = errors.New("partner_id is required when ownership is 'partner'")
	ErrBuildingNotFound = errors.New("building not found")
)

type Building struct {
	ID          uuid.UUID
	Name        string
	Address     string
	Description string
	Ownership   string     // "self" | "partner"
	PartnerID   *uuid.UUID // nil when ownership = "self"
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type PartnerRef struct {
	ID   uuid.UUID
	Name string
}

type BuildingWithPartner struct {
	Building
	Partner *PartnerRef // nil when ownership = "self"
}

func NewBuilding(name, address, description, ownership string, partnerID *uuid.UUID) (*Building, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if ownership != "self" && ownership != "partner" {
		return nil, ErrInvalidOwnership
	}
	if ownership == "partner" && partnerID == nil {
		return nil, ErrPartnerRequired
	}
	return &Building{
		ID:          uuid.New(),
		Name:        name,
		Address:     address,
		Description: description,
		Ownership:   ownership,
		PartnerID:   partnerID,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}, nil
}

type RoomSummary struct {
	ID       uuid.UUID
	Name     string
	Capacity int
}

type BuildingWithRooms struct {
	Building
	RoomCount     int
	TotalCapacity int
	Rooms         []RoomSummary
}

type WriteRepository interface {
	Save(ctx context.Context, b *Building) error
	Update(ctx context.Context, b *Building) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Building, error)
	GetByIDWithPartner(ctx context.Context, id uuid.UUID) (*BuildingWithPartner, error)
	List(ctx context.Context, offset, limit int) ([]*Building, int, error)
	ListWithRooms(ctx context.Context, offset, limit int, search string) ([]BuildingWithRooms, int, error)
}
