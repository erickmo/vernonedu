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
	verifycertificate "github.com/vernonedu/entrepreneurship-api/internal/query/verify_certificate"
)

func newCertHandler(t *testing.T, qry interface{}) (*chi.Mux, *httphandler.CertificateHandler) {
	t.Helper()
	cmdBus := &mockCommandBus{}
	qryBus := &mockQueryBus{result: qry}
	h := httphandler.NewCertificateHandler(cmdBus, qryBus)
	r := chi.NewRouter()
	httphandler.RegisterCertificateExtraRoutes(h, r)
	httphandler.RegisterCertificatePublicVerifyAlias(h, r)
	return r, h
}

func TestIssueParticipant_Success(t *testing.T) {
	r, _ := newCertHandler(t, nil)
	body := map[string]string{
		"templateId": uuid.New().String(),
		"studentId":  uuid.New().String(),
		"batchId":    uuid.New().String(),
		"courseId":   uuid.New().String(),
	}
	b, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/certificates/participant", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d", w.Code)
	}
}

func TestIssueCompetency_RequiresTestPassed(t *testing.T) {
	r, _ := newCertHandler(t, nil)
	body := map[string]interface{}{
		"templateId": uuid.New().String(),
		"studentId":  uuid.New().String(),
		"courseId":   uuid.New().String(),
		"testPassed": false,
	}
	b, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/certificates/competency", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 when testPassed=false, got %d", w.Code)
	}
}

func TestIssueCompetency_Success(t *testing.T) {
	r, _ := newCertHandler(t, nil)
	body := map[string]interface{}{
		"templateId": uuid.New().String(),
		"studentId":  uuid.New().String(),
		"courseId":   uuid.New().String(),
		"testPassed": true,
	}
	b, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/certificates/competency", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d", w.Code)
	}
}

func TestListByStudent_OK(t *testing.T) {
	r, _ := newCertHandler(t, &struct{}{})
	id := uuid.New().String()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/students/"+id+"/certificates", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestListByBatch_OK(t *testing.T) {
	r, _ := newCertHandler(t, &struct{}{})
	id := uuid.New().String()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/batches/"+id+"/certificates", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
}

func TestVerifyPublic_StripsPII(t *testing.T) {
	studentID := uuid.New().String()
	batchID := uuid.New().String()
	courseID := uuid.New().String()

	full := &verifycertificate.VerifyResult{
		Certificate: verifycertificate.CertReadModel{
			ID:              uuid.New().String(),
			StudentID:       studentID,
			BatchID:         batchID,
			CourseID:        courseID,
			Type:            "participant",
			CertificateCode: "VE-P-2026-ABCDEFGH",
			Status:          "active",
			IssuedAt:        "2026-05-02T10:00:00Z",
		},
		IsValid:   true,
		IsRevoked: false,
	}
	r, _ := newCertHandler(t, full)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/public/certificates/verify/VE-P-2026-ABCDEFGH", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	body := w.Body.String()
	for _, leak := range []string{studentID, batchID, courseID} {
		if bytes.Contains(w.Body.Bytes(), []byte(leak)) {
			t.Errorf("PII leak: response contains %s\nbody=%s", leak, body)
		}
	}
}

func TestToPublicVerifyResult_NilSafe(t *testing.T) {
	got := httphandler.ToPublicVerifyResult(nil)
	if got == nil {
		t.Fatal("expected non-nil result")
	}
	if got.CertificateCode != "" {
		t.Errorf("expected empty code on nil input")
	}
}

func TestVerifyPublic_MissingCode(t *testing.T) {
	r, _ := newCertHandler(t, nil)
	// chi will not match an empty {code} param, so we hit the route with a slash.
	req := httptest.NewRequest(http.MethodGet, "/api/v1/public/certificates/verify/", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code == http.StatusOK {
		t.Errorf("expected non-200 for missing code, got %d", w.Code)
	}
}
