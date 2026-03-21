package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_department"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_department"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_department"
	getdeptbatches "github.com/vernonedu/entrepreneurship-api/internal/query/get_department_batches"
	getdeptcourses "github.com/vernonedu/entrepreneurship-api/internal/query/get_department_courses"
	getdeptstudents "github.com/vernonedu/entrepreneurship-api/internal/query/get_department_students"
	getdepttalentpool "github.com/vernonedu/entrepreneurship-api/internal/query/get_department_talentpool"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_department"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_department"
	listdeptsummary "github.com/vernonedu/entrepreneurship-api/internal/query/list_department_summary"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type DepartmentHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewDepartmentHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *DepartmentHandler {
	return &DepartmentHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateDepartmentRequest struct {
	Name        string `json:"name" validate:"required,min=1"`
	Description string `json:"description"`
	IsActive    bool   `json:"is_active"`
}

type UpdateDepartmentRequest struct {
	Name        string `json:"name" validate:"required,min=1"`
	Description string `json:"description"`
	IsActive    bool   `json:"is_active"`
}

func (h *DepartmentHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateDepartmentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_department.CreateDepartmentCommand{
		Name:        req.Name,
		Description: req.Description,
		IsActive:    req.IsActive,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create department command")
		writeError(w, http.StatusInternalServerError, "failed to create department")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "department created successfully"})
}

func (h *DepartmentHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	departmentIDStr := chi.URLParam(r, "id")
	departmentID, err := uuid.Parse(departmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid department id")
		return
	}

	query := &get_department.GetDepartmentQuery{DepartmentID: departmentID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get department query")
		writeError(w, http.StatusInternalServerError, "failed to get department")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *DepartmentHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_department.ListDepartmentQuery{Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list department query")
		writeError(w, http.StatusInternalServerError, "failed to list departments")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (h *DepartmentHandler) Update(w http.ResponseWriter, r *http.Request) {
	departmentIDStr := chi.URLParam(r, "id")
	departmentID, err := uuid.Parse(departmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid department id")
		return
	}

	var req UpdateDepartmentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_department.UpdateDepartmentCommand{
		DepartmentID: departmentID,
		Name:         req.Name,
		Description:  req.Description,
		IsActive:     req.IsActive,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update department command")
		writeError(w, http.StatusInternalServerError, "failed to update department")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "department updated successfully"})
}

func (h *DepartmentHandler) Delete(w http.ResponseWriter, r *http.Request) {
	departmentIDStr := chi.URLParam(r, "id")
	departmentID, err := uuid.Parse(departmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid department id")
		return
	}

	cmd := &delete_department.DeleteDepartmentCommand{DepartmentID: departmentID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete department command")
		writeError(w, http.StatusInternalServerError, "failed to delete department")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "department deleted successfully"})
}

// ListSummaries returns per-department aggregated stats for the dashboard card view.
func (h *DepartmentHandler) ListSummaries(w http.ResponseWriter, r *http.Request) {
	query := &listdeptsummary.ListDepartmentSummaryQuery{}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list department summary query")
		writeError(w, http.StatusInternalServerError, "failed to list department summaries")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetBatches returns all course batches for a department (Calendar tab).
func (h *DepartmentHandler) GetBatches(w http.ResponseWriter, r *http.Request) {
	deptID := chi.URLParam(r, "id")

	query := &getdeptbatches.GetDepartmentBatchesQuery{DepartmentID: deptID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get department batches query")
		writeError(w, http.StatusInternalServerError, "failed to get department batches")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetCourses returns all courses for a department (Course tab).
func (h *DepartmentHandler) GetCourses(w http.ResponseWriter, r *http.Request) {
	deptID := chi.URLParam(r, "id")

	query := &getdeptcourses.GetDepartmentCoursesQuery{DepartmentID: deptID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get department courses query")
		writeError(w, http.StatusInternalServerError, "failed to get department courses")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetStudents returns students in a department (Student tab).
// Query param: ?status=active|alumni (empty = all)
func (h *DepartmentHandler) GetStudents(w http.ResponseWriter, r *http.Request) {
	deptID := chi.URLParam(r, "id")
	status := r.URL.Query().Get("status")

	query := &getdeptstudents.GetDepartmentStudentsQuery{DepartmentID: deptID, Status: status}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get department students query")
		writeError(w, http.StatusInternalServerError, "failed to get department students")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetTalentPool returns talent pool entries for students in a department.
func (h *DepartmentHandler) GetTalentPool(w http.ResponseWriter, r *http.Request) {
	deptID := chi.URLParam(r, "id")

	query := &getdepttalentpool.GetDepartmentTalentPoolQuery{DepartmentID: deptID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get department talentpool query")
		writeError(w, http.StatusInternalServerError, "failed to get department talentpool")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func RegisterDepartmentRoutes(h *DepartmentHandler, r chi.Router) {
	// Specific routes BEFORE parameterized /{id}
	r.Get("/api/v1/departments/summaries", h.ListSummaries)
	r.Post("/api/v1/departments", h.Create)
	r.Get("/api/v1/departments", h.List)
	r.Get("/api/v1/departments/{id}", h.GetByID)
	r.Put("/api/v1/departments/{id}", h.Update)
	r.Delete("/api/v1/departments/{id}", h.Delete)
	// Dashboard sub-routes
	r.Get("/api/v1/departments/{id}/batches", h.GetBatches)
	r.Get("/api/v1/departments/{id}/courses", h.GetCourses)
	r.Get("/api/v1/departments/{id}/students", h.GetStudents)
	r.Get("/api/v1/departments/{id}/talentpool", h.GetTalentPool)
}
