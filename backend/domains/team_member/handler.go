package team_member

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

// Handler holds team_member HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs team_member Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// ── TeamMember endpoints ──────────────────────────────────────

func (h *Handler) CreateTeamMember(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		UserID           string `json:"user_id"`
		FullName         string `json:"full_name"`
		Phone            string `json:"phone"`
		DepartmentID     string `json:"department_id"`
		EmploymentStatus string `json:"employment_status"`
		JoinedAt         string `json:"joined_at"`
		IsFacilitator    bool   `json:"is_facilitator"`
		Specialization   string `json:"specialization"`
		Bio              string `json:"bio"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	userID, err := uuid.Parse(req.UserID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid user_id"))
		return
	}

	joinedAt, err := time.Parse("2006-01-02", req.JoinedAt)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid joined_at: use YYYY-MM-DD"))
		return
	}

	var deptID *uuid.UUID
	if req.DepartmentID != "" {
		id, err := uuid.Parse(req.DepartmentID)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid department_id"))
			return
		}
		deptID = &id
	}

	m, err := h.svc.CreateTeamMember(r.Context(), CreateMemberInput{
		UserID:           userID,
		FullName:         req.FullName,
		Phone:            req.Phone,
		DepartmentID:     deptID,
		EmploymentStatus: EmploymentStatus(req.EmploymentStatus),
		JoinedAt:         joinedAt,
		IsFacilitator:    req.IsFacilitator,
		Specialization:   req.Specialization,
		Bio:              req.Bio,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(m)
}

func (h *Handler) GetTeamMember(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid team member id"))
		return
	}

	m, err := h.svc.GetTeamMember(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(m)
}

func (h *Handler) ListTeamMembers(w http.ResponseWriter, r *http.Request) {
	members, err := h.svc.ListTeamMembers(r.Context())
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(members)
}

// ── FeeTier endpoints ─────────────────────────────────────────

func (h *Handler) CreateFeeTier(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		Name            string `json:"name"`
		AmountPerClass  string `json:"amount_per_class"`
		AmountPerCourse string `json:"amount_per_course"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	in := CreateFeeTierInput{Name: req.Name, CreatedBy: uc.ID}

	if req.AmountPerClass != "" {
		v, err := decimal.NewFromString(req.AmountPerClass)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid amount_per_class"))
			return
		}
		in.AmountPerClass = &v
	}
	if req.AmountPerCourse != "" {
		v, err := decimal.NewFromString(req.AmountPerCourse)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid amount_per_course"))
			return
		}
		in.AmountPerCourse = &v
	}

	t, err := h.svc.CreateFeeTier(r.Context(), in)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(t)
}

func (h *Handler) ListFeeTiers(w http.ResponseWriter, r *http.Request) {
	tiers, err := h.svc.ListFeeTiers(r.Context())
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(tiers)
}

// ── Proposal endpoints ────────────────────────────────────────

func (h *Handler) CreateProposal(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req struct {
		CourseID      string `json:"course_id"`
		ProposedByID  string `json:"proposed_by_id"`
		FacilitatorID string `json:"facilitator_id"`
		FeeTierID     string `json:"fee_tier_id"`
		FeeBasis      string `json:"fee_basis"`
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
	proposedByID, err := uuid.Parse(req.ProposedByID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid proposed_by_id"))
		return
	}
	facilitatorID, err := uuid.Parse(req.FacilitatorID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid facilitator_id"))
		return
	}
	feeTierID, err := uuid.Parse(req.FeeTierID)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid fee_tier_id"))
		return
	}

	p, err := h.svc.CreateProposal(r.Context(), CreateProposalInput{
		CourseID:       courseID,
		ProposedByID:   proposedByID,
		ProposerUserID: uc.ID,
		FacilitatorID:  facilitatorID,
		FeeTierID:      feeTierID,
		FeeBasis:       FeeBasis(req.FeeBasis),
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(p)
}

func (h *Handler) GetProposal(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid proposal id"))
		return
	}

	p, err := h.svc.GetProposal(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(p)
}

func (h *Handler) DeptLeaderReview(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid proposal id"))
		return
	}

	var req struct {
		Status string  `json:"status"`
		Note   *string `json:"note"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	if err := h.svc.DeptLeaderReview(r.Context(), ReviewInput{
		ProposalID: id,
		Status:     ReviewStatus(req.Status),
		Note:       req.Note,
	}); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) AcademicLeaderReview(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid proposal id"))
		return
	}

	var req struct {
		Status string  `json:"status"`
		Note   *string `json:"note"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	if err := h.svc.AcademicLeaderReview(r.Context(), ReviewInput{
		ProposalID: id,
		Status:     ReviewStatus(req.Status),
		Note:       req.Note,
	}); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
