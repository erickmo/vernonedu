package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/okr"
)

type OkrRepository struct {
	db *sqlx.DB
}

func NewOkrRepository(db *sqlx.DB) *OkrRepository {
	return &OkrRepository{db: db}
}

type okrObjectiveRecord struct {
	ID        uuid.UUID  `db:"id"`
	Title     string     `db:"title"`
	OwnerID   *uuid.UUID `db:"owner_id"`
	OwnerName string     `db:"owner_name"`
	Period    string     `db:"period"`
	Level     string     `db:"level"`
	Status    string     `db:"status"`
	Progress  int        `db:"progress"`
	CreatedAt time.Time  `db:"created_at"`
	UpdatedAt time.Time  `db:"updated_at"`
}

type okrKeyResultRecord struct {
	ID          uuid.UUID `db:"id"`
	ObjectiveID uuid.UUID `db:"objective_id"`
	Title       string    `db:"title"`
	Progress    int       `db:"progress"`
	CreatedAt   time.Time `db:"created_at"`
	UpdatedAt   time.Time `db:"updated_at"`
}

func (r *OkrRepository) Save(ctx context.Context, o *okr.Objective) error {
	query := `
		INSERT INTO okr_objectives (id, title, owner_id, owner_name, period, level, status, progress, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err := r.db.ExecContext(ctx, query,
		o.ID, o.Title, o.OwnerID, o.OwnerName, o.Period, o.Level,
		o.Status, o.Progress, o.CreatedAt, o.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save okr objective: %w", err)
	}
	return nil
}

func (r *OkrRepository) Update(ctx context.Context, o *okr.Objective) error {
	query := `
		UPDATE okr_objectives SET title=$1, owner_id=$2, owner_name=$3, period=$4, level=$5,
		status=$6, progress=$7, updated_at=$8 WHERE id=$9
	`
	_, err := r.db.ExecContext(ctx, query,
		o.Title, o.OwnerID, o.OwnerName, o.Period, o.Level,
		o.Status, o.Progress, time.Now(), o.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update okr objective: %w", err)
	}
	return nil
}

func (r *OkrRepository) SaveKeyResult(ctx context.Context, kr *okr.KeyResult) error {
	query := `
		INSERT INTO okr_key_results (id, objective_id, title, progress, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := r.db.ExecContext(ctx, query,
		kr.ID, kr.ObjectiveID, kr.Title, kr.Progress, kr.CreatedAt, kr.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save key result: %w", err)
	}
	return nil
}

func (r *OkrRepository) UpdateKeyResultProgress(ctx context.Context, id uuid.UUID, progress int) error {
	_, err := r.db.ExecContext(ctx, `UPDATE okr_key_results SET progress=$1, updated_at=$2 WHERE id=$3`, progress, time.Now(), id)
	if err != nil {
		return fmt.Errorf("failed to update key result progress: %w", err)
	}
	return nil
}

func (r *OkrRepository) List(ctx context.Context, level string) ([]*okr.Objective, error) {
	var objRecs []okrObjectiveRecord
	var query string
	var args []interface{}

	if level != "" && level != "all" {
		query = `SELECT id, title, owner_id, owner_name, period, level, status, progress, created_at, updated_at FROM okr_objectives WHERE level = $1 ORDER BY created_at DESC`
		args = []interface{}{level}
	} else {
		query = `SELECT id, title, owner_id, owner_name, period, level, status, progress, created_at, updated_at FROM okr_objectives ORDER BY created_at DESC`
	}

	if err := r.db.SelectContext(ctx, &objRecs, query, args...); err != nil {
		return nil, fmt.Errorf("failed to list okr objectives: %w", err)
	}

	objectives := make([]*okr.Objective, len(objRecs))
	for i, rec := range objRecs {
		obj := &okr.Objective{
			ID:        rec.ID,
			Title:     rec.Title,
			OwnerID:   rec.OwnerID,
			OwnerName: rec.OwnerName,
			Period:    rec.Period,
			Level:     rec.Level,
			Status:    rec.Status,
			Progress:  rec.Progress,
			CreatedAt: rec.CreatedAt,
			UpdatedAt: rec.UpdatedAt,
		}

		var krRecs []okrKeyResultRecord
		krQuery := `SELECT id, objective_id, title, progress, created_at, updated_at FROM okr_key_results WHERE objective_id = $1 ORDER BY created_at ASC`
		if err := r.db.SelectContext(ctx, &krRecs, krQuery, rec.ID); err != nil {
			return nil, fmt.Errorf("failed to list key results for objective %s: %w", rec.ID, err)
		}

		krs := make([]*okr.KeyResult, len(krRecs))
		for j, kr := range krRecs {
			krs[j] = &okr.KeyResult{
				ID:          kr.ID,
				ObjectiveID: kr.ObjectiveID,
				Title:       kr.Title,
				Progress:    kr.Progress,
				CreatedAt:   kr.CreatedAt,
				UpdatedAt:   kr.UpdatedAt,
			}
		}
		obj.KeyResults = krs
		objectives[i] = obj
	}
	return objectives, nil
}
