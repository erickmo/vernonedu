package identity

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// ─── Admin endpoints ──────────────────────────────────────────────────────────

func (h *Handler) ListStudents(w http.ResponseWriter, r *http.Request) {
	f := StudentFilter{
		Search:  r.URL.Query().Get("search"),
		SortBy:  r.URL.Query().Get("sort_by"),
		SortDir: r.URL.Query().Get("sort_dir"),
	}
	if src := r.URL.Query().Get("source"); src != "" {
		s := StudentSource(src)
		f.Source = &s
	}
	if pidStr := r.URL.Query().Get("partner_id"); pidStr != "" {
		pid, err := uuid.Parse(pidStr)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid partner_id"))
			return
		}
		f.PartnerID = &pid
	}
	if pcStr := r.URL.Query().Get("profile_complete"); pcStr != "" {
		pc := pcStr == "true"
		f.ProfileComplete = &pc
	}
	f.Limit, _ = strconv.Atoi(r.URL.Query().Get("limit"))
	f.Offset, _ = strconv.Atoi(r.URL.Query().Get("offset"))

	students, err := h.svc.ListStudentsFiltered(r.Context(), f)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	total, err := h.svc.CountStudentsFiltered(r.Context(), f)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"data":   students,
		"total":  total,
		"limit":  f.Limit,
		"offset": f.Offset,
	})
}

func (h *Handler) GetStudent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
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

func (h *Handler) UpdateStudent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}
	var req struct {
		Name      string        `json:"name"`
		Email     string        `json:"email"`
		Phone     string        `json:"phone"`
		Source    StudentSource `json:"source"`
		PartnerID *uuid.UUID    `json:"partner_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.Name == "" || req.Email == "" {
		apperrors.Render(w, apperrors.Validationf("name, email are required"))
		return
	}
	student, err := h.svc.UpdateStudent(r.Context(), id, UpdateStudentInput{
		Name: req.Name, Email: req.Email, Phone: req.Phone,
		Source: req.Source, PartnerID: req.PartnerID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(student)
}

func (h *Handler) GetStudentProfileByID(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}
	profile, err := h.svc.GetStudentProfile(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profile)
}

func (h *Handler) UpdateStudentProfileByAdmin(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}
	h.handleProfileUpdate(w, r, id)
}

// ─── Student self-service endpoints ──────────────────────────────────────────

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
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(student)
}

func (h *Handler) UpdateMyStudentProfile(w http.ResponseWriter, r *http.Request) {
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
	h.handleProfileUpdate(w, r, student.ID)
}

// ─── Shared helper ────────────────────────────────────────────────────────────

func (h *Handler) handleProfileUpdate(w http.ResponseWriter, r *http.Request, studentID uuid.UUID) {
	var req struct {
		DateOfBirth *string `json:"date_of_birth"`
		Gender      *string `json:"gender"`
		IDType      *string `json:"id_type"`
		IDNumber    *string `json:"id_number"`
		Address     *string `json:"address"`
		City        *string `json:"city"`
		Province    *string `json:"province"`
		PostalCode  *string `json:"postal_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	var dob *time.Time
	if req.DateOfBirth != nil {
		dobParsed, err := time.Parse("2006-01-02", *req.DateOfBirth)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid date_of_birth format, use YYYY-MM-DD"))
			return
		}
		dob = &dobParsed
	}

	profile, err := h.svc.UpdateStudentProfile(r.Context(), studentID, UpdateStudentProfileInput{
		DateOfBirth: dob, Gender: req.Gender, IDType: req.IDType, IDNumber: req.IDNumber,
		Address: req.Address, City: req.City, Province: req.Province, PostalCode: req.PostalCode,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profile)
}
