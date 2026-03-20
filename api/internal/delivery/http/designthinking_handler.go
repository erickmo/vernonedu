package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/query/search_designthinking"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type DesignThinkingHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewDesignThinkingHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *DesignThinkingHandler {
	return &DesignThinkingHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateDesignThinkingRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

func (h *DesignThinkingHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateDesignThinkingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_designthinking.CreateDesignThinkingCommand{Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create design thinking command")
		writeError(w, http.StatusInternalServerError, "failed to create design thinking")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "design thinking created successfully"})
}

func (h *DesignThinkingHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	dtIDStr := chi.URLParam(r, "id")
	dtID, err := uuid.Parse(dtIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid design thinking id")
		return
	}

	query := &get_designthinking.GetDesignThinkingQuery{DesignThinkingID: dtID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get design thinking query")
		writeError(w, http.StatusInternalServerError, "failed to get design thinking")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *DesignThinkingHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_designthinking.ListDesignThinkingQuery{Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list design thinking query")
		writeError(w, http.StatusInternalServerError, "failed to list design thinkings")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *DesignThinkingHandler) Search(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &search_designthinking.SearchDesignThinkingQuery{Name: name, Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute search design thinking query")
		writeError(w, http.StatusInternalServerError, "failed to search design thinkings")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type UpdateDesignThinkingRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

func (h *DesignThinkingHandler) Update(w http.ResponseWriter, r *http.Request) {
	dtIDStr := chi.URLParam(r, "id")
	dtID, err := uuid.Parse(dtIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid design thinking id")
		return
	}

	var req UpdateDesignThinkingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_designthinking.UpdateDesignThinkingCommand{DesignThinkingID: dtID, Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update design thinking command")
		writeError(w, http.StatusInternalServerError, "failed to update design thinking")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "design thinking updated successfully"})
}

func (h *DesignThinkingHandler) Delete(w http.ResponseWriter, r *http.Request) {
	dtIDStr := chi.URLParam(r, "id")
	dtID, err := uuid.Parse(dtIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid design thinking id")
		return
	}

	cmd := &delete_designthinking.DeleteDesignThinkingCommand{DesignThinkingID: dtID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete design thinking command")
		writeError(w, http.StatusInternalServerError, "failed to delete design thinking")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "design thinking deleted successfully"})
}

func RegisterDesignThinkingRoutes(h *DesignThinkingHandler, r chi.Router) {
	r.Post("/api/v1/design-thinkings", h.Create)
	r.Get("/api/v1/design-thinkings", h.List)
	r.Get("/api/v1/design-thinkings/search", h.Search)
	r.Get("/api/v1/design-thinkings/{id}", h.GetByID)
	r.Put("/api/v1/design-thinkings/{id}", h.Update)
	r.Delete("/api/v1/design-thinkings/{id}", h.Delete)
}
