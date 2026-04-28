//go:build integration

package enrollment_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/enrollment"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildEnrollmentRouter(svc *enrollment.Service, role string) http.Handler {
	h := enrollment.NewHandler(svc)
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	r.Post("/api/v1/enrollments", h.CreateEnrollment)
	r.Get("/api/v1/enrollments/{id}", h.GetEnrollment)
	r.Post("/api/v1/enrollments/{id}/drop", h.DropEnrollment)
	r.Post("/api/v1/enrollments/{id}/complete", h.CompleteEnrollment)
	r.Get("/api/v1/students/{studentID}/enrollments", h.ListEnrollmentsByStudent)

	return r
}

func TestEnrollment_GetEnrollment_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildEnrollmentRouter(svc, "student")

	id := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/enrollments/"+id.String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestEnrollment_ListEnrollmentsByStudent_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildEnrollmentRouter(svc, "student")

	studentID := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/students/"+studentID.String()+"/enrollments", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
