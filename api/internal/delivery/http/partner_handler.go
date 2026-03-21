package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	createmoucmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_mou"
	createpartnercmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_partner"
	createpartnergroupcmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_partner_group"
	deletemoucmd "github.com/vernonedu/entrepreneurship-api/internal/command/delete_mou"
	deletepartnercmd "github.com/vernonedu/entrepreneurship-api/internal/command/delete_partner"
	updatemoucmd "github.com/vernonedu/entrepreneurship-api/internal/command/update_mou"
	updatepartnercmd "github.com/vernonedu/entrepreneurship-api/internal/command/update_partner"
	updatepartnergroupcmd "github.com/vernonedu/entrepreneurship-api/internal/command/update_partner_group"
	getpartnerqry "github.com/vernonedu/entrepreneurship-api/internal/query/get_partner"
	listexpiringmousqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_expiring_mous"
	listmousqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_mous"
	listpartnergroupsqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_partner_groups"
	listpartnersqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_partners"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type PartnerHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewPartnerHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *PartnerHandler {
	return &PartnerHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterPartnerRoutes(h *PartnerHandler, r chi.Router) {
	// Partner CRUD
	r.Get("/api/v1/partners", h.List)
	r.Post("/api/v1/partners", h.Create)
	r.Get("/api/v1/partners/{id}", h.GetByID)
	r.Put("/api/v1/partners/{id}", h.Update)
	r.Delete("/api/v1/partners/{id}", h.Delete)

	// MOUs under a partner
	r.Post("/api/v1/partners/{id}/mou", h.AddMOU)
	r.Get("/api/v1/partners/{id}/mous", h.ListMOUs)

	// MOU top-level operations
	r.Put("/api/v1/mous/{id}", h.UpdateMOU)
	r.Delete("/api/v1/mous/{id}", h.DeleteMOU)
	r.Get("/api/v1/mous/expiring", h.ListExpiringMOUs)

	// Partner groups
	r.Get("/api/v1/partner-groups", h.ListGroups)
	r.Post("/api/v1/partner-groups", h.CreateGroup)
	r.Put("/api/v1/partner-groups/{id}", h.UpdateGroup)
}

// ────────────────────────────────────────────────────────────────
// Partner handlers
// ────────────────────────────────────────────────────────────────

func (h *PartnerHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	status := r.URL.Query().Get("status")

	result, err := h.qryBus.Execute(r.Context(), &listpartnersqry.ListPartnersQuery{
		Offset: offset, Limit: limit, Status: status,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list partners")
		writeError(w, http.StatusInternalServerError, "failed to list partners")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *PartnerHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	result, err := h.qryBus.Execute(r.Context(), &getpartnerqry.GetPartnerQuery{ID: id})
	if err != nil {
		log.Error().Err(err).Msg("failed to get partner")
		writeError(w, http.StatusNotFound, "partner not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *PartnerHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name          string `json:"name"`
		Industry      string `json:"industry"`
		Status        string `json:"status"`
		ContactEmail  string `json:"contact_email"`
		ContactPhone  string `json:"contact_phone"`
		ContactPerson string `json:"contact_person"`
		Website       string `json:"website"`
		Address       string `json:"address"`
		Notes         string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &createpartnercmd.CreatePartnerCommand{
		Name:          body.Name,
		Industry:      body.Industry,
		Status:        body.Status,
		ContactEmail:  body.ContactEmail,
		ContactPhone:  body.ContactPhone,
		ContactPerson: body.ContactPerson,
		Website:       body.Website,
		Address:       body.Address,
		Notes:         body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create partner")
		writeError(w, http.StatusInternalServerError, "failed to create partner")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "partner created"})
}

func (h *PartnerHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Name          string `json:"name"`
		Industry      string `json:"industry"`
		Status        string `json:"status"`
		ContactEmail  string `json:"contact_email"`
		ContactPhone  string `json:"contact_phone"`
		ContactPerson string `json:"contact_person"`
		Website       string `json:"website"`
		Address       string `json:"address"`
		LogoURL       string `json:"logo_url"`
		Notes         string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updatepartnercmd.UpdatePartnerCommand{
		ID:            id,
		Name:          body.Name,
		Industry:      body.Industry,
		Status:        body.Status,
		ContactEmail:  body.ContactEmail,
		ContactPhone:  body.ContactPhone,
		ContactPerson: body.ContactPerson,
		Website:       body.Website,
		Address:       body.Address,
		LogoURL:       body.LogoURL,
		Notes:         body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update partner")
		writeError(w, http.StatusInternalServerError, "failed to update partner")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "partner updated"})
}

func (h *PartnerHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	cmd := &deletepartnercmd.DeletePartnerCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete partner")
		writeError(w, http.StatusInternalServerError, "failed to delete partner")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "partner deleted"})
}

