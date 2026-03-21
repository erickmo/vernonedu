package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_delegation"
	listdelegations "github.com/vernonedu/entrepreneurship-api/internal/query/list_delegations"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type DelegationHTTPHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewDelegationHTTPHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *DelegationHTTPHandler {
	return &DelegationHTTPHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterDelegationRoutes(h *DelegationHTTPHandler, r chi.Router) {
	r.Get("/api/v1/delegations", h.List)
	r.Post("/api/v1/delegations", h.Create)
}

func (h *DelegationHTTPHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	status := r.URL.Query().Get("status")
	delegationType := r.URL.Query().Get("type")

	result, err := h.qryBus.Execute(r.Context(), &listdelegations.ListDelegationsQuery{
		Offset: offset, Limit: limit, Status: status, DelegationType: delegationType,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list delegations")
		writeError(w, http.StatusInternalServerError, "failed to list delegations")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *DelegationHTTPHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Title            string `json:"title"`
		Type             string `json:"type"`
		Description      string `json:"description"`
		AssignedToID     string `json:"assigned_to_id"`
		AssignedToName   string `json:"assigned_to_name"`
		AssignedByID     string `json:"assigned_by_id"`
		AssignedByName   string `json:"assigned_by_name"`
		Priority         string `json:"priority"`
		Deadline         string `json:"deadline"`
		LinkedEntityID   string `json:"linked_entity_id"`
		LinkedEntityType string `json:"linked_entity_type"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &create_delegation.CreateDelegationCommand{
		Title:            body.Title,
		Type:             body.Type,
		Description:      body.Description,
		AssignedToID:     body.AssignedToID,
		AssignedToName:   body.AssignedToName,
		AssignedByID:     body.AssignedByID,
		AssignedByName:   body.AssignedByName,
		Priority:         body.Priority,
		Deadline:         body.Deadline,
		LinkedEntityID:   body.LinkedEntityID,
		LinkedEntityType: body.LinkedEntityType,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create delegation")
		writeError(w, http.StatusInternalServerError, "failed to create delegation")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "delegation created"})
}
