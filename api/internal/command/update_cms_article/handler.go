package update_cms_article

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type UpdateCmsArticleCommand struct {
	ID               string `validate:"required"`
	Title            string
	Slug             string
	Category         string
	Content          string
	FeaturedImageURL string
	Status           string
}

type Handler struct {
	writeRepo cms.ArticleWriteRepository
	readRepo  cms.ArticleReadRepository
}

func NewHandler(writeRepo cms.ArticleWriteRepository, readRepo cms.ArticleReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateCmsArticleCommand)
	if !ok {
		return ErrInvalidCommand
	}

	articleID, err := uuid.Parse(c.ID)
	if err != nil {
		return errors.New("invalid article id")
	}

	existing, err := h.readRepo.GetArticleByID(ctx, articleID)
	if err != nil {
		if errors.Is(err, cms.ErrArticleNotFound) {
			return cms.ErrArticleNotFound
		}
		log.Error().Err(err).Str("article_id", c.ID).Msg("failed to get cms article")
		return err
	}

	now := time.Now()

	if c.Title != "" {
		existing.Title = c.Title
	}
	if c.Slug != "" {
		existing.Slug = c.Slug
	}
	if c.Category != "" {
		existing.Category = c.Category
	}
	if c.Content != "" {
		existing.Content = c.Content
	}
	if c.FeaturedImageURL != "" {
		existing.FeaturedImageURL = c.FeaturedImageURL
	}
	if c.Status != "" && c.Status != existing.Status {
		if c.Status == cms.StatusPublished && existing.PublishedAt == nil {
			existing.PublishedAt = &now
		}
		existing.Status = c.Status
	}
	existing.UpdatedAt = now

	if err := h.writeRepo.UpdateArticle(ctx, existing); err != nil {
		log.Error().Err(err).Str("article_id", c.ID).Msg("failed to update cms article")
		return err
	}

	log.Info().Str("article_id", c.ID).Msg("cms article updated successfully")
	return nil
}
