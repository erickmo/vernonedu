package get_bmc

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/bmc"
)

// GetBmcQuery fetches the Business Model Canvas for a branch.
type GetBmcQuery struct {
	BranchID uuid.UUID
}

// BmcResult is the read model returned by the GetBmc query.
type BmcResult struct {
	ID                    string   `json:"id"`
	BranchID              string   `json:"branch_id"`
	CustomerSegments      []string `json:"customer_segments"`
	ValuePropositions     []string `json:"value_propositions"`
	Channels              []string `json:"channels"`
	CustomerRelationships []string `json:"customer_relationships"`
	RevenueStreams        []string `json:"revenue_streams"`
	KeyResources          []string `json:"key_resources"`
	KeyActivities         []string `json:"key_activities"`
	KeyPartnerships       []string `json:"key_partnerships"`
	CostStructure         []string `json:"cost_structure"`
	UpdatedBy             string   `json:"updated_by"`
	CreatedAt             int64    `json:"created_at"`
	UpdatedAt             int64    `json:"updated_at"`
}

// Handler handles the GetBmc query.
type Handler struct {
	readRepo bmc.ReadRepository
}

// NewHandler builds a new GetBmc query handler.
func NewHandler(readRepo bmc.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle returns the BMC for a branch. When no canvas exists yet, an empty
// result with all blocks initialised to empty arrays is returned so the client
// can render the page without special-casing 404s.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetBmcQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	entity, err := h.readRepo.GetByBranchID(ctx, q.BranchID)
	if err != nil {
		if errors.Is(err, bmc.ErrBmcNotFound) {
			return emptyResult(q.BranchID), nil
		}
		log.Error().Err(err).Str("branch_id", q.BranchID.String()).Msg("failed to load bmc")
		return nil, err
	}

	updatedBy := ""
	if entity.UpdatedBy != nil {
		updatedBy = entity.UpdatedBy.String()
	}

	return &BmcResult{
		ID:                    entity.ID.String(),
		BranchID:              entity.BranchID.String(),
		CustomerSegments:      entity.CustomerSegments,
		ValuePropositions:     entity.ValuePropositions,
		Channels:              entity.Channels,
		CustomerRelationships: entity.CustomerRelationships,
		RevenueStreams:        entity.RevenueStreams,
		KeyResources:          entity.KeyResources,
		KeyActivities:         entity.KeyActivities,
		KeyPartnerships:       entity.KeyPartnerships,
		CostStructure:         entity.CostStructure,
		UpdatedBy:             updatedBy,
		CreatedAt:             entity.CreatedAt.Unix(),
		UpdatedAt:             entity.UpdatedAt.Unix(),
	}, nil
}

func emptyResult(branchID uuid.UUID) *BmcResult {
	return &BmcResult{
		ID:                    "",
		BranchID:              branchID.String(),
		CustomerSegments:      []string{},
		ValuePropositions:     []string{},
		Channels:              []string{},
		CustomerRelationships: []string{},
		RevenueStreams:        []string{},
		KeyResources:          []string{},
		KeyActivities:         []string{},
		KeyPartnerships:       []string{},
		CostStructure:         []string{},
	}
}
