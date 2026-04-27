// Package crypto provides small encryption helpers used across domains.
//
// AESGCM wraps a 32-byte (AES-256) key into an authenticated-encryption
// primitive used to seal/open opaque secrets at rest (e.g. OAuth tokens for
// the platform calendar_sync table).
package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"io"
)

// aesKeyBytes is the required key length for AES-256.
const aesKeyBytes = 32

// AESGCM is a small wrapper around an AEAD cipher. The zero value is unusable;
// always construct via NewAESGCMFromHex.
type AESGCM struct {
	gcm cipher.AEAD
}

// NewAESGCMFromHex constructs an AESGCM from a hex-encoded 32-byte key.
func NewAESGCMFromHex(hexKey string) (*AESGCM, error) {
	key, err := hex.DecodeString(hexKey)
	if err != nil {
		return nil, err
	}
	if len(key) != aesKeyBytes {
		return nil, errors.New("aesgcm: key must be 32 bytes")
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	g, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	return &AESGCM{gcm: g}, nil
}

// Seal encrypts plaintext and prepends a fresh random nonce to the ciphertext.
func (a *AESGCM) Seal(plaintext []byte) ([]byte, error) {
	nonce := make([]byte, a.gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, err
	}
	ct := a.gcm.Seal(nil, nonce, plaintext, nil)
	return append(nonce, ct...), nil
}

// Open decrypts the [nonce || ciphertext] payload produced by Seal.
func (a *AESGCM) Open(ct []byte) ([]byte, error) {
	if len(ct) < a.gcm.NonceSize() {
		return nil, errors.New("aesgcm: ciphertext too short")
	}
	nonce, body := ct[:a.gcm.NonceSize()], ct[a.gcm.NonceSize():]
	return a.gcm.Open(nil, nonce, body, nil)
}
