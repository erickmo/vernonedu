package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createcalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/create_calendar_event"
	deletecalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/delete_calendar_event"
	updatecalendarevent "github.com/vernonedu/entrepreneurship-api/internal/command/update_calendar_event"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
	getcalendarevent "github.com/vernonedu/entrepreneurship-api/internal/query/get_calendar_event"
	listcalendarevents "github.com/vernonedu/entrepreneurship-api/internal/query/list_calendar_events"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// CalendarHandler handles HTTP requests for the calendar domain.
type CalendarHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewCalendarHandler constructs a CalendarHandler.
func NewCalendarHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *CalendarHandler {
	return &CalendarHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// RegisterCalendarRoutes registers all calendar routes onto the given router.
func RegisterCalendarRoutes(h *CalendarHandler, r chi.Router) {
	r.Get("/api/v1/calendar/events", h.ListEvents)
	r.Post("/api/v1/calendar/events", h.CreateEvent)
	r.Get("/api/v1/calendar/events/{id}", h.GetEvent)
	r.Put("/api/v1/calendar/events/{id}", h.UpdateEvent)
	r.Delete("/api/v1/calendar/events/{id}", h.DeleteEvent)
}

// ListEvents godoc
// @Summary      List calendar events
// @Description  Returns all calendar events in the given month/year.
// @Tags         calendar
// @Produce      json
// @Param        month  query  int  false  "Month (1-12)"
// @Param        year   query  int  false  "Year"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events [get]
func (h *CalendarHandler) ListEvents(w http.ResponseWriter, r *http.Request) {
	month, _ := strconv.Atoi(r.URL.Query().Get("month"))
	year, _ := strconv.Atoi(r.URL.Query().Get("year"))
	if year == 0 {
		year = time.Now().Year()
	}
	if month == 0 {
		month = int(time.Now().Month())
	}

	result, err := h.qryBus.Execute(r.Context(), &listcalendarevents.ListCalendarEventsQuery{
		Year: year, Month: month,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list calendar events")
		writeError(w, http.StatusInternalServerError, "failed to list calendar events")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// GetEvent godoc
// @Summary      Get calendar event
// @Description  Returns a single calendar event by ID.
// @Tags         calendar
// @Produce      json
// @Param        id  path  string  true  "Event ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events/{id} [get]
func (h *CalendarHandler) GetEvent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid event id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getcalendarevent.GetCalendarEventQuery{ID: id})
	if err != nil {
		if errors.Is(err, calendar.ErrCalendarEventNotFound) {
			writeError(w, http.StatusNotFound, "event not found")
			return
		}
		log.Error().Err(err).Msg("failed to get calendar event")
		writeError(w, http.StatusInternalServerError, "failed to get calendar event")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// CreateEvent godoc
// @Summary      Create calendar event
// @Description  Creates a new manual calendar event.
// @Tags         calendar
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "Event data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events [post]
func (h *CalendarHandler) CreateEvent(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Title          string `json:"title"`
		Description    string `json:"description"`
		EventType      string `json:"event_type"`
		StartAt        string `json:"start_at"`
		EndAt          string `json:"end_at"`
		IsAllDay       bool   `json:"is_all_day"`
		RecurrenceRule string `json:"recurrence_rule"`
		Location       string `json:"location"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	userID := pkgmiddleware.GetUserIDFromContext(r.Context())

	cmd := &createcalendarevent.CreateCalendarEventCommand{
		Title:          body.Title,
		Description:    body.Description,
		EventType:      body.EventType,
		StartAt:        body.StartAt,
		EndAt:          body.EndAt,
		IsAllDay:       body.IsAllDay,
		RecurrenceRule: body.RecurrenceRule,
		Location:       body.Location,
		CreatedBy:      userID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create calendar event")
		writeError(w, http.StatusInternalServerError, "failed to create calendar event")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "calendar event created"})
}

// UpdateEvent godoc
// @Summary      Update calendar event
// @Description  Updates a manual calendar event. Returns 403 for auto-generated events.
// @Tags         calendar
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Event ID"
// @Param        body  body  object  true  "Event data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events/{id} [put]
func (h *CalendarHandler) UpdateEvent(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")

	var body struct {
		Title          string `json:"title"`
		Description    string `json:"description"`
		EventType      string `json:"event_type"`
		StartAt        string `json:"start_at"`
		EndAt          string `json:"end_at"`
		IsAllDay       bool   `json:"is_all_day"`
		RecurrenceRule string `json:"recurrence_rule"`
		Location       string `json:"location"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatecalendarevent.UpdateCalendarEventCommand{
		ID:             idStr,
		Title:          body.Title,
		Description:    body.Description,
		EventType:      body.EventType,
		StartAt:        body.StartAt,
		EndAt:          body.EndAt,
		IsAllDay:       body.IsAllDay,
		RecurrenceRule: body.RecurrenceRule,
		Location:       body.Location,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, calendar.ErrCalendarEventNotFound) {
			writeError(w, http.StatusNotFound, "event not found")
			return
		}
		if errors.Is(err, calendar.ErrAutoGeneratedEventReadOnly) {
			writeError(w, http.StatusForbidden, "auto-generated events are read-only")
			return
		}
		log.Error().Err(err).Msg("failed to update calendar event")
		writeError(w, http.StatusInternalServerError, "failed to update calendar event")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "calendar event updated"})
}

// DeleteEvent godoc
// @Summary      Delete calendar event
// @Description  Deletes a manual calendar event. Returns 403 for auto-generated events.
// @Tags         calendar
// @Produce      json
// @Param        id  path  string  true  "Event ID"
// @Success      200  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /calendar/events/{id} [delete]
func (h *CalendarHandler) DeleteEvent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid event id")
		return
	}

	cmd := &deletecalendarevent.DeleteCalendarEventCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, calendar.ErrCalendarEventNotFound) {
			writeError(w, http.StatusNotFound, "event not found")
			return
		}
		if errors.Is(err, calendar.ErrAutoGeneratedEventReadOnly) {
			writeError(w, http.StatusForbidden, "auto-generated events are read-only")
			return
		}
		log.Error().Err(err).Msg("failed to delete calendar event")
		writeError(w, http.StatusInternalServerError, "failed to delete calendar event")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "calendar event deleted"})
}
