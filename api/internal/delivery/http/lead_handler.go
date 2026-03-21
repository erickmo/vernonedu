package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createlead "github.com/vernonedu/entrepreneurship-api/internal/command/create_lead"
	deletelead "github.com/vernonedu/entrepreneurship-api/internal/command/delete_lead"
	updatelead "github.com/vernonedu/entrepreneurship-api/internal/command/update_lead"
	getlead "github.com/vernonedu/entrepreneurship-api/internal/query/get_lead"
	listlead "github.com/vernonedu/entrepreneurship-api/internal/query/list_lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type LeadHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewLeadHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *LeadHandler {
	return &LeadHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateLeadRequest struct {
	Name     string `json:"name" validate:"required"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Interest string `json:"interest"`
	Source   string `json:"source"`
	Notes    string `json:"notes"`
}

type UpdateLeadRequest struct {
	Name     string `json:"name" validate:"required"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Interest string `json:"interest"`
	Source   string `json:"source"`
	Notes    string `json:"notes"`
	Status   string `json:"status"`
}

func (h *LeadHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateLeadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createlead.CreateLeadCommand{
		Name:     req.Name,
		Email:    req.Email,
		Phone:    req.Phone,
		Interest: req.Interest,
		Source:   req.Source,
		Notes:    req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create lead command")
		writeError(w, http.StatusInternalServerError, "failed to create lead")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "lead created successfully"})
}

func (h *LeadHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	query := &getlead.GetLeadQuery{ID: leadID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get lead query")
		writeError(w, http.StatusInternalServerError, "failed to get lead")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *LeadHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}
	status := r.URL.Query().Get("status")

	query := &listlead.ListLeadQuery{Offset: offset, Limit: limit, Status: status}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list lead query")
		writeError(w, http.StatusInternalServerError, "failed to list leads")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (h *LeadHandler) Update(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	var req UpdateLeadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatelead.UpdateLeadCommand{
		ID:       leadID,
		Name:     req.Name,
		Email:    req.Email,
		Phone:    req.Phone,
		Interest: req.Interest,
		Source:   req.Source,
		Notes:    req.Notes,
		Status:   req.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update lead command")
		writeError(w, http.StatusInternalServerError, "failed to update lead")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "lead updated successfully"})
}

func (h *LeadHandler) Delete(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	cmd := &deletelead.DeleteLeadCommand{ID: leadID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete lead command")
		writeError(w, http.StatusInternalServerError, "failed to delete lead")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "lead deleted successfully"})
}

func RegisterLeadRoutes(h *LeadHandler, r chi.Router) {
	r.Post("/api/v1/leads", h.Create)
	r.Get("/api/v1/leads", h.List)
	r.Get("/api/v1/leads/{id}", h.GetByID)
	r.Put("/api/v1/leads/{id}", h.Update)
	r.Delete("/api/v1/leads/{id}", h.Delete)
}
