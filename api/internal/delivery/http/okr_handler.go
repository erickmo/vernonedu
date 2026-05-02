package http

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_okr_keyresult"
	"github.com/vernonedu/entrepreneurship-api/internal/command/create_okr_objective"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_okr_keyresult"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_okr_keyresult"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/okr"
	getokrobjective "github.com/vernonedu/entrepreneurship-api/internal/query/get_okr_objective"
	listokr "github.com/vernonedu/entrepreneurship-api/internal/query/list_okr"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type OkrHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewOkrHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *OkrHandler {
	return &OkrHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterOkrRoutes(h *OkrHandler, r chi.Router) {
	r.Get("/api/v1/okr", h.List)
	r.Post("/api/v1/okr", h.Create)
	r.Get("/api/v1/okr/objectives/{id}", h.GetObjective)
	r.Post("/api/v1/okr/objectives/{id}/keyresults", h.CreateKeyResult)
	r.Put("/api/v1/okr/keyresults/{id}", h.UpdateKeyResult)
	r.Delete("/api/v1/okr/keyresults/{id}", h.DeleteKeyResult)
}

func (h *OkrHandler) List(w http.ResponseWriter, r *http.Request) {
	level := r.URL.Query().Get("level")

	result, err := h.qryBus.Execute(r.Context(), &listokr.ListOkrQuery{Level: level})
	if err != nil {
		log.Error().Err(err).Msg("failed to list okr")
		writeError(w, http.StatusInternalServerError, "failed to list okr objectives")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *OkrHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Title     string `json:"title"`
		OwnerID   string `json:"owner_id"`
		OwnerName string `json:"owner_name"`
		Period    string `json:"period"`
		Level     string `json:"level"`
		Status    string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &create_okr_objective.CreateOkrObjectiveCommand{
		Title:     body.Title,
		OwnerID:   body.OwnerID,
		OwnerName: body.OwnerName,
		Period:    body.Period,
		Level:     body.Level,
		Status:    body.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create okr objective")
		writeError(w, http.StatusInternalServerError, "failed to create okr objective")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "okr objective created"})
}

func (h *OkrHandler) GetObjective(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	result, err := h.qryBus.Execute(r.Context(), &getokrobjective.GetOkrObjectiveQuery{ID: id})
	if err != nil {
		if errors.Is(err, okr.ErrObjectiveNotFound) {
			writeError(w, http.StatusNotFound, "okr objective not found")
			return
		}
		log.Error().Err(err).Msg("failed to get okr objective")
		writeError(w, http.StatusInternalServerError, "failed to get okr objective")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *OkrHandler) CreateKeyResult(w http.ResponseWriter, r *http.Request) {
	objectiveID := chi.URLParam(r, "id")
	var body struct {
		Title    string `json:"title"`
		Progress int    `json:"progress"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &create_okr_keyresult.CreateOkrKeyResultCommand{
		ObjectiveID: objectiveID,
		Title:       body.Title,
		Progress:    body.Progress,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create okr key result")
		writeError(w, http.StatusInternalServerError, "failed to create okr key result")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "okr key result created"})
}

func (h *OkrHandler) UpdateKeyResult(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Title    *string `json:"title"`
		Progress *int    `json:"progress"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &update_okr_keyresult.UpdateOkrKeyResultCommand{
		ID:       id,
		Title:    body.Title,
		Progress: body.Progress,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, okr.ErrKeyResultNotFound) {
			writeError(w, http.StatusNotFound, "okr key result not found")
			return
		}
		log.Error().Err(err).Msg("failed to update okr key result")
		writeError(w, http.StatusInternalServerError, "failed to update okr key result")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "okr key result updated"})
}

func (h *OkrHandler) DeleteKeyResult(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	cmd := &delete_okr_keyresult.DeleteOkrKeyResultCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, okr.ErrKeyResultNotFound) {
			writeError(w, http.StatusNotFound, "okr key result not found")
			return
		}
		log.Error().Err(err).Msg("failed to delete okr key result")
		writeError(w, http.StatusInternalServerError, "failed to delete okr key result")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "okr key result deleted"})
}
