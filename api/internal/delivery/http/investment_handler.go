package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_investment_plan"
	listinvestments "github.com/vernonedu/entrepreneurship-api/internal/query/list_investment_plans"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type InvestmentHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewInvestmentHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *InvestmentHandler {
	return &InvestmentHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterInvestmentRoutes(h *InvestmentHandler, r chi.Router) {
	r.Get("/api/v1/investments", h.List)
	r.Post("/api/v1/investments", h.Create)
}

func (h *InvestmentHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	status := r.URL.Query().Get("status")

	result, err := h.qryBus.Execute(r.Context(), &listinvestments.ListInvestmentPlansQuery{
		Offset: offset, Limit: limit, Status: status,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list investment plans")
		writeError(w, http.StatusInternalServerError, "failed to list investment plans")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *InvestmentHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Title       string  `json:"title"`
		Category    string  `json:"category"`
		ProposedBy  string  `json:"proposed_by"`
		Amount      int64   `json:"amount"`
		ExpectedROI float64 `json:"expected_roi"`
		Status      string  `json:"status"`
		Notes       string  `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &create_investment_plan.CreateInvestmentPlanCommand{
		Title:       body.Title,
		Category:    body.Category,
		ProposedBy:  body.ProposedBy,
		Amount:      body.Amount,
		ExpectedROI: body.ExpectedROI,
		Status:      body.Status,
		Notes:       body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create investment plan")
		writeError(w, http.StatusInternalServerError, "failed to create investment plan")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "investment plan created"})
}
