package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_investment_plan"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_investment_plan"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/investment"
	getinvestment "github.com/vernonedu/entrepreneurship-api/internal/query/get_investment_plan"
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
	r.Get("/api/v1/investments/{id}", h.Get)
	r.Put("/api/v1/investments/{id}", h.Update)
}

// List godoc
// @Summary      List investment plans
// @Description  Retrieve paginated list of investment plans with optional status filter
// @Tags         investment
// @Accept       json
// @Produce      json
// @Param        offset  query  int     false  "Pagination offset"
// @Param        limit   query  int     false  "Pagination limit (default 20)"
// @Param        status  query  string  false  "Filter by status"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /investments [get]
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

// Create godoc
// @Summary      Create investment plan
// @Description  Create a new investment plan with title, category, amount, expected ROI, etc.
// @Tags         investment
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "Investment plan creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /investments [post]
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

// Get godoc
// @Summary      Get investment plan by ID
// @Description  Retrieve a single investment plan by its ID
// @Tags         investment
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Investment plan ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /investments/{id} [get]
func (h *InvestmentHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	result, err := h.qryBus.Execute(r.Context(), &getinvestment.GetInvestmentPlanQuery{ID: id})
	if err != nil {
		if errors.Is(err, investment.ErrInvestmentNotFound) {
			writeError(w, http.StatusNotFound, "investment plan not found")
			return
		}
		if errors.Is(err, getinvestment.ErrInvalidID) {
			writeError(w, http.StatusBadRequest, "invalid investment plan id")
			return
		}
		log.Error().Err(err).Msg("failed to get investment plan")
		writeError(w, http.StatusInternalServerError, "failed to get investment plan")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// Update godoc
// @Summary      Update investment plan
// @Description  Update an existing investment plan by ID
// @Tags         investment
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Investment plan ID"
// @Param        body  body  object  true  "Investment plan update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /investments/{id} [put]
func (h *InvestmentHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Title       string  `json:"title"`
		Category    string  `json:"category"`
		ProposedBy  string  `json:"proposed_by"`
		Amount      int64   `json:"amount"`
		ExpectedROI float64 `json:"expected_roi"`
		ActualSpend int64   `json:"actual_spend"`
		Status      string  `json:"status"`
		ApprovedBy  string  `json:"approved_by"`
		Notes       string  `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &update_investment_plan.UpdateInvestmentPlanCommand{
		ID:          id,
		Title:       body.Title,
		Category:    body.Category,
		ProposedBy:  body.ProposedBy,
		Amount:      body.Amount,
		ExpectedROI: body.ExpectedROI,
		ActualSpend: body.ActualSpend,
		Status:      body.Status,
		ApprovedBy:  body.ApprovedBy,
		Notes:       body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, investment.ErrInvestmentNotFound) {
			writeError(w, http.StatusNotFound, "investment plan not found")
			return
		}
		if errors.Is(err, update_investment_plan.ErrInvalidID) {
			writeError(w, http.StatusBadRequest, "invalid investment plan id")
			return
		}
		log.Error().Err(err).Msg("failed to update investment plan")
		writeError(w, http.StatusInternalServerError, "failed to update investment plan")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "investment plan updated"})
}
