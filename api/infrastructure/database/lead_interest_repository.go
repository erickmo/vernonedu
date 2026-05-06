package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadInterestRepository struct {
	db *sqlx.DB
}

func NewLeadInterestRepository(db *sqlx.DB) *LeadInterestRepository {
	return &LeadInterestRepository{db: db}
}

type leadInterestRow struct {
	ID         string    `db:"id"`
	LeadID     string    `db:"lead_id"`
	EntityType string    `db:"entity_type"`
	EntityID   string    `db:"entity_id"`
	EntityName string    `db:"entity_name"`
	CreatedAt  time.Time `db:"created_at"`
}

func (row *leadInterestRow) toDomain() (*lead.LeadInterest, error) {
	id, _ := uuid.Parse(row.ID)
	leadID, _ := uuid.Parse(row.LeadID)
	entityID, _ := uuid.Parse(row.EntityID)
	return &lead.LeadInterest{
		ID:         id,
		LeadID:     leadID,
		EntityType: row.EntityType,
		EntityID:   entityID,
		EntityName: row.EntityName,
		CreatedAt:  row.CreatedAt,
	}, nil
}

func (r *LeadInterestRepository) SaveInterest(ctx context.Context, i *lead.LeadInterest) error {
	query := `
		INSERT INTO lead_interests (id, lead_id, entity_type, entity_id, created_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err := r.db.ExecContext(ctx, query,
		i.ID.String(), i.LeadID.String(), i.EntityType, i.EntityID.String(), i.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save lead interest: %w", err)
	}
	return nil
}

func (r *LeadInterestRepository) DeleteInterest(ctx context.Context, leadID, interestID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`DELETE FROM lead_interests WHERE id=$1 AND lead_id=$2`,
		interestID.String(), leadID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to delete lead interest: %w", err)
	}
	return nil
}

func (r *LeadInterestRepository) ListInterests(ctx context.Context, leadID uuid.UUID) ([]*lead.LeadInterest, error) {
	var rows []leadInterestRow
	query := `
		SELECT
			li.id, li.lead_id, li.entity_type, li.entity_id, li.created_at,
			COALESCE(mc.course_name, ct.type_name, cb.name, '') AS entity_name
		FROM lead_interests li
		LEFT JOIN master_courses mc ON li.entity_type = 'master_course' AND li.entity_id = mc.id
		LEFT JOIN course_types ct   ON li.entity_type = 'course_type'   AND li.entity_id = ct.id
		LEFT JOIN course_batches cb  ON li.entity_type = 'course_batch'  AND li.entity_id = cb.id
		WHERE li.lead_id = $1
		ORDER BY li.created_at
	`
	if err := r.db.SelectContext(ctx, &rows, query, leadID.String()); err != nil {
		return nil, fmt.Errorf("failed to list lead interests: %w", err)
	}
	interests := make([]*lead.LeadInterest, 0, len(rows))
	for _, row := range rows {
		i, err := row.toDomain()
		if err != nil {
			return nil, err
		}
		interests = append(interests, i)
	}
	return interests, nil
}
