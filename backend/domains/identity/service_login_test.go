package identity

import (
	"context"
	"testing"

	"github.com/golang-jwt/jwt/v5"
)

func TestLogin_ValidCredentialsReturnsToken(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	hash, err := HashPassword("supersecret")
	if err != nil {
		t.Fatalf("hash: %v", err)
	}
	repo.SeedUser("a@example.com", hash, RoleStudent)
	svc := NewService(repo, newFakeBus(), testLogger(), testJWTSecret, testJWTExpiry)

	out, err := svc.Login(ctx, "a@example.com", "supersecret")
	if err != nil {
		t.Fatalf("login: %v", err)
	}
	if out == nil {
		t.Fatal("expected output")
	}
	if out.Token == "" {
		t.Fatal("expected token")
	}
	if out.User.Email != "a@example.com" {
		t.Fatalf("unexpected user email: %q", out.User.Email)
	}

	// Token must be parseable with the same secret using HS256.
	parsed, err := jwt.Parse(out.Token, func(tok *jwt.Token) (interface{}, error) {
		if _, ok := tok.Method.(*jwt.SigningMethodHMAC); !ok {
			t.Errorf("unexpected signing method: %v", tok.Method)
		}
		return []byte(testJWTSecret), nil
	})
	if err != nil || !parsed.Valid {
		t.Fatalf("token parse: err=%v valid=%v", err, parsed != nil && parsed.Valid)
	}
}

func TestLogin_WrongPasswordRejected(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	hash, err := HashPassword("supersecret")
	if err != nil {
		t.Fatalf("hash: %v", err)
	}
	repo.SeedUser("a@example.com", hash, RoleStudent)
	svc := NewService(repo, newFakeBus(), testLogger(), testJWTSecret, testJWTExpiry)

	if _, err := svc.Login(ctx, "a@example.com", "wrong"); err == nil {
		t.Fatal("expected unauthorized")
	}
}

func TestLogin_InactiveUserRejected(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	hash, _ := HashPassword("supersecret")
	u := repo.SeedUser("a@example.com", hash, RoleStudent)
	u.IsActive = false
	svc := NewService(repo, newFakeBus(), testLogger(), testJWTSecret, testJWTExpiry)

	if _, err := svc.Login(ctx, "a@example.com", "supersecret"); err == nil {
		t.Fatal("expected unauthorized for inactive user")
	}
}
