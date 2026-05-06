package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	changevacancystatus "github.com/vernonedu/entrepreneurship-api/internal/command/change_vacancy_status"
	createjobvacancy "github.com/vernonedu/entrepreneurship-api/internal/command/create_job_vacancy"
	deletejobvacancy "github.com/vernonedu/entrepreneurship-api/internal/command/delete_job_vacancy"
	updatejobvacancy "github.com/vernonedu/entrepreneurship-api/internal/command/update_job_vacancy"
	getjobvacancy "github.com/vernonedu/entrepreneurship-api/internal/query/get_job_vacancy"
	listjobvacancies "github.com/vernonedu/entrepreneurship-api/internal/query/list_job_vacancies"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/filterutil"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
	"github.com/vernonedu/entrepreneurship-api/pkg/sortutil"
)

type JobVacancyHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewJobVacancyHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *JobVacancyHandler {
	return &JobVacancyHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateJobVacancyRequest struct {
	Title           string   `json:"title"`
	Description     string   `json:"description"`
	PartnerID       string   `json:"partner_id"`
	DepartmentID    *string  `json:"department_id"`
	Location        string   `json:"location"`
	Type            string   `json:"type"`
	ExperienceLevel string   `json:"experience_level"`
	Slots           int      `json:"slots"`
	MinSalary       *int64   `json:"min_salary"`
	MaxSalary       *int64   `json:"max_salary"`
	RequiredSkills  []string `json:"required_skills"`
	Deadline        *string  `json:"deadline"` // "YYYY-MM-DD"
	CreatedBy       string   `json:"created_by"`
}

type UpdateJobVacancyRequest struct {
	Title           string   `json:"title"`
	Description     string   `json:"description"`
	PartnerID       string   `json:"partner_id"`
	DepartmentID    *string  `json:"department_id"`
	Location        string   `json:"location"`
	Type            string   `json:"type"`
	ExperienceLevel string   `json:"experience_level"`
	Slots           int      `json:"slots"`
	MinSalary       *int64   `json:"min_salary"`
	MaxSalary       *int64   `json:"max_salary"`
	RequiredSkills  []string `json:"required_skills"`
	Deadline        *string  `json:"deadline"` // "YYYY-MM-DD"
}

type ChangeVacancyStatusRequest struct {
	Status string `json:"status"`
}

// Create godoc
// @Summary      Create job vacancy
// @Description  Create a new job vacancy
// @Tags         talentpool-vacancies
// @Accept       json
// @Produce      json
// @Param        body  body  CreateJobVacancyRequest  true  "Job vacancy data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /talentpool/vacancies [post]
func (h *JobVacancyHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateJobVacancyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	partnerID, err := uuid.Parse(req.PartnerID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid partner_id")
		return
	}

	createdBy, err := uuid.Parse(req.CreatedBy)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid created_by")
		return
	}

	var departmentID *uuid.UUID
	if req.DepartmentID != nil && *req.DepartmentID != "" {
		parsed, err := uuid.Parse(*req.DepartmentID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid department_id")
			return
		}
		departmentID = &parsed
	}

	var deadline *time.Time
	if req.Deadline != nil && *req.Deadline != "" {
		parsed, err := time.Parse("2006-01-02", *req.Deadline)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid deadline format, use YYYY-MM-DD")
			return
		}
		deadline = &parsed
	}

	cmd := &createjobvacancy.CreateJobVacancyCommand{
		Title:           req.Title,
		Description:     req.Description,
		PartnerID:       partnerID,
		DepartmentID:    departmentID,
		Location:        req.Location,
		Type:            req.Type,
		ExperienceLevel: req.ExperienceLevel,
		Slots:           req.Slots,
		MinSalary:       req.MinSalary,
		MaxSalary:       req.MaxSalary,
		RequiredSkills:  req.RequiredSkills,
		Deadline:        deadline,
		CreatedBy:       createdBy,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create job vacancy command")
		writeError(w, http.StatusInternalServerError, "failed to create job vacancy")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "job vacancy created successfully"})
}

// GetByID godoc
// @Summary      Get job vacancy by ID
// @Description  Get a single job vacancy by its ID
// @Tags         talentpool-vacancies
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Job Vacancy ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /talentpool/vacancies/{id} [get]
func (h *JobVacancyHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid job vacancy id")
		return
	}

	query := &getjobvacancy.GetJobVacancyQuery{ID: id}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get job vacancy query")
		writeError(w, http.StatusInternalServerError, "failed to get job vacancy")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// List godoc
