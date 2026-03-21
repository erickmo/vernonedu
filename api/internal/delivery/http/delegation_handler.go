package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	acceptdelegation "github.com/vernonedu/entrepreneurship-api/internal/command/accept_delegation"
	canceldelegation "github.com/vernonedu/entrepreneurship-api/internal/command/cancel_delegation"
	completedelegation "github.com/vernonedu/entrepreneurship-api/internal/command/complete_delegation"
	createdelegation "github.com/vernonedu/entrepreneurship-api/internal/command/create_delegation"
	updatedelegation "github.com/vernonedu/entrepreneurship-api/internal/command/update_delegation"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/delegation"
	getdelegation "github.com/vernonedu/entrepreneurship-api/internal/query/get_delegation"
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
	r.Get("/api/v1/delegations/{id}", h.GetByID)
	r.Put("/api/v1/delegations/{id}", h.Update)
	r.Post("/api/v1/delegations/{id}/accept", h.Accept)
	r.Post("/api/v1/delegations/{id}/complete", h.Complete)
	r.Post("/api/v1/delegations/{id}/cancel", h.Cancel)
}

// List handles GET /api/v1/delegations
func (h *DelegationHTTPHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	result, err := h.qryBus.Execute(r.Context(), &listdelegations.ListDelegationsQuery{
		Offset:         offset,
		Limit:          limit,
		Status:         r.URL.Query().Get("status"),
		DelegationType: r.URL.Query().Get("type"),
		AssignedToID:   r.URL.Query().Get("assigned_to_id"),
		RequestedByID:  r.URL.Query().Get("requested_by_id"),
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list delegations")
		writeError(w, http.StatusInternalServerError, "failed to list delegations")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// GetByID handles GET /api/v1/delegations/{id}
func (h *DelegationHTTPHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid delegation id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getdelegation.GetDelegationQuery{ID: id})
	if err != nil {
		if err == delegation.ErrDelegationNotFound {
			writeError(w, http.StatusNotFound, "delegation not found")
			return
		}
		log.Error().Err(err).Msg("failed to get delegation")
		writeError(w, http.StatusInternalServerError, "failed to get delegation")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Create handles POST /api/v1/delegations
func (h *DelegationHTTPHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Title            string `json:"title"`
		Type             string `json:"type"`
		Description      string `json:"description"`
		RequestedByID    string `json:"requestedById"`
		RequestedByName  string `json:"requestedByName"`
		AssignedToID     string `json:"assignedToId"`
		AssignedToName   string `json:"assignedToName"`
		AssignedToRole   string `json:"assignedToRole"`
		DueDate          string `json:"dueDate"`
		Priority         string `json:"priority"`
		LinkedEntityType string `json:"linkedEntityType"`
		LinkedEntityID   string `json:"linkedEntityId"`
		Notes            string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createdelegation.CreateDelegationCommand{
		Title:            body.Title,
		Type:             body.Type,
		Description:      body.Description,
		RequestedByID:    body.RequestedByID,
		RequestedByName:  body.RequestedByName,
		AssignedToID:     body.AssignedToID,
		AssignedToName:   body.AssignedToName,
		AssignedToRole:   body.AssignedToRole,
		DueDate:          body.DueDate,
		Priority:         body.Priority,
		LinkedEntityType: body.LinkedEntityType,
		LinkedEntityID:   body.LinkedEntityID,
		Notes:            body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create delegation")
		writeError(w, http.StatusInternalServerError, "failed to create delegation")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "delegation created"})
}

// Update handles PUT /api/v1/delegations/{id}
func (h *DelegationHTTPHandler) Update(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid delegation id")
		return
	}

	var body struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		DueDate     string `json:"dueDate"`
		Priority    string `json:"priority"`
		Notes       string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatedelegation.UpdateDelegationCommand{
		DelegationID: id,
		Title:        body.Title,
		Description:  body.Description,
		DueDate:      body.DueDate,
		Priority:     body.Priority,
		Notes:        body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if err == delegation.ErrDelegationNotFound {
			writeError(w, http.StatusNotFound, "delegation not found")
			return
		}
		log.Error().Err(err).Msg("failed to update delegation")
		writeError(w, http.StatusInternalServerError, "failed to update delegation")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "delegation updated"})
}

// Accept handles POST /api/v1/delegations/{id}/accept
func (h *DelegationHTTPHandler) Accept(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid delegation id")
		return
	}

	cmd := &acceptdelegation.AcceptDelegationCommand{DelegationID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if err == delegation.ErrDelegationNotFound {
			writeError(w, http.StatusNotFound, "delegation not found")
			return
		}
		if err == delegation.ErrInvalidStatusTransition {
			writeError(w, http.StatusConflict, "invalid status transition")
			return
		}
		log.Error().Err(err).Msg("failed to accept delegation")
		writeError(w, http.StatusInternalServerError, "failed to accept delegation")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "delegation accepted"})
}

// Complete handles POST /api/v1/delegations/{id}/complete
func (h *DelegationHTTPHandler) Complete(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid delegation id")
		return
	}

	var body struct {
		Notes string `json:"notes"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	cmd := &completedelegation.CompleteDelegationCommand{
		DelegationID: id,
		Notes:        body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if err == delegation.ErrDelegationNotFound {
			writeError(w, http.StatusNotFound, "delegation not found")
			return
		}
		if err == delegation.ErrInvalidStatusTransition {
			writeError(w, http.StatusConflict, "invalid status transition")
			return
		}
		log.Error().Err(err).Msg("failed to complete delegation")
		writeError(w, http.StatusInternalServerError, "failed to complete delegation")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "delegation completed"})
}

// Cancel handles POST /api/v1/delegations/{id}/cancel
func (h *DelegationHTTPHandler) Cancel(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid delegation id")
		return
	}

	var body struct {
		Notes string `json:"notes"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	cmd := &canceldelegation.CancelDelegationCommand{
		DelegationID: id,
		Notes:        body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if err == delegation.ErrDelegationNotFound {
			writeError(w, http.StatusNotFound, "delegation not found")
			return
		}
		if err == delegation.ErrInvalidStatusTransition {
			writeError(w, http.StatusConflict, "invalid status transition")
			return
		}
		log.Error().Err(err).Msg("failed to cancel delegation")
		writeError(w, http.StatusInternalServerError, "failed to cancel delegation")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "delegation cancelled"})
}
