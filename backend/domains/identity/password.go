package identity

import (
	"errors"

	"golang.org/x/crypto/bcrypt"
)

const minPasswordLen = 8

// ErrPasswordTooShort indicates the supplied plaintext password is below the minimum length.
var ErrPasswordTooShort = errors.New("password must be at least 8 characters")

// HashPassword bcrypt-hashes the plaintext password after enforcing the minimum length.
func HashPassword(plain string) (string, error) {
	if len(plain) < minPasswordLen {
		return "", ErrPasswordTooShort
	}
	h, err := bcrypt.GenerateFromPassword([]byte(plain), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(h), nil
}

// VerifyPassword reports whether the plaintext matches the bcrypt hash.
func VerifyPassword(hash, plain string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(plain)) == nil
}
