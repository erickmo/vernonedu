package credentialing

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds credentialing HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs credentialing Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// writeJSON writes a JSON response with the given status code.
func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if body != nil {
		_ = json.NewEncoder(w).Encode(body)
	}
}

func (h *Handler) VerifyCertificate(w http.ResponseWriter, r *http.Request) {
	number := chi.URLParam(r, "number")
	if number == "" {
		apperrors.Render(w, apperrors.Validationf("certificate number required"))
		return
	}

	result, err := h.svc.Verify(r.Context(), number)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *Handler) ListCertificates(w http.ResponseWriter, r *http.Request) {
	enrollmentID, err := uuid.Parse(chi.URLParam(r, "enrollmentID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}

	certs, err := h.svc.ListCertificatesByEnrollment(r.Context(), enrollmentID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, certs)
}

func (h *Handler) RequestAction(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	certID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid certificate id"))
		return
	}

	var req struct {
		Action string `json:"action"`
		Reason string `json:"reason"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	actionReq, err := h.svc.RequestAction(r.Context(), RequestActionInput{
		StudentCertificateID: certID,
		Action:               CertAction(req.Action),
		Reason:               req.Reason,
		RequestedBy:          uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, actionReq)
}

func (h *Handler) ApproveAction(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	reqID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request id"))
		return
	}

	if err := h.svc.ApproveAction(r.Context(), reqID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RejectAction(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	reqID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request id"))
		return
	}

	if err := h.svc.RejectAction(r.Context(), reqID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListMyCertificates(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	certs, err := h.svc.ListMyCertificates(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, certs)
}

func (h *Handler) DownloadMyCertificate(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	certID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid certificate id"))
		return
	}

	res, err := h.svc.DownloadCertificate(r.Context(), certID, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", "attachment; filename=\""+res.Filename+"\"")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(res.Content)
}

func (h *Handler) CreateCertificateType(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		Name           string `json:"name"`
		Category       string `json:"category"`
		ValidityMonths *int   `json:"validity_months"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	ct, err := h.svc.CreateCertificateType(r.Context(), CreateCertificateTypeInput{
		Name:           req.Name,
		Category:       CertCategory(req.Category),
		ValidityMonths: req.ValidityMonths,
		CreatedBy:      uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, ct)
}

func (h *Handler) DeactivateCertificateType(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid certificate type id"))
		return
	}

	if err := h.svc.DeactivateCertificateType(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) AddCertificateConfig(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}

	var req struct {
		CertificateTypeID uuid.UUID `json:"certificate_type_id"`
		IssuedOn          string    `json:"issued_on"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	cfg, err := h.svc.AddCertificateConfig(r.Context(), AddCertificateConfigInput{
		CourseID:          courseID,
		CertificateTypeID: req.CertificateTypeID,
		IssuedOn:          IssuedOn(req.IssuedOn),
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, cfg)
}

func (h *Handler) ListCertificateConfigs(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}

	cfgs, err := h.svc.ListCertificateConfigsByCourse(r.Context(), courseID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, cfgs)
}
