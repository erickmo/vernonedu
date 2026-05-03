package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_course"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_course"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_course"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_course"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_course"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type CourseHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewCourseHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *CourseHandler {
	return &CourseHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateCourseRequest struct {
	Name        string `json:"name" validate:"required,min=1"`
	Description string `json:"description"`
	IsActive    bool   `json:"is_active"`
}

type UpdateCourseRequest struct {
	Name        string `json:"name" validate:"required,min=1"`
	Description string `json:"description"`
	IsActive    bool   `json:"is_active"`
}

// Create godoc
// @Summary      Create a new course
// @Description  Create a course with name, description, and active status
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        body  body  CreateCourseRequest  true  "Course creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /courses [post]
func (h *CourseHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateCourseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_course.CreateCourseCommand{
		Name:        req.Name,
		Description: req.Description,
		IsActive:    req.IsActive,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create course command")
		writeError(w, http.StatusInternalServerError, "failed to create course")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "course created successfully"})
}

// GetByID godoc
// @Summary      Get course by ID
// @Description  Retrieve a single course by its UUID
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Course ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /courses/{id} [get]
func (h *CourseHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	courseIDStr := chi.URLParam(r, "id")
	courseID, err := uuid.Parse(courseIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course id")
		return
	}

	query := &get_course.GetCourseQuery{CourseID: courseID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get course query")
		writeError(w, http.StatusInternalServerError, "failed to get course")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// List godoc
// @Summary      List courses
// @Description  Retrieve a paginated list of courses
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        offset  query  int  false  "Pagination offset"
// @Param        limit   query  int  false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /courses [get]
func (h *CourseHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_course.ListCourseQuery{Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list course query")
		writeError(w, http.StatusInternalServerError, "failed to list courses")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// Update godoc
// @Summary      Update course
// @Description  Update a course's name, description, and active status
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        id    path  string                true  "Course ID (UUID)"
// @Param        body  body  UpdateCourseRequest  true  "Course update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /courses/{id} [put]
func (h *CourseHandler) Update(w http.ResponseWriter, r *http.Request) {
	courseIDStr := chi.URLParam(r, "id")
	courseID, err := uuid.Parse(courseIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course id")
		return
	}

	var req UpdateCourseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_course.UpdateCourseCommand{
		CourseID:    courseID,
		Name:        req.Name,
		Description: req.Description,
		IsActive:    req.IsActive,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update course command")
		writeError(w, http.StatusInternalServerError, "failed to update course")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course updated successfully"})
}

// Delete godoc
// @Summary      Delete course
// @Description  Delete a course by its ID
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Course ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /courses/{id} [delete]
func (h *CourseHandler) Delete(w http.ResponseWriter, r *http.Request) {
	courseIDStr := chi.URLParam(r, "id")
	courseID, err := uuid.Parse(courseIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course id")
		return
	}

	cmd := &delete_course.DeleteCourseCommand{CourseID: courseID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete course command")
		writeError(w, http.StatusInternalServerError, "failed to delete course")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course deleted successfully"})
}

func RegisterCourseRoutes(h *CourseHandler, r chi.Router) {
	r.Post("/api/v1/courses", h.Create)
	r.Get("/api/v1/courses", h.List)
	r.Get("/api/v1/courses/{id}", h.GetByID)
	r.Put("/api/v1/courses/{id}", h.Update)
	r.Delete("/api/v1/courses/{id}", h.Delete)
}
