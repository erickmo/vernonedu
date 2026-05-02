package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	issuecertificate "github.com/vernonedu/entrepreneurship-api/internal/command/issue_certificate"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
	listcertificates "github.com/vernonedu/entrepreneurship-api/internal/query/list_certificates"
	verifycertificate "github.com/vernonedu/entrepreneurship-api/internal/query/verify_certificate"
)

const (
	certTypeParticipant = "participant"
	certTypeCompetency  = "competency"
	defaultCertLimit    = 50
)

// RegisterCertificateExtraRoutes wires convenience and PII-safe public verification routes.
func RegisterCertificateExtraRoutes(h *CertificateHandler, r chi.Router) {
	r.Post("/api/v1/certificates/participant", h.IssueParticipant)
	r.Post("/api/v1/certificates/competency", h.IssueCompetency)
	r.Get("/api/v1/students/{id}/certificates", h.ListByStudent)
	r.Get("/api/v1/batches/{id}/certificates", h.ListByBatch)
}

// RegisterCertificatePublicVerifyAlias mounts the PRD-spec'd public verify path.
func RegisterCertificatePublicVerifyAlias(h *CertificateHandler, r chi.Router) {
	r.Get("/api/v1/public/certificates/verify/{code}", h.VerifyPublic)
}

type issueParticipantRequest struct {
	TemplateID          string `json:"templateId"`
	StudentID           string `json:"studentId"`
	BatchID             string `json:"batchId"`
	CourseID            string `json:"courseId"`
	VerificationBaseURL string `json:"verificationBaseUrl"`
}

// IssueParticipant POST /api/v1/certificates/participant
func (h *CertificateHandler) IssueParticipant(w http.ResponseWriter, r *http.Request) {
	var req issueParticipantRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := buildIssueCmd(req.TemplateID, req.StudentID, req.BatchID, req.CourseID,
		certTypeParticipant, req.VerificationBaseURL)
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("issue participant certificate failed")
		writeError(w, http.StatusInternalServerError, "failed to issue certificate")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "certificate issued successfully"})
}

type issueCompetencyRequest struct {
	TemplateID          string `json:"templateId"`
	StudentID           string `json:"studentId"`
	BatchID             string `json:"batchId"`
	CourseID            string `json:"courseId"`
	TestPassed          bool   `json:"testPassed"`
	VerificationBaseURL string `json:"verificationBaseUrl"`
}

// IssueCompetency POST /api/v1/certificates/competency — requires testPassed=true.
func (h *CertificateHandler) IssueCompetency(w http.ResponseWriter, r *http.Request) {
	var req issueCompetencyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if !req.TestPassed {
		writeError(w, http.StatusBadRequest, "competency certificate requires testPassed=true")
		return
	}
	cmd := buildIssueCmd(req.TemplateID, req.StudentID, req.BatchID, req.CourseID,
		certTypeCompetency, req.VerificationBaseURL)
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("issue competency certificate failed")
		writeError(w, http.StatusInternalServerError, "failed to issue certificate")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "certificate issued successfully"})
}

func buildIssueCmd(templateID, studentID, batchID, courseID, certType, baseURL string) *issuecertificate.IssueCertificateCommand {
	return &issuecertificate.IssueCertificateCommand{
		TemplateID:          templateID,
		StudentID:           studentID,
		BatchID:             batchID,
		CourseID:            courseID,
		Type:                certType,
		VerificationBaseURL: baseURL,
	}
}

// ListByStudent GET /api/v1/students/{id}/certificates
func (h *CertificateHandler) ListByStudent(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if id == "" {
		writeError(w, http.StatusBadRequest, "student id is required")
		return
	}
	h.dispatchList(w, r, &listcertificates.ListCertificatesQuery{StudentID: id, Limit: defaultCertLimit})
}

// ListByBatch GET /api/v1/batches/{id}/certificates
func (h *CertificateHandler) ListByBatch(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if id == "" {
		writeError(w, http.StatusBadRequest, "batch id is required")
		return
	}
	h.dispatchList(w, r, &listcertificates.ListCertificatesQuery{BatchID: id, Limit: defaultCertLimit})
}

func (h *CertificateHandler) dispatchList(w http.ResponseWriter, r *http.Request, q *listcertificates.ListCertificatesQuery) {
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("list certificates failed")
		writeError(w, http.StatusInternalServerError, "failed to list certificates")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// PublicVerifyResult is the PII-safe payload returned to anonymous verifiers.
type PublicVerifyResult struct {
	CertificateCode  string `json:"certificate_code"`
	Type             string `json:"type"`
	IssuedAt         string `json:"issued_at"`
	Status           string `json:"status"`
	IsValid          bool   `json:"is_valid"`
	IsRevoked        bool   `json:"is_revoked"`
	RevocationReason string `json:"revocation_reason,omitempty"`
}

// VerifyPublic GET /api/v1/public/certificates/verify/{code} — strips PII.
func (h *CertificateHandler) VerifyPublic(w http.ResponseWriter, r *http.Request) {
	code := chi.URLParam(r, "code")
	if code == "" {
		writeError(w, http.StatusBadRequest, "certificate code is required")
		return
	}
	q := &verifycertificate.VerifyCertificateQuery{Code: code}
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		if err == certificate.ErrCertificateNotFound {
			writeError(w, http.StatusNotFound, "certificate not found")
			return
		}
		log.Error().Err(err).Msg("public verify certificate failed")
		writeError(w, http.StatusInternalServerError, "failed to verify certificate")
		return
	}
	writeJSON(w, http.StatusOK, ToPublicVerifyResult(result))
}

// ToPublicVerifyResult strips IDs and PII from the internal verify payload.
// Exported for unit testing.
func ToPublicVerifyResult(raw interface{}) *PublicVerifyResult {
	v, ok := raw.(*verifycertificate.VerifyResult)
	if !ok || v == nil {
		return &PublicVerifyResult{}
	}
	return &PublicVerifyResult{
		CertificateCode:  v.Certificate.CertificateCode,
		Type:             v.Certificate.Type,
		IssuedAt:         v.Certificate.IssuedAt,
		Status:           v.Certificate.Status,
		IsValid:          v.IsValid,
		IsRevoked:        v.IsRevoked,
		RevocationReason: v.RevocationReason,
	}
}
