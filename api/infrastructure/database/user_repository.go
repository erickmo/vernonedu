package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/user"
)

type UserRepository struct {
	db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) *UserRepository {
	return &UserRepository{db: db}
}

type userRecord struct {
	ID           uuid.UUID      `db:"id"`
	Name         string         `db:"name"`
	Email        string         `db:"email"`
	PasswordHash string         `db:"password_hash"`
	Roles        pq.StringArray `db:"roles"`
	CreatedAt    time.Time      `db:"created_at"`
	UpdatedAt    time.Time      `db:"updated_at"`
}

func (rec *userRecord) toDomain() *user.User {
	roles := []string(rec.Roles)
	if len(roles) == 0 {
		roles = []string{user.RoleStudent}
	}
	return &user.User{
		ID:           rec.ID,
		Name:         rec.Name,
		Email:        rec.Email,
		PasswordHash: rec.PasswordHash,
		Roles:        roles,
		CreatedAt:    rec.CreatedAt,
		UpdatedAt:    rec.UpdatedAt,
	}
}

func (r *UserRepository) Save(ctx context.Context, u *user.User) error {
	query := `
		INSERT INTO users (id, name, email, password_hash, roles, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := r.db.ExecContext(ctx, query,
		u.ID, u.Name, u.Email, u.PasswordHash,
		pq.Array(u.Roles), u.CreatedAt, u.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save user: %w", err)
	}
	return nil
}

func (r *UserRepository) Update(ctx context.Context, u *user.User) error {
	query := `
		UPDATE users
		SET name = $1, email = $2, password_hash = $3, roles = $4, updated_at = $5
		WHERE id = $6
	`
	_, err := r.db.ExecContext(ctx, query,
		u.Name, u.Email, u.PasswordHash,
		pq.Array(u.Roles), u.UpdatedAt, u.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}
	return nil
}

func (r *UserRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM users WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}
	return nil
}

func (r *UserRepository) GetByID(ctx context.Context, id uuid.UUID) (*user.User, error) {
	var rec userRecord
	query := `SELECT id, name, email, password_hash, roles, created_at, updated_at FROM users WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*user.User, error) {
	var rec userRecord
	query := `SELECT id, name, email, password_hash, roles, created_at, updated_at FROM users WHERE email = $1`
	if err := r.db.GetContext(ctx, &rec, query, email); err != nil {
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *UserRepository) List(ctx context.Context, offset, limit int) ([]*user.User, error) {
	var recs []userRecord
	query := `SELECT id, name, email, password_hash, roles, created_at, updated_at FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, fmt.Errorf("failed to list users: %w", err)
	}
	users := make([]*user.User, len(recs))
	for i, rec := range recs {
		users[i] = rec.toDomain()
	}
	return users, nil
}

func (r *UserRepository) Search(ctx context.Context, name string, offset, limit int) ([]*user.User, error) {
	var recs []userRecord
	query := `SELECT id, name, email, password_hash, roles, created_at, updated_at FROM users WHERE name ILIKE $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`
	if err := r.db.SelectContext(ctx, &recs, query, "%"+name+"%", limit, offset); err != nil {
		return nil, fmt.Errorf("failed to search users: %w", err)
	}
	users := make([]*user.User, len(recs))
	for i, rec := range recs {
		users[i] = rec.toDomain()
	}
	return users, nil
}
