package identity

import (
	"context"
	"testing"

	"github.com/google/uuid"
)

func TestRegisterStudent_CreatesUserAndStudent(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger(), testJWTSecret, testJWTExpiry)

	out, err := svc.RegisterStudent(ctx, RegisterInput{
		Name:     "Alice",
		Email:    "a@example.com",
		Phone:    "+62800",
		Password: "supersecret",
		Source:   SourceB2C,
	})
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	if out.Student.ID == uuid.Nil {
		t.Fatal("expected student ID")
	}
	if out.User.ID == uuid.Nil {
		t.Fatal("expected user ID")
	}
	if out.Student.UserID != out.User.ID {
		t.Fatalf("student.UserID=%v != user.ID=%v", out.Student.UserID, out.User.ID)
	}
	if !bus.Fired("auth.user.created") {
		t.Fatal("expected auth.user.created event")
	}
}

func TestRegisterStudent_RejectsDuplicateEmail(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	repo.SeedUserEmail("a@example.com")
	svc := NewService(repo, newFakeBus(), testLogger(), testJWTSecret, testJWTExpiry)

	_, err := svc.RegisterStudent(ctx, RegisterInput{
		Name:     "Alice",
		Email:    "a@example.com",
		Phone:    "+62800",
		Password: "supersecret",
		Source:   SourceB2C,
	})
	if err == nil {
		t.Fatal("expected duplicate-email error")
	}
}
