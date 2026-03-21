package http_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	httphandler "github.com/vernonedu/entrepreneurship-api/internal/delivery/http"
)

func TestFinanceHandler_ListAccounts(t *testing.T) {
	h := httphandler.NewFinanceHandler(&mockCommandBus{}, &mockQueryBus{result: []interface{}{}})
	r := chi.NewRouter()
	httphandler.RegisterFinanceRoutes(h, r)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/finance/coa", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestFinanceHandler_CreateAccount(t *testing.T) {
	h := httphandler.NewFinanceHandler(&mockCommandBus{}, &mockQueryBus{})
	r := chi.NewRouter()
	httphandler.RegisterFinanceRoutes(h, r)

	body, _ := json.Marshal(map[string]interface{}{
		"code": "9999", "name": "Test Account", "type": "asset",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/coa", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d", w.Code)
	}
}

func TestFinanceHandler_GetAccount_InvalidID(t *testing.T) {
	h := httphandler.NewFinanceHandler(&mockCommandBus{}, &mockQueryBus{})
	r := chi.NewRouter()
	httphandler.RegisterFinanceRoutes(h, r)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/finance/coa/not-a-uuid", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestFinanceHandler_ListTransactions(t *testing.T) {
	h := httphandler.NewFinanceHandler(&mockCommandBus{}, &mockQueryBus{result: map[string]interface{}{"data": []interface{}{}}})
	r := chi.NewRouter()
	httphandler.RegisterFinanceRoutes(h, r)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/finance/transactions", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestFinanceHandler_CreateTransaction_InvalidDebitID(t *testing.T) {
	h := httphandler.NewFinanceHandler(&mockCommandBus{}, &mockQueryBus{})
	r := chi.NewRouter()
	httphandler.RegisterFinanceRoutes(h, r)

	body, _ := json.Marshal(map[string]interface{}{
		"description":       "Test",
		"account_debit_id":  "not-a-uuid",
		"account_credit_id": uuid.New().String(),
		"amount":            1000.0,
		"branch_id":         uuid.New().String(),
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/transactions", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestFinanceHandler_ListJournal(t *testing.T) {
	h := httphandler.NewFinanceHandler(&mockCommandBus{}, &mockQueryBus{result: map[string]interface{}{"data": []interface{}{}}})
	r := chi.NewRouter()
	httphandler.RegisterFinanceRoutes(h, r)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/finance/journal", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}
