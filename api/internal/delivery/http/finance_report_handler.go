package http

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	getbalancesheet "github.com/vernonedu/entrepreneurship-api/internal/query/get_balance_sheet"
	getcashflow "github.com/vernonedu/entrepreneurship-api/internal/query/get_cash_flow"
	getgeneralledger "github.com/vernonedu/entrepreneurship-api/internal/query/get_general_ledger"
	getprofitloss "github.com/vernonedu/entrepreneurship-api/internal/query/get_profit_loss"
	gettrialbalance "github.com/vernonedu/entrepreneurship-api/internal/query/get_trial_balance"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type FinanceReportHandler struct {
	qryBus querybus.QueryBus
}

func NewFinanceReportHandler(qryBus querybus.QueryBus) *FinanceReportHandler {
	return &FinanceReportHandler{qryBus: qryBus}
}

func (h *FinanceReportHandler) getBalanceSheet(w http.ResponseWriter, r *http.Request) {
	query := &getbalancesheet.GetBalanceSheetQuery{
		From:     r.URL.Query().Get("from"),
		To:       r.URL.Query().Get("to"),
		BranchID: r.URL.Query().Get("branch_id"),
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get balance sheet")
		writeError(w, http.StatusInternalServerError, "failed to get balance sheet")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *FinanceReportHandler) getProfitLoss(w http.ResponseWriter, r *http.Request) {
	query := &getprofitloss.GetProfitLossQuery{
		From:     r.URL.Query().Get("from"),
		To:       r.URL.Query().Get("to"),
		BranchID: r.URL.Query().Get("branch_id"),
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get profit loss")
		writeError(w, http.StatusInternalServerError, "failed to get profit & loss")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *FinanceReportHandler) getCashFlow(w http.ResponseWriter, r *http.Request) {
	query := &getcashflow.GetCashFlowQuery{
		From:     r.URL.Query().Get("from"),
		To:       r.URL.Query().Get("to"),
		BranchID: r.URL.Query().Get("branch_id"),
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get cash flow")
		writeError(w, http.StatusInternalServerError, "failed to get cash flow")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *FinanceReportHandler) getGeneralLedger(w http.ResponseWriter, r *http.Request) {
	account := r.URL.Query().Get("account")
	if account == "" {
		writeError(w, http.StatusBadRequest, "account is required")
		return
	}
	query := &getgeneralledger.GetGeneralLedgerQuery{
		AccountCode: account,
		From:        r.URL.Query().Get("from"),
		To:          r.URL.Query().Get("to"),
		BranchID:    r.URL.Query().Get("branch_id"),
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Str("account", account).Msg("failed to get general ledger")
		writeError(w, http.StatusInternalServerError, "failed to get general ledger")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *FinanceReportHandler) getTrialBalance(w http.ResponseWriter, r *http.Request) {
	query := &gettrialbalance.GetTrialBalanceQuery{
		From:     r.URL.Query().Get("from"),
		To:       r.URL.Query().Get("to"),
		BranchID: r.URL.Query().Get("branch_id"),
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get trial balance")
		writeError(w, http.StatusInternalServerError, "failed to get trial balance")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func RegisterFinanceReportRoutes(h *FinanceReportHandler, r chi.Router) {
	r.Get("/api/v1/finance/reports/balance-sheet", h.getBalanceSheet)
	r.Get("/api/v1/finance/reports/profit-loss", h.getProfitLoss)
	r.Get("/api/v1/finance/reports/cash-flow", h.getCashFlow)
	r.Get("/api/v1/finance/reports/ledger", h.getGeneralLedger)
	r.Get("/api/v1/finance/reports/trial-balance", h.getTrialBalance)
}
