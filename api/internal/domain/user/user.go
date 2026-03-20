package user

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName  = errors.New("invalid user name")
	ErrInvalidEmail = errors.New("invalid user email")
	ErrUserNotFound = errors.New("user not found")
)

type User struct {
	ID           uuid.UUID
	Name         string
	Email        string
	PasswordHash string
	Role         string
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func NewUser(name, email, passwordHash, role string) (*User, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if email == "" {
		return nil, ErrInvalidEmail
	}

	return &User{
		ID:           uuid.New(),
		Name:         name,
		Email:        email,
		PasswordHash: passwordHash,
		Role:         role,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}, nil
}

func (u *User) UpdateName(name string) error {
	if name == "" {
		return ErrInvalidName
	}
	u.Name = name
	u.UpdatedAt = time.Now()
	return nil
}

func (u *User) UpdatePassword(hash string) error {
	u.PasswordHash = hash
	u.UpdatedAt = time.Now()
	return nil
}

// Repositories
type WriteRepository interface {
	Save(ctx context.Context, u *User) error
	Update(ctx context.Context, u *User) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*User, error)
	GetByEmail(ctx context.Context, email string) (*User, error)
	List(ctx context.Context, offset, limit int) ([]*User, error)
	Search(ctx context.Context, name string, offset, limit int) ([]*User, error)
}
