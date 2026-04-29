//go:build integration

package module_test

import (
	"bytes"
	"context"
	"encoding/json"
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
	viewModule    := mw.RequireRole("vernonedu_admin", "course_creator", "dept_leader", "facilitator", "student")
	studentAccess := mw.RequireRole("student")

	r.With(manageModule).Post("/api/v1/courses/{id}/modules", h.CreateModule)
	r.With(viewModule).Get("/api/v1/courses/{id}/modules", h.ListModules)
	r.With(viewModule).Get("/api/v1/modules/{id}/versions", h.ListVersions)
	r.With(studentAccess).Get("/api/v1/enrollments/{id}/modules", h.GetStudentModules)
	r.With(manageModule).Get("/api/v1/module-versions/{id}/assets", h.ListAssetsByVersion)
	r.With(manageModule).Post("/api/v1/module-versions/{id}/publish", h.PublishVersionByVersionID)
	r.With(manageModule).Post("/api/v1/module-assets", h.CreateAssetByVersionID)

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

func TestListAssetsByVersion(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	m, err := svc.CreateModule(ctx, seed.courseID, "Mod 1", 1, seed.actorID)
	require.NoError(t, err)

	ver, err := svc.CreateModuleVersion(ctx, m.ID, "1.0.0", nil, seed.actorID)
	require.NoError(t, err)

	router := buildModuleRouter(svc, seed.actorID, "vernonedu_admin")
	req := httptest.NewRequest(http.MethodGet, "/api/v1/module-versions/"+ver.ID.String()+"/assets", http.NoBody)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)
}

func TestPublishVersionByVersionID(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	m, err := svc.CreateModule(ctx, seed.courseID, "Mod Publish", 1, seed.actorID)
	require.NoError(t, err)

	ver, err := svc.CreateModuleVersion(ctx, m.ID, "1.0.0", nil, seed.actorID)
	require.NoError(t, err)

	router := buildModuleRouter(svc, seed.actorID, "vernonedu_admin")
	req := httptest.NewRequest(http.MethodPost, "/api/v1/module-versions/"+ver.ID.String()+"/publish", http.NoBody)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusNoContent, rec.Code)
}

func TestCreateAssetByVersionID(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	m, err := svc.CreateModule(ctx, seed.courseID, "Mod Asset", 1, seed.actorID)
	require.NoError(t, err)

	ver, err := svc.CreateModuleVersion(ctx, m.ID, "1.0.0", nil, seed.actorID)
	require.NoError(t, err)

	router := buildModuleRouter(svc, seed.actorID, "vernonedu_admin")
	body, _ := json.Marshal(map[string]any{
		"version_id":      ver.ID,
		"title":           "Lecture Slide",
		"asset_type":      "document",
		"url":             "https://example.com/slide.pdf",
		"order":           1,
		"is_downloadable": true,
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/module-assets", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusCreated, rec.Code)
}

func TestListModules(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	_, err := svc.CreateModule(ctx, seed.courseID, "Module A", 1, seed.actorID)
	require.NoError(t, err)
	_, err = svc.CreateModule(ctx, seed.courseID, "Module B", 2, seed.actorID)
	require.NoError(t, err)

	router := buildModuleRouter(svc, seed.actorID, "vernonedu_admin")
	req := httptest.NewRequest(http.MethodGet, "/api/v1/courses/"+seed.courseID.String()+"/modules", http.NoBody)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)
	var result []*module.CourseModule
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&result))
	require.Len(t, result, 2)
}

func TestListVersionsByModule(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	m, err := svc.CreateModule(ctx, seed.courseID, "Versioned Module", 1, seed.actorID)
	require.NoError(t, err)

	_, err = svc.CreateModuleVersion(ctx, m.ID, "Draft v1", nil, seed.actorID)
	require.NoError(t, err)
	_, err = svc.CreateModuleVersion(ctx, m.ID, "Draft v2", nil, seed.actorID)
	require.NoError(t, err)

	router := buildModuleRouter(svc, seed.actorID, "vernonedu_admin")
	req := httptest.NewRequest(http.MethodGet, "/api/v1/modules/"+m.ID.String()+"/versions", http.NoBody)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)
	var result []*module.ModuleVersion
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&result))
	require.Len(t, result, 2)
}
