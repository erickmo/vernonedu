package update_partner

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	readRepo  partner.ReadRepository
	writeRepo partner.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(readRepo partner.ReadRepository, writeRepo partner.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{readRepo: readRepo, writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdatePartnerCommand)
	if !ok {
		return ErrInvalidCommand
	}
	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidPartnerID
	}
	p, err := h.readRepo.GetByID(ctx, id)
	if err != nil {
		return ErrPartnerNotFound
	}
	if c.Name != "" {
		p.Name = c.Name
	}
	if c.Industry != "" {
		p.Industry = c.Industry
	}
	if c.Status != "" {
		p.Status = c.Status
	}
	if c.GroupID != nil {
		p.GroupID = c.GroupID
	}
	if c.ContactEmail != "" {
		p.ContactEmail = c.ContactEmail
	}
	if c.ContactPhone != "" {
		p.ContactPhone = c.ContactPhone
	}
	if c.ContactPerson != "" {
		p.ContactPerson = c.ContactPerson
	}
	if c.Website != "" {
		p.Website = c.Website
	}
	if c.Address != "" {
		p.Address = c.Address
	}
	if c.LogoURL != "" {
		p.LogoURL = c.LogoURL
	}
	if c.Notes != "" {
		p.Notes = c.Notes
	}
	if err := h.writeRepo.Update(ctx, p); err != nil {
		return err
	}
	log.Info().Str("partner_id", id.String()).Msg("partner updated")
	return nil
}
