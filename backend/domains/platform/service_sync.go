package platform

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

// ProviderGoogle is the only OAuth provider currently supported for calendar sync.
const ProviderGoogle = "google"

// stateNonceBytes is the size of the random nonce embedded in OAuth state tokens.
const stateNonceBytes = 16

// ErrSyncNotConfigured is returned when calendar-sync methods are invoked on a
// Service that was constructed without a TokenExchanger or AES-GCM cipher.
var ErrSyncNotConfigured = errors.New("platform: calendar sync not configured")

// ErrInvalidState is returned when a callback's state token cannot be decoded
// or does not contain a valid user_id.
var ErrInvalidState = errors.New("platform: invalid oauth state")

// OAuthTokens carries the result of an OAuth code exchange or refresh.
type OAuthTokens struct {
	AccessToken  string
	RefreshToken string
	ExpiresAt    time.Time
}

// TokenExchanger abstracts the OAuth provider so the service can be unit-tested
// without hitting the network. Production wires a Google implementation.
type TokenExchanger interface {
	AuthURL(state string) string
	Exchange(ctx context.Context, code string) (*OAuthTokens, error)
	Refresh(ctx context.Context, refreshToken string) (*OAuthTokens, error)
}

// generateState builds a stateless OAuth state token: base64(userID ":" nonce).
// The handler echoes it back on callback; parseState extracts the userID.
func generateState(userID uuid.UUID) (string, error) {
	nonce := make([]byte, stateNonceBytes)
	if _, err := rand.Read(nonce); err != nil {
		return "", err
	}
	raw := userID.String() + ":" + base64.RawURLEncoding.EncodeToString(nonce)
	return base64.RawURLEncoding.EncodeToString([]byte(raw)), nil
}

// parseState recovers the userID from a state token produced by generateState.
func parseState(state string) (uuid.UUID, error) {
	raw, err := base64.RawURLEncoding.DecodeString(state)
	if err != nil {
		return uuid.Nil, fmt.Errorf("%w: %v", ErrInvalidState, err)
	}
	parts := strings.SplitN(string(raw), ":", 2)
	if len(parts) != 2 {
		return uuid.Nil, ErrInvalidState
	}
	uid, err := uuid.Parse(parts[0])
	if err != nil {
		return uuid.Nil, fmt.Errorf("%w: %v", ErrInvalidState, err)
	}
	return uid, nil
}

// StartOAuthFlow returns the provider authorization URL with a fresh state
// token that encodes userID for the callback step.
func (s *Service) StartOAuthFlow(ctx context.Context, userID uuid.UUID) (string, error) {
	if s.exchanger == nil {
		return "", ErrSyncNotConfigured
	}
	state, err := generateState(userID)
	if err != nil {
		return "", err
	}
	return s.exchanger.AuthURL(state), nil
}

// HandleOAuthCallback exchanges the authorization code for tokens, encrypts
// them, and upserts the calendar_sync row for the user encoded in state.
func (s *Service) HandleOAuthCallback(ctx context.Context, code, state string) (*CalendarSync, error) {
	if s.exchanger == nil || s.crypto == nil {
		return nil, ErrSyncNotConfigured
	}
	userID, err := parseState(state)
	if err != nil {
		return nil, err
	}
	tokens, err := s.exchanger.Exchange(ctx, code)
	if err != nil {
		return nil, err
	}
	accessEnc, err := s.crypto.Seal([]byte(tokens.AccessToken))
	if err != nil {
		return nil, err
	}
	refreshEnc, err := s.crypto.Seal([]byte(tokens.RefreshToken))
	if err != nil {
		return nil, err
	}
	sync := &CalendarSync{
		ID:              uuid.New(),
		UserID:          userID,
		Provider:        ProviderGoogle,
		AccessTokenEnc:  accessEnc,
		RefreshTokenEnc: refreshEnc,
		TokenExpiresAt:  tokens.ExpiresAt,
	}
	if err := s.repo.UpsertCalendarSync(ctx, sync); err != nil {
		return nil, err
	}
	return sync, nil
}

// RefreshTokenIfExpired returns the existing sync record when the access token
// is still valid; otherwise it uses the stored refresh_token to obtain a new
// access token and persists the updated tokens.
func (s *Service) RefreshTokenIfExpired(ctx context.Context, userID uuid.UUID) (*CalendarSync, error) {
	if s.exchanger == nil || s.crypto == nil {
		return nil, ErrSyncNotConfigured
	}
	sync, err := s.repo.GetCalendarSyncByUser(ctx, userID)
	if err != nil {
		return nil, err
	}
	if time.Now().Before(sync.TokenExpiresAt) {
		return sync, nil
	}
	refreshPlain, err := s.crypto.Open(sync.RefreshTokenEnc)
	if err != nil {
		return nil, err
	}
	tokens, err := s.exchanger.Refresh(ctx, string(refreshPlain))
	if err != nil {
		return nil, err
	}
	accessEnc, err := s.crypto.Seal([]byte(tokens.AccessToken))
	if err != nil {
		return nil, err
	}
	refreshEnc := sync.RefreshTokenEnc
	if tokens.RefreshToken != "" {
		refreshEnc, err = s.crypto.Seal([]byte(tokens.RefreshToken))
		if err != nil {
			return nil, err
		}
	}
	sync.AccessTokenEnc = accessEnc
	sync.RefreshTokenEnc = refreshEnc
	sync.TokenExpiresAt = tokens.ExpiresAt
	if err := s.repo.UpsertCalendarSync(ctx, sync); err != nil {
		return nil, err
	}
	return sync, nil
}
