package credentialing

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

const (
	contentTypePDF       = "application/pdf"
	contentDispositionFmt = `attachment; filename="%s.pdf"`
)

// Handler holds credentialing HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs credentialing Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) VerifyCertificate(w http.ResponseWriter, r *http.Request) {
	number := chi.URLParam(r, "number")
	if number == "" {
		apperrors.Render(w, apperrors.Validationf("certificate number required"))
		return
	}

	cert, err := h.svc.VerifyCertificate(r.Context(), number)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(cert)
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

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(certs)
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

	actionReq, err := h.svc.RequestAction(r.Context(), certID, CertAction(req.Action), req.Reason, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(actionReq)
}

func (h *Handler) ApproveActionRequest(w http.ResponseWriter, r *http.Request) {
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

	if err := h.svc.ApproveActionRequest(r.Context(), reqID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// VerifyByHash is a public endpoint resolving a certificate by its PDF hash.
func (h *Handler) VerifyByHash(w http.ResponseWriter, r *http.Request) {
	hash := chi.URLParam(r, "hash")
	if hash == "" {
		apperrors.Render(w, apperrors.Validationf("hash required"))
		return
	}
	res, err := h.svc.VerifyByHash(r.Context(), hash)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(res)
}

// DownloadCertificate streams the PDF blob for a given certificate ID.
// Auth-required: caller has been authenticated by the surrounding chi.Group.
func (h *Handler) DownloadCertificate(w http.ResponseWriter, r *http.Request) {
	certID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid certificate id"))
		return
	}
	cert, err := h.svc.GetCertificateForDownload(r.Context(), certID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	f, err := os.Open(*cert.PDFPath)
	if err != nil {
		apperrors.Render(w, apperrors.NotFoundf("certificate file missing"))
		return
	}
	defer func() { _ = f.Close() }()

	w.Header().Set("Content-Type", contentTypePDF)
	w.Header().Set("Content-Disposition", fmt.Sprintf(contentDispositionFmt, cert.CertificateNumber))
	if _, err := io.Copy(w, f); err != nil {
		// header already sent; best effort
		return
	}
}
