package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_mou"
	"github.com/vernonedu/entrepreneurship-api/internal/command/create_partner"
	getpartner "github.com/vernonedu/entrepreneurship-api/internal/query/get_partner"
	listpartners "github.com/vernonedu/entrepreneurship-api/internal/query/list_partners"
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
	r.Get("/api/v1/partners", h.List)
	r.Post("/api/v1/partners", h.Create)
	r.Get("/api/v1/partners/{id}", h.GetByID)
	r.Post("/api/v1/partners/{id}/mou", h.AddMOU)
}

func (h *PartnerHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	status := r.URL.Query().Get("status")

	result, err := h.qryBus.Execute(r.Context(), &listpartners.ListPartnersQuery{
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
	result, err := h.qryBus.Execute(r.Context(), &getpartner.GetPartnerQuery{ID: id})
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
	cmd := &create_partner.CreatePartnerCommand{
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

func (h *PartnerHandler) AddMOU(w http.ResponseWriter, r *http.Request) {
	partnerID := chi.URLParam(r, "id")
	var body struct {
		DocumentNumber string `json:"document_number"`
		StartDate      string `json:"start_date"`
		EndDate        string `json:"end_date"`
		Notes          string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &create_mou.CreateMOUCommand{
		PartnerIDStr:   partnerID,
		DocumentNumber: body.DocumentNumber,
		StartDate:      body.StartDate,
		EndDate:        body.EndDate,
		Notes:          body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to add MOU")
		writeError(w, http.StatusInternalServerError, "failed to add MOU")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "mou added"})
}
