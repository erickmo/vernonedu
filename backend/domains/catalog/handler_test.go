//go:build integration

package catalog_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/catalog"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// buildCatalogRouter creates a test router with the given actor injected.
func buildCatalogRouter(svc *catalog.Service, actorID uuid.UUID) http.Handler {
	h := catalog.NewHandler(svc)
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: "vernonedu_admin"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	r.Get("/api/v1/courses", h.ListCourses)
	r.Post("/api/v1/courses", h.CreateCourse)
	r.Get("/api/v1/courses/{id}", h.GetCourse)
	r.Patch("/api/v1/courses/{id}", h.UpdateCourse)
	r.Get("/api/v1/courses/{id}/batches", h.ListBatchesByCourseID)

	r.Post("/api/v1/batches", h.CreateBatch)
	r.Get("/api/v1/batches", h.ListBatches)
	r.Get("/api/v1/batches/{id}", h.GetBatch)
	r.Post("/api/v1/batches/{id}/open", h.OpenBatch)
	r.Post("/api/v1/batches/{id}/close", h.CloseBatch)
	r.Patch("/api/v1/batches/{id}/status", h.PatchBatchStatus)

	r.Get("/api/v1/batches/{batchID}/classes", h.ListClasses)
	r.Post("/api/v1/classes", h.CreateClass)

	return r
}

// TestCatalog_ListCourses_Authenticated verifies authenticated list returns 200.
func TestCatalog_ListCourses_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	s := seedIdentity(t, pool)
	router := buildCatalogRouter(svc, s.creatorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/courses?department_id="+s.deptID.String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

// TestCatalog_GetCourse_NotFound verifies 404 for unknown course ID.
func TestCatalog_GetCourse_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildCatalogRouter(svc, uuid.New())

	req := httptest.NewRequest(http.MethodGet, "/api/v1/courses/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

// TestCatalog_ListBatches_Authenticated verifies authenticated list returns 200.
func TestCatalog_ListBatches_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	s := seedIdentity(t, pool)
	router := buildCatalogRouter(svc, s.creatorID)

	// course_id query param is required by the handler
	req := httptest.NewRequest(http.MethodGet, "/api/v1/batches?course_id="+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

// TestCatalog_UpdateCourse verifies PATCH /api/v1/courses/{id} updates and returns the course.
func TestCatalog_UpdateCourse(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	s := seedIdentity(t, pool)
	router := buildCatalogRouter(svc, s.creatorID)

	ctx := t.Context()
	course := &catalog.Course{
		Name:            "Intro Go",
		Format:          "online",
		Status:          "active",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1500000),
		MinPrice:        decimal.NewFromInt(1000000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	body, err := json.Marshal(map[string]any{
		"name":          "Updated",
		"description":   "New desc",
		"duration_days": 14,
		"status":        "active",
	})
	require.NoError(t, err)

	req := httptest.NewRequest(http.MethodPatch, "/api/v1/courses/"+course.ID.String(), bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)

	var result catalog.Course
	require.NoError(t, json.NewDecoder(w.Body).Decode(&result))
	require.Equal(t, "Updated", result.Name)
	require.Equal(t, "New desc", result.Description)
	require.Equal(t, 14, result.DurationDays)
	require.Equal(t, "active", result.Status)
}

// TestCatalog_GetBatch_NotFound verifies 404 for unknown batch ID.
func TestCatalog_GetBatch_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildCatalogRouter(svc, uuid.New())

	req := httptest.NewRequest(http.MethodGet, "/api/v1/batches/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

// TestCatalog_ListBatchesByCourseID verifies GET /api/v1/courses/{id}/batches returns batches for a course.
func TestCatalog_ListBatchesByCourseID(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Course X",
		Format:          "online",
		Status:          "active",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1000000),
		MinPrice:        decimal.NewFromInt(800000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	batch := &catalog.CourseBatch{
		CourseID:  course.ID,
		Label:     "Batch A",
		StartDate: time.Now(),
		EndDate:   time.Now().AddDate(0, 1, 0),
		Price:     decimal.NewFromInt(1200000),
		CreatedBy: s.creatorID,
	}
	require.NoError(t, svc.CreateBatch(ctx, batch))

	router := buildCatalogRouter(svc, s.creatorID)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/courses/"+course.ID.String()+"/batches", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
	var result []*catalog.CourseBatch
	require.NoError(t, json.NewDecoder(w.Body).Decode(&result))
	require.Len(t, result, 1)
	require.Equal(t, batch.ID, result[0].ID)
}

// TestCatalog_PatchBatchStatus verifies PATCH /api/v1/batches/{id}/status updates status.
func TestCatalog_PatchBatchStatus(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Course Y",
		Format:          "online",
		Status:          "active",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1000000),
		MinPrice:        decimal.NewFromInt(800000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	batch := &catalog.CourseBatch{
		CourseID:  course.ID,
		Label:     "Batch B",
		StartDate: time.Now(),
		EndDate:   time.Now().AddDate(0, 1, 0),
		Price:     decimal.NewFromInt(1200000),
		CreatedBy: s.creatorID,
	}
	require.NoError(t, svc.CreateBatch(ctx, batch))

	router := buildCatalogRouter(svc, s.creatorID)
	body := `{"status":"open"}`
	req := httptest.NewRequest(http.MethodPatch, "/api/v1/batches/"+batch.ID.String()+"/status", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
	var result catalog.CourseBatch
	require.NoError(t, json.NewDecoder(w.Body).Decode(&result))
	require.Equal(t, catalog.BatchOpen, result.Status)
}

// TestCatalog_CreateClass verifies POST /api/v1/classes creates a class and returns 201.
func TestCatalog_CreateClass(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Course Z",
		Format:          "online",
		Status:          "active",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1000000),
		MinPrice:        decimal.NewFromInt(800000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	batch := &catalog.CourseBatch{
		CourseID:  course.ID,
		Label:     "Batch C",
		StartDate: time.Now(),
		EndDate:   time.Now().AddDate(0, 1, 0),
		Price:     decimal.NewFromInt(1200000),
		CreatedBy: s.creatorID,
	}
	require.NoError(t, svc.CreateBatch(ctx, batch))

	router := buildCatalogRouter(svc, s.creatorID)
	body := fmt.Sprintf(`{
		"course_batch_id": %q,
		"session_date": "2026-05-01T09:00:00Z",
		"start_time": "09:00",
		"end_time": "12:00",
		"mode": "online",
		"instructor_id": %q,
		"instructor_type": "course_creator",
		"assigned_by": "course_creator_self"
	}`, batch.ID, s.creatorID)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/classes", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
	var cl catalog.Class
	require.NoError(t, json.NewDecoder(w.Body).Decode(&cl))
	require.Equal(t, batch.ID, cl.CourseBatchID)
	require.NotEqual(t, uuid.Nil, cl.ID)
}
