package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_canvas"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_canvas"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_canvas"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_canvas"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_canvas"
	"github.com/vernonedu/entrepreneurship-api/internal/query/search_canvas"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type CanvasHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewCanvasHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *CanvasHandler {
	return &CanvasHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateCanvasRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

func (h *CanvasHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateCanvasRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_canvas.CreateCanvasCommand{Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create canvas command")
		writeError(w, http.StatusInternalServerError, "failed to create canvas")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "canvas created successfully"})
}

func (h *CanvasHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	canvasIDStr := chi.URLParam(r, "id")
	canvasID, err := uuid.Parse(canvasIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid canvas id")
		return
	}

	query := &get_canvas.GetCanvasQuery{CanvasID: canvasID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get canvas query")
		writeError(w, http.StatusInternalServerError, "failed to get canvas")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *CanvasHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_canvas.ListCanvasQuery{Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list canvas query")
		writeError(w, http.StatusInternalServerError, "failed to list canvases")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *CanvasHandler) Search(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &search_canvas.SearchCanvasQuery{Name: name, Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute search canvas query")
		writeError(w, http.StatusInternalServerError, "failed to search canvases")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type UpdateCanvasRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

func (h *CanvasHandler) Update(w http.ResponseWriter, r *http.Request) {
	canvasIDStr := chi.URLParam(r, "id")
	canvasID, err := uuid.Parse(canvasIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid canvas id")
		return
	}

	var req UpdateCanvasRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_canvas.UpdateCanvasCommand{CanvasID: canvasID, Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update canvas command")
		writeError(w, http.StatusInternalServerError, "failed to update canvas")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "canvas updated successfully"})
}

func (h *CanvasHandler) Delete(w http.ResponseWriter, r *http.Request) {
	canvasIDStr := chi.URLParam(r, "id")
	canvasID, err := uuid.Parse(canvasIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid canvas id")
		return
	}

	cmd := &delete_canvas.DeleteCanvasCommand{CanvasID: canvasID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete canvas command")
		writeError(w, http.StatusInternalServerError, "failed to delete canvas")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "canvas deleted successfully"})
}

func RegisterCanvasRoutes(h *CanvasHandler, r chi.Router) {
	r.Post("/api/v1/canvases", h.Create)
	r.Get("/api/v1/canvases", h.List)
	r.Get("/api/v1/canvases/search", h.Search)
	r.Get("/api/v1/canvases/{id}", h.GetByID)
	r.Put("/api/v1/canvases/{id}", h.Update)
	r.Delete("/api/v1/canvases/{id}", h.Delete)
}
