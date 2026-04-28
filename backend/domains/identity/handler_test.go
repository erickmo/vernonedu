//go:build integration

package identity_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/identity"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

const testJWTSecret = "test-secret"

func testConfig() *config.Config {
	cfg := &config.Config{}
	cfg.JWT.Secret = testJWTSecret
	cfg.JWT.ExpiryHours = 24
	return cfg
}

// buildAuthRouter wires only the 4 auth/department routes.
// The injectedRole parameter controls the fake UserContext for JWT-protected routes.
// Pass an empty string to skip UserContext injection (public route testing).
func buildAuthRouter(svc *identity.Service, injectedRole string) http.Handler {
	h := identity.NewHandler(svc, testConfig())
	r := chi.NewRouter()

	if injectedRole != "" {
		r.Use(func(next http.Handler) http.Handler {
			return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
				uc := &mw.UserContext{ID: uuid.New(), Role: injectedRole}
				next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
			})
		})
	}

	r.Post("/api/v1/auth/register", h.Register)
	r.Post("/api/v1/auth/login", h.Login)
	r.Get("/api/v1/auth/me", h.GetMe)
	r.Get("/api/v1/departments", h.ListDepartments)

	return r
}

func TestIdentity_Register_CreatesUser(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildAuthRouter(svc, "")

	body := `{"email":"handler_reg@test.local","password":"secret123","name":"Handler Reg","phone":"0811"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)

	var user identity.User
	require.NoError(t, json.NewDecoder(w.Body).Decode(&user))
	require.Equal(t, "handler_reg@test.local", user.Email)
	require.NotEqual(t, uuid.Nil, user.ID)
}

func TestIdentity_Register_MissingFields_Returns400(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildAuthRouter(svc, "")

	body := `{"email":"incomplete@test.local"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusUnprocessableEntity, w.Code)
}

func TestIdentity_Login_ReturnsToken(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildAuthRouter(svc, "")

	// Seed a user via the public register endpoint
	regBody := `{"email":"handler_login@test.local","password":"pass123","name":"Login User","phone":"0812"}`
	regReq := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", strings.NewReader(regBody))
	regReq.Header.Set("Content-Type", "application/json")
	regW := httptest.NewRecorder()
	router.ServeHTTP(regW, regReq)
	require.Equal(t, http.StatusCreated, regW.Code)

	// Now login
	loginBody := `{"email":"handler_login@test.local","password":"pass123"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", strings.NewReader(loginBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]string
	require.NoError(t, json.NewDecoder(w.Body).Decode(&resp))
	require.NotEmpty(t, resp["token"])
}

func TestIdentity_Login_WrongPassword_Returns401(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildAuthRouter(svc, "")

	// Seed user first
	regBody := `{"email":"badpass@test.local","password":"correct","name":"Bad Pass","phone":"0812"}`
	regReq := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", strings.NewReader(regBody))
	regReq.Header.Set("Content-Type", "application/json")
	regW := httptest.NewRecorder()
	router.ServeHTTP(regW, regReq)
	require.Equal(t, http.StatusCreated, regW.Code)

	loginBody := `{"email":"badpass@test.local","password":"wrong"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", strings.NewReader(loginBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIdentity_GetMe_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)

	// Register a real user so GetMe can fetch it from the DB
	ctx := t.Context()
	user, err := svc.Register(ctx, identity.RegisterInput{
		Email:    "getme@test.local",
		Password: "secret",
		Name:     "Get Me",
		Phone:    "0813",
		Role:     identity.RoleStudent,
		Source:   identity.SourceB2C,
	})
	require.NoError(t, err)

	// Build router with a UserContext pointing to the real user ID
	h := identity.NewHandler(svc, testConfig())
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: user.ID, Role: string(user.Role)}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Get("/api/v1/auth/me", h.GetMe)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", http.NoBody)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)

	var got identity.User
	require.NoError(t, json.NewDecoder(w.Body).Decode(&got))
	require.Equal(t, user.ID, got.ID)
	require.Equal(t, "getme@test.local", got.Email)
}

func TestIdentity_GetMe_NoContext_Returns401(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	// No UserContext injected
	router := buildAuthRouter(svc, "")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIdentity_ListDepartments_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	// Inject any authenticated role — ListDepartments has no RBAC guard
	router := buildAuthRouter(svc, "admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/departments", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
