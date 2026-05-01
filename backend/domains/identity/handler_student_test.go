//go:build integration

package identity_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/identity"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildStudentTestRouter(svc *identity.Service, role string) http.Handler {
	h := identity.NewHandler(svc, &config.Config{})
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	manageStudents := mw.RequireRole("admin", "ceo", "vernonedu_admin")
	studentSelf := mw.RequireRole("student")

	r.With(manageStudents).Get("/api/v1/students", h.ListStudents)
	r.With(manageStudents).Get("/api/v1/students/{id}", h.GetStudent)
	r.With(manageStudents).Put("/api/v1/students/{id}", h.UpdateStudent)
	r.With(manageStudents).Get("/api/v1/students/{id}/profile", h.GetStudentProfileByID)
	r.With(manageStudents).Put("/api/v1/students/{id}/profile", h.UpdateStudentProfileByAdmin)
	r.With(studentSelf).Get("/api/v1/me/student", h.GetMyStudent)
	r.With(studentSelf).Put("/api/v1/me/student/profile", h.UpdateMyStudentProfile)

	return r
}

func TestStudentList_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/students", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestStudentList_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/students", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestUpdateStudent_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "student")

	req := httptest.NewRequest(http.MethodPut, "/api/v1/students/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestUpdateStudentProfileByAdmin_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "student")

	req := httptest.NewRequest(http.MethodPut, "/api/v1/students/"+uuid.New().String()+"/profile", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestGetMyStudent_ForbiddenForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me/student", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestUpdateMyStudentProfile_ForbiddenForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "admin")

	req := httptest.NewRequest(http.MethodPut, "/api/v1/me/student/profile", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestUpdateMyStudentProfile_AllowedForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()
	_ = zap.NewNop()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "selfservice@test.local", Password: "pass", Name: "Self Service", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)

	h := identity.NewHandler(svc, &config.Config{})
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: u.ID, Role: "student"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	studentSelf := mw.RequireRole("student")
	r.With(studentSelf).Put("/api/v1/me/student/profile", h.UpdateMyStudentProfile)

	body := `{"city":"Jakarta","province":"DKI Jakarta"}`
	req := httptest.NewRequest(http.MethodPut, "/api/v1/me/student/profile", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)

	var profile identity.StudentProfile
	require.NoError(t, json.NewDecoder(w.Body).Decode(&profile))
	require.NotNil(t, profile.City)
	require.Equal(t, "Jakarta", *profile.City)
}
