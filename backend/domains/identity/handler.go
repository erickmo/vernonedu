package identity

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

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

