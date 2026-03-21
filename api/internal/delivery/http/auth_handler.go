package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"golang.org/x/crypto/bcrypt"

	"github.com/vernonedu/entrepreneurship-api/internal/command/register_user"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/user"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/jwtutil"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type AuthHandler struct {
	cmdBus       commandbus.CommandBus
	qryBus       querybus.QueryBus
	userReadRepo user.ReadRepository
	jwtUtil      *jwtutil.JWTUtil
}

func NewAuthHandler(
	cmdBus commandbus.CommandBus,
	qryBus querybus.QueryBus,
	userReadRepo user.ReadRepository,
	jwtUtil *jwtutil.JWTUtil,
) *AuthHandler {
	return &AuthHandler{
		cmdBus:       cmdBus,
		qryBus:       qryBus,
		userReadRepo: userReadRepo,
		jwtUtil:      jwtUtil,
	}
}

func writeJSON(w http.ResponseWriter, status int, body interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		log.Error().Err(err).Msg("failed to encode response")
	}
}

func writeError(w http.ResponseWriter, status int, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(map[string]string{"error": msg}); err != nil {
		log.Error().Err(err).Msg("failed to encode error response")
	}
}

type RegisterRequest struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &register_user.RegisterUserCommand{
		Name:     req.Name,
		Email:    req.Email,
		Password: req.Password,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to register user")
		writeError(w, http.StatusInternalServerError, "failed to register user")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "user registered successfully"})
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginUserInfo struct {
	ID    uuid.UUID `json:"id"`
	Name  string    `json:"name"`
	Email string    `json:"email"`
	Role  string    `json:"role"`
}

type LoginResponse struct {
	AccessToken  string        `json:"access_token"`
	RefreshToken string        `json:"refresh_token"`
	User         LoginUserInfo `json:"user"`
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Email == "" || req.Password == "" {
		writeError(w, http.StatusBadRequest, "email and password are required")
		return
	}

	u, err := h.userReadRepo.GetByEmail(r.Context(), req.Email)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid credentials")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(req.Password)); err != nil {
		writeError(w, http.StatusUnauthorized, "invalid credentials")
		return
	}

	tokenPair, err := h.jwtUtil.GenerateTokenPair(u.ID.String(), u.Email, u.Role)
	if err != nil {
		log.Error().Err(err).Msg("failed to generate token pair")
		writeError(w, http.StatusInternalServerError, "internal server error")
		return
	}

	writeJSON(w, http.StatusOK, LoginResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		User: LoginUserInfo{
			ID:    u.ID,
			Name:  u.Name,
			Email: u.Email,
			Role:  u.Role,
		},
	})
}

type MeResponse struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	Email        string    `json:"email"`
	Role         string    `json:"role"`
	DepartmentID *string   `json:"department_id"`
	DepartmentName *string `json:"department_name"`
	AvatarURL    *string   `json:"avatar_url"`
	IsActive     bool      `json:"is_active"`
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	userIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	if userIDStr == "" {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid user id in token")
		return
	}

	u, err := h.userReadRepo.GetByID(r.Context(), userID)
	if err != nil {
		log.Error().Err(err).Str("user_id", userIDStr).Msg("failed to get user")
		writeError(w, http.StatusNotFound, "user not found")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"data": MeResponse{
			ID:             u.ID,
			Name:           u.Name,
			Email:          u.Email,
			Role:           u.Role,
			DepartmentID:   nil,
			DepartmentName: nil,
			AvatarURL:      nil,
			IsActive:       true,
		},
	})
}

func RegisterAuthRoutes(h *AuthHandler, r chi.Router, jwtMiddleware func(http.Handler) http.Handler) {
	r.Post("/api/v1/auth/register", h.Register)
	r.Post("/api/v1/auth/login", h.Login)
	r.With(jwtMiddleware).Get("/api/v1/auth/me", h.Me)
}
