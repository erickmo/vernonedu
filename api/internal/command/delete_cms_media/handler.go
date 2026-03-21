package delete_cms_media

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type DeleteCmsMediaCommand struct {
	ID string `validate:"required"`
}

type Handler struct {
	writeRepo cms.MediaWriteRepository
}

func NewHandler(writeRepo cms.MediaWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteCmsMediaCommand)
	if !ok {
		return ErrInvalidCommand
	}

	mediaID, err := uuid.Parse(c.ID)
	if err != nil {
		return errors.New("invalid media id")
	}

	if err := h.writeRepo.DeleteMedia(ctx, mediaID); err != nil {
		log.Error().Err(err).Str("media_id", c.ID).Msg("failed to delete cms media")
		return err
	}

	log.Info().Str("media_id", c.ID).Msg("cms media deleted successfully")
	return nil
}
