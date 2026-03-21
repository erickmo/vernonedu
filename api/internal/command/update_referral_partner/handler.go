package update_referral_partner

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo marketing.WriteRepository
	readRepo  marketing.ReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo marketing.WriteRepository, readRepo marketing.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateReferralPartnerCommand)
	if !ok {
		return ErrInvalidCommand
	}

	rp, err := h.readRepo.GetReferralPartnerByID(ctx, c.ID)
	if err != nil {
		if errors.Is(err, marketing.ErrReferralPartnerNotFound) {
			return ErrReferralPartnerNotFound
		}
		log.Error().Err(err).Str("referral_partner_id", c.ID.String()).Msg("failed to get referral partner")
		return err
	}

	if c.Name != "" {
		rp.Name = c.Name
	}
	if c.ContactEmail != "" {
		rp.ContactEmail = c.ContactEmail
	}
	if c.CommissionType != "" {
		rp.CommissionType = c.CommissionType
	}
	if c.CommissionValue != 0 {
		rp.CommissionValue = c.CommissionValue
	}
	if c.IsActive != nil {
		rp.IsActive = *c.IsActive
	}
	rp.UpdatedAt = time.Now()

	if err := h.writeRepo.UpdateReferralPartner(ctx, rp); err != nil {
		log.Error().Err(err).Msg("failed to update referral partner")
		return err
	}

	log.Info().Str("referral_partner_id", rp.ID.String()).Msg("referral partner updated")
	return nil
}
