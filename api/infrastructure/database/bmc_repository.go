package database

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/bmc"
)

// BmcRepository implements bmc.WriteRepository and bmc.ReadRepository on
// PostgreSQL using JSONB columns for the 9 strategic blocks.
type BmcRepository struct {
	db *sqlx.DB
}

// NewBmcRepository builds a new BmcRepository.
func NewBmcRepository(db *sqlx.DB) *BmcRepository {
	return &BmcRepository{db: db}
}

type bmcRecord struct {
	ID                    uuid.UUID  `db:"id"`
	BranchID              uuid.UUID  `db:"branch_id"`
	CustomerSegments      []byte     `db:"customer_segments"`
	ValuePropositions     []byte     `db:"value_propositions"`
	Channels              []byte     `db:"channels"`
	CustomerRelationships []byte     `db:"customer_relationships"`
	RevenueStreams        []byte     `db:"revenue_streams"`
	KeyResources          []byte     `db:"key_resources"`
	KeyActivities         []byte     `db:"key_activities"`
	KeyPartnerships       []byte     `db:"key_partnerships"`
	CostStructure         []byte     `db:"cost_structure"`
	UpdatedBy             *uuid.UUID `db:"updated_by"`
	CreatedAt             time.Time  `db:"created_at"`
	UpdatedAt             time.Time  `db:"updated_at"`
}

func decodeBlock(raw []byte) []string {
	if len(raw) == 0 {
		return []string{}
	}
	var out []string
	if err := json.Unmarshal(raw, &out); err != nil {
		return []string{}
	}
	if out == nil {
		return []string{}
	}
	return out
}

func encodeBlock(in []string) ([]byte, error) {
	if in == nil {
		in = []string{}
	}
	return json.Marshal(in)
}

func (rec *bmcRecord) toDomain() *bmc.BusinessModelCanvas {
	return &bmc.BusinessModelCanvas{
		ID:                    rec.ID,
		BranchID:              rec.BranchID,
		CustomerSegments:      decodeBlock(rec.CustomerSegments),
		ValuePropositions:     decodeBlock(rec.ValuePropositions),
		Channels:              decodeBlock(rec.Channels),
		CustomerRelationships: decodeBlock(rec.CustomerRelationships),
		RevenueStreams:        decodeBlock(rec.RevenueStreams),
		KeyResources:          decodeBlock(rec.KeyResources),
		KeyActivities:         decodeBlock(rec.KeyActivities),
		KeyPartnerships:       decodeBlock(rec.KeyPartnerships),
		CostStructure:         decodeBlock(rec.CostStructure),
		UpdatedBy:             rec.UpdatedBy,
		CreatedAt:             rec.CreatedAt,
		UpdatedAt:             rec.UpdatedAt,
	}
}

func encodeAllBlocks(b *bmc.BusinessModelCanvas) ([9][]byte, error) {
	var blocks [9][]byte
	sources := [][]string{
		b.CustomerSegments, b.ValuePropositions, b.Channels,
		b.CustomerRelationships, b.RevenueStreams, b.KeyResources,
		b.KeyActivities, b.KeyPartnerships, b.CostStructure,
	}
	for i, src := range sources {
		raw, err := encodeBlock(src)
		if err != nil {
			return blocks, fmt.Errorf("failed to encode bmc block %d: %w", i, err)
		}
		blocks[i] = raw
	}
	return blocks, nil
}

// Save persists a brand-new BMC row.
func (r *BmcRepository) Save(ctx context.Context, b *bmc.BusinessModelCanvas) error {
	blocks, err := encodeAllBlocks(b)
	if err != nil {
		return err
	}
	query := `
		INSERT INTO business_model_canvases (
			id, branch_id,
			customer_segments, value_propositions, channels, customer_relationships,
			revenue_streams, key_resources, key_activities, key_partnerships, cost_structure,
			updated_by, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
	`
	_, err = r.db.ExecContext(ctx, query,
		b.ID, b.BranchID,
		blocks[0], blocks[1], blocks[2], blocks[3], blocks[4],
		blocks[5], blocks[6], blocks[7], blocks[8],
		b.UpdatedBy, b.CreatedAt, b.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save bmc: %w", err)
	}
	return nil
}

// Update replaces all 9 blocks for an existing BMC row.
func (r *BmcRepository) Update(ctx context.Context, b *bmc.BusinessModelCanvas) error {
	blocks, err := encodeAllBlocks(b)
	if err != nil {
		return err
	}
	query := `
		UPDATE business_model_canvases SET
			customer_segments = $1,
			value_propositions = $2,
			channels = $3,
			customer_relationships = $4,
			revenue_streams = $5,
			key_resources = $6,
			key_activities = $7,
			key_partnerships = $8,
			cost_structure = $9,
			updated_by = $10,
			updated_at = $11
		WHERE id = $12
	`
	_, err = r.db.ExecContext(ctx, query,
		blocks[0], blocks[1], blocks[2], blocks[3], blocks[4],
		blocks[5], blocks[6], blocks[7], blocks[8],
		b.UpdatedBy, b.UpdatedAt, b.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update bmc: %w", err)
	}
	return nil
}

// GetByBranchID loads the BMC row for a branch, returning bmc.ErrBmcNotFound
// when absent.
func (r *BmcRepository) GetByBranchID(ctx context.Context, branchID uuid.UUID) (*bmc.BusinessModelCanvas, error) {
	var rec bmcRecord
	query := `
		SELECT id, branch_id,
		       customer_segments, value_propositions, channels, customer_relationships,
		       revenue_streams, key_resources, key_activities, key_partnerships, cost_structure,
		       updated_by, created_at, updated_at
		FROM business_model_canvases
		WHERE branch_id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, branchID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, bmc.ErrBmcNotFound
		}
		return nil, fmt.Errorf("failed to get bmc by branch id: %w", err)
	}
	return rec.toDomain(), nil
}
