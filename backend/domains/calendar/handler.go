package calendar

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) CreateEvent(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var e CalendarEvent
	if err := json.NewDecoder(r.Body).Decode(&e); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	e.CreatedBy = uc.ID
	if err := h.svc.CreateEvent(r.Context(), &e); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, e)
}

func (h *Handler) GetEvent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	e, err := h.svc.GetEvent(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, e)
}

func (h *Handler) ListEvents(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	f := ListFilter{UserID: &uc.ID}
	if v := r.URL.Query().Get("from"); v != "" {
		t, err := time.Parse(time.RFC3339, v)
		if err == nil {
			f.From = &t
		}
	}
	if v := r.URL.Query().Get("to"); v != "" {
		t, err := time.Parse(time.RFC3339, v)
		if err == nil {
			f.To = &t
		}
	}
	if v := r.URL.Query().Get("type"); v != "" {
		et := CalEventType(v)
		f.EventType = &et
	}
	evts, err := h.svc.ListEvents(r.Context(), f)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, evts)
}

func (h *Handler) UpdateEvent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	var e CalendarEvent
	if err := json.NewDecoder(r.Body).Decode(&e); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	e.ID = id
	if err := h.svc.UpdateEvent(r.Context(), &e); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) DeleteEvent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	if err := h.svc.DeleteEvent(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) AddAttendee(w http.ResponseWriter, r *http.Request) {
	eventID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	var body struct {
		UserID uuid.UUID    `json:"user_id"`
		Role   AttendeeRole `json:"role"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if err := h.svc.AddAttendee(r.Context(), eventID, body.UserID, body.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) UpdateRSVP(w http.ResponseWriter, r *http.Request) {
	eventID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var body struct {
		Status RSVPStatus `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if err := h.svc.UpdateRSVP(r.Context(), eventID, uc.ID, body.Status); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetAttendees(w http.ResponseWriter, r *http.Request) {
	eventID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	attendees, err := h.svc.GetAttendees(r.Context(), eventID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, attendees)
}

func (h *Handler) ExportUserICal(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	ical, err := h.svc.ExportICalForUser(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "text/calendar; charset=utf-8")
	w.Header().Set("Content-Disposition", "attachment; filename=vernonedu.ics")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(ical))
}

func (h *Handler) ExportEventICal(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	ical, err := h.svc.ExportICalForEvent(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "text/calendar; charset=utf-8")
	w.Header().Set("Content-Disposition", "attachment; filename=event.ics")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(ical))
}

func (h *Handler) UpsertSync(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var body struct {
		AccessToken    string     `json:"access_token"`
		RefreshToken   string     `json:"refresh_token"`
		TokenExpiresAt *time.Time `json:"token_expires_at"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	sync := &CalendarSync{
		UserID:         uc.ID,
		Provider:       ProviderGoogleCalendar,
		AccessToken:    body.AccessToken,
		RefreshToken:   body.RefreshToken,
		TokenExpiresAt: body.TokenExpiresAt,
	}
	if err := h.svc.UpsertSync(r.Context(), sync); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetSync(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	sync, err := h.svc.GetSync(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, sync)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
