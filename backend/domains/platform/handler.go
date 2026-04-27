package platform

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds platform HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs platform Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

type createTemplateRequest struct {
	Key     string              `json:"key"`
	Channel NotificationChannel `json:"channel"`
	Subject *string             `json:"subject,omitempty"`
	Body    string              `json:"body"`
}

// CreateTemplate handles POST /api/v1/notification-templates (vernonedu_admin).
func (h *Handler) CreateTemplate(w http.ResponseWriter, r *http.Request) {
	var req createTemplateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.Key == "" || req.Channel == "" || req.Body == "" {
		apperrors.Render(w, apperrors.Validationf("key, channel, body are required"))
		return
	}

	tmpl, err := h.svc.CreateTemplate(r.Context(), req.Key, req.Channel, req.Subject, req.Body)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(tmpl)
}

// DeactivateTemplate handles PATCH /api/v1/notification-templates/{id}/deactivate.
func (h *Handler) DeactivateTemplate(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid template id"))
		return
	}

	if err := h.svc.DeactivateTemplate(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListMyNotifications(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))

	notifs, err := h.svc.ListMyNotifications(r.Context(), uc.ID, limit, offset)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(notifs)
}

func (h *Handler) MarkRead(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid notification id"))
		return
	}

	if err := h.svc.MarkRead(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
