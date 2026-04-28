//go:build integration

package voucher_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/voucher"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// seedAdminUser inserts an admin user and returns their ID.
// Does not conflict with seedFixture (different email).
func seedAdminUser(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	err := pool.QueryRow(context.Background(), `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('admin.handler@v.local','x','admin')
		RETURNING id`).Scan(&id)
	require.NoError(t, err)
	return id
}

func buildVoucherRouter(svc *voucher.Service, role string, callerID uuid.UUID) http.Handler {
	h := voucher.NewHandler(svc)
	r := chi.NewRouter()

	adminMW := mw.RequireRole("admin", "vernonedu_admin")

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: callerID, Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	// Admin-only routes
	r.Group(func(r chi.Router) {
		r.Use(adminMW)
		r.Post("/api/v1/vouchers", h.CreateVoucher)
		r.Get("/api/v1/vouchers/{id}", h.GetVoucher)
		r.Get("/api/v1/vouchers", h.ListVouchers)
		r.Patch("/api/v1/vouchers/{id}/deactivate", h.DeactivateVoucher)
	})

	// Any authenticated user
	r.Post("/api/v1/vouchers/apply", h.ApplyVoucher)

	// Student viewing their own assigned vouchers
	r.Get("/api/v1/students/{studentID}/vouchers", h.ListMyVouchers)

	return r
}

func TestVoucher_CreateVoucher_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildVoucherRouter(svc, "student", uuid.New())

	body := `{"code":"SAVE10","discount_type":"percentage","discount_value":"10","valid_from":"2026-01-01"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/vouchers", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestVoucher_ListVouchers_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildVoucherRouter(svc, "student", uuid.New())

	req := httptest.NewRequest(http.MethodGet, "/api/v1/vouchers", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestVoucher_CreateVoucher_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	adminID := seedAdminUser(t, pool)
	svc := newService(t, pool)
	router := buildVoucherRouter(svc, "admin", adminID)

	payload := map[string]interface{}{
		"code":           "ADMIN10",
		"discount_type":  string(voucher.DiscountPercentage),
		"discount_value": "10",
		"valid_from":     time.Now().Format("2006-01-02"),
	}
	bodyBytes, _ := json.Marshal(payload)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/vouchers", strings.NewReader(string(bodyBytes)))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestVoucher_ListVouchers_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildVoucherRouter(svc, "admin", uuid.New())

	req := httptest.NewRequest(http.MethodGet, "/api/v1/vouchers", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestVoucher_ListMyVouchers_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildVoucherRouter(svc, "student", uuid.New())

	studentID := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/students/"+studentID.String()+"/vouchers", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
