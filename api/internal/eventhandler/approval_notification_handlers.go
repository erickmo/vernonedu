package eventhandler

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
)

// ApprovalCreatedPayload mirrors ApprovalCreatedEvent fields from the approval domain.
type ApprovalCreatedPayload struct {
	ApprovalID  uuid.UUID `json:"approval_id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	InitiatorID uuid.UUID `json:"initiator_id"`
	ApproverID  uuid.UUID `json:"approver_id"`
	Timestamp   int64     `json:"timestamp"`
}

// ApprovalStepApprovedPayload mirrors ApprovalStepApprovedEvent fields.
type ApprovalStepApprovedPayload struct {
	ApprovalID     uuid.UUID  `json:"approval_id"`
	Title          string     `json:"title"`
	InitiatorID    uuid.UUID  `json:"initiator_id"`
	ApprovedByID   uuid.UUID  `json:"approved_by_id"`
	NextApproverID *uuid.UUID `json:"next_approver_id,omitempty"`
	IsCompleted    bool       `json:"is_completed"`
	Timestamp      int64      `json:"timestamp"`
}

// ApprovalRejectedPayload mirrors ApprovalRejectedEvent fields.
type ApprovalRejectedPayload struct {
	ApprovalID   uuid.UUID `json:"approval_id"`
	Title        string    `json:"title"`
	InitiatorID  uuid.UUID `json:"initiator_id"`
	RejectedByID uuid.UUID `json:"rejected_by_id"`
	Reason       string    `json:"reason"`
	Timestamp    int64     `json:"timestamp"`
}

// ApprovalNotificationHandler holds the notification write repo used by all approval handlers.
type ApprovalNotificationHandler struct {
	notifWriteRepo notification.WriteRepository
}

func NewApprovalNotificationHandler(repo notification.WriteRepository) *ApprovalNotificationHandler {
	return &ApprovalNotificationHandler{notifWriteRepo: repo}
}

// OnApprovalCreated sends a notification to the approver when a new approval is requested.
func (h *ApprovalNotificationHandler) OnApprovalCreated(ctx context.Context, data []byte) error {
	var payload ApprovalCreatedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("ApprovalCreated: failed to unmarshal payload")
		return err
	}

	title := "Permintaan Persetujuan Baru"
	body := fmt.Sprintf("Anda memiliki permintaan persetujuan baru: %q. Mohon segera ditinjau.", payload.Title)

	n := notification.NewNotification(
		payload.ApproverID,
		notification.TypeApprovalRequested,
		title,
		body,
		notification.ChannelInApp,
		map[string]interface{}{
			"approval_id":  payload.ApprovalID.String(),
			"initiator_id": payload.InitiatorID.String(),
		},
	)
	if err := h.notifWriteRepo.Save(ctx, n); err != nil {
		log.Error().Err(err).
			Str("approval_id", payload.ApprovalID.String()).
			Msg("ApprovalCreated: failed to save notification for approver")
		return err
	}

	log.Info().
		Str("approval_id", payload.ApprovalID.String()).
		Str("approver_id", payload.ApproverID.String()).
		Msg("ApprovalCreated: notification sent to approver")
	return nil
}

// OnApprovalStepApproved sends notifications to:
//   - the initiator (approval progress / final approval)
//   - the next approver (if the chain is not yet complete)
func (h *ApprovalNotificationHandler) OnApprovalStepApproved(ctx context.Context, data []byte) error {
	var payload ApprovalStepApprovedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("ApprovalStepApproved: failed to unmarshal payload")
		return err
	}

	// Notify initiator
	var initiatorTitle, initiatorBody string
	if payload.IsCompleted {
		initiatorTitle = "Persetujuan Disetujui"
		initiatorBody = fmt.Sprintf("Permintaan persetujuan %q telah sepenuhnya disetujui.", payload.Title)
	} else {
		initiatorTitle = "Langkah Persetujuan Disetujui"
		initiatorBody = fmt.Sprintf("Satu langkah persetujuan untuk %q telah disetujui. Menunggu persetujuan berikutnya.", payload.Title)
	}

	initiatorNotif := notification.NewNotification(
		payload.InitiatorID,
		notification.TypeApprovalApproved,
		initiatorTitle,
		initiatorBody,
		notification.ChannelInApp,
		map[string]interface{}{
			"approval_id":   payload.ApprovalID.String(),
			"approved_by":   payload.ApprovedByID.String(),
			"is_completed":  payload.IsCompleted,
		},
	)
	if err := h.notifWriteRepo.Save(ctx, initiatorNotif); err != nil {
		log.Error().Err(err).
			Str("approval_id", payload.ApprovalID.String()).
			Msg("ApprovalStepApproved: failed to save notification for initiator")
		return err
	}

	// Notify next approver if the chain continues
	if !payload.IsCompleted && payload.NextApproverID != nil {
		nextTitle := "Permintaan Persetujuan Menunggu"
		nextBody := fmt.Sprintf("Anda perlu menyetujui permintaan: %q.", payload.Title)

		nextNotif := notification.NewNotification(
			*payload.NextApproverID,
			notification.TypeApprovalRequested,
			nextTitle,
			nextBody,
			notification.ChannelInApp,
			map[string]interface{}{
				"approval_id":  payload.ApprovalID.String(),
				"initiator_id": payload.InitiatorID.String(),
			},
		)
		if err := h.notifWriteRepo.Save(ctx, nextNotif); err != nil {
			log.Error().Err(err).
				Str("approval_id", payload.ApprovalID.String()).
				Str("next_approver_id", payload.NextApproverID.String()).
				Msg("ApprovalStepApproved: failed to save notification for next approver")
			return err
		}

		log.Info().
			Str("approval_id", payload.ApprovalID.String()).
			Str("next_approver_id", payload.NextApproverID.String()).
			Msg("ApprovalStepApproved: notification sent to next approver")
	}

	log.Info().
		Str("approval_id", payload.ApprovalID.String()).
		Str("initiator_id", payload.InitiatorID.String()).
		Msg("ApprovalStepApproved: notification sent to initiator")
	return nil
}

// OnApprovalRejected sends a notification to the initiator when an approval is rejected.
func (h *ApprovalNotificationHandler) OnApprovalRejected(ctx context.Context, data []byte) error {
	var payload ApprovalRejectedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("ApprovalRejected: failed to unmarshal payload")
		return err
	}

	title := "Persetujuan Ditolak"
	body := fmt.Sprintf("Permintaan persetujuan %q telah ditolak.", payload.Title)
	if payload.Reason != "" {
		body = fmt.Sprintf("%s Alasan: %s", body, payload.Reason)
	}

	n := notification.NewNotification(
		payload.InitiatorID,
		notification.TypeApprovalRejected,
		title,
		body,
		notification.ChannelInApp,
		map[string]interface{}{
			"approval_id":    payload.ApprovalID.String(),
			"rejected_by":    payload.RejectedByID.String(),
			"reason":         payload.Reason,
		},
	)
	if err := h.notifWriteRepo.Save(ctx, n); err != nil {
		log.Error().Err(err).
			Str("approval_id", payload.ApprovalID.String()).
			Msg("ApprovalRejected: failed to save notification for initiator")
		return err
	}

	log.Info().
		Str("approval_id", payload.ApprovalID.String()).
		Str("initiator_id", payload.InitiatorID.String()).
		Msg("ApprovalRejected: notification sent to initiator")
	return nil
}
