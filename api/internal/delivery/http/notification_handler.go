package http

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	markallread "github.com/vernonedu/entrepreneurship-api/internal/command/mark_all_notifications_read"
	markread "github.com/vernonedu/entrepreneurship-api/internal/command/mark_notification_read"
	getunreadcount "github.com/vernonedu/entrepreneurship-api/internal/query/get_unread_count"
	listnotifications "github.com/vernonedu/entrepreneurship-api/internal/query/list_notifications"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// NotificationHandler handles notification-related HTTP requests.
type NotificationHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewNotificationHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *NotificationHandler {
	return &NotificationHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// RegisterNotificationRoutes mounts all notification routes on the given router.
func RegisterNotificationRoutes(h *NotificationHandler, r chi.Router) {
	r.Get("/api/v1/notifications", h.List)
	r.Get("/api/v1/notifications/unread-count", h.UnreadCount)
	r.Put("/api/v1/notifications/{id}/read", h.MarkRead)
	r.Put("/api/v1/notifications/read-all", h.MarkAllRead)
}

// List godoc
// @Summary      List notifications
// @Description  Retrieve paginated notifications for the authenticated user.
// @Tags         notifications
// @Produce      json
// @Param        offset  query  int     false  "Pagination offset"
// @Param        limit   query  int     false  "Pagination limit (default 20)"
// @Param        read    query  string  false  "Filter by read status (true|false)"
// @Param        type    query  string  false  "Filter by notification type"
// @Success      200  {object}  map[string]interface{}
// @Failure      401  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /notifications [get]
func (h *NotificationHandler) List(w http.ResponseWriter, r *http.Request) {
	recipientIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	recipientID, err := uuid.Parse(recipientIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	onlyUnread := false
	if readParam := r.URL.Query().Get("read"); readParam == "false" {
		onlyUnread = true
	}

	notifType := r.URL.Query().Get("type")

	query := &listnotifications.ListNotificationsQuery{
		RecipientID: recipientID,
		Offset:      offset,
		Limit:       limit,
		OnlyUnread:  onlyUnread,
		Type:        notifType,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list notifications")
		writeError(w, http.StatusInternalServerError, "failed to list notifications")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// UnreadCount godoc
// @Summary      Get unread notification count
// @Description  Returns the number of unread notifications for the authenticated user.
// @Tags         notifications
// @Produce      json
// @Success      200  {object}  map[string]interface{}
// @Failure      401  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /notifications/unread-count [get]
func (h *NotificationHandler) UnreadCount(w http.ResponseWriter, r *http.Request) {
	recipientIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	recipientID, err := uuid.Parse(recipientIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	query := &getunreadcount.GetUnreadCountQuery{RecipientID: recipientID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to get unread count")
		writeError(w, http.StatusInternalServerError, "failed to get unread count")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// MarkRead godoc
// @Summary      Mark a notification as read
// @Description  Mark a specific notification as read for the authenticated user.
// @Tags         notifications
// @Produce      json
// @Param        id  path  string  true  "Notification ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /notifications/{id}/read [put]
func (h *NotificationHandler) MarkRead(w http.ResponseWriter, r *http.Request) {
	recipientIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	recipientID, err := uuid.Parse(recipientIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	notifIDStr := chi.URLParam(r, "id")
	notifID, err := uuid.Parse(notifIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid notification id")
		return
	}

	cmd := &markread.MarkNotificationReadCommand{
		NotificationID: notifID,
		RecipientID:    recipientID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to mark notification as read")
		writeError(w, http.StatusInternalServerError, "failed to mark notification as read")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "notification marked as read"})
}

// MarkAllRead godoc
// @Summary      Mark all notifications as read
// @Description  Mark all unread notifications as read for the authenticated user.
// @Tags         notifications
// @Produce      json
// @Success      200  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /notifications/read-all [put]
func (h *NotificationHandler) MarkAllRead(w http.ResponseWriter, r *http.Request) {
	recipientIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	recipientID, err := uuid.Parse(recipientIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	cmd := &markallread.MarkAllNotificationsReadCommand{RecipientID: recipientID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to mark all notifications as read")
		writeError(w, http.StatusInternalServerError, "failed to mark all notifications as read")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "all notifications marked as read"})
}
