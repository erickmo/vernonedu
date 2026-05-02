package upsert_bmc

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/bmc"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

// UpsertBmcCommand carries data for creating or updating a Business Model Canvas
// for a specific branch. All 9 blocks are replaced in their entirety.
type UpsertBmcCommand struct {
	BranchID              uuid.UUID `validate:"required"`
	UpdatedBy             *uuid.UUID
	CustomerSegments      []string
	ValuePropositions     []string
	Channels              []string
	CustomerRelationships []string
	RevenueStreams        []string
	KeyResources          []string
	KeyActivities         []string
	KeyPartnerships       []string
	CostStructure         []string
}

// Handler handles the UpsertBmcCommand.
type Handler struct {
	writeRepo bmc.WriteRepository
	readRepo  bmc.ReadRepository
}

// NewHandler builds a new UpsertBmc command handler.
func NewHandler(writeRepo bmc.WriteRepository, readRepo bmc.ReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

// Handle creates the BMC for the branch if it does not exist, otherwise updates
// the existing one with the provided block contents.
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpsertBmcCommand)
	if !ok {
		return ErrInvalidCommand
	}

	existing, err := h.readRepo.GetByBranchID(ctx, c.BranchID)
	if err != nil && !errors.Is(err, bmc.ErrBmcNotFound) {
		log.Error().Err(err).Str("branch_id", c.BranchID.String()).Msg("failed to load existing bmc")
		return err
	}

	if existing != nil {
		existing.UpdateBlocks(
			c.CustomerSegments, c.ValuePropositions, c.Channels,
			c.CustomerRelationships, c.RevenueStreams, c.KeyResources,
			c.KeyActivities, c.KeyPartnerships, c.CostStructure,
			c.UpdatedBy,
		)
		if err := h.writeRepo.Update(ctx, existing); err != nil {
			log.Error().Err(err).Str("bmc_id", existing.ID.String()).Msg("failed to update bmc")
			return err
		}
		return nil
	}

	entity, err := bmc.NewBusinessModelCanvas(c.BranchID, c.UpdatedBy)
	if err != nil {
		return err
	}
	entity.UpdateBlocks(
		c.CustomerSegments, c.ValuePropositions, c.Channels,
		c.CustomerRelationships, c.RevenueStreams, c.KeyResources,
		c.KeyActivities, c.KeyPartnerships, c.CostStructure,
		c.UpdatedBy,
	)
	if err := h.writeRepo.Save(ctx, entity); err != nil {
		log.Error().Err(err).Str("branch_id", c.BranchID.String()).Msg("failed to save bmc")
		return err
	}
	return nil
}
