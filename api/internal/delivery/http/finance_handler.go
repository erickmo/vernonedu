package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createfinanceaccount "github.com/vernonedu/entrepreneurship-api/internal/command/create_finance_account"
	createfinancetransaction "github.com/vernonedu/entrepreneurship-api/internal/command/create_finance_transaction"
	createjournalentry "github.com/vernonedu/entrepreneurship-api/internal/command/create_journal_entry"
	updatefinanceaccount "github.com/vernonedu/entrepreneurship-api/internal/command/update_finance_account"
	getfinanceaccount "github.com/vernonedu/entrepreneurship-api/internal/query/get_finance_account"
	listfinanceaccounts "github.com/vernonedu/entrepreneurship-api/internal/query/list_finance_accounts"
	listfinancetransactions "github.com/vernonedu/entrepreneurship-api/internal/query/list_finance_transactions"
	listjournalentries "github.com/vernonedu/entrepreneurship-api/internal/query/list_journal_entries"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
	"github.com/vernonedu/entrepreneurship-api/pkg/sortutil"
)

type FinanceHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewFinanceHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *FinanceHandler {
	return &FinanceHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// ─── CoA ─────────────────────────────────────────────────────────────────────

type CreateFinanceAccountRequest struct {
	Code     string  `json:"code"`
	Name     string  `json:"name"`
	Type     string  `json:"type"`
	ParentID *string `json:"parent_id"`
	BranchID *string `json:"branch_id"`
}

type UpdateFinanceAccountRequest struct {
	Name     string `json:"name"`
	IsActive bool   `json:"is_active"`
}

// listAccounts godoc
// @Summary      List finance accounts
// @Description  Get all finance chart of accounts, optionally filtered by branch
// @Tags         finance
// @Accept       json
// @Produce      json
// @Param        branch_id  query  string  false  "Filter by branch ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /finance/coa [get]
func (h *FinanceHandler) listAccounts(w http.ResponseWriter, r *http.Request) {
	var branchID *uuid.UUID
	if s := r.URL.Query().Get("branch_id"); s != "" {
		if id, err := uuid.Parse(s); err == nil {
			branchID = &id
		}
	}
	result, err := h.qryBus.Execute(r.Context(), &listfinanceaccounts.ListFinanceAccountsQuery{BranchID: branchID})
	if err != nil {
		log.Error().Err(err).Msg("failed to list finance accounts")
		writeError(w, http.StatusInternalServerError, "failed to list finance accounts")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// getAccount godoc
// @Summary      Get finance account
// @Description  Get a single finance account by ID
// @Tags         finance
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Account ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /finance/coa/{id} [get]
func (h *FinanceHandler) getAccount(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid account id")
		return
	}
	result, err := h.qryBus.Execute(r.Context(), &getfinanceaccount.GetFinanceAccountQuery{ID: id})
	if err != nil {
		writeError(w, http.StatusNotFound, "account not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// createAccount godoc
// @Summary      Create finance account
// @Description  Create a new chart of accounts entry
// @Tags         finance
// @Accept       json
// @Produce      json
// @Param        body  body  CreateFinanceAccountRequest  true  "Account data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /finance/coa [post]
func (h *FinanceHandler) createAccount(w http.ResponseWriter, r *http.Request) {
	var req CreateFinanceAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &createfinanceaccount.CreateFinanceAccountCommand{
		Code: req.Code,
		Name: req.Name,
		Type: req.Type,
	}
	if req.ParentID != nil {
		if id, err := uuid.Parse(*req.ParentID); err == nil {
			cmd.ParentID = &id
		}
	}
	if req.BranchID != nil {
		if id, err := uuid.Parse(*req.BranchID); err == nil {
			cmd.BranchID = &id
		}
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create finance account")
		writeError(w, http.StatusInternalServerError, "failed to create finance account")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "account created"})
}

// updateAccount godoc
// @Summary      Update finance account
// @Description  Update name and active status of a finance account
// @Tags         finance
// @Accept       json
// @Produce      json
// @Param        id    path  string                      true  "Account ID"
// @Param        body  body  UpdateFinanceAccountRequest  true  "Update data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /finance/coa/{id} [put]
func (h *FinanceHandler) updateAccount(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid account id")
		return
	}
	var req UpdateFinanceAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updatefinanceaccount.UpdateFinanceAccountCommand{
		ID:       id,
		Name:     req.Name,
		IsActive: req.IsActive,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update finance account")
		writeError(w, http.StatusInternalServerError, "failed to update finance account")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "account updated"})
}

// ─── Transactions ─────────────────────────────────────────────────────────────

type CreateFinanceTransactionRequest struct {
	Description     string  `json:"description"`
	AccountDebitID  string  `json:"account_debit_id"`
	AccountCreditID string  `json:"account_credit_id"`
	Amount          float64 `json:"amount"`
	Reference       string  `json:"reference"`
	BranchID        string  `json:"branch_id"`
	AttachmentURL   string  `json:"attachment_url"`
}

// listTransactions godoc
// @Summary      List finance transactions
// @Description  Get paginated list of finance transactions with optional filters
// @Tags         finance
// @Accept       json
// @Produce      json
// @Param        offset      query  int     false  "Pagination offset"
// @Param        limit       query  int     false  "Pagination limit (default 25)"
// @Param        source      query  string  false  "Filter by source"
// @Param        account_id  query  string  false  "Filter by account ID"
// @Param        branch_id   query  string  false  "Filter by branch ID"
// @Param        date_from   query  string  false  "Filter from date (YYYY-MM-DD)"
// @Param        date_to     query  string  false  "Filter to date (YYYY-MM-DD)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /finance/transactions [get]
func (h *FinanceHandler) listTransactions(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 25
	}

	sortBy, sortDir := "", ""
	if s := sortutil.Parse(r.URL.Query().Get("sort")); s != nil {
		sortBy, sortDir = s.Column, s.Dir
	}

	q := &listfinancetransactions.ListFinanceTransactionsQuery{
		Offset:  offset,
		Limit:   limit,
		Source:  r.URL.Query().Get("source"),
		SortBy:  sortBy,
		SortDir: sortDir,
	}
	if s := r.URL.Query().Get("account_id"); s != "" {
		if id, err := uuid.Parse(s); err == nil {
			q.AccountID = &id
		}
	}
	if s := r.URL.Query().Get("branch_id"); s != "" {
		if id, err := uuid.Parse(s); err == nil {
			q.BranchID = &id
		}
	}
	if s := r.URL.Query().Get("date_from"); s != "" {
		if t, err := time.Parse("2006-01-02", s); err == nil {
			q.DateFrom = &t
		}
	}
	if s := r.URL.Query().Get("date_to"); s != "" {
		if t, err := time.Parse("2006-01-02", s); err == nil {
			q.DateTo = &t
		}
	}

	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to list finance transactions")
		writeError(w, http.StatusInternalServerError, "failed to list finance transactions")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// createTransaction godoc
// @Summary      Create finance transaction
// @Description  Create a new double-entry finance transaction
// @Tags         finance
// @Accept       json
// @Produce      json
// @Param        body  body  CreateFinanceTransactionRequest  true  "Transaction data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /finance/transactions [post]
func (h *FinanceHandler) createTransaction(w http.ResponseWriter, r *http.Request) {
	var req CreateFinanceTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	debitID, err := uuid.Parse(req.AccountDebitID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid account_debit_id")
		return
	}
	creditID, err := uuid.Parse(req.AccountCreditID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid account_credit_id")
		return
	}
	branchID, err := uuid.Parse(req.BranchID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid branch_id")
		return
	}

	// Extract createdBy from JWT context
	createdBy := uuid.Nil
	if claims := r.Context().Value("claims"); claims != nil {
		if c, ok := claims.(map[string]interface{}); ok {
			if sub, ok := c["sub"].(string); ok {
				if id, err := uuid.Parse(sub); err == nil {
					createdBy = id
				}
			}
		}
	}

	cmd := &createfinancetransaction.CreateFinanceTransactionCommand{
		Description:     req.Description,
		AccountDebitID:  debitID,
		AccountCreditID: creditID,
		Amount:          req.Amount,
		Reference:       req.Reference,
		BranchID:        branchID,
		AttachmentURL:   req.AttachmentURL,
		CreatedBy:       createdBy,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create finance transaction")
		writeError(w, http.StatusInternalServerError, "failed to create finance transaction")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "transaction created"})
}

// ─── Journal ──────────────────────────────────────────────────────────────────

type CreateJournalEntryRequest struct {
	TransactionID string  `json:"transaction_id"`
	AccountID     string  `json:"account_id"`
	Debit         float64 `json:"debit"`
	Credit        float64 `json:"credit"`
	Description   string  `json:"description"`
	Source        string  `json:"source"`
}

// listJournal godoc
// @Summary      List journal entries
// @Description  Get paginated list of journal entries with optional filters
// @Tags         finance
// @Accept       json
// @Produce      json
// @Param        offset      query  int     false  "Pagination offset"
// @Param        limit       query  int     false  "Pagination limit (default 25)"
// @Param        source      query  string  false  "Filter by source"
// @Param        account_id  query  string  false  "Filter by account ID"
// @Param        date_from   query  string  false  "Filter from date (YYYY-MM-DD)"
// @Param        date_to     query  string  false  "Filter to date (YYYY-MM-DD)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /finance/journal [get]
func (h *FinanceHandler) listJournal(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 25
	}

	q := &listjournalentries.ListJournalEntriesQuery{
		Offset: offset,
		Limit:  limit,
		Source: r.URL.Query().Get("source"),
	}
	if s := r.URL.Query().Get("account_id"); s != "" {
		if id, err := uuid.Parse(s); err == nil {
			q.AccountID = &id
		}
	}
	if s := r.URL.Query().Get("date_from"); s != "" {
		if t, err := time.Parse("2006-01-02", s); err == nil {
			q.DateFrom = &t
		}
	}
	if s := r.URL.Query().Get("date_to"); s != "" {
		if t, err := time.Parse("2006-01-02", s); err == nil {
			q.DateTo = &t
		}
	}

	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to list journal entries")
		writeError(w, http.StatusInternalServerError, "failed to list journal entries")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// createJournalEntry godoc
// @Summary      Create journal entry
// @Description  Create a new journal entry for a transaction
// @Tags         finance
// @Accept       json
// @Produce      json
// @Param        body  body  CreateJournalEntryRequest  true  "Journal entry data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /finance/journal [post]
func (h *FinanceHandler) createJournalEntry(w http.ResponseWriter, r *http.Request) {
	var req CreateJournalEntryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	txnID, err := uuid.Parse(req.TransactionID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid transaction_id")
		return
	}
	accountID, err := uuid.Parse(req.AccountID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid account_id")
		return
	}

	cmd := &createjournalentry.CreateJournalEntryCommand{
		TransactionID: txnID,
		AccountID:     accountID,
		Debit:         req.Debit,
		Credit:        req.Credit,
		Description:   req.Description,
		Source:        req.Source,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create journal entry")
		writeError(w, http.StatusInternalServerError, "failed to create journal entry")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "journal entry created"})
}

func RegisterFinanceRoutes(h *FinanceHandler, r chi.Router) {
	// CoA
	r.Get("/api/v1/finance/coa", h.listAccounts)
	r.Get("/api/v1/finance/coa/{id}", h.getAccount)
	r.Post("/api/v1/finance/coa", h.createAccount)
	r.Put("/api/v1/finance/coa/{id}", h.updateAccount)
	// Transactions
	r.Get("/api/v1/finance/transactions", h.listTransactions)
	r.Post("/api/v1/finance/transactions", h.createTransaction)
	// Journal
	r.Get("/api/v1/finance/journal", h.listJournal)
	r.Post("/api/v1/finance/journal", h.createJournalEntry)
}
