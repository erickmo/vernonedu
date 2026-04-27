package platform

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

const contentTypeICal = "text/calendar; charset=utf-8"

type updateTemplateRequest struct {
	IsActive *bool   `json:"is_active,omitempty"`
	Subject  *string `json:"subject,omitempty"`
	Body     *string `json:"body,omitempty"`
}

// UpdateTemplate handles PATCH /api/v1/notification-templates/{id}.
// Body fields are optional; is_active=false triggers DeactivateTemplate.
func (h *Handler) UpdateTemplate(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid template id"))
		return
	}
	var req updateTemplateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.Subject != nil || req.Body != nil {
		if err := h.svc.UpdateTemplate(r.Context(), id, req.Subject, req.Body); err != nil {
			apperrors.Render(w, err)
			return
		}
	}
	if req.IsActive != nil && !*req.IsActive {
		if err := h.svc.DeactivateTemplate(r.Context(), id); err != nil {
			apperrors.Render(w, err)
			return
		}
	}
	w.WriteHeader(http.StatusNoContent)
}

// ListMyPreferences handles GET /api/v1/notification-preferences/me.
func (h *Handler) ListMyPreferences(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	prefs, err := h.svc.GetMyPreferences(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, prefs)
}

type upsertPreferenceRequest struct {
	TemplateKey string              `json:"template_key"`
	Channel     NotificationChannel `json:"channel"`
	Enabled     bool                `json:"enabled"`
}

// UpsertMyPreference handles PUT /api/v1/notification-preferences/me.
func (h *Handler) UpsertMyPreference(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var req upsertPreferenceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.TemplateKey == "" || req.Channel == "" {
		apperrors.Render(w, apperrors.Validationf("template_key and channel are required"))
		return
	}
	pref := &NotificationPreference{
		UserID:      uc.ID,
		TemplateKey: req.TemplateKey,
		Channel:     req.Channel,
		Enabled:     req.Enabled,
	}
	if err := h.svc.UpsertPreference(r.Context(), pref); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, pref)
}

// ExportMyICal handles GET /api/v1/calendar/export/me.ics.
func (h *Handler) ExportMyICal(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	data, err := h.svc.ExportICalForUser(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", contentTypeICal)
	w.Header().Set("Content-Disposition", `attachment; filename="calendar.ics"`)
	_, _ = w.Write(data)
}

// ExportSingleEventICal handles GET /api/v1/calendar/events/{id}/export.ics.
// Caller must be the creator or an attendee of the event.
func (h *Handler) ExportSingleEventICal(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	evt, err := h.svc.GetCalendarEvent(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	allowed, err := h.callerCanReadEvent(r.Context(), uc.ID, evt)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if !allowed {
		apperrors.Render(w, apperrors.ErrForbidden)
		return
	}
	data, err := h.svc.ExportSingleEvent(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", contentTypeICal)
	_, _ = w.Write(data)
}

// callerCanReadEvent returns true if user is creator or in attendees list.
func (h *Handler) callerCanReadEvent(ctx context.Context, userID uuid.UUID, evt *CalendarEvent) (bool, error) {
	if evt.CreatedBy != nil && *evt.CreatedBy == userID {
		return true, nil
	}
	atts, err := h.svc.ListEventAttendees(ctx, evt.ID)
	if err != nil {
		return false, err
	}
	for _, a := range atts {
		if a.UserID == userID {
			return true, nil
		}
	}
	return false, nil
}

// StartGoogleOAuth handles GET /api/v1/calendar/sync/google/authorize.
func (h *Handler) StartGoogleOAuth(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	url, err := h.svc.StartOAuthFlow(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"authorize_url": url})
}

// HandleGoogleOAuthCallback handles GET /api/v1/calendar/sync/google/callback (public).
func (h *Handler) HandleGoogleOAuthCallback(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")
	state := r.URL.Query().Get("state")
	if code == "" || state == "" {
		apperrors.Render(w, apperrors.Validationf("code and state are required"))
		return
	}
	if _, err := h.svc.HandleOAuthCallback(r.Context(), code, state); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("calendar sync connected"))
}
