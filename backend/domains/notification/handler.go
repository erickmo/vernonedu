package notification

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds HTTP handler methods for the notification domain.
type Handler struct {
	svc *Service
}

// NewHandler constructs a Handler with injected Service.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// ListNotifications lists the caller's notifications with optional filters.
func (h *Handler) ListNotifications(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	f := ListNotifFilter{RecipientID: &uc.ID}

	if v := r.URL.Query().Get("status"); v != "" {
		s := NotifStatus(v)
		f.Status = &s
	}
	if v := r.URL.Query().Get("channel"); v != "" {
		ch := Channel(v)
		f.Channel = &ch
	}

	list, err := h.svc.ListNotifications(r.Context(), f)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, list)
}

// CountUnread returns the count of unread in_app notifications for the caller.
func (h *Handler) CountUnread(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	count, err := h.svc.CountUnread(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]int{"unread_count": count})
}

// MarkRead marks an in_app notification as read for the authenticated caller.
func (h *Handler) MarkRead(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid notification id"))
		return
	}
	if err := h.svc.MarkRead(r.Context(), id, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ListPreferences lists notification preferences for the caller.
func (h *Handler) ListPreferences(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	prefs, err := h.svc.ListPreferences(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, prefs)
}

// UpsertPreference creates or updates a notification preference for the caller.
func (h *Handler) UpsertPreference(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var body struct {
		TemplateKey string  `json:"template_key"`
		Channel     Channel `json:"channel"`
		Enabled     bool    `json:"enabled"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if body.TemplateKey == "" {
		apperrors.Render(w, apperrors.Validationf("template_key is required"))
		return
	}
	pref := &NotificationPreference{
		UserID:      uc.ID,
		TemplateKey: body.TemplateKey,
		Channel:     body.Channel,
		Enabled:     body.Enabled,
	}
	if err := h.svc.UpsertPreference(r.Context(), pref); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, pref)
}

// ListTemplates returns all notification templates (admin only).
func (h *Handler) ListTemplates(w http.ResponseWriter, r *http.Request) {
	templates, err := h.svc.ListTemplates(r.Context())
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, templates)
}

// CreateTemplate creates a new notification template (admin only).
func (h *Handler) CreateTemplate(w http.ResponseWriter, r *http.Request) {
	var t NotificationTemplate
	if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if t.Key == "" || t.Body == "" {
		apperrors.Render(w, apperrors.Validationf("key and body are required"))
		return
	}
	t.IsActive = true
	if err := h.svc.CreateTemplate(r.Context(), &t); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, t)
}

// UpdateTemplate updates an existing notification template (admin only).
func (h *Handler) UpdateTemplate(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid template id"))
		return
	}
	var t NotificationTemplate
	if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	t.ID = id
	if err := h.svc.UpdateTemplate(r.Context(), &t); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// DeleteTemplate removes a notification template (admin only).
func (h *Handler) DeleteTemplate(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid template id"))
		return
	}
	if err := h.svc.DeleteTemplate(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// writeJSON encodes v as JSON and writes it with the given HTTP status.
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
