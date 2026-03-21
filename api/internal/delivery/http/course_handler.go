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
