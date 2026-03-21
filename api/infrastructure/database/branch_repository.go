package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/branch"
)

type BranchRepository struct {
	db *sqlx.DB
}

func NewBranchRepository(db *sqlx.DB) *BranchRepository {
	return &BranchRepository{db: db}
}

type branchRecord struct {
	ID           uuid.UUID  `db:"id"`
	Name         string     `db:"name"`
	City         string     `db:"city"`
	Address      string     `db:"address"`
	Region       string     `db:"region"`
	ContactName  string     `db:"contact_name"`
	ContactPhone string     `db:"contact_phone"`
	Status       string     `db:"status"`
	PartnerID    *uuid.UUID `db:"partner_id"`
	PartnerName  string     `db:"partner_name"`
	IsActive     bool       `db:"is_active"`
	CreatedAt    time.Time  `db:"created_at"`
	UpdatedAt    time.Time  `db:"updated_at"`
}

func (rec *branchRecord) toDomain() *branch.Branch {
	return &branch.Branch{
		ID:           rec.ID,
		Name:         rec.Name,
		City:         rec.City,
		Address:      rec.Address,
		Region:       rec.Region,
		ContactName:  rec.ContactName,
		ContactPhone: rec.ContactPhone,
		Status:       rec.Status,
		PartnerID:    rec.PartnerID,
		PartnerName:  rec.PartnerName,
		IsActive:     rec.IsActive,
		CreatedAt:    rec.CreatedAt,
		UpdatedAt:    rec.UpdatedAt,
	}
}

const branchCols = `id, name, city, address, region, contact_name, contact_phone, status, partner_id, partner_name, is_active, created_at, updated_at`

func (r *BranchRepository) Save(ctx context.Context, b *branch.Branch) error {
	query := `
		INSERT INTO branches (id, name, city, address, region, contact_name, contact_phone, status,
		                      partner_id, partner_name, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
	`
	_, err := r.db.ExecContext(ctx, query,
		b.ID, b.Name, b.City, b.Address, b.Region, b.ContactName, b.ContactPhone, b.Status,
		b.PartnerID, b.PartnerName, b.IsActive, b.CreatedAt, b.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save branch: %w", err)
	}
	return nil
}

func (r *BranchRepository) Update(ctx context.Context, b *branch.Branch) error {
	query := `
		UPDATE branches
		SET name=$1, city=$2, address=$3, region=$4, contact_name=$5, contact_phone=$6,
		    status=$7, partner_id=$8, partner_name=$9, is_active=$10, updated_at=$11
		WHERE id=$12
	`
	_, err := r.db.ExecContext(ctx, query,
		b.Name, b.City, b.Address, b.Region, b.ContactName, b.ContactPhone,
		b.Status, b.PartnerID, b.PartnerName, b.IsActive, b.UpdatedAt, b.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update branch: %w", err)
	}
	return nil
}

func (r *BranchRepository) GetByID(ctx context.Context, id uuid.UUID) (*branch.Branch, error) {
	var rec branchRecord
	query := `SELECT ` + branchCols + ` FROM branches WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get branch: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *BranchRepository) List(ctx context.Context, offset, limit int) ([]*branch.Branch, int, error) {
	var total int
	if err := r.db.GetContext(ctx, &total, `SELECT COUNT(*) FROM branches`); err != nil {
		return nil, 0, fmt.Errorf("failed to count branches: %w", err)
	}

	var recs []branchRecord
	query := `SELECT ` + branchCols + ` FROM branches ORDER BY name ASC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list branches: %w", err)
	}

	branches := make([]*branch.Branch, len(recs))
	for i, rec := range recs {
		branches[i] = rec.toDomain()
	}
	return branches, total, nil
}
