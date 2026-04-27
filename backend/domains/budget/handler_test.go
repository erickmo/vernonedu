//go:build integration

package budget_test

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

	"github.com/vernonedu/vernonedu2/backend/domains/budget"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildTestRouter(svc *budget.Service, role string) http.Handler {
	h := budget.NewHandler(svc, zap.NewNop())
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	manageTemplate := mw.RequireRole("course_creator", "vernonedu_admin")
	manageBatch := mw.RequireRole("course_creator", "vernonedu_admin")
	manageRealization := mw.RequireRole("vernonedu_admin")

	r.Get("/api/v1/courses/{course_id}/budget-templates", h.ListTemplateItems)
	r.Get("/api/v1/courses/{course_id}/budget-templates/{id}", h.GetTemplateItem)
	r.With(manageTemplate).Post("/api/v1/courses/{course_id}/budget-templates", h.CreateTemplateItem)

	r.Get("/api/v1/batches/{batch_id}/budget-items", h.ListBatchItems)
	r.Get("/api/v1/batches/{batch_id}/budget-items/{id}", h.GetBatchItem)
	r.With(manageBatch).Post("/api/v1/batches/{batch_id}/budget-items", h.CreateBatchItem)

	r.Get("/api/v1/budget-items/{item_id}/realizations", h.ListRealizations)
	r.Get("/api/v1/budget-items/{item_id}/realizations/{id}", h.GetRealization)
	r.With(manageRealization).Post("/api/v1/budget-items/{item_id}/realizations", h.CreateRealization)

	r.Get("/api/v1/batches/{batch_id}/budget-summary", h.GetBatchSummary)

	return r
}

func TestRoleEnforcement_TemplateCreate_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := budget.NewService(budget.NewRepository(pool), zap.NewNop())
	router := buildTestRouter(svc, "student")

	courseID := uuid.New()
	req := httptest.NewRequest(http.MethodPost,
		"/api/v1/courses/"+courseID.String()+"/budget-templates",
		http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestRoleEnforcement_TemplateCreate_AllowedForCourseCreator(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	courseID, _ := seedCourseAndTemplates(t, pool)

	svc := budget.NewService(budget.NewRepository(pool), zap.NewNop())
	router := buildTestRouter(svc, "course_creator")

	body := `{"label":"New Line","preset_amount":200,"overridable":true}`
	req := httptest.NewRequest(http.MethodPost,
		"/api/v1/courses/"+courseID.String()+"/budget-templates",
		strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestRoleEnforcement_RealizationCreate_ForbiddenForCourseCreator(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := budget.NewService(budget.NewRepository(pool), zap.NewNop())
	router := buildTestRouter(svc, "course_creator")

	itemID := uuid.New()
	req := httptest.NewRequest(http.MethodPost,
		"/api/v1/budget-items/"+itemID.String()+"/realizations",
		http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestGetSingleTemplateItem_ReturnsItem(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	courseID, _ := seedCourseAndTemplates(t, pool)

	repo := budget.NewRepository(pool)
	items, err := repo.ListTemplateItems(context.Background(), courseID)
	require.NoError(t, err)
	require.NotEmpty(t, items)

	svc := budget.NewService(repo, zap.NewNop())
	router := buildTestRouter(svc, "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet,
		"/api/v1/courses/"+courseID.String()+"/budget-templates/"+items[0].ID.String(),
		nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)

	var result budget.CourseBudgetTemplateItem
	require.NoError(t, json.NewDecoder(w.Body).Decode(&result))
	require.Equal(t, items[0].ID, result.ID)
}
