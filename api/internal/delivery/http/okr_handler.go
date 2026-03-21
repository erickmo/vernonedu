package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_okr_objective"
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
