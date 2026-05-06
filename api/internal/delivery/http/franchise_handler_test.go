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
	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
)

func TestFranchiseeList_ReturnsOK(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{result: map[string]interface{}{"data": []interface{}{}, "total": 0}}

	h := httphandler.NewFranchiseHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterFranchiseRoutes(h, r)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestFranchiseeCreate_Returns201(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{}

	h := httphandler.NewFranchiseHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterFranchiseRoutes(h, r)

	body := map[string]interface{}{
		"name":        "Test Franchise",
		"branch_name": "Branch Jakarta",
		"location":    "Jakarta",
		"contact":     "081234567890",
		"status":      "active",
	}
	b, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/franchisees", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d", w.Code)
	}
}

func TestFranchiseeGetByID_NotFound(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{err: franchise.ErrFranchiseeNotFound}

	h := httphandler.NewFranchiseHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterFranchiseRoutes(h, r)

	id := uuid.New().String()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees/"+id, nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestFranchiseeUpdate_NotFound(t *testing.T) {
	cmdBus := &mockCommandBus{err: franchise.ErrFranchiseeNotFound}
	qryBus := &mockQueryBus{}

	h := httphandler.NewFranchiseHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterFranchiseRoutes(h, r)

	body := map[string]interface{}{
		"name":        "Updated Franchise",
		"branch_name": "Branch Bandung",
		"location":    "Bandung",
		"contact":     "089876543210",
		"status":      "active",
	}
	b, _ := json.Marshal(body)

	id := uuid.New().String()
	req := httptest.NewRequest(http.MethodPut, "/api/v1/franchisees/"+id, bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}

func TestFranchiseeGetAgreement_NotFound(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{err: franchise.ErrAgreementNotFound}

	h := httphandler.NewFranchiseHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterFranchiseRoutes(h, r)

	id := uuid.New().String()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees/"+id+"/agreement", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}
