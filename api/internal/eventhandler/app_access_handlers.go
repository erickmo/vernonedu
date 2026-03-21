package eventhandler

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	grantaccess "github.com/vernonedu/entrepreneurship-api/internal/command/grant_app_access"
	revokeaccess "github.com/vernonedu/entrepreneurship-api/internal/command/revoke_app_access"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

// AppAccessHandler handles events that affect student app access.
type AppAccessHandler struct {
	cmdBus commandbus.CommandBus
}

func NewAppAccessHandler(cmdBus commandbus.CommandBus) *AppAccessHandler {
	return &AppAccessHandler{cmdBus: cmdBus}
}

// enrollmentCreatedPayload is the shape of the EnrollmentCreated event.
type enrollmentCreatedPayload struct {
	EnrollmentID  uuid.UUID `json:"enrollment_id"`
	StudentID     uuid.UUID `json:"student_id"`
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	// AppName is optionally set when the batch has a supporting app
	AppName   string `json:"app_name"`
	Timestamp int64  `json:"timestamp"`
}

// OnEnrollmentCreated grants app access if the event carries an AppName.
// Note: The EnrollmentCreated event publisher should set AppName when the batch's
// course type has a supporting app. For now, the handler is a no-op if AppName is empty.
func (h *AppAccessHandler) OnEnrollmentCreated(ctx context.Context, data []byte) error {
	var payload enrollmentCreatedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("AppAccess/OnEnrollmentCreated: failed to unmarshal")
		return err
	}

	if payload.AppName == "" {
		// Batch has no supporting app — nothing to grant
		return nil
	}

	cmd := &grantaccess.GrantAppAccessCommand{
		StudentID: payload.StudentID,
		AppName:   payload.AppName,
		BatchID:   payload.CourseBatchID,
	}
	if err := h.cmdBus.Execute(ctx, cmd); err != nil {
		log.Error().Err(err).
			Str("student_id", payload.StudentID.String()).
			Str("app", payload.AppName).
			Msg("AppAccess/OnEnrollmentCreated: failed to grant access")
		return err
	}
	return nil
}

// batchCompletedPayload is the shape of CourseBatchCompleted.
type batchCompletedPayload struct {
	BatchID   uuid.UUID `json:"batch_id"`
	Timestamp int64     `json:"timestamp"`
}

// OnBatchCompleted revokes app access for all students in the batch.
func (h *AppAccessHandler) OnBatchCompleted(ctx context.Context, data []byte) error {
	var payload batchCompletedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("AppAccess/OnBatchCompleted: failed to unmarshal")
		return err
	}

	cmd := &revokeaccess.RevokeAllBatchAccessCommand{
		BatchID: payload.BatchID,
		Reason:  "batch_completed",
	}
	if err := h.cmdBus.Execute(ctx, cmd); err != nil {
		log.Error().Err(err).
			Str("batch_id", payload.BatchID.String()).
			Msg("AppAccess/OnBatchCompleted: failed to revoke all access")
		return err
	}
	return nil
}

// enrollmentStatusPayload is the shape of EnrollmentStatusUpdated.
type enrollmentStatusPayload struct {
	EnrollmentID  uuid.UUID `json:"enrollment_id"`
	StudentID     uuid.UUID `json:"student_id"`
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	Status        string    `json:"status"`
	Timestamp     int64     `json:"timestamp"`
}

// OnEnrollmentStatusUpdated revokes access when a student drops or is suspended.
func (h *AppAccessHandler) OnEnrollmentStatusUpdated(ctx context.Context, data []byte) error {
	var payload enrollmentStatusPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("AppAccess/OnEnrollmentStatusUpdated: failed to unmarshal")
		return err
	}

	if payload.Status != "dropped" && payload.Status != "suspended" {
		return nil
	}

	cmd := &revokeaccess.RevokeAppAccessCommand{
		StudentID: payload.StudentID,
		BatchID:   payload.CourseBatchID,
		Reason:    "enrollment_" + payload.Status,
	}
	if err := h.cmdBus.Execute(ctx, cmd); err != nil {
		log.Error().Err(err).
			Str("student_id", payload.StudentID.String()).
			Msg("AppAccess/OnEnrollmentStatusUpdated: failed to revoke access")
		return err
	}
	return nil
}

// invoiceOverduePayload is the shape of InvoiceOverdueEvent.
type invoiceOverduePayload struct {
	InvoiceID    uuid.UUID  `json:"invoice_id"`
	EnrollmentID *uuid.UUID `json:"enrollment_id"`
	StudentID    *uuid.UUID `json:"student_id"`
	BatchID      *uuid.UUID `json:"batch_id"`
	Timestamp    int64      `json:"timestamp"`
}

// OnInvoiceOverdue revokes access when a scheduled payment is missed.
func (h *AppAccessHandler) OnInvoiceOverdue(ctx context.Context, data []byte) error {
	var payload invoiceOverduePayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("AppAccess/OnInvoiceOverdue: failed to unmarshal")
		return err
	}

	if payload.StudentID == nil || payload.BatchID == nil {
		return nil
	}

	cmd := &revokeaccess.RevokeAppAccessCommand{
		StudentID: *payload.StudentID,
		BatchID:   *payload.BatchID,
		Reason:    "invoice_overdue",
	}
	if err := h.cmdBus.Execute(ctx, cmd); err != nil {
		log.Error().Err(err).
			Str("student_id", payload.StudentID.String()).
			Msg("AppAccess/OnInvoiceOverdue: failed to revoke access")
		return err
	}
	return nil
}
