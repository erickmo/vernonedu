package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	addcrmlog "github.com/vernonedu/entrepreneurship-api/internal/command/add_crm_log"
	convertlead "github.com/vernonedu/entrepreneurship-api/internal/command/convert_lead_to_student"
	createlead "github.com/vernonedu/entrepreneurship-api/internal/command/create_lead"
	deletelead "github.com/vernonedu/entrepreneurship-api/internal/command/delete_lead"
	updatelead "github.com/vernonedu/entrepreneurship-api/internal/command/update_lead"
	getlead "github.com/vernonedu/entrepreneurship-api/internal/query/get_lead"
	listcrmlogs "github.com/vernonedu/entrepreneurship-api/internal/query/list_crm_logs"
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
	Name     string  `json:"name" validate:"required"`
	Email    string  `json:"email"`
	Phone    string  `json:"phone"`
	Interest string  `json:"interest"`
	Source   string  `json:"source"`
	Notes    string  `json:"notes"`
	PicID    *string `json:"pic_id"`
}

type UpdateLeadRequest struct {
	Name     string  `json:"name" validate:"required"`
	Email    string  `json:"email"`
	Phone    string  `json:"phone"`
	Interest string  `json:"interest"`
	Source   string  `json:"source"`
	Notes    string  `json:"notes"`
	Status   string  `json:"status"`
	PicID    *string `json:"pic_id"`
}

type AddCrmLogRequest struct {
	ContactedByID string  `json:"contacted_by_id" validate:"required"`
	ContactMethod string  `json:"contact_method" validate:"required"`
	Response      string  `json:"response" validate:"required"`
	FollowUpDate  *string `json:"follow_up_date"`
}

func (h *LeadHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateLeadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	var picID *uuid.UUID
	if req.PicID != nil && *req.PicID != "" {
		parsed, err := uuid.Parse(*req.PicID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid pic_id")
			return
		}
		picID = &parsed
	}

	cmd := &createlead.CreateLeadCommand{
		Name:     req.Name,
		Email:    req.Email,
		Phone:    req.Phone,
		Interest: req.Interest,
		Source:   req.Source,
		Notes:    req.Notes,
		PicID:    picID,
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
	source := r.URL.Query().Get("source")
	interest := r.URL.Query().Get("interest")

	query := &listlead.ListLeadQuery{
		Offset:   offset,
		Limit:    limit,
		Status:   status,
		Source:   source,
		Interest: interest,
	}
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

	var picID *uuid.UUID
	if req.PicID != nil && *req.PicID != "" {
		parsed, err := uuid.Parse(*req.PicID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid pic_id")
			return
		}
		picID = &parsed
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
		PicID:    picID,
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

func (h *LeadHandler) AddCrmLog(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	var req AddCrmLogRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	contactedByID, err := uuid.Parse(req.ContactedByID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid contacted_by_id")
		return
	}

	var followUpDate *time.Time
	if req.FollowUpDate != nil && *req.FollowUpDate != "" {
		t, err := time.Parse(time.RFC3339, *req.FollowUpDate)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid follow_up_date format, use RFC3339")
			return
		}
		followUpDate = &t
	}

	cmd := &addcrmlog.AddCrmLogCommand{
		LeadID:        leadID,
		ContactedByID: contactedByID,
		ContactMethod: req.ContactMethod,
		Response:      req.Response,
		FollowUpDate:  followUpDate,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute add crm log command")
		writeError(w, http.StatusInternalServerError, "failed to add crm log")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "crm log added successfully"})
}

func (h *LeadHandler) ListCrmLogs(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	query := &listcrmlogs.ListCrmLogsQuery{LeadID: leadID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list crm logs query")
		writeError(w, http.StatusInternalServerError, "failed to list crm logs")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *LeadHandler) ConvertLead(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	cmd := &convertlead.ConvertLeadToStudentCommand{LeadID: leadID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute convert lead command")
		writeError(w, http.StatusInternalServerError, "failed to convert lead to student")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "lead converted to student successfully"})
}

func RegisterLeadRoutes(h *LeadHandler, r chi.Router) {
	r.Post("/api/v1/leads", h.Create)
	r.Get("/api/v1/leads", h.List)
	r.Get("/api/v1/leads/{id}", h.GetByID)
	r.Put("/api/v1/leads/{id}", h.Update)
	r.Delete("/api/v1/leads/{id}", h.Delete)
	r.Post("/api/v1/leads/{id}/convert", h.ConvertLead)
	r.Get("/api/v1/leads/{id}/crm-logs", h.ListCrmLogs)
	r.Post("/api/v1/leads/{id}/crm-logs", h.AddCrmLog)
}
