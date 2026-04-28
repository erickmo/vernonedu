//go:build integration

package module_test

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/module"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildModuleRouter(svc *module.Service, actorID uuid.UUID, role string) http.Handler {
	h := module.NewHandler(svc)
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	manageModule  := mw.RequireRole("vernonedu_admin", "course_creator")
	studentAccess := mw.RequireRole("student")

	r.With(manageModule).Post("/api/v1/courses/{id}/modules", h.CreateModule)
	r.With(studentAccess).Get("/api/v1/enrollments/{id}/modules", h.GetStudentModules)

	return r
}

func TestCreateModule_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := module.NewService(module.NewRepository(pool), zap.NewNop())
	router := buildModuleRouter(svc, uuid.New(), "student")

	body := `{"title":"Test","order":1}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/courses/"+uuid.New().String()+"/modules",
		bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusForbidden, rec.Code)
}

func TestCreateModule_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)

	svc := module.NewService(module.NewRepository(pool), zap.NewNop())
	router := buildModuleRouter(svc, seed.actorID, "vernonedu_admin")

	body := `{"title":"Intro","order":1}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/courses/"+seed.courseID.String()+"/modules",
		bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusCreated, rec.Code)
}
