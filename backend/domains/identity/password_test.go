package identity

import "testing"

func TestHashPassword_Verifies(t *testing.T) {
	hash, err := HashPassword("supersecret123")
	if err != nil {
		t.Fatalf("hash: %v", err)
	}
	if !VerifyPassword(hash, "supersecret123") {
		t.Fatal("verify failed for correct password")
	}
	if VerifyPassword(hash, "wrong") {
		t.Fatal("verify accepted wrong password")
	}
}

func TestHashPassword_RejectsTooShort(t *testing.T) {
	if _, err := HashPassword("short"); err == nil {
		t.Fatal("expected error for short password")
	}
}
