package bmc

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Sentinel errors for BMC domain.
var (
	ErrBmcNotFound  = errors.New("business model canvas not found")
	ErrInvalidBranch = errors.New("branch id is required")
)

// BusinessModelCanvas represents the 9-block strategic canvas for a branch.
// Each block is a list of free-form text entries.
type BusinessModelCanvas struct {
	ID                    uuid.UUID
	BranchID              uuid.UUID
	CustomerSegments      []string
	ValuePropositions     []string
	Channels              []string
	CustomerRelationships []string
	RevenueStreams        []string
	KeyResources          []string
	KeyActivities         []string
	KeyPartnerships       []string
	CostStructure         []string
	UpdatedBy             *uuid.UUID
	CreatedAt             time.Time
	UpdatedAt             time.Time
}

// NewBusinessModelCanvas creates a new BMC entity with empty blocks.
func NewBusinessModelCanvas(branchID uuid.UUID, updatedBy *uuid.UUID) (*BusinessModelCanvas, error) {
	if branchID == uuid.Nil {
		return nil, ErrInvalidBranch
	}
	now := time.Now()
	return &BusinessModelCanvas{
		ID:                    uuid.New(),
		BranchID:              branchID,
		CustomerSegments:      []string{},
		ValuePropositions:     []string{},
		Channels:              []string{},
		CustomerRelationships: []string{},
		RevenueStreams:        []string{},
		KeyResources:          []string{},
		KeyActivities:         []string{},
		KeyPartnerships:       []string{},
		CostStructure:         []string{},
		UpdatedBy:             updatedBy,
		CreatedAt:             now,
		UpdatedAt:             now,
	}, nil
}

// UpdateBlocks replaces the contents of all 9 blocks.
func (b *BusinessModelCanvas) UpdateBlocks(
	customerSegments, valuePropositions, channels, customerRelationships,
	revenueStreams, keyResources, keyActivities, keyPartnerships, costStructure []string,
	updatedBy *uuid.UUID,
) {
	b.CustomerSegments = ensureSlice(customerSegments)
	b.ValuePropositions = ensureSlice(valuePropositions)
	b.Channels = ensureSlice(channels)
	b.CustomerRelationships = ensureSlice(customerRelationships)
	b.RevenueStreams = ensureSlice(revenueStreams)
	b.KeyResources = ensureSlice(keyResources)
	b.KeyActivities = ensureSlice(keyActivities)
	b.KeyPartnerships = ensureSlice(keyPartnerships)
	b.CostStructure = ensureSlice(costStructure)
	b.UpdatedBy = updatedBy
	b.UpdatedAt = time.Now()
}

func ensureSlice(s []string) []string {
	if s == nil {
		return []string{}
	}
	return s
}

// WriteRepository defines write operations for BMC.
type WriteRepository interface {
	Save(ctx context.Context, b *BusinessModelCanvas) error
	Update(ctx context.Context, b *BusinessModelCanvas) error
}

// ReadRepository defines read operations for BMC.
type ReadRepository interface {
	GetByBranchID(ctx context.Context, branchID uuid.UUID) (*BusinessModelCanvas, error)
}
