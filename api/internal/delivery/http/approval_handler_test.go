package http_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	httphandler "github.com/vernonedu/entrepreneurship-api/internal/delivery/http"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// mockCommandBus implements commandbus.CommandBus for unit tests
type mockCommandBus struct {
	err error
}

func (m *mockCommandBus) Register(_ commandbus.Command, _ commandbus.CommandHandler) error {
	return nil
}

func (m *mockCommandBus) Execute(_ context.Context, _ commandbus.Command) error {
	return m.err
}

// mockQueryBus implements querybus.QueryBus for unit tests
type mockQueryBus struct {
	result interface{}
	err    error
}

func (m *mockQueryBus) Register(_ querybus.Query, _ querybus.QueryHandler) error {
	return nil
}

func (m *mockQueryBus) Execute(_ context.Context, _ querybus.Query) (interface{}, error) {
	return m.result, m.err
}

func TestApprovalHandler_ListApprovals(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{result: map[string]interface{}{"data": []interface{}{}, "total": 0}}

	h := httphandler.NewApprovalHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterApprovalRoutes(h, r)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/approvals?status=pending", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestApprovalHandler_CreateApproval(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{}

	h := httphandler.NewApprovalHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterApprovalRoutes(h, r)

	body := map[string]interface{}{
		"type":        "propose_course",
		"entity_type": "course",
		"entity_id":   uuid.New().String(),
		"steps": []map[string]interface{}{
			{"approver_id": uuid.New().String(), "approver_role": "education_leader"},
		},
	}
	b, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/approvals", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d", w.Code)
	}
}

func TestApprovalHandler_GetApproval_InvalidID(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{}

	h := httphandler.NewApprovalHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterApprovalRoutes(h, r)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/approvals/not-a-uuid", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestApprovalHandler_ApproveStep(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{}

	h := httphandler.NewApprovalHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterApprovalRoutes(h, r)

	body := map[string]string{"comment": "looks good"}
	b, _ := json.Marshal(body)

	id := uuid.New().String()
	req := httptest.NewRequest(http.MethodPut, "/api/v1/approvals/"+id+"/approve", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestApprovalHandler_RejectStep(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{}

	h := httphandler.NewApprovalHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterApprovalRoutes(h, r)

	body := map[string]string{"comment": "needs revision"}
	b, _ := json.Marshal(body)

	id := uuid.New().String()
	req := httptest.NewRequest(http.MethodPut, "/api/v1/approvals/"+id+"/reject", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestApprovalHandler_CancelApproval(t *testing.T) {
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{}

	h := httphandler.NewApprovalHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterApprovalRoutes(h, r)

	id := uuid.New().String()
	req := httptest.NewRequest(http.MethodPut, "/api/v1/approvals/"+id+"/cancel", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}
