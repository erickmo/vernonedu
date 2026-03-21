package eventhandler

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

// SessionCompletedPayload mirrors SessionCompleted fields from the coursebatch domain.
type SessionCompletedPayload struct {
	BatchID    uuid.UUID `json:"batch_id"`
	SessionID  uuid.UUID `json:"session_id"`
	BatchName  string    `json:"batch_name"`
	ModuleName string    `json:"module_name"`
	ClassDate  string    `json:"class_date"` // YYYY-MM-DD
	Timestamp  int64     `json:"timestamp"`
}

// SessionCompletedHandler handles SessionCompleted events and auto-schedules class doc posts.
type SessionCompletedHandler struct {
	marketingWriteRepo marketing.WriteRepository
	holidayReadRepo    settings.HolidayReadRepository
}

// NewSessionCompletedHandler creates a SessionCompletedHandler.
func NewSessionCompletedHandler(
	marketingWriteRepo marketing.WriteRepository,
	holidayReadRepo settings.HolidayReadRepository,
) *SessionCompletedHandler {
	return &SessionCompletedHandler{
		marketingWriteRepo: marketingWriteRepo,
		holidayReadRepo:    holidayReadRepo,
	}
}

// OnSessionCompleted is the subscriber callback for the "SessionCompleted" event.
func (h *SessionCompletedHandler) OnSessionCompleted(ctx context.Context, data []byte) error {
	var payload SessionCompletedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("failed to unmarshal SessionCompleted event")
		return err
	}

	classDate, err := time.Parse("2006-01-02", payload.ClassDate)
	if err != nil {
		log.Error().Err(err).Msg("invalid class_date in SessionCompleted event")
		return err
	}

	// Schedule post 2 days after class
	scheduledPostDate := classDate.AddDate(0, 0, 2)

	// Check if it falls on a holiday; if so, add 1 more day
	holidays, err := h.holidayReadRepo.ListByYear(ctx, scheduledPostDate.Year())
	if err != nil {
		log.Warn().Err(err).Msg("failed to load holidays; skipping holiday check")
		holidays = nil
	}
	holidayMap := make(map[string]bool)
	for _, hol := range holidays {
		holidayMap[hol.Date.Format("2006-01-02")] = true
	}
	if holidayMap[scheduledPostDate.Format("2006-01-02")] {
		scheduledPostDate = scheduledPostDate.AddDate(0, 0, 1)
	}

	now := time.Now()
	docPost := &marketing.ClassDocPost{
		ID:                uuid.New(),
		BatchID:           payload.BatchID,
		SessionID:         payload.SessionID,
		ModuleName:        payload.ModuleName,
		BatchName:         payload.BatchName,
		ClassDate:         classDate,
		ScheduledPostDate: scheduledPostDate,
		Status:            "scheduled",
		CreatedAt:         now,
		UpdatedAt:         now,
	}

	if err := h.marketingWriteRepo.SaveClassDocPost(ctx, docPost); err != nil {
		log.Error().Err(err).Msg("failed to save class doc post")
		return err
	}

	log.Info().
		Str("batch_id", payload.BatchID.String()).
		Str("scheduled_post_date", scheduledPostDate.Format("2006-01-02")).
		Msg("class doc post auto-scheduled")
	return nil
}