// ────────────────────────────────────────────────────────────────
// MOU handlers
// ────────────────────────────────────────────────────────────────

func (h *PartnerHandler) AddMOU(w http.ResponseWriter, r *http.Request) {
	partnerID := chi.URLParam(r, "id")
	var body struct {
		DocumentNumber string `json:"document_number"`
		Title          string `json:"title"`
		StartDate      string `json:"start_date"`
		EndDate        string `json:"end_date"`
		Status         string `json:"status"`
		DocumentURL    string `json:"document_url"`
		Notes          string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &createmoucmd.CreateMOUCommand{
		PartnerIDStr:   partnerID,
		DocumentNumber: body.DocumentNumber,
		Title:          body.Title,
		StartDate:      body.StartDate,
		EndDate:        body.EndDate,
		Status:         body.Status,
		DocumentURL:    body.DocumentURL,
		Notes:          body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to add MOU")
		writeError(w, http.StatusInternalServerError, "failed to add MOU")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "mou added"})
}

func (h *PartnerHandler) ListMOUs(w http.ResponseWriter, r *http.Request) {
	partnerID := chi.URLParam(r, "id")
	result, err := h.qryBus.Execute(r.Context(), &listmousqry.ListMOUsQuery{PartnerIDStr: partnerID})
	if err != nil {
		log.Error().Err(err).Msg("failed to list MOUs")
		writeError(w, http.StatusInternalServerError, "failed to list MOUs")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *PartnerHandler) UpdateMOU(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		DocumentNumber string `json:"document_number"`
		Title          string `json:"title"`
		StartDate      string `json:"start_date"`
		EndDate        string `json:"end_date"`
		Status         string `json:"status"`
		DocumentURL    string `json:"document_url"`
		Notes          string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updatemoucmd.UpdateMOUCommand{
		ID:             id,
		DocumentNumber: body.DocumentNumber,
		Title:          body.Title,
		StartDate:      body.StartDate,
		EndDate:        body.EndDate,
		Status:         body.Status,
		DocumentURL:    body.DocumentURL,
		Notes:          body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update MOU")
		writeError(w, http.StatusInternalServerError, "failed to update MOU")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "mou updated"})
}

func (h *PartnerHandler) DeleteMOU(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	cmd := &deletemoucmd.DeleteMOUCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete MOU")
		writeError(w, http.StatusInternalServerError, "failed to delete MOU")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "mou deleted"})
}

func (h *PartnerHandler) ListExpiringMOUs(w http.ResponseWriter, r *http.Request) {
	withinMonths, _ := strconv.Atoi(r.URL.Query().Get("within_months"))
	result, err := h.qryBus.Execute(r.Context(), &listexpiringmousqry.ListExpiringMOUsQuery{WithinMonths: withinMonths})
	if err != nil {
		log.Error().Err(err).Msg("failed to list expiring MOUs")
		writeError(w, http.StatusInternalServerError, "failed to list expiring MOUs")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ────────────────────────────────────────────────────────────────
// Partner group handlers
// ────────────────────────────────────────────────────────────────

func (h *PartnerHandler) ListGroups(w http.ResponseWriter, r *http.Request) {
	result, err := h.qryBus.Execute(r.Context(), &listpartnergroupsqry.ListPartnerGroupsQuery{})
	if err != nil {
		log.Error().Err(err).Msg("failed to list partner groups")
		writeError(w, http.StatusInternalServerError, "failed to list partner groups")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *PartnerHandler) CreateGroup(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &createpartnergroupcmd.CreatePartnerGroupCommand{
		Name:        body.Name,
		Description: body.Description,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create partner group")
		writeError(w, http.StatusInternalServerError, "failed to create partner group")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "partner group created"})
}

func (h *PartnerHandler) UpdateGroup(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updatepartnergroupcmd.UpdatePartnerGroupCommand{
		ID:          id,
		Name:        body.Name,
		Description: body.Description,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update partner group")
		writeError(w, http.StatusInternalServerError, "failed to update partner group")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "partner group updated"})
}
