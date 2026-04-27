package identity

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// writeJSON writes a JSON response with the given status code.
func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

// Handler holds HTTP handlers for the identity domain.
type Handler struct {
	svc *Service
	cfg *config.Config
}

// NewHandler constructs an identity Handler.
func NewHandler(svc *Service, cfg *config.Config) *Handler {
	return &Handler{svc: svc, cfg: cfg}
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
		Name     string `json:"name"`
		Phone    string `json:"phone"`
		Role     string `json:"role"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	if req.Email == "" || req.Password == "" || req.Name == "" {
		apperrors.Render(w, apperrors.Validationf("email, password, name are required"))
		return
	}

	role := UserRole(req.Role)
	if role == "" {
		role = RoleStudent
	}

	user, err := h.svc.Register(r.Context(), RegisterInput{
		Email:    req.Email,
		Password: req.Password,
		Name:     req.Name,
		Phone:    req.Phone,
		Role:     role,
		Source:   SourceB2C,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(user)
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	out, err := h.svc.Login(r.Context(), req.Email, req.Password)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{"token": out.Token})
}

func (h *Handler) GetMe(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	user, err := h.svc.GetUser(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(user)
}

func (h *Handler) ListStudents(w http.ResponseWriter, r *http.Request) {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))

	students, err := h.svc.ListStudents(r.Context(), limit, offset)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(students)
}

func (h *Handler) GetStudent(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}

	student, err := h.svc.GetStudentByID(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(student)
}

func (h *Handler) DeactivateUser(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid user id"))
		return
	}

	if err := h.svc.DeactivateUser(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListDepartments(w http.ResponseWriter, r *http.Request) {
	depts, err := h.svc.ListDepartments(r.Context())
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(depts)
}

// GetMyStudent — GET /students/me — returns the caller's student record.
func (h *Handler) GetMyStudent(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	student, err := h.svc.GetStudentByUserID(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, student)
}

type updateProfileRequest struct {
	DateOfBirth *string `json:"date_of_birth,omitempty"`
	Gender      *string `json:"gender,omitempty"`
	IDType      *string `json:"id_type,omitempty"`
	IDNumber    *string `json:"id_number,omitempty"`
	Address     *string `json:"address,omitempty"`
	City        *string `json:"city,omitempty"`
	Province    *string `json:"province,omitempty"`
	PostalCode  *string `json:"postal_code,omitempty"`
}

// UpdateOwnProfile — PUT /students/me/profile.
func (h *Handler) UpdateOwnProfile(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var req updateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	in := ProfileInput{
		Gender: req.Gender, IDType: req.IDType, IDNumber: req.IDNumber,
		Address: req.Address, City: req.City, Province: req.Province, PostalCode: req.PostalCode,
	}
	if req.DateOfBirth != nil {
		t, err := time.Parse("2006-01-02", *req.DateOfBirth)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid date_of_birth"))
			return
		}
		in.DateOfBirth = &t
	}
	student, err := h.svc.GetStudentByUserID(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	p, err := h.svc.UpdateStudentProfile(r.Context(), student.ID, in)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

type createTeamMemberRequest struct {
	UserID           uuid.UUID  `json:"user_id"`
	FullName         string     `json:"full_name"`
	Phone            string     `json:"phone"`
	Role             string     `json:"role"`
	DepartmentID     *uuid.UUID `json:"department_id,omitempty"`
	EmploymentStatus string     `json:"employment_status,omitempty"`
	IsFacilitator   bool       `json:"is_facilitator,omitempty"`
}

// CreateTeamMember — POST /team-members.
func (h *Handler) CreateTeamMember(w http.ResponseWriter, r *http.Request) {
	var req createTeamMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.UserID == uuid.Nil || req.Role == "" {
		apperrors.Render(w, apperrors.Validationf("user_id and role are required"))
		return
	}
	tm, err := h.svc.CreateTeamMember(r.Context(), CreateTeamMemberInput{
		UserID:           req.UserID,
		FullName:         req.FullName,
		Phone:            req.Phone,
		Role:             UserRole(req.Role),
		DepartmentID:     req.DepartmentID,
		EmploymentStatus: EmploymentStatus(req.EmploymentStatus),
		IsFacilitator:    req.IsFacilitator,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, tm)
}

type updateStatusRequest struct {
	Status string `json:"status"`
}

// UpdateTeamMemberStatus — PATCH /team-members/{id}/status.
func (h *Handler) UpdateTeamMemberStatus(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid team member id"))
		return
	}
	var req updateStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if err := h.svc.UpdateTeamMemberStatus(r.Context(), id, EmploymentStatus(req.Status)); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// DeactivateTeamMember — DELETE /team-members/{id}.
func (h *Handler) DeactivateTeamMember(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid team member id"))
		return
	}
	if err := h.svc.DeactivateTeamMember(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type createFeeTierRequest struct {
	Name            string  `json:"name"`
	AmountPerClass  *string `json:"amount_per_class,omitempty"`
	AmountPerCourse *string `json:"amount_per_course,omitempty"`
}

func parseDecimalPtr(s *string) (*decimal.Decimal, error) {
	if s == nil || *s == "" {
		return nil, nil
	}
	d, err := decimal.NewFromString(*s)
	if err != nil {
		return nil, err
	}
	return &d, nil
}

// CreateFeeTier — POST /fee-tiers.
func (h *Handler) CreateFeeTier(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var req createFeeTierRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	perClass, err := parseDecimalPtr(req.AmountPerClass)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid amount_per_class"))
		return
	}
	perCourse, err := parseDecimalPtr(req.AmountPerCourse)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid amount_per_course"))
		return
	}
	ft, err := h.svc.CreateFeeTier(r.Context(), CreateFeeTierInput{
		Name:            req.Name,
		AmountPerClass:  perClass,
		AmountPerCourse: perCourse,
		CreatedBy:       uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, ft)
}

// ListFeeTiers — GET /fee-tiers.
func (h *Handler) ListFeeTiers(w http.ResponseWriter, r *http.Request) {
	includeInactive := r.URL.Query().Get("include_inactive") == "true"
	tiers, err := h.svc.ListFeeTiers(r.Context(), includeInactive)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, tiers)
}

// DeactivateFeeTier — PATCH /fee-tiers/{id}/deactivate.
func (h *Handler) DeactivateFeeTier(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid fee tier id"))
		return
	}
	if err := h.svc.DeactivateFeeTier(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type proposeRequest struct {
	CourseID                uuid.UUID `json:"course_id"`
	FacilitatorTeamMemberID uuid.UUID `json:"facilitator_team_member_id"`
	FeeTierID               uuid.UUID `json:"fee_tier_id"`
	FeeBasis                string    `json:"fee_basis"`
}

// ProposeFacilitator — POST /facilitator-proposals.
func (h *Handler) ProposeFacilitator(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var req proposeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	tm, err := h.svc.GetTeamMemberByUserID(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	p, err := h.svc.ProposeFacilitator(r.Context(), ProposeFacilitatorInput{
		ProposedByTeamMemberID:  tm.ID,
		CourseID:                req.CourseID,
		FacilitatorTeamMemberID: req.FacilitatorTeamMemberID,
		FeeTierID:               req.FeeTierID,
		FeeBasis:                FeeBasis(req.FeeBasis),
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, p)
}

type reviewRequest struct {
	Note *string `json:"note,omitempty"`
}

// reviewParams parses proposal id + reviewer team member from request.
func (h *Handler) reviewParams(r *http.Request) (uuid.UUID, uuid.UUID, *string, error) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		return uuid.Nil, uuid.Nil, nil, apperrors.Validationf("invalid proposal id")
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		return uuid.Nil, uuid.Nil, nil, apperrors.ErrUnauthorized
	}
	var req reviewRequest
	if r.ContentLength > 0 {
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			return uuid.Nil, uuid.Nil, nil, apperrors.Validationf("invalid request body")
		}
	}
	tm, err := h.svc.GetTeamMemberByUserID(r.Context(), uc.ID)
	if err != nil {
		return uuid.Nil, uuid.Nil, nil, err
	}
	return id, tm.ID, req.Note, nil
}

// ApproveByDeptLeader — POST /facilitator-proposals/{id}/dept-leader-approve.
func (h *Handler) ApproveByDeptLeader(w http.ResponseWriter, r *http.Request) {
	id, reviewerID, note, err := h.reviewParams(r)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.ApproveProposalDeptLeader(r.Context(), id, reviewerID, note); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// RejectByDeptLeader — POST /facilitator-proposals/{id}/dept-leader-reject.
func (h *Handler) RejectByDeptLeader(w http.ResponseWriter, r *http.Request) {
	id, reviewerID, note, err := h.reviewParams(r)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.RejectProposalDeptLeader(r.Context(), id, reviewerID, note); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ApproveByAcademicLeader — POST /facilitator-proposals/{id}/academic-leader-approve.
func (h *Handler) ApproveByAcademicLeader(w http.ResponseWriter, r *http.Request) {
	id, reviewerID, note, err := h.reviewParams(r)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.ApproveProposalAcademicLeader(r.Context(), id, reviewerID, note); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// RejectByAcademicLeader — POST /facilitator-proposals/{id}/academic-leader-reject.
func (h *Handler) RejectByAcademicLeader(w http.ResponseWriter, r *http.Request) {
	id, reviewerID, note, err := h.reviewParams(r)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.RejectProposalAcademicLeader(r.Context(), id, reviewerID, note); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

