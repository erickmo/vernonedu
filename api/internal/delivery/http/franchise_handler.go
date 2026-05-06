package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createagreementcmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_agreement"
	createfranchiseecmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_franchisee"
	createotherrevenuecmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_other_revenue"
	createroyaltypaymentcmd "github.com/vernonedu/entrepreneurship-api/internal/command/create_royalty_payment"
	deleteotherrevenuecmd "github.com/vernonedu/entrepreneurship-api/internal/command/delete_other_revenue"
	markroyaltypaidcmd "github.com/vernonedu/entrepreneurship-api/internal/command/mark_royalty_paid"
	updateagreementcmd "github.com/vernonedu/entrepreneurship-api/internal/command/update_agreement"
	updatefranchiseecmd "github.com/vernonedu/entrepreneurship-api/internal/command/update_franchisee"
	updateotherrevenuecmd "github.com/vernonedu/entrepreneurship-api/internal/command/update_other_revenue"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
	getagreementqry "github.com/vernonedu/entrepreneurship-api/internal/query/get_agreement"
	getfranchiseeqry "github.com/vernonedu/entrepreneurship-api/internal/query/get_franchisee"
	listfranchiseesqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_franchisees"
	listotherrevenueqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_other_revenue"
	listroyaltypaymentsqry "github.com/vernonedu/entrepreneurship-api/internal/query/list_royalty_payments"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// FranchiseHandler handles HTTP requests for the franchise domain.
type FranchiseHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewFranchiseHandler creates a new FranchiseHandler.
func NewFranchiseHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *FranchiseHandler {
	return &FranchiseHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// RegisterFranchiseRoutes wires all franchise-domain routes onto the given router.
func RegisterFranchiseRoutes(h *FranchiseHandler, r chi.Router) {
	// Franchisee CRUD
	r.Get("/api/v1/franchisees", h.List)
	r.Post("/api/v1/franchisees", h.Create)
	r.Get("/api/v1/franchisees/{id}", h.GetByID)
	r.Put("/api/v1/franchisees/{id}", h.Update)

	// Agreement sub-resource
	r.Get("/api/v1/franchisees/{id}/agreement", h.GetAgreement)
	r.Post("/api/v1/franchisees/{id}/agreement", h.CreateAgreement)
	r.Put("/api/v1/franchisees/{id}/agreement/{agrId}", h.UpdateAgreement)

	// Royalty payments sub-resource
	r.Get("/api/v1/franchisees/{id}/royalty-payments", h.ListRoyaltyPayments)
	r.Post("/api/v1/franchisees/{id}/royalty-payments", h.CreateRoyaltyPayment)
	r.Put("/api/v1/franchisees/{id}/royalty-payments/{rpId}/mark-paid", h.MarkRoyaltyPaid)

	// Other revenue sub-resource
	r.Get("/api/v1/franchisees/{id}/other-revenue", h.ListOtherRevenue)
	r.Post("/api/v1/franchisees/{id}/other-revenue", h.CreateOtherRevenue)
	r.Put("/api/v1/franchisees/{id}/other-revenue/{revId}", h.UpdateOtherRevenue)
	r.Delete("/api/v1/franchisees/{id}/other-revenue/{revId}", h.DeleteOtherRevenue)
}

// ────────────────────────────────────────────────────────────────
// Franchisee handlers
// ────────────────────────────────────────────────────────────────

// List godoc
// @Summary      List franchisees
// @Description  Retrieve paginated list of franchisees with optional status and search filters
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        offset  query  int     false  "Pagination offset"
// @Param        limit   query  int     false  "Pagination limit (default 20)"
// @Param        status  query  string  false  "Filter by status"
// @Param        search  query  string  false  "Search by name or branch"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees [get]
func (h *FranchiseHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	status := r.URL.Query().Get("status")
	search := r.URL.Query().Get("search")

	result, err := h.qryBus.Execute(r.Context(), &listfranchiseesqry.ListFranchiseesQuery{
		Offset: offset, Limit: limit, Status: status, Search: search,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list franchisees")
		writeError(w, http.StatusInternalServerError, "failed to list franchisees")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// GetByID godoc
// @Summary      Get franchisee by ID
// @Description  Retrieve a single franchisee by its UUID
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Franchisee ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id} [get]
func (h *FranchiseHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid franchisee id")
		return
	}
	result, err := h.qryBus.Execute(r.Context(), &getfranchiseeqry.GetFranchiseeQuery{ID: id})
	if err != nil {
		if errors.Is(err, franchise.ErrFranchiseeNotFound) {
			writeError(w, http.StatusNotFound, "franchisee not found")
			return
		}
		log.Error().Err(err).Msg("failed to get franchisee")
		writeError(w, http.StatusInternalServerError, "failed to get franchisee")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Create godoc
// @Summary      Create franchisee
// @Description  Register a new franchisee branch
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "Franchisee creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees [post]
func (h *FranchiseHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name       string `json:"name"`
		BranchName string `json:"branch_name"`
		Location   string `json:"location"`
		Contact    string `json:"contact"`
		Status     string `json:"status"`
		CreatedBy  string `json:"created_by"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createfranchiseecmd.CreateFranchiseeCommand{
		Name:       body.Name,
		BranchName: body.BranchName,
		Location:   body.Location,
		Contact:    body.Contact,
		Status:     body.Status,
	}
	if body.CreatedBy != "" {
		if id, err := uuid.Parse(body.CreatedBy); err == nil {
			cmd.CreatedBy = &id
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create franchisee")
		writeError(w, http.StatusInternalServerError, "failed to create franchisee")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "franchisee created"})
}

// Update godoc
// @Summary      Update franchisee
// @Description  Update an existing franchisee by ID
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Franchisee ID (UUID)"
// @Param        body  body  object  true  "Franchisee update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id} [put]
func (h *FranchiseHandler) Update(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid franchisee id")
		return
	}

	var body struct {
		Name       string `json:"name"`
		BranchName string `json:"branch_name"`
		Location   string `json:"location"`
		Contact    string `json:"contact"`
		Status     string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatefranchiseecmd.UpdateFranchiseeCommand{
		ID:         id,
		Name:       body.Name,
		BranchName: body.BranchName,
		Location:   body.Location,
		Contact:    body.Contact,
		Status:     body.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, franchise.ErrFranchiseeNotFound) {
			writeError(w, http.StatusNotFound, "franchisee not found")
			return
		}
		log.Error().Err(err).Msg("failed to update franchisee")
		writeError(w, http.StatusInternalServerError, "failed to update franchisee")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "franchisee updated"})
}

// ────────────────────────────────────────────────────────────────
// Agreement handlers
// ────────────────────────────────────────────────────────────────

// GetAgreement godoc
// @Summary      Get franchise agreement
// @Description  Get the active franchise agreement for a franchisee
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Franchisee ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/agreement [get]
func (h *FranchiseHandler) GetAgreement(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid franchisee id")
		return
	}
	result, err := h.qryBus.Execute(r.Context(), &getagreementqry.GetAgreementQuery{FranchiseeID: id})
	if err != nil {
		if errors.Is(err, franchise.ErrAgreementNotFound) {
			writeError(w, http.StatusNotFound, "agreement not found")
			return
		}
		log.Error().Err(err).Msg("failed to get agreement")
		writeError(w, http.StatusInternalServerError, "failed to get agreement")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// CreateAgreement godoc
// @Summary      Create franchise agreement
// @Description  Create a franchise agreement for a franchisee
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Franchisee ID (UUID)"
// @Param        body  body  object  true  "Agreement creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/agreement [post]
func (h *FranchiseHandler) CreateAgreement(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid franchisee id")
		return
	}

	var body struct {
		BuyInFee          float64 `json:"buy_in_fee"`
		MonthlyRoyalty    float64 `json:"monthly_royalty"`
		RevenueRoyaltyPct float64 `json:"revenue_royalty_pct"`
		StartDate         string  `json:"start_date"`
		EndDate           string  `json:"end_date"`
		Status            string  `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createagreementcmd.CreateAgreementCommand{
		FranchiseeID:      franchiseeID,
		BuyInFee:          body.BuyInFee,
		MonthlyRoyalty:    body.MonthlyRoyalty,
		RevenueRoyaltyPct: body.RevenueRoyaltyPct,
		StartDate:         body.StartDate,
		EndDate:           body.EndDate,
		Status:            body.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create agreement")
		writeError(w, http.StatusInternalServerError, "failed to create agreement")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "agreement created"})
}

// UpdateAgreement godoc
// @Summary      Update franchise agreement
// @Description  Update an existing franchise agreement
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id     path  string  true  "Franchisee ID (UUID)"
// @Param        agrId  path  string  true  "Agreement ID (UUID)"
// @Param        body   body  object  true  "Agreement update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/agreement/{agrId} [put]
func (h *FranchiseHandler) UpdateAgreement(w http.ResponseWriter, r *http.Request) {
	agrID, err := uuid.Parse(chi.URLParam(r, "agrId"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid agreement id")
		return
	}

	var body struct {
		BuyInFee          float64 `json:"buy_in_fee"`
		MonthlyRoyalty    float64 `json:"monthly_royalty"`
		RevenueRoyaltyPct float64 `json:"revenue_royalty_pct"`
		StartDate         string  `json:"start_date"`
		EndDate           string  `json:"end_date"`
		Status            string  `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updateagreementcmd.UpdateAgreementCommand{
		ID:                agrID,
		BuyInFee:          body.BuyInFee,
		MonthlyRoyalty:    body.MonthlyRoyalty,
		RevenueRoyaltyPct: body.RevenueRoyaltyPct,
		StartDate:         body.StartDate,
		EndDate:           body.EndDate,
		Status:            body.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, franchise.ErrAgreementNotFound) {
			writeError(w, http.StatusNotFound, "agreement not found")
			return
		}
		log.Error().Err(err).Msg("failed to update agreement")
		writeError(w, http.StatusInternalServerError, "failed to update agreement")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "agreement updated"})
}

// ────────────────────────────────────────────────────────────────
// Royalty payment handlers
// ────────────────────────────────────────────────────────────────

// ListRoyaltyPayments godoc
// @Summary      List royalty payments
// @Description  List royalty payment records for a franchisee, optionally filtered by period
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id      path   string  true   "Franchisee ID (UUID)"
// @Param        period  query  string  false  "Filter by period (YYYY-MM)"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/royalty-payments [get]
func (h *FranchiseHandler) ListRoyaltyPayments(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid franchisee id")
		return
	}
	period := r.URL.Query().Get("period")

	result, err := h.qryBus.Execute(r.Context(), &listroyaltypaymentsqry.ListRoyaltyPaymentsQuery{
		FranchiseeID: franchiseeID,
		Period:       period,
	})
	if err != nil {
		if errors.Is(err, franchise.ErrFranchiseeNotFound) {
			writeError(w, http.StatusNotFound, "franchisee not found")
			return
		}
		log.Error().Err(err).Msg("failed to list royalty payments")
		writeError(w, http.StatusInternalServerError, "failed to list royalty payments")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// CreateRoyaltyPayment godoc
// @Summary      Create royalty payment
// @Description  Record a royalty payment for a franchisee
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Franchisee ID (UUID)"
// @Param        body  body  object  true  "Royalty payment payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      422  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/royalty-payments [post]
func (h *FranchiseHandler) CreateRoyaltyPayment(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid franchisee id")
		return
	}

	var body struct {
		Period       string  `json:"period"`
		GrossRevenue float64 `json:"gross_revenue"`
		RecordedBy   string  `json:"recorded_by"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createroyaltypaymentcmd.CreateRoyaltyPaymentCommand{
		FranchiseeID: franchiseeID,
		Period:       body.Period,
		GrossRevenue: body.GrossRevenue,
	}
	if body.RecordedBy != "" {
		if id, err := uuid.Parse(body.RecordedBy); err == nil {
			cmd.RecordedBy = &id
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, franchise.ErrAgreementNotFound) {
			writeError(w, http.StatusUnprocessableEntity, "no active agreement found for franchisee")
			return
		}
		log.Error().Err(err).Msg("failed to create royalty payment")
		writeError(w, http.StatusInternalServerError, "failed to create royalty payment")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "royalty payment recorded"})
}

// MarkRoyaltyPaid godoc
// @Summary      Mark royalty payment as paid
// @Description  Mark a royalty payment record as paid
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Franchisee ID (UUID)"
// @Param        rpId  path  string  true  "Royalty payment record ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/royalty-payments/{rpId}/mark-paid [put]
func (h *FranchiseHandler) MarkRoyaltyPaid(w http.ResponseWriter, r *http.Request) {
	rpID, err := uuid.Parse(chi.URLParam(r, "rpId"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid royalty payment id")
		return
	}

	cmd := &markroyaltypaidcmd.MarkRoyaltyPaidCommand{RecordID: rpID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, franchise.ErrRoyaltyRecordNotFound) {
			writeError(w, http.StatusNotFound, "royalty payment record not found")
			return
		}
		log.Error().Err(err).Msg("failed to mark royalty paid")
		writeError(w, http.StatusInternalServerError, "failed to mark royalty paid")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "royalty payment marked as paid"})
}

// ────────────────────────────────────────────────────────────────
// Other revenue handlers
// ────────────────────────────────────────────────────────────────

// ListOtherRevenue godoc
// @Summary      List other revenue
// @Description  List other (non-royalty) revenue entries for a franchisee
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id      path   string  true   "Franchisee ID (UUID)"
// @Param        period  query  string  false  "Filter by period (YYYY-MM)"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/other-revenue [get]
func (h *FranchiseHandler) ListOtherRevenue(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid franchisee id")
		return
	}
	period := r.URL.Query().Get("period")

	result, err := h.qryBus.Execute(r.Context(), &listotherrevenueqry.ListOtherRevenueQuery{
		FranchiseeID: franchiseeID,
		Period:       period,
	})
	if err != nil {
		if errors.Is(err, franchise.ErrFranchiseeNotFound) {
			writeError(w, http.StatusNotFound, "franchisee not found")
			return
		}
		log.Error().Err(err).Msg("failed to list other revenue")
		writeError(w, http.StatusInternalServerError, "failed to list other revenue")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// CreateOtherRevenue godoc
// @Summary      Create other revenue entry
// @Description  Add an other revenue entry for a franchisee
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Franchisee ID (UUID)"
// @Param        body  body  object  true  "Other revenue payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/other-revenue [post]
func (h *FranchiseHandler) CreateOtherRevenue(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid franchisee id")
		return
	}

	var body struct {
		Label       string  `json:"label"`
		Amount      float64 `json:"amount"`
		RevenueDate string  `json:"revenue_date"`
		AddedBy     string  `json:"added_by"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createotherrevenuecmd.CreateOtherRevenueCommand{
		FranchiseeID: franchiseeID,
		Label:        body.Label,
		Amount:       body.Amount,
		RevenueDate:  body.RevenueDate,
	}
	if body.AddedBy != "" {
		if id, err := uuid.Parse(body.AddedBy); err == nil {
			cmd.AddedBy = &id
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create other revenue")
		writeError(w, http.StatusInternalServerError, "failed to create other revenue")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "other revenue added"})
}

// UpdateOtherRevenue godoc
// @Summary      Update other revenue entry
// @Description  Update an existing other revenue entry
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id     path  string  true  "Franchisee ID (UUID)"
// @Param        revId  path  string  true  "Other revenue entry ID (UUID)"
// @Param        body   body  object  true  "Other revenue update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/other-revenue/{revId} [put]
func (h *FranchiseHandler) UpdateOtherRevenue(w http.ResponseWriter, r *http.Request) {
	revID, err := uuid.Parse(chi.URLParam(r, "revId"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid other revenue id")
		return
	}

	var body struct {
		Label       string  `json:"label"`
		Amount      float64 `json:"amount"`
		RevenueDate string  `json:"revenue_date"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updateotherrevenuecmd.UpdateOtherRevenueCommand{
		ID:          revID,
		Label:       body.Label,
		Amount:      body.Amount,
		RevenueDate: body.RevenueDate,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, franchise.ErrOtherRevenueNotFound) {
			writeError(w, http.StatusNotFound, "other revenue entry not found")
			return
		}
		log.Error().Err(err).Msg("failed to update other revenue")
		writeError(w, http.StatusInternalServerError, "failed to update other revenue")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "other revenue updated"})
}

// DeleteOtherRevenue godoc
// @Summary      Delete other revenue entry
// @Description  Delete an other revenue entry
// @Tags         franchisees
// @Accept       json
// @Produce      json
// @Param        id     path  string  true  "Franchisee ID (UUID)"
// @Param        revId  path  string  true  "Other revenue entry ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /franchisees/{id}/other-revenue/{revId} [delete]
func (h *FranchiseHandler) DeleteOtherRevenue(w http.ResponseWriter, r *http.Request) {
	revID, err := uuid.Parse(chi.URLParam(r, "revId"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid other revenue id")
		return
	}

	cmd := &deleteotherrevenuecmd.DeleteOtherRevenueCommand{ID: revID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, franchise.ErrOtherRevenueNotFound) {
			writeError(w, http.StatusNotFound, "other revenue entry not found")
			return
		}
		log.Error().Err(err).Msg("failed to delete other revenue")
		writeError(w, http.StatusInternalServerError, "failed to delete other revenue")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "other revenue deleted"})
}
