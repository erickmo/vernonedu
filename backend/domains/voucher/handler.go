package voucher

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

const dateLayout = "2006-01-02"

// Handler holds voucher HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs a voucher Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) CreateVoucher(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		Code          string  `json:"code"`
		DiscountType  string  `json:"discount_type"`
		DiscountValue string  `json:"discount_value"`
		AssignedTo    *string `json:"assigned_to"`
		CourseID      *string `json:"course_id"`
		CourseBatchID *string `json:"course_batch_id"`
		ValidFrom     string  `json:"valid_from"`
		ValidUntil    *string `json:"valid_until"`
		MaxUses       *int    `json:"max_uses"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	discountValue, err := decimal.NewFromString(req.DiscountValue)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid discount_value"))
		return
	}

	in, err := buildCreateInput(req.Code, req.DiscountType, discountValue,
		req.AssignedTo, req.CourseID, req.CourseBatchID,
		req.ValidFrom, req.ValidUntil, req.MaxUses, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	v, err := h.svc.CreateVoucher(r.Context(), in)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(v)
}

func (h *Handler) GetVoucher(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid voucher id"))
		return
	}

	v, err := h.svc.GetVoucher(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

func (h *Handler) ListVouchers(w http.ResponseWriter, r *http.Request) {
	f := ListFilter{}
	if q := r.URL.Query().Get("is_active"); q != "" {
		b, err := strconv.ParseBool(q)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid is_active value"))
			return
		}
		f.IsActive = &b
	}
	if q := r.URL.Query().Get("code"); q != "" {
		f.Code = q
	}

	vouchers, err := h.svc.ListVouchers(r.Context(), f)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(vouchers)
}

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

func (h *Handler) ApplyVoucher(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		Code          string  `json:"code"`
		EnrollmentID  string  `json:"enrollment_id"`
		OriginalPrice string  `json:"original_price"`
		StudentID     *string `json:"student_id"`
		CourseBatchID *string `json:"course_batch_id"`
		CourseID      *string `json:"course_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	enrollmentID, err := uuid.Parse(req.EnrollmentID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment_id"))
		return
	}
	originalPrice, err := decimal.NewFromString(req.OriginalPrice)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid original_price"))
		return
	}

	in := ApplyInput{
		VoucherCode:   req.Code,
		EnrollmentID:  enrollmentID,
		OriginalPrice: originalPrice,
		CallerUserID:  uc.ID,
	}
	if err := populateOptionalUUIDs(&in, req.StudentID, req.CourseBatchID, req.CourseID); err != nil {
		apperrors.Render(w, err)
		return
	}

	usage, err := h.svc.ApplyVoucher(r.Context(), in)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(usage)
}

func (h *Handler) ListMyVouchers(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	studentIDStr := chi.URLParam(r, "studentID")
	if studentIDStr == "" {
		studentIDStr = r.URL.Query().Get("student_id")
	}

	studentID, err := uuid.Parse(studentIDStr)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student_id"))
		return
	}

	vouchers, err := h.svc.ListMyVouchers(r.Context(), studentID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(vouchers)
}

// buildCreateInput parses and maps raw request fields to CreateInput.
func buildCreateInput(
	code, discountTypeStr string,
	discountValue decimal.Decimal,
	assignedToStr, courseIDStr, batchIDStr *string,
	validFromStr string, validUntilStr *string,
	maxUses *int,
	callerID uuid.UUID,
) (CreateInput, error) {
	validFrom, err := time.Parse(dateLayout, validFromStr)
	if err != nil {
		return CreateInput{}, apperrors.Validationf("invalid valid_from date (expected YYYY-MM-DD)")
	}

	in := CreateInput{
		Code:          code,
		DiscountType:  DiscountType(discountTypeStr),
		DiscountValue: discountValue,
		ValidFrom:     validFrom,
		MaxUses:       maxUses,
		CreatedBy:     callerID,
	}

	if validUntilStr != nil {
		t, err := time.Parse(dateLayout, *validUntilStr)
		if err != nil {
			return CreateInput{}, apperrors.Validationf("invalid valid_until date (expected YYYY-MM-DD)")
		}
		in.ValidUntil = &t
	}

	if assignedToStr != nil {
		id, err := uuid.Parse(*assignedToStr)
		if err != nil {
			return CreateInput{}, apperrors.Validationf("invalid assigned_to")
		}
		in.AssignedTo = &id
	}
	if courseIDStr != nil {
		id, err := uuid.Parse(*courseIDStr)
		if err != nil {
			return CreateInput{}, apperrors.Validationf("invalid course_id")
		}
		in.CourseID = &id
	}
	if batchIDStr != nil {
		id, err := uuid.Parse(*batchIDStr)
		if err != nil {
			return CreateInput{}, apperrors.Validationf("invalid course_batch_id")
		}
		in.CourseBatchID = &id
	}
	return in, nil
}

// populateOptionalUUIDs parses optional UUID fields into ApplyInput.
func populateOptionalUUIDs(in *ApplyInput, studentIDStr, batchIDStr, courseIDStr *string) error {
	if studentIDStr != nil {
		id, err := uuid.Parse(*studentIDStr)
		if err != nil {
			return apperrors.Validationf("invalid student_id")
		}
		in.StudentID = &id
	}
	if batchIDStr != nil {
		id, err := uuid.Parse(*batchIDStr)
		if err != nil {
			return apperrors.Validationf("invalid course_batch_id")
		}
		in.CourseBatchID = &id
	}
	if courseIDStr != nil {
		id, err := uuid.Parse(*courseIDStr)
		if err != nil {
			return apperrors.Validationf("invalid course_id")
		}
		in.CourseID = &id
	}
	return nil
}
