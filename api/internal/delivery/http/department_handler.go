package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/assign_department_leader"
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
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
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

type AssignLeaderRequest struct {
	LeaderID string `json:"leader_id" validate:"required"`
}

// Create godoc
// @Summary      Create a new department
// @Description  Create a department with name, description, and active status
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        body  body  CreateDepartmentRequest  true  "Department creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments [post]
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

// GetByID godoc
// @Summary      Get department by ID
// @Description  Retrieve a single department by its UUID
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Department ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id} [get]
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

// List godoc
// @Summary      List departments
// @Description  Retrieve a paginated list of departments
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        offset  query  int  false  "Pagination offset"
// @Param        limit   query  int  false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments [get]
func (h *DepartmentHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	search := r.URL.Query().Get("search")
	sort := r.URL.Query().Get("sort")
	query := &list_department.ListDepartmentQuery{Offset: offset, Limit: limit, Search: search, Sort: sort}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list department query")
		writeError(w, http.StatusInternalServerError, "failed to list departments")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// Update godoc
// @Summary      Update department
// @Description  Update a department's name, description, and active status
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id    path  string                  true  "Department ID (UUID)"
// @Param        body  body  UpdateDepartmentRequest  true  "Department update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id} [put]
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

// AssignLeader godoc
// @Summary      Assign department leader
// @Description  Assign or change the leader (dept_leader role) for a department
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id    path  string                  true  "Department ID (UUID)"
// @Param        body  body  AssignLeaderRequest      true  "Leader assignment payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id}/leader [put]
func (h *DepartmentHandler) AssignLeader(w http.ResponseWriter, r *http.Request) {
	departmentIDStr := chi.URLParam(r, "id")
	departmentID, err := uuid.Parse(departmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid department id")
		return
	}

	var req AssignLeaderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	leaderID, err := uuid.Parse(req.LeaderID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid leader_id")
		return
	}

	cmd := &assign_department_leader.AssignDepartmentLeaderCommand{
		DepartmentID: departmentID,
		LeaderID:     &leaderID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute assign department leader command")
		writeError(w, http.StatusInternalServerError, "failed to assign department leader")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "department leader assigned successfully"})
}

// Delete godoc
// @Summary      Delete department
// @Description  Delete a department by its ID
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Department ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id} [delete]
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

// ListSummaries godoc
// @Summary      List department summaries
// @Description  Returns per-department aggregated stats for the dashboard card view
// @Tags         departments
// @Accept       json
// @Produce      json
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/summaries [get]
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

// GetBatches godoc
// @Summary      Get department batches
// @Description  Returns all course batches for a department (Calendar tab)
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Department ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id}/batches [get]
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

// GetCourses godoc
// @Summary      Get department courses
// @Description  Returns all courses for a department (Course tab)
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Department ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id}/courses [get]
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

// GetStudents godoc
// @Summary      Get department students
// @Description  Returns students in a department (Student tab). Filter by status: active or alumni (empty = all)
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id      path   string  true   "Department ID (UUID)"
// @Param        status  query  string  false  "Filter by status: active or alumni"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id}/students [get]
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

// GetTalentPool godoc
// @Summary      Get department talent pool
// @Description  Returns talent pool entries for students in a department
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Department ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id}/talentpool [get]
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
	eduRoles := pkgmiddleware.RequireRole("director", "education_leader", "dept_leader", "course_owner", "facilitator")
	mgmtRoles := pkgmiddleware.RequireRole("director", "education_leader")

	// Read-only (education + facilitator)
	r.With(eduRoles).Get("/api/v1/departments/summaries", h.ListSummaries)
	r.With(eduRoles).Get("/api/v1/departments", h.List)
	r.With(eduRoles).Get("/api/v1/departments/{id}", h.GetByID)
	r.With(eduRoles).Get("/api/v1/departments/{id}/batches", h.GetBatches)
	r.With(eduRoles).Get("/api/v1/departments/{id}/courses", h.GetCourses)
	r.With(eduRoles).Get("/api/v1/departments/{id}/students", h.GetStudents)
	r.With(eduRoles).Get("/api/v1/departments/{id}/talentpool", h.GetTalentPool)

	// Write (management only)
	r.With(mgmtRoles).Post("/api/v1/departments", h.Create)
	r.With(mgmtRoles).Put("/api/v1/departments/{id}", h.Update)
	r.With(mgmtRoles).Put("/api/v1/departments/{id}/leader", h.AssignLeader)
	r.With(mgmtRoles).Delete("/api/v1/departments/{id}", h.Delete)
}
