package enrollment

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds enrollment HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs enrollment Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) CreateEnrollment(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		StudentID     string `json:"student_id"`
		CourseBatchID string `json:"course_batch_id"`
		Format        string `json:"format"`
		Mode          string `json:"mode"`
		Payer         string `json:"payer"`
		Price         string `json:"price"`
		VoucherCode   string `json:"voucher_code"`
		Source        string `json:"source"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	studentID, err := uuid.Parse(req.StudentID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student_id"))
		return
	}
	batchID, err := uuid.Parse(req.CourseBatchID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course_batch_id"))
		return
	}
	price, err := decimal.NewFromString(req.Price)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid price"))
		return
	}

	enrollment, err := h.svc.Enroll(r.Context(), EnrollInput{
		StudentID:     studentID,
		CourseBatchID: batchID,
		Format:        EnrollmentFormat(req.Format),
		Mode:          EnrollmentMode(req.Mode),
		Payer:         req.Payer,
		Price:         price,
		VoucherCode:   req.VoucherCode,
		Source:        req.Source,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(enrollment)
}

func (h *Handler) GetEnrollment(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}

	e, err := h.svc.GetEnrollment(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(e)
}

func (h *Handler) DropEnrollment(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}

	if err := h.svc.DropEnrollment(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CompleteEnrollment(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}

	if err := h.svc.CompleteEnrollment(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListEnrollmentsByStudent(w http.ResponseWriter, r *http.Request) {
	studentID, err := uuid.Parse(chi.URLParam(r, "studentID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}

	enrollments, err := h.svc.ListByStudent(r.Context(), studentID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(enrollments)
}
