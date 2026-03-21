package delete_cms_article

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type DeleteCmsArticleCommand struct {
	ID string `validate:"required"`
}

type Handler struct {
	writeRepo cms.ArticleWriteRepository
}

func NewHandler(writeRepo cms.ArticleWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteCmsArticleCommand)
	if !ok {
		return ErrInvalidCommand
	}

	articleID, err := uuid.Parse(c.ID)
	if err != nil {
		return errors.New("invalid article id")
	}

	if err := h.writeRepo.DeleteArticle(ctx, articleID); err != nil {
		log.Error().Err(err).Str("article_id", c.ID).Msg("failed to delete cms article")
		return err
	}

	log.Info().Str("article_id", c.ID).Msg("cms article deleted successfully")
	return nil
}
