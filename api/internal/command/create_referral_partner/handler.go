package create_referral_partner

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo marketing.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo marketing.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateReferralPartnerCommand)
	if !ok {
		return ErrInvalidCommand
	}

	now := time.Now()
	rp := &marketing.ReferralPartner{
		ID:              uuid.New(),
		Name:            c.Name,
		ContactEmail:    c.ContactEmail,
		ReferralCode:    c.ReferralCode,
		CommissionType:  c.CommissionType,
		CommissionValue: c.CommissionValue,
		IsActive:        true,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	if err := h.writeRepo.SaveReferralPartner(ctx, rp); err != nil {
		log.Error().Err(err).Msg("failed to save referral partner")
		return err
	}

	log.Info().Str("referral_partner_id", rp.ID.String()).Msg("referral partner created")
	return nil
}
