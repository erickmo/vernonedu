package platform_test

import (
	"context"
	"errors"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/crypto"
	"github.com/vernonedu/vernonedu2/backend/internal/testdb"
)

// testAESKeyHex is a 32-byte AES-256 key used only by these tests.
const testAESKeyHex = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"

const calendarSyncTable = "platform.calendar_sync"

// stubExchanger is an in-memory TokenExchanger for unit tests.
type stubExchanger struct {
	authURLPrefix string

	exchangeTokens *platform.OAuthTokens
	exchangeErr    error

	refreshTokens *platform.OAuthTokens
	refreshErr    error
	refreshCalls  int32
}

func (s *stubExchanger) AuthURL(state string) string {
	prefix := s.authURLPrefix
	if prefix == "" {
		prefix = "https://accounts.google.com/o/oauth2/v2/auth?"
	}
	return prefix + "state=" + state
}

func (s *stubExchanger) Exchange(_ context.Context, _ string) (*platform.OAuthTokens, error) {
	if s.exchangeErr != nil {
		return nil, s.exchangeErr
	}
	return s.exchangeTokens, nil
}

func (s *stubExchanger) Refresh(_ context.Context, _ string) (*platform.OAuthTokens, error) {
	atomic.AddInt32(&s.refreshCalls, 1)
	if s.refreshErr != nil {
		return nil, s.refreshErr
	}
	return s.refreshTokens, nil
}

func newSyncSvc(t *testing.T, ex platform.TokenExchanger) (*platform.Service, platform.Repository, *crypto.AESGCM) {
	t.Helper()
	pool := testdb.New(t)
	testdb.Truncate(t, pool, usersTable, calendarSyncTable)
	gcm, err := crypto.NewAESGCMFromHex(testAESKeyHex)
	require.NoError(t, err)
	repo := platform.NewRepository(pool)
	svc := platform.NewService(repo, nil, zap.NewNop(), nil, ex, gcm)
	return svc, repo, gcm
}

func TestStartOAuthFlow_ReturnsURLWithState(t *testing.T) {
	ex := &stubExchanger{
		exchangeTokens: &platform.OAuthTokens{
			AccessToken:  "AT",
			RefreshToken: "RT",
			ExpiresAt:    time.Now().Add(time.Hour),
		},
	}
	svc, _, _ := newSyncSvc(t, ex)
	uid := uuid.New()

	url, err := svc.StartOAuthFlow(context.Background(), uid)
	require.NoError(t, err)
	require.True(t, strings.Contains(url, "state="), "expected state= in url, got %s", url)
	require.True(t, strings.HasPrefix(url, "https://accounts.google.com/"))

	// State must round-trip back to the originating user via the callback.
	state := strings.TrimPrefix(url, ex.AuthURL(""))
	require.NotEmpty(t, state)

	sync, err := svc.HandleOAuthCallback(context.Background(), "code", state)
	require.NoError(t, err)
	assert.Equal(t, uid, sync.UserID)
}

func TestHandleOAuthCallback_StoresEncryptedTokens(t *testing.T) {
	ex := &stubExchanger{
		exchangeTokens: &platform.OAuthTokens{
			AccessToken:  "AT-secret",
			RefreshToken: "RT-secret",
			ExpiresAt:    time.Now().Add(time.Hour).UTC().Truncate(time.Second),
		},
	}
	svc, repo, gcm := newSyncSvc(t, ex)
	uid := uuid.New()

	authURL, err := svc.StartOAuthFlow(context.Background(), uid)
	require.NoError(t, err)
	state := strings.TrimPrefix(authURL, ex.AuthURL(""))

	sync, err := svc.HandleOAuthCallback(context.Background(), "code-xyz", state)
	require.NoError(t, err)
	require.NotNil(t, sync)
	assert.Equal(t, uid, sync.UserID)
	assert.Equal(t, platform.ProviderGoogle, sync.Provider)

	// Stored ciphertext must NOT equal plaintext.
	stored, err := repo.GetCalendarSyncByUser(context.Background(), uid)
	require.NoError(t, err)
	assert.NotEqual(t, []byte("AT-secret"), stored.AccessTokenEnc)
	assert.NotContains(t, string(stored.AccessTokenEnc), "AT-secret")

	// And it must decrypt back to the original.
	gotAccess, err := gcm.Open(stored.AccessTokenEnc)
	require.NoError(t, err)
	assert.Equal(t, "AT-secret", string(gotAccess))
	gotRefresh, err := gcm.Open(stored.RefreshTokenEnc)
	require.NoError(t, err)
	assert.Equal(t, "RT-secret", string(gotRefresh))
}

