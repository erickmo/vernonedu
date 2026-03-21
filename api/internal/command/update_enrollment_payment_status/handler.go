package update_enrollment_payment_status

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/enrollment"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type UpdateEnrollmentPaymentStatusCommand struct {
	EnrollmentID  uuid.UUID `validate:"required"`
	PaymentStatus string    `validate:"required"`
}

var validPaymentStatuses = map[string]bool{
	"pending": true, "paid": true, "failed": true,
}

type Handler struct {
	writeRepo enrollment.WriteRepository
}

func NewHandler(writeRepo enrollment.WriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateEnrollmentPaymentStatusCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if !validPaymentStatuses[c.PaymentStatus] {
		return ErrInvalidPaymentStatus
	}
	if err := h.writeRepo.UpdatePaymentStatus(ctx, c.EnrollmentID, c.PaymentStatus); err != nil {
		log.Error().Err(err).Str("enrollment_id", c.EnrollmentID.String()).Msg("failed to update enrollment payment status")
		return err
	}
	log.Info().Str("enrollment_id", c.EnrollmentID.String()).Str("payment_status", c.PaymentStatus).Msg("enrollment payment status updated")
	return nil
}
