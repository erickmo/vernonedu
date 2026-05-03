package http

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createbankaccount "github.com/vernonedu/entrepreneurship-api/internal/command/create_bank_account"
	deletebankaccount "github.com/vernonedu/entrepreneurship-api/internal/command/delete_bank_account"
	deletetransaction "github.com/vernonedu/entrepreneurship-api/internal/command/delete_transaction"
	updatebankaccount "github.com/vernonedu/entrepreneurship-api/internal/command/update_bank_account"
	updatetransaction "github.com/vernonedu/entrepreneurship-api/internal/command/update_transaction"
	getbalancebyaccount "github.com/vernonedu/entrepreneurship-api/internal/query/get_balance_by_account"
	getbankaccount "github.com/vernonedu/entrepreneurship-api/internal/query/get_bank_account"
	listbankaccounts "github.com/vernonedu/entrepreneurship-api/internal/query/list_bank_accounts"
	listcoatree "github.com/vernonedu/entrepreneurship-api/internal/query/list_coa_tree"
)

// CreateBankAccountRequest is the JSON body for POST /accounting/bank-accounts.
type CreateBankAccountRequest struct {
	BranchID      string `json:"branch_id" validate:"required"`
	Name          string `json:"name" validate:"required"`
	AccountNumber string `json:"account_number"`
	BankName      string `json:"bank_name"`
	BalanceCents  int64  `json:"balance_cents"`
	Currency      string `json:"currency"`
	CoaCode       string `json:"coa_code"`
}

// UpdateBankAccountRequest is the JSON body for PUT /accounting/bank-accounts/{id}.
type UpdateBankAccountRequest struct {
	Name          string `json:"name" validate:"required"`
	AccountNumber string `json:"account_number"`
	BankName      string `json:"bank_name"`
	BalanceCents  int64  `json:"balance_cents"`
	Currency      string `json:"currency"`
	CoaCode       string `json:"coa_code"`
}

// UpdateTransactionRequest is the JSON body for PUT /accounting/transactions/{id}.
type UpdateTransactionRequest struct {
	Description string `json:"description" validate:"required"`
	Category    string `json:"category"`
}

// createBankAccount godoc
// @Summary      Create bank account
// @Description  Create a new bank account linked to a branch
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Param        body  body  CreateBankAccountRequest  true  "Bank account data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/bank-accounts [post]
func (h *AccountingHandler) createBankAccount(w http.ResponseWriter, r *http.Request) {
	var req CreateBankAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	branchID, err := uuid.Parse(req.BranchID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid branch_id")
		return
	}
	createdBy := currentUserIDFromCtx(r)
	cmd := &createbankaccount.CreateBankAccountCommand{
		BranchID:      branchID,
		Name:          req.Name,
		AccountNumber: req.AccountNumber,
		BankName:      req.BankName,
		BalanceCents:  req.BalanceCents,
		Currency:      req.Currency,
		CoaCode:       req.CoaCode,
	}
	if createdBy != uuid.Nil {
		cmd.CreatedBy = &createdBy
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create bank account")
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "bank account created"})
}

// updateBankAccount godoc
// @Summary      Update bank account
// @Description  Update an existing bank account
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Param        id    path  string                      true  "Bank account ID"
// @Param        body  body  UpdateBankAccountRequest    true  "Updated bank account data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/bank-accounts/{id} [put]
func (h *AccountingHandler) updateBankAccount(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	var req UpdateBankAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updatebankaccount.UpdateBankAccountCommand{
		ID:            id,
		Name:          req.Name,
		AccountNumber: req.AccountNumber,
		BankName:      req.BankName,
		BalanceCents:  req.BalanceCents,
		Currency:      req.Currency,
		CoaCode:       req.CoaCode,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update bank account")
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "bank account updated"})
}

// deleteBankAccount godoc
// @Summary      Delete bank account
// @Description  Deactivate (soft delete) a bank account
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Bank account ID"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/bank-accounts/{id} [delete]
func (h *AccountingHandler) deleteBankAccount(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	cmd := &deletebankaccount.DeleteBankAccountCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete bank account")
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "bank account deactivated"})
}

