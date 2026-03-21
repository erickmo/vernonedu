package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	cancelinvoice "github.com/vernonedu/entrepreneurship-api/internal/command/cancel_invoice"
	createinvoice "github.com/vernonedu/entrepreneurship-api/internal/command/create_invoice"
	markpaid "github.com/vernonedu/entrepreneurship-api/internal/command/mark_invoice_paid"
	sendinvoice "github.com/vernonedu/entrepreneurship-api/internal/command/send_invoice"
	createtransaction "github.com/vernonedu/entrepreneurship-api/internal/command/create_transaction"
	updateinvoicestatus "github.com/vernonedu/entrepreneurship-api/internal/command/update_invoice_status"
	getaccountingstats "github.com/vernonedu/entrepreneurship-api/internal/query/get_accounting_stats"
	getinvoice "github.com/vernonedu/entrepreneurship-api/internal/query/get_invoice"
	getinvoicestats "github.com/vernonedu/entrepreneurship-api/internal/query/get_invoice_stats"
	getbatchprofitability "github.com/vernonedu/entrepreneurship-api/internal/query/get_batch_profitability"
	getbudgetvsactual "github.com/vernonedu/entrepreneurship-api/internal/query/get_budget_vs_actual"
	getcashforecast "github.com/vernonedu/entrepreneurship-api/internal/query/get_cash_forecast"
	getcostanalysis "github.com/vernonedu/entrepreneurship-api/internal/query/get_cost_analysis"
	getfinancialalerts "github.com/vernonedu/entrepreneurship-api/internal/query/get_financial_alerts"
	getfinancialratios "github.com/vernonedu/entrepreneurship-api/internal/query/get_financial_ratios"
	getfinancialsuggestions "github.com/vernonedu/entrepreneurship-api/internal/query/get_financial_suggestions"
	getrevenueanalysis "github.com/vernonedu/entrepreneurship-api/internal/query/get_revenue_analysis"
	listcoa "github.com/vernonedu/entrepreneurship-api/internal/query/list_coa"
	listinvoices "github.com/vernonedu/entrepreneurship-api/internal/query/list_invoices"
	listtransactions "github.com/vernonedu/entrepreneurship-api/internal/query/list_transactions"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type AccountingHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewAccountingHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *AccountingHandler {
	return &AccountingHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateTransactionRequest struct {
	Description       string  `json:"description" validate:"required"`
	TransactionType   string  `json:"transaction_type" validate:"required"`
	Amount            float64 `json:"amount" validate:"required,gt=0"`
	DebitAccountCode  string  `json:"debit_account_code"`
	CreditAccountCode string  `json:"credit_account_code"`
	Category          string  `json:"category"`
	TransactionDate   string  `json:"transaction_date"`
	Status            string  `json:"status"`
}

type UpdateInvoiceStatusRequest struct {
	Status string `json:"status" validate:"required"`
}

type CreateInvoiceRequest struct {
	BatchID       string `json:"batch_id" validate:"required"`
	BatchName     string `json:"batch_name"`
	StudentID     string `json:"student_id"`
	EnrollmentID  string `json:"enrollment_id"`
	StudentName   string `json:"student_name"`
	ClientName    string `json:"client_name"`
	BranchID      string `json:"branch_id"`
	Amount        int64  `json:"amount" validate:"required,gt=0"`
	DueDate       string `json:"due_date" validate:"required"`
	PaymentMethod string `json:"payment_method" validate:"required"`
	Notes         string `json:"notes"`
}

type MarkInvoicePaidRequest struct {
	PaidAt       string  `json:"paid_at"`
	PaidAmount   float64 `json:"paid_amount" validate:"required,gt=0"`
	PaymentProof string  `json:"payment_proof"`
	AccountCode  string  `json:"account_code" validate:"required"`
}

type CancelInvoiceRequest struct {
	Reason string `json:"reason" validate:"required"`
}

func currentMonthYear() (int, int) {
	now := time.Now()
	return int(now.Month()), now.Year()
}

func parseMonthYear(r *http.Request) (int, int) {
	defaultMonth, defaultYear := currentMonthYear()

	monthStr := r.URL.Query().Get("month")
	yearStr := r.URL.Query().Get("year")

	month := defaultMonth
	year := defaultYear

	if m, err := strconv.Atoi(monthStr); err == nil && m >= 1 && m <= 12 {
		month = m
	}
	if y, err := strconv.Atoi(yearStr); err == nil && y > 0 {
		year = y
	}

	return month, year
}

func (h *AccountingHandler) getStats(w http.ResponseWriter, r *http.Request) {
	month, year := parseMonthYear(r)

	query := &getaccountingstats.GetAccountingStatsQuery{Month: month, Year: year}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get accounting stats")
		writeError(w, http.StatusInternalServerError, "failed to get accounting stats")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) listTransactions(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	month, year := parseMonthYear(r)
	txType := r.URL.Query().Get("type")

	query := &listtransactions.ListTransactionsQuery{
		Offset: offset,
		Limit:  limit,
		Month:  month,
		Year:   year,
		Type:   txType,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list transactions")
		writeError(w, http.StatusInternalServerError, "failed to list transactions")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (h *AccountingHandler) createTransaction(w http.ResponseWriter, r *http.Request) {
	var req CreateTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createtransaction.CreateTransactionCommand{
		Description:       req.Description,
		TransactionType:   req.TransactionType,
		Amount:            req.Amount,
		DebitAccountCode:  req.DebitAccountCode,
		CreditAccountCode: req.CreditAccountCode,
		Category:          req.Category,
		TransactionDate:   req.TransactionDate,
		Status:            req.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create transaction")
		writeError(w, http.StatusInternalServerError, "failed to create transaction")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "transaction created successfully"})
}

func (h *AccountingHandler) listInvoices(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	month, year := parseMonthYear(r)
	status := r.URL.Query().Get("status")

	query := &listinvoices.ListInvoicesQuery{
		Offset: offset,
		Limit:  limit,
		Month:  month,
		Year:   year,
		Status: status,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list invoices")
		writeError(w, http.StatusInternalServerError, "failed to list invoices")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (h *AccountingHandler) updateInvoiceStatus(w http.ResponseWriter, r *http.Request) {
	invoiceIDStr := chi.URLParam(r, "id")
	invoiceID, err := uuid.Parse(invoiceIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid invoice id")
		return
	}

	var req UpdateInvoiceStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updateinvoicestatus.UpdateInvoiceStatusCommand{
		ID:     invoiceID,
		Status: req.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update invoice status")
		writeError(w, http.StatusInternalServerError, "failed to update invoice status")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "invoice status updated successfully"})
}

func (h *AccountingHandler) listCoa(w http.ResponseWriter, r *http.Request) {
	query := &listcoa.ListCoaQuery{}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list chart of accounts")
		writeError(w, http.StatusInternalServerError, "failed to list chart of accounts")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) getBudgetVsActual(w http.ResponseWriter, r *http.Request) {
	month, year := parseMonthYear(r)

	query := &getbudgetvsactual.GetBudgetVsActualQuery{Month: month, Year: year}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get budget vs actual")
		writeError(w, http.StatusInternalServerError, "failed to get budget vs actual")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) getFinancialRatios(w http.ResponseWriter, r *http.Request) {
	month, year := parseMonthYear(r)
	period := r.URL.Query().Get("period")
	branchID := r.URL.Query().Get("branch_id")
	comparison := r.URL.Query().Get("comparison")

	query := &getfinancialratios.GetFinancialRatiosQuery{
		Period:     period,
		Month:      month,
		Year:       year,
		BranchID:   branchID,
		Comparison: comparison,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get financial ratios")
		writeError(w, http.StatusInternalServerError, "failed to get financial ratios")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) getRevenueAnalysis(w http.ResponseWriter, r *http.Request) {
	month, year := parseMonthYear(r)
	period := r.URL.Query().Get("period")
	branchID := r.URL.Query().Get("branch_id")
	groupBy := r.URL.Query().Get("group_by")

	query := &getrevenueanalysis.GetRevenueAnalysisQuery{
		Period:   period,
		Month:    month,
		Year:     year,
		BranchID: branchID,
		GroupBy:  groupBy,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get revenue analysis")
		writeError(w, http.StatusInternalServerError, "failed to get revenue analysis")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) getCostAnalysis(w http.ResponseWriter, r *http.Request) {
	month, year := parseMonthYear(r)
	period := r.URL.Query().Get("period")
	branchID := r.URL.Query().Get("branch_id")
	groupBy := r.URL.Query().Get("group_by")

	query := &getcostanalysis.GetCostAnalysisQuery{
		Period:   period,
		Month:    month,
		Year:     year,
		BranchID: branchID,
		GroupBy:  groupBy,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get cost analysis")
		writeError(w, http.StatusInternalServerError, "failed to get cost analysis")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) getBatchProfitability(w http.ResponseWriter, r *http.Request) {
	month, year := parseMonthYear(r)
	period := r.URL.Query().Get("period")
	branchID := r.URL.Query().Get("branch_id")
	sort := r.URL.Query().Get("sort")
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))

	query := &getbatchprofitability.GetBatchProfitabilityQuery{
		Period:   period,
		Month:    month,
		Year:     year,
		BranchID: branchID,
		Sort:     sort,
		Limit:    limit,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get batch profitability")
		writeError(w, http.StatusInternalServerError, "failed to get batch profitability")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) getCashForecast(w http.ResponseWriter, r *http.Request) {
	months, _ := strconv.Atoi(r.URL.Query().Get("months"))
	branchID := r.URL.Query().Get("branch_id")

	query := &getcashforecast.GetCashForecastQuery{
		Months:   months,
		BranchID: branchID,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get cash forecast")
		writeError(w, http.StatusInternalServerError, "failed to get cash forecast")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) getAlerts(w http.ResponseWriter, r *http.Request) {
	query := &getfinancialalerts.GetFinancialAlertsQuery{}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get financial alerts")
		writeError(w, http.StatusInternalServerError, "failed to get financial alerts")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) getSuggestions(w http.ResponseWriter, r *http.Request) {
	query := &getfinancialsuggestions.GetFinancialSuggestionsQuery{}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get financial suggestions")
		writeError(w, http.StatusInternalServerError, "failed to get financial suggestions")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func currentUserIDFromCtx(r *http.Request) uuid.UUID {
	if val := r.Context().Value("user_id"); val != nil {
		if id, ok := val.(uuid.UUID); ok {
			return id
		}
		if str, ok := val.(string); ok {
			if id, err := uuid.Parse(str); err == nil {
				return id
			}
		}
	}
	return uuid.Nil
}

func (h *AccountingHandler) createInvoice(w http.ResponseWriter, r *http.Request) {
	var req CreateInvoiceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	batchID, err := uuid.Parse(req.BatchID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid batch_id")
		return
	}

	dueDate, err := time.Parse("2006-01-02", req.DueDate)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid due_date format (expected YYYY-MM-DD)")
		return
	}

	userID := currentUserIDFromCtx(r)
	cmd := &createinvoice.CreateInvoiceCommand{
		BatchID:       batchID,
		BatchName:     req.BatchName,
		ClientName:    req.ClientName,
		StudentName:   req.StudentName,
		Amount:        req.Amount,
		DueDate:       dueDate,
		PaymentMethod: req.PaymentMethod,
		Notes:         req.Notes,
		CreatedBy:     userID,
	}
	if req.StudentID != "" {
		if id, err := uuid.Parse(req.StudentID); err == nil {
			cmd.StudentID = &id
		}
	}
	if req.EnrollmentID != "" {
		if id, err := uuid.Parse(req.EnrollmentID); err == nil {
			cmd.EnrollmentID = &id
		}
	}
	if req.BranchID != "" {
		if id, err := uuid.Parse(req.BranchID); err == nil {
			cmd.BranchID = &id
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create invoice")
		writeError(w, http.StatusInternalServerError, "failed to create invoice")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "invoice created successfully"})
}

func (h *AccountingHandler) getInvoice(w http.ResponseWriter, r *http.Request) {
	invoiceIDStr := chi.URLParam(r, "id")
	invoiceID, err := uuid.Parse(invoiceIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid invoice id")
		return
	}

	query := &getinvoice.GetInvoiceQuery{InvoiceID: invoiceID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get invoice")
		writeError(w, http.StatusInternalServerError, "failed to get invoice")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) markInvoicePaid(w http.ResponseWriter, r *http.Request) {
	invoiceIDStr := chi.URLParam(r, "id")
	invoiceID, err := uuid.Parse(invoiceIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid invoice id")
		return
	}

	var req MarkInvoicePaidRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	paidAt := time.Now()
	if req.PaidAt != "" {
		if t, err := time.Parse("2006-01-02", req.PaidAt); err == nil {
			paidAt = t
		}
	}

	userID := currentUserIDFromCtx(r)
	cmd := &markpaid.MarkInvoicePaidCommand{
		InvoiceID:    invoiceID,
		PaidAt:       paidAt,
		PaidAmount:   req.PaidAmount,
		PaidBy:       userID,
		PaymentProof: req.PaymentProof,
		AccountCode:  req.AccountCode,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to mark invoice paid")
		writeError(w, http.StatusInternalServerError, "failed to mark invoice paid")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "invoice marked as paid"})
}

func (h *AccountingHandler) cancelInvoice(w http.ResponseWriter, r *http.Request) {
	invoiceIDStr := chi.URLParam(r, "id")
	invoiceID, err := uuid.Parse(invoiceIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid invoice id")
		return
	}

	var req CancelInvoiceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	userID := currentUserIDFromCtx(r)
	cmd := &cancelinvoice.CancelInvoiceCommand{
		InvoiceID:   invoiceID,
		Reason:      req.Reason,
		CancelledBy: userID,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to cancel invoice")
		writeError(w, http.StatusInternalServerError, "failed to cancel invoice")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "invoice cancelled"})
}

func (h *AccountingHandler) sendInvoice(w http.ResponseWriter, r *http.Request) {
	invoiceIDStr := chi.URLParam(r, "id")
	invoiceID, err := uuid.Parse(invoiceIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid invoice id")
		return
	}

	userID := currentUserIDFromCtx(r)
	cmd := &sendinvoice.SendInvoiceCommand{
		InvoiceID: invoiceID,
		SentBy:    userID,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to send invoice")
		writeError(w, http.StatusInternalServerError, "failed to send invoice")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "invoice sent"})
}

func (h *AccountingHandler) getInvoiceStats(w http.ResponseWriter, r *http.Request) {
	query := &getinvoicestats.GetInvoiceStatsQuery{}

	if branchIDStr := r.URL.Query().Get("branch_id"); branchIDStr != "" {
		if id, err := uuid.Parse(branchIDStr); err == nil {
			query.BranchID = &id
		}
	}
	if m, err := strconv.Atoi(r.URL.Query().Get("month")); err == nil {
		query.Month = m
	}
	if y, err := strconv.Atoi(r.URL.Query().Get("year")); err == nil {
		query.Year = y
	}

	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get invoice stats")
		writeError(w, http.StatusInternalServerError, "failed to get invoice stats")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *AccountingHandler) listInvoicesEnriched(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	month, year := parseMonthYear(r)
	status := r.URL.Query().Get("status")
	paymentMethod := r.URL.Query().Get("payment_method")

	query := &listinvoices.ListInvoicesQuery{
		Offset:        offset,
		Limit:         limit,
		Month:         month,
		Year:          year,
		Status:        status,
		PaymentMethod: paymentMethod,
	}
	if batchIDStr := r.URL.Query().Get("batch_id"); batchIDStr != "" {
		if id, err := uuid.Parse(batchIDStr); err == nil {
			query.BatchID = &id
		}
	}
	if studentIDStr := r.URL.Query().Get("student_id"); studentIDStr != "" {
		if id, err := uuid.Parse(studentIDStr); err == nil {
			query.StudentID = &id
		}
	}
	if dateFromStr := r.URL.Query().Get("date_from"); dateFromStr != "" {
		if t, err := time.Parse("2006-01-02", dateFromStr); err == nil {
			query.DateFrom = &t
		}
	}
	if dateToStr := r.URL.Query().Get("date_to"); dateToStr != "" {
		if t, err := time.Parse("2006-01-02", dateToStr); err == nil {
			query.DateTo = &t
		}
	}

	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list invoices")
		writeError(w, http.StatusInternalServerError, "failed to list invoices")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func RegisterAccountingRoutes(h *AccountingHandler, r chi.Router) {
	// Legacy accounting routes
	r.Get("/api/v1/accounting/stats", h.getStats)
	r.Get("/api/v1/accounting/transactions", h.listTransactions)
	r.Post("/api/v1/accounting/transactions", h.createTransaction)
	r.Get("/api/v1/accounting/invoices", h.listInvoices)
	r.Put("/api/v1/accounting/invoices/{id}/status", h.updateInvoiceStatus)
	r.Get("/api/v1/accounting/coa", h.listCoa)
	r.Get("/api/v1/accounting/budget-vs-actual", h.getBudgetVsActual)

	// Finance routes (new path prefix)
	r.Get("/api/v1/finance/transactions", h.listTransactions)
	r.Post("/api/v1/finance/transactions", h.createTransaction)
	r.Post("/api/v1/finance/invoices", h.createInvoice)
	r.Get("/api/v1/finance/invoices/stats", h.getInvoiceStats)
	r.Get("/api/v1/finance/invoices", h.listInvoicesEnriched)
	r.Get("/api/v1/finance/invoices/{id}", h.getInvoice)
	r.Put("/api/v1/finance/invoices/{id}/pay", h.markInvoicePaid)
	r.Put("/api/v1/finance/invoices/{id}/cancel", h.cancelInvoice)
	r.Put("/api/v1/finance/invoices/{id}/send", h.sendInvoice)
	r.Get("/api/v1/finance/coa", h.listCoa)
	r.Get("/api/v1/finance/stats", h.getStats)

	// Finance Analysis routes
	r.Get("/api/v1/finance/analysis/ratios", h.getFinancialRatios)
	r.Get("/api/v1/finance/analysis/revenue", h.getRevenueAnalysis)
	r.Get("/api/v1/finance/analysis/costs", h.getCostAnalysis)
	r.Get("/api/v1/finance/analysis/batch-profit", h.getBatchProfitability)
	r.Get("/api/v1/finance/analysis/cash-forecast", h.getCashForecast)
	r.Get("/api/v1/finance/analysis/alerts", h.getAlerts)
	r.Get("/api/v1/finance/analysis/suggestions", h.getSuggestions)
}
