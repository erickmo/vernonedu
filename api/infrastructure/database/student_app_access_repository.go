package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/studentappaccess"
)

type appAccessRecord struct {
	ID        uuid.UUID  `db:"id"`
	StudentID uuid.UUID  `db:"student_id"`
	AppName   string     `db:"app_name"`
	BatchID   uuid.UUID  `db:"batch_id"`
	GrantedAt time.Time  `db:"granted_at"`
	RevokedAt *time.Time `db:"revoked_at"`
	Status    string     `db:"status"`
}

type StudentAppAccessRepository struct {
	db *sqlx.DB
}

func NewStudentAppAccessRepository(db *sqlx.DB) *StudentAppAccessRepository {
	return &StudentAppAccessRepository{db: db}
}

func (r *StudentAppAccessRepository) Save(ctx context.Context, a *studentappaccess.StudentAppAccess) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO student_app_access (id, student_id, app_name, batch_id, granted_at, revoked_at, status)
		VALUES ($1,$2,$3,$4,$5,$6,$7)
	`, a.ID, a.StudentID, a.AppName, a.BatchID, a.GrantedAt, a.RevokedAt, string(a.Status))
	if err != nil {
		return fmt.Errorf("failed to save app access: %w", err)
	}
	return nil
}

func (r *StudentAppAccessRepository) RevokeByStudentAndBatch(ctx context.Context, studentID, batchID uuid.UUID) error {
	now := time.Now()
	_, err := r.db.ExecContext(ctx, `
		UPDATE student_app_access
		SET status='revoked', revoked_at=$3
		WHERE student_id=$1 AND batch_id=$2 AND status='active'
	`, studentID, batchID, now)
	if err != nil {
		return fmt.Errorf("failed to revoke app access: %w", err)
	}
	return nil
}

func (r *StudentAppAccessRepository) RevokeAllByBatch(ctx context.Context, batchID uuid.UUID) error {
	now := time.Now()
	_, err := r.db.ExecContext(ctx, `
		UPDATE student_app_access
		SET status='revoked', revoked_at=$2
		WHERE batch_id=$1 AND status='active'
	`, batchID, now)
	if err != nil {
		return fmt.Errorf("failed to revoke all batch app access: %w", err)
	}
	return nil
}

func (r *StudentAppAccessRepository) GetActiveByStudentAndBatch(ctx context.Context, studentID, batchID uuid.UUID) (*studentappaccess.StudentAppAccess, error) {
	var rec appAccessRecord
	err := r.db.GetContext(ctx, &rec, `
		SELECT id, student_id, app_name, batch_id, granted_at, revoked_at, status
		FROM student_app_access
		WHERE student_id=$1 AND batch_id=$2 AND status='active'
		LIMIT 1
	`, studentID, batchID)
	if err == sql.ErrNoRows {
		return nil, studentappaccess.ErrAccessNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get app access: %w", err)
	}
	return &studentappaccess.StudentAppAccess{
		ID:        rec.ID,
		StudentID: rec.StudentID,
		AppName:   rec.AppName,
		BatchID:   rec.BatchID,
		GrantedAt: rec.GrantedAt,
		RevokedAt: rec.RevokedAt,
		Status:    studentappaccess.Status(rec.Status),
	}, nil
}

func (r *StudentAppAccessRepository) ListByStudent(ctx context.Context, studentID uuid.UUID) ([]*studentappaccess.StudentAppAccess, error) {
	var rows []appAccessRecord
	err := r.db.SelectContext(ctx, &rows, `
		SELECT id, student_id, app_name, batch_id, granted_at, revoked_at, status
		FROM student_app_access
		WHERE student_id=$1
		ORDER BY granted_at DESC
	`, studentID)
	if err != nil {
		return nil, fmt.Errorf("failed to list app access: %w", err)
	}
	out := make([]*studentappaccess.StudentAppAccess, len(rows))
	for i, row := range rows {
		out[i] = &studentappaccess.StudentAppAccess{
			ID:        row.ID,
			StudentID: row.StudentID,
			AppName:   row.AppName,
			BatchID:   row.BatchID,
			GrantedAt: row.GrantedAt,
			RevokedAt: row.RevokedAt,
			Status:    studentappaccess.Status(row.Status),
		}
	}
	return out, nil
}