// listBankAccounts godoc
// @Summary      List bank accounts
// @Description  Get all bank accounts, optionally filtered by branch and inactive status
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Param        branch_id          query  string  false  "Filter by branch ID"
// @Param        include_inactive   query  bool    false  "Include inactive accounts"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/bank-accounts [get]
func (h *AccountingHandler) listBankAccounts(w http.ResponseWriter, r *http.Request) {
	q := &listbankaccounts.ListBankAccountsQuery{}
	if v := r.URL.Query().Get("branch_id"); v != "" {
		if id, err := uuid.Parse(v); err == nil {
			q.BranchID = &id
		}
	}
	if r.URL.Query().Get("include_inactive") == "true" {
		q.IncludeInactive = true
	}
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list bank accounts")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// getBankAccount godoc
// @Summary      Get bank account by ID
// @Description  Get a single bank account by its ID
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Bank account ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/bank-accounts/{id} [get]
func (h *AccountingHandler) getBankAccount(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	q := &getbankaccount.GetBankAccountQuery{ID: id}
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		writeError(w, http.StatusNotFound, "bank account not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// updateTransaction godoc
// @Summary      Update transaction
// @Description  Update description and category of an existing accounting transaction
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Param        id    path  string                     true  "Transaction ID"
// @Param        body  body  UpdateTransactionRequest   true  "Updated transaction data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/transactions/{id} [put]
func (h *AccountingHandler) updateTransaction(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	var req UpdateTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updatetransaction.UpdateTransactionCommand{
		ID:          id,
		Description: req.Description,
		Category:    req.Category,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "transaction updated"})
}

// deleteTransaction godoc
// @Summary      Delete transaction
// @Description  Cancel (soft delete) an accounting transaction
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Transaction ID"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/transactions/{id} [delete]
func (h *AccountingHandler) deleteTransaction(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	cmd := &deletetransaction.DeleteTransactionCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "transaction cancelled"})
}

// getBalanceByAccount godoc
// @Summary      Get balance by account
// @Description  Get current balance for a specific chart of account code
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Param        coa_code    query  string  true   "Chart of Account code"
// @Param        branch_id   query  string  false  "Filter by branch ID"
// @Param        date_to     query  string  false  "Balance as of date (YYYY-MM-DD)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/balance [get]
func (h *AccountingHandler) getBalanceByAccount(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("coa_code")
	if code == "" {
		writeError(w, http.StatusBadRequest, "coa_code is required")
		return
	}
	q := &getbalancebyaccount.GetBalanceByAccountQuery{CoaCode: code}
	if v := r.URL.Query().Get("branch_id"); v != "" {
		if id, err := uuid.Parse(v); err == nil {
			q.BranchID = &id
		}
	}
	if v := r.URL.Query().Get("date_to"); v != "" {
		if t, err := time.Parse("2006-01-02", v); err == nil {
			q.DateTo = &t
		}
	}
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get balance")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// listCoaTree godoc
// @Summary      List COA tree
// @Description  Get the chart of accounts in a hierarchical tree structure
// @Tags         accounting
// @Accept       json
// @Produce      json
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /accounting/coa/tree [get]
func (h *AccountingHandler) listCoaTree(w http.ResponseWriter, r *http.Request) {
	q := &listcoatree.ListCoaTreeQuery{}
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list coa tree")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// RegisterAccountingBankRoutes wires the bank-account / balance / coa-tree
// endpoints into the chi router.
func RegisterAccountingBankRoutes(h *AccountingHandler, r chi.Router) {
	r.Get("/api/v1/accounting/coa/tree", h.listCoaTree)
	r.Get("/api/v1/accounting/bank-accounts", h.listBankAccounts)
	r.Post("/api/v1/accounting/bank-accounts", h.createBankAccount)
	r.Get("/api/v1/accounting/bank-accounts/{id}", h.getBankAccount)
	r.Put("/api/v1/accounting/bank-accounts/{id}", h.updateBankAccount)
	r.Delete("/api/v1/accounting/bank-accounts/{id}", h.deleteBankAccount)
	r.Put("/api/v1/accounting/transactions/{id}", h.updateTransaction)
	r.Delete("/api/v1/accounting/transactions/{id}", h.deleteTransaction)
	r.Get("/api/v1/accounting/balance", h.getBalanceByAccount)
}
