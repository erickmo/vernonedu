package profit_split

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds profit_split HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs profit_split Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// ─── GlobalSettings ──────────────────────────────────────────────────────────

func (h *Handler) GetGlobalSettings(w http.ResponseWriter, r *http.Request) {
	gs, err := h.svc.GetGlobalSettings(r.Context())
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, gs)
}

func (h *Handler) UpdateGlobalSettings(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		ID               string `json:"id"`
		VernonEduPct     string `json:"vernonedu_pct"`
		CourseCreatorPct string `json:"course_creator_pct"`
		DeptLeaderPct    string `json:"dept_leader_pct"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	id, err := uuid.Parse(req.ID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	vPct, ccPct, dlPct, err := parsePcts(req.VernonEduPct, req.CourseCreatorPct, req.DeptLeaderPct)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	gs, svcErr := h.svc.UpdateGlobalSettings(r.Context(), UpdateGlobalSettingsInput{
		ID: id, VernonEduPct: vPct, CourseCreatorPct: ccPct, DeptLeaderPct: dlPct,
		UpdatedBy: uc.ID, UpdatedByRole: uc.Role,
	})
	if svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	writeJSON(w, http.StatusOK, gs)
}

// ─── CourseOverride ───────────────────────────────────────────────────────────

func (h *Handler) CreateCourseOverride(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		CourseID         string `json:"course_id"`
		VernonEduPct     string `json:"vernonedu_pct"`
		CourseCreatorPct string `json:"course_creator_pct"`
		DeptLeaderPct    string `json:"dept_leader_pct"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	courseID, err := uuid.Parse(req.CourseID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course_id"))
		return
	}
	vPct, ccPct, dlPct, err := parsePcts(req.VernonEduPct, req.CourseCreatorPct, req.DeptLeaderPct)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	co, svcErr := h.svc.CreateCourseOverride(r.Context(), CreateCourseOverrideInput{
		CourseID: courseID, VernonEduPct: vPct, CourseCreatorPct: ccPct, DeptLeaderPct: dlPct,
		OverriddenBy: uc.ID, OverriddenByRole: uc.Role,
	})
	if svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	writeJSON(w, http.StatusCreated, co)
}

func (h *Handler) GetCourseOverride(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "courseID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course_id"))
		return
	}
	co, svcErr := h.svc.GetCourseOverride(r.Context(), courseID)
	if svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	writeJSON(w, http.StatusOK, co)
}

// ─── ExtraRevenue ─────────────────────────────────────────────────────────────

func (h *Handler) AddExtraRevenue(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		CourseBatchID string `json:"course_batch_id"`
		Label         string `json:"label"`
		Amount        string `json:"amount"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	batchID, err := uuid.Parse(req.CourseBatchID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course_batch_id"))
		return
	}
	amount, err := decimal.NewFromString(req.Amount)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid amount"))
		return
	}

	er, svcErr := h.svc.AddExtraRevenue(r.Context(), AddExtraRevenueInput{
		CourseBatchID: batchID, Label: req.Label, Amount: amount,
		AddedBy: uc.ID, AddedByRole: uc.Role,
	})
	if svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	writeJSON(w, http.StatusCreated, er)
}

func (h *Handler) ApproveExtraRevenue(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	if svcErr := h.svc.ApproveExtraRevenue(r.Context(), id, uc.ID, uc.Role); svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RejectExtraRevenue(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	if svcErr := h.svc.RejectExtraRevenue(r.Context(), id, uc.ID, uc.Role); svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── BatchCostLineItem ────────────────────────────────────────────────────────

func (h *Handler) CreateBatchCostLineItem(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		CourseBatchID string `json:"course_batch_id"`
		TemplateRef   string `json:"template_ref"`
		Label         string `json:"label"`
		Amount        string `json:"amount"`
		CostType      string `json:"cost_type"`
		ReferenceType string `json:"reference_type"`
		ReferenceID   string `json:"reference_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	batchID, err := uuid.Parse(req.CourseBatchID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course_batch_id"))
		return
	}
	amount, err := decimal.NewFromString(req.Amount)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid amount"))
		return
	}

	in := CreateBatchCostInput{
		CourseBatchID: batchID,
		Label:         req.Label,
		Amount:        amount,
		CostType:      CostType(req.CostType),
		ReferenceType: CostRefType(req.ReferenceType),
		CreatedBy:     uc.ID,
	}
	if req.TemplateRef != "" {
		tid, parseErr := uuid.Parse(req.TemplateRef)
		if parseErr == nil {
			in.TemplateRef = &tid
		}
	}
	if req.ReferenceID != "" {
		rid, parseErr := uuid.Parse(req.ReferenceID)
		if parseErr == nil {
			in.ReferenceID = &rid
		}
	}

	item, svcErr := h.svc.CreateBatchCostLineItem(r.Context(), in)
	if svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (h *Handler) RemoveBatchCostLineItem(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	if svcErr := h.svc.RemoveBatchCostLineItem(r.Context(), id); svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── BatchSplitRecord ─────────────────────────────────────────────────────────

func (h *Handler) GetBatchSplitRecord(w http.ResponseWriter, r *http.Request) {
	batchID, err := uuid.Parse(chi.URLParam(r, "batchID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch_id"))
		return
	}
	rec, svcErr := h.svc.GetBatchSplitRecord(r.Context(), batchID)
	if svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	writeJSON(w, http.StatusOK, rec)
}

// ─── PeriodBonus ─────────────────────────────────────────────────────────────

func (h *Handler) CalculatePeriodBonus(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		Period string `json:"period"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	pb, svcErr := h.svc.CalculatePeriodBonus(r.Context(), CalculatePeriodBonusInput{
		Period:       req.Period,
		CalculatedBy: uc.ID,
	})
	if svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	writeJSON(w, http.StatusCreated, pb)
}

func (h *Handler) GetPeriodBonus(w http.ResponseWriter, r *http.Request) {
	period := chi.URLParam(r, "period")
	pb, svcErr := h.svc.GetPeriodBonus(r.Context(), period)
	if svcErr != nil {
		apperrors.Render(w, svcErr)
		return
	}
	writeJSON(w, http.StatusOK, pb)
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func parsePcts(v, cc, dl string) (decimal.Decimal, decimal.Decimal, decimal.Decimal, *apperrors.AppError) {
	vPct, err := decimal.NewFromString(v)
	if err != nil {
		return decimal.Zero, decimal.Zero, decimal.Zero, apperrors.Validationf("invalid vernonedu_pct")
	}
	ccPct, err := decimal.NewFromString(cc)
	if err != nil {
		return decimal.Zero, decimal.Zero, decimal.Zero, apperrors.Validationf("invalid course_creator_pct")
	}
	dlPct, err := decimal.NewFromString(dl)
	if err != nil {
		return decimal.Zero, decimal.Zero, decimal.Zero, apperrors.Validationf("invalid dept_leader_pct")
	}
	return vPct, ccPct, dlPct, nil
}
