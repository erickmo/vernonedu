package enrollment

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// dateLayout is the canonical YYYY-MM-DD layout for voucher validity dates.
const dateLayout = "2006-01-02"

// writeJSON writes a JSON-encoded body with the given status code.
func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

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
		StudentID     string  `json:"student_id"`
		CourseBatchID string  `json:"course_batch_id"`
		Format        string  `json:"format"`
		Mode          string  `json:"mode"`
		PartnerID     *string `json:"partner_id,omitempty"`
		FranchiseeID  *string `json:"franchisee_id,omitempty"`
		VoucherCode   string  `json:"voucher_code"`
		Source        string  `json:"source"`
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
	var partnerID *uuid.UUID
	if req.PartnerID != nil && *req.PartnerID != "" {
		id, perr := uuid.Parse(*req.PartnerID)
		if perr != nil {
			apperrors.Render(w, apperrors.Validationf("invalid partner_id"))
			return
		}
		partnerID = &id
	}
	var franchiseeID *uuid.UUID
	if req.FranchiseeID != nil && *req.FranchiseeID != "" {
		id, ferr := uuid.Parse(*req.FranchiseeID)
		if ferr != nil {
			apperrors.Render(w, apperrors.Validationf("invalid franchisee_id"))
			return
		}
		franchiseeID = &id
	}

	enrollment, err := h.svc.Enroll(r.Context(), EnrollInput{
		StudentID:     studentID,
		CourseBatchID: batchID,
		Format:        EnrollmentFormat(req.Format),
		Mode:          EnrollmentMode(req.Mode),
		PartnerID:     partnerID,
		FranchiseeID:  franchiseeID,
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

	if err := h.svc.Drop(r.Context(), id); err != nil {
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

	if err := h.svc.MarkCompleted(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ListMyEnrollments returns enrollments for the authenticated student
// (resolves user_id -> student_id via identity.students join).
func (h *Handler) ListMyEnrollments(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	out, err := h.svc.ListMyEnrollments(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

// createVoucherRequest is the JSON payload for POST /vouchers.
type createVoucherRequest struct {
	Code          string     `json:"code"`
	DiscountType  string     `json:"discount_type"`
	DiscountValue string     `json:"discount_value"`
	AssignedTo    *uuid.UUID `json:"assigned_to,omitempty"`
	CourseID      *uuid.UUID `json:"course_id,omitempty"`
	CourseBatchID *uuid.UUID `json:"course_batch_id,omitempty"`
	ValidFrom     string     `json:"valid_from"`
	ValidUntil    *string    `json:"valid_until,omitempty"`
	MaxUses       *int       `json:"max_uses,omitempty"`
}

// CreateVoucher handles POST /vouchers (admin).
func (h *Handler) CreateVoucher(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var req createVoucherRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	val, err := decimal.NewFromString(req.DiscountValue)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid discount_value"))
		return
	}
	vf, err := time.Parse(dateLayout, req.ValidFrom)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid valid_from"))
		return
	}
	var vu *time.Time
	if req.ValidUntil != nil && *req.ValidUntil != "" {
		t, err := time.Parse(dateLayout, *req.ValidUntil)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid valid_until"))
			return
		}
		vu = &t
	}
	out, err := h.svc.CreateVoucher(r.Context(), CreateVoucherInput{
		Code:          req.Code,
		DiscountType:  DiscountType(req.DiscountType),
		DiscountValue: val,
		AssignedTo:    req.AssignedTo,
		CourseID:      req.CourseID,
		CourseBatchID: req.CourseBatchID,
		ValidFrom:     vf,
		ValidUntil:    vu,
		MaxUses:       req.MaxUses,
		CreatedBy:     uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, out)
}

// assignVoucherRequest is the JSON payload for PATCH /vouchers/{id}/assign.
type assignVoucherRequest struct {
	StudentID uuid.UUID `json:"student_id"`
}

// AssignVoucher handles PATCH /vouchers/{id}/assign (admin).
func (h *Handler) AssignVoucher(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid voucher id"))
		return
	}
	var req assignVoucherRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if err := h.svc.AssignVoucher(r.Context(), id, req.StudentID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// DeactivateVoucher handles PATCH /vouchers/{id}/deactivate (admin).
func (h *Handler) DeactivateVoucher(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid voucher id"))
		return
	}
	if err := h.svc.DeactivateVoucher(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ListMyVouchers handles GET /vouchers/me (student) — returns vouchers
// assigned to the student linked to the authenticated user.
func (h *Handler) ListMyVouchers(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	out, err := h.svc.ListVouchersAssignedToUser(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}

// redeemVoucherRequest is the JSON payload for POST /vouchers/redeem.
type redeemVoucherRequest struct {
	Code string `json:"code"`
}

// RedeemVoucher handles POST /vouchers/redeem (student) — validates a code
// and returns the voucher record.
func (h *Handler) RedeemVoucher(w http.ResponseWriter, r *http.Request) {
	var req redeemVoucherRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.Code == "" {
		apperrors.Render(w, apperrors.Validationf("code required"))
		return
	}
	v, err := h.svc.GetVoucherByCode(r.Context(), req.Code)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, v)
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
