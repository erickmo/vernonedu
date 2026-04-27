package platform

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// internalStaffRoles lists roles allowed to schedule manual_internal events.
var internalStaffRoles = map[string]struct{}{
	"vernonedu_admin": {},
	"course_creator":  {},
	"dept_leader":     {},
}

// adminOrDeptLeaderRoles lists roles allowed to invite calendar attendees.
var adminOrDeptLeaderRoles = map[string]struct{}{
	"vernonedu_admin": {},
	"dept_leader":     {},
}

type createCalendarEventRequest struct {
	Title       string     `json:"title"`
	Description *string    `json:"description,omitempty"`
	StartAt     time.Time  `json:"start_at"`
	EndAt       time.Time  `json:"end_at"`
	Location    *string    `json:"location,omitempty"`
	Rrule       *string    `json:"rrule,omitempty"`
	Internal    bool       `json:"internal,omitempty"`
}

// CreateCalendarEvent handles POST /api/v1/calendar/events.
func (h *Handler) CreateCalendarEvent(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var req createCalendarEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.Internal {
		if _, ok := internalStaffRoles[uc.Role]; !ok {
			apperrors.Render(w, apperrors.ErrForbidden)
			return
		}
	}

	evt, err := h.svc.CreateManualEvent(r.Context(), CreateManualEventInput{
		Title:       req.Title,
		Description: req.Description,
		StartAt:     req.StartAt,
		EndAt:       req.EndAt,
		Location:    req.Location,
		Rrule:       req.Rrule,
		CreatorID:   uc.ID,
		Internal:    req.Internal,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, evt)
}

// ListMyCalendarEvents handles GET /api/v1/calendar/events.
func (h *Handler) ListMyCalendarEvents(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	events, err := h.svc.ListEventsByUser(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, events)
}

type updateCalendarEventRequest struct {
	Title       *string    `json:"title,omitempty"`
	Description *string    `json:"description,omitempty"`
	StartAt     *time.Time `json:"start_at,omitempty"`
	EndAt       *time.Time `json:"end_at,omitempty"`
	Location    *string    `json:"location,omitempty"`
	Rrule       *string    `json:"rrule,omitempty"`
}

// UpdateCalendarEvent handles PATCH /api/v1/calendar/events/{id}.
// Only the creator or a vernonedu_admin can update.
func (h *Handler) UpdateCalendarEvent(w http.ResponseWriter, r *http.Request) {
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
	if !canMutateEvent(uc, evt) {
		apperrors.Render(w, apperrors.ErrForbidden)
		return
	}

	var req updateCalendarEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	applyEventPatch(evt, req)
	if err := h.svc.UpdateEvent(r.Context(), evt); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, evt)
}

// DeleteCalendarEvent handles DELETE /api/v1/calendar/events/{id}.
func (h *Handler) DeleteCalendarEvent(w http.ResponseWriter, r *http.Request) {
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
	if !canMutateEvent(uc, evt) {
		apperrors.Render(w, apperrors.ErrForbidden)
		return
	}
	if err := h.svc.DeleteEvent(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type addAttendeeRequest struct {
	UserID uuid.UUID `json:"user_id"`
	Role   string    `json:"role"`
}

// AddCalendarAttendee handles POST /api/v1/calendar/events/{id}/attendees.
// Allowed for vernonedu_admin or dept_leader.
func (h *Handler) AddCalendarAttendee(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	if _, ok := adminOrDeptLeaderRoles[uc.Role]; !ok {
		apperrors.Render(w, apperrors.ErrForbidden)
		return
	}
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid event id"))
		return
	}
	var req addAttendeeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.UserID == uuid.Nil || req.Role == "" {
		apperrors.Render(w, apperrors.Validationf("user_id and role are required"))
		return
	}
	att, err := h.svc.AddAttendee(r.Context(), id, req.UserID, req.Role)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, att)
}

// canMutateEvent reports true when the caller is the event's creator or admin.
func canMutateEvent(uc *mw.UserContext, evt *CalendarEvent) bool {
	if uc.Role == "vernonedu_admin" {
		return true
	}
	if evt.CreatedBy != nil && *evt.CreatedBy == uc.ID {
		return true
	}
	return false
}

// applyEventPatch copies non-nil request fields into evt.
func applyEventPatch(evt *CalendarEvent, req updateCalendarEventRequest) {
	if req.Title != nil {
		evt.Title = *req.Title
	}
	if req.Description != nil {
		evt.Description = req.Description
	}
	if req.StartAt != nil {
		evt.StartAt = *req.StartAt
	}
	if req.EndAt != nil {
		evt.EndAt = *req.EndAt
	}
	if req.Location != nil {
		evt.Location = req.Location
	}
	if req.Rrule != nil {
		evt.Rrule = req.Rrule
	}
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