func TestRefreshTokenIfExpired_RefreshesWhenExpired(t *testing.T) {
	newExpiry := time.Now().Add(2 * time.Hour).UTC().Truncate(time.Second)
	ex := &stubExchanger{
		refreshTokens: &platform.OAuthTokens{
			AccessToken:  "AT-new",
			RefreshToken: "RT-new",
			ExpiresAt:    newExpiry,
		},
	}
	svc, repo, gcm := newSyncSvc(t, ex)
	uid := uuid.New()

	// Pre-insert an expired sync row.
	accessEnc, err := gcm.Seal([]byte("AT-old"))
	require.NoError(t, err)
	refreshEnc, err := gcm.Seal([]byte("RT-old"))
	require.NoError(t, err)
	pre := &platform.CalendarSync{
		ID:              uuid.New(),
		UserID:          uid,
		Provider:        platform.ProviderGoogle,
		AccessTokenEnc:  accessEnc,
		RefreshTokenEnc: refreshEnc,
		TokenExpiresAt:  time.Now().Add(-time.Hour).UTC().Truncate(time.Second),
	}
	require.NoError(t, repo.UpsertCalendarSync(context.Background(), pre))

	updated, err := svc.RefreshTokenIfExpired(context.Background(), uid)
	require.NoError(t, err)
	assert.WithinDuration(t, newExpiry, updated.TokenExpiresAt, time.Second)

	stored, err := repo.GetCalendarSyncByUser(context.Background(), uid)
	require.NoError(t, err)
	assert.WithinDuration(t, newExpiry, stored.TokenExpiresAt, time.Second)

	plain, err := gcm.Open(stored.AccessTokenEnc)
	require.NoError(t, err)
	assert.Equal(t, "AT-new", string(plain))

	assert.Equal(t, int32(1), atomic.LoadInt32(&ex.refreshCalls))
}

func TestRefreshTokenIfExpired_SkipsWhenStillValid(t *testing.T) {
	ex := &stubExchanger{
		refreshErr: errors.New("should not be called"),
	}
	svc, repo, gcm := newSyncSvc(t, ex)
	uid := uuid.New()

	accessEnc, err := gcm.Seal([]byte("AT-current"))
	require.NoError(t, err)
	refreshEnc, err := gcm.Seal([]byte("RT-current"))
	require.NoError(t, err)
	expiresAt := time.Now().Add(time.Hour).UTC().Truncate(time.Second)
	pre := &platform.CalendarSync{
		ID:              uuid.New(),
		UserID:          uid,
		Provider:        platform.ProviderGoogle,
		AccessTokenEnc:  accessEnc,
		RefreshTokenEnc: refreshEnc,
		TokenExpiresAt:  expiresAt,
	}
	require.NoError(t, repo.UpsertCalendarSync(context.Background(), pre))

	got, err := svc.RefreshTokenIfExpired(context.Background(), uid)
	require.NoError(t, err)
	assert.WithinDuration(t, expiresAt, got.TokenExpiresAt, time.Second)
	assert.Equal(t, int32(0), atomic.LoadInt32(&ex.refreshCalls))

	// And confirm decrypted access token remains unchanged.
	plain, err := gcm.Open(got.AccessTokenEnc)
	require.NoError(t, err)
	assert.Equal(t, "AT-current", string(plain))
}
