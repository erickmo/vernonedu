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

// Valid role constants
const (
	RoleDirector         = "director"
	RoleEducationLeader  = "education_leader"
	RoleDeptLeader       = "dept_leader"
	RoleCourseOwner      = "course_owner"
	RoleFacilitator      = "facilitator"
	RoleOperationLeader  = "operation_leader"
	RoleOperationAdmin   = "operation_admin"
	RoleCustomerService  = "customer_service"
	RoleMarketing        = "marketing"
	RoleAccountingLeader = "accounting_leader"
	RoleAccountingStaff  = "accounting_staff"
	RoleStudent          = "student"
	RolePartner          = "partner"
)

type User struct {
	ID           uuid.UUID
	Name         string
	Email        string
	PasswordHash string
	Roles        []string
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func NewUser(name, email, passwordHash string, roles []string) (*User, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if email == "" {
		return nil, ErrInvalidEmail
	}
	if len(roles) == 0 {
		roles = []string{RoleStudent}
	}

	return &User{
		ID:           uuid.New(),
		Name:         name,
		Email:        email,
		PasswordHash: passwordHash,
		Roles:        roles,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}, nil
}

func (u *User) HasRole(role string) bool {
	for _, r := range u.Roles {
		if r == role {
			return true
		}
	}
	return false
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