// @Summary      List job vacancies
// @Description  Get paginated list of job vacancies with optional filters
// @Tags         talentpool-vacancies
// @Accept       json
// @Produce      json
// @Param        offset     query  int     false  "Pagination offset"
// @Param        limit      query  int     false  "Pagination limit (default 20)"
// @Param        filters    query  string  false  "Filters JSON"
// @Param        sort       query  string  false  "Sort JSON"
// @Param        search     query  string  false  "Search keyword"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /talentpool/vacancies [get]
func (h *JobVacancyHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	search := r.URL.Query().Get("search")

	filters := filterutil.Parse(r.URL.Query().Get("filters"))
	status := filterutil.Get(filters, "status")
	partnerID := filterutil.Get(filters, "partner_id")
	vacancyType := filterutil.Get(filters, "type")

	sort := sortutil.Parse(r.URL.Query().Get("sort"))
	var sortBy, sortDir string
	if sort != nil {
		sortBy = sort.Column
		sortDir = sort.Dir
	}

	query := &listjobvacancies.ListJobVacanciesQuery{
		Offset:    offset,
		Limit:     limit,
		Status:    status,
		PartnerID: partnerID,
		Type:      vacancyType,
		Search:    search,
		SortBy:    sortBy,
		SortDir:   sortDir,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list job vacancies query")
		writeError(w, http.StatusInternalServerError, "failed to list job vacancies")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// Update godoc
// @Summary      Update job vacancy
// @Description  Update an existing job vacancy
// @Tags         talentpool-vacancies
// @Accept       json
// @Produce      json
// @Param        id    path  string                  true  "Job Vacancy ID"
// @Param        body  body  UpdateJobVacancyRequest true  "Updated job vacancy data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /talentpool/vacancies/{id} [put]
func (h *JobVacancyHandler) Update(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid job vacancy id")
		return
	}

	var req UpdateJobVacancyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	partnerID, err := uuid.Parse(req.PartnerID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid partner_id")
		return
	}

	var departmentID *uuid.UUID
	if req.DepartmentID != nil && *req.DepartmentID != "" {
		parsed, err := uuid.Parse(*req.DepartmentID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid department_id")
			return
		}
		departmentID = &parsed
	}

	var deadline *time.Time
	if req.Deadline != nil && *req.Deadline != "" {
		parsed, err := time.Parse("2006-01-02", *req.Deadline)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid deadline format, use YYYY-MM-DD")
			return
		}
		deadline = &parsed
	}

	cmd := &updatejobvacancy.UpdateJobVacancyCommand{
		ID:              id,
		Title:           req.Title,
		Description:     req.Description,
		PartnerID:       partnerID,
		DepartmentID:    departmentID,
		Location:        req.Location,
		Type:            req.Type,
		ExperienceLevel: req.ExperienceLevel,
		Slots:           req.Slots,
		MinSalary:       req.MinSalary,
		MaxSalary:       req.MaxSalary,
		RequiredSkills:  req.RequiredSkills,
		Deadline:        deadline,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update job vacancy command")
		writeError(w, http.StatusInternalServerError, "failed to update job vacancy")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "job vacancy updated successfully"})
}

// ChangeStatus godoc
// @Summary      Change job vacancy status
// @Description  Transition job vacancy status (draft→open, open→closed)
// @Tags         talentpool-vacancies
// @Accept       json
// @Produce      json
// @Param        id    path  string                      true  "Job Vacancy ID"
// @Param        body  body  ChangeVacancyStatusRequest  true  "New status"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /talentpool/vacancies/{id}/status [patch]
func (h *JobVacancyHandler) ChangeStatus(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid job vacancy id")
		return
	}

	var req ChangeVacancyStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &changevacancystatus.ChangeVacancyStatusCommand{
		ID:        id,
		NewStatus: req.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute change vacancy status command")
		writeError(w, http.StatusInternalServerError, "failed to change job vacancy status")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "job vacancy status updated successfully"})
}

// Delete godoc
// @Summary      Delete job vacancy
// @Description  Soft-delete a job vacancy
// @Tags         talentpool-vacancies
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Job Vacancy ID"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /talentpool/vacancies/{id} [delete]
func (h *JobVacancyHandler) Delete(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid job vacancy id")
		return
	}

	cmd := &deletejobvacancy.DeleteJobVacancyCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete job vacancy command")
		writeError(w, http.StatusInternalServerError, "failed to delete job vacancy")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "job vacancy deleted successfully"})
}

func RegisterJobVacancyRoutes(h *JobVacancyHandler, r chi.Router) {
	r.Get("/api/v1/talentpool/vacancies", h.List)
	r.Get("/api/v1/talentpool/vacancies/{id}", h.GetByID)
	r.Post("/api/v1/talentpool/vacancies", h.Create)
	r.Put("/api/v1/talentpool/vacancies/{id}", h.Update)
	r.Patch("/api/v1/talentpool/vacancies/{id}/status", h.ChangeStatus)
	r.Delete("/api/v1/talentpool/vacancies/{id}", h.Delete)
}
