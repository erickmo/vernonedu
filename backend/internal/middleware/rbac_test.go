package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func okHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) }
}

func TestRequireRoles_AllowsMatchingRole(t *testing.T) {
	h := mw.RequireRoles("admin", "ceo")(okHandler())
	req := httptest.NewRequest("GET", "/", nil)
	ctx := mw.WithUserContext(req.Context(), &mw.UserContext{ID: uuid.New(), Role: "admin"})
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req.WithContext(ctx))
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
}

func TestRequireRoles_RejectsWrongRole(t *testing.T) {
	h := mw.RequireRoles("admin")(okHandler())
	req := httptest.NewRequest("GET", "/", nil)
	ctx := mw.WithUserContext(req.Context(), &mw.UserContext{ID: uuid.New(), Role: "student"})
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req.WithContext(ctx))
	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected 403, got %d", rec.Code)
	}
}

func TestRequireRoles_RejectsAnonymous(t *testing.T) {
	h := mw.RequireRoles("admin")(okHandler())
	req := httptest.NewRequest("GET", "/", nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", rec.Code)
	}
}
