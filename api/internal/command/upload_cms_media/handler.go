package upload_cms_media

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type UploadCmsMediaCommand struct {
	URL        string `validate:"required"`
	FileName   string `validate:"required"`
	FileType   string
	FileSize   int64
	UploadedBy string `validate:"required"`
}

type Handler struct {
	writeRepo cms.MediaWriteRepository
}

func NewHandler(writeRepo cms.MediaWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UploadCmsMediaCommand)
	if !ok {
		return ErrInvalidCommand
	}

	uploadedBy, err := uuid.Parse(c.UploadedBy)
	if err != nil {
		return errors.New("invalid uploaded_by id")
	}

	media := &cms.CmsMedia{
		ID:         uuid.New(),
		URL:        c.URL,
		FileName:   c.FileName,
		FileType:   c.FileType,
		FileSize:   c.FileSize,
		UploadedBy: uploadedBy,
		CreatedAt:  time.Now(),
	}

	if err := h.writeRepo.SaveMedia(ctx, media); err != nil {
		log.Error().Err(err).Str("file_name", c.FileName).Msg("failed to save cms media")
		return err
	}

	log.Info().Str("media_id", media.ID.String()).Msg("cms media uploaded successfully")
	return nil
}
