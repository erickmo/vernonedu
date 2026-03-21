package create_cms_article

import (
	"context"
	"errors"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type CreateCmsArticleCommand struct {
	Title            string `validate:"required"`
	Category         string `validate:"required"`
	Content          string
	FeaturedImageURL string
	Status           string // default "draft"
	AuthorID         string `validate:"required"`
}

type Handler struct {
	writeRepo cms.ArticleWriteRepository
}

func NewHandler(writeRepo cms.ArticleWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func slugify(s string) string {
	s = strings.ToLower(s)
	reg := regexp.MustCompile(`[^a-z0-9\s-]`)
	s = reg.ReplaceAllString(s, "")
	reg2 := regexp.MustCompile(`[\s-]+`)
	s = reg2.ReplaceAllString(s, "-")
	return strings.Trim(s, "-")
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateCmsArticleCommand)
	if !ok {
		return ErrInvalidCommand
	}

	authorID, err := uuid.Parse(c.AuthorID)
	if err != nil {
		return errors.New("invalid author_id")
	}

	status := c.Status
	if status == "" {
		status = cms.StatusDraft
	}

	now := time.Now()
	article := &cms.CmsArticle{
		ID:               uuid.New(),
		Slug:             slugify(c.Title),
		Title:            c.Title,
		Category:         c.Category,
		Content:          c.Content,
		FeaturedImageURL: c.FeaturedImageURL,
		Status:           status,
		AuthorID:         authorID,
		CreatedAt:        now,
		UpdatedAt:        now,
	}

	if status == cms.StatusPublished {
		article.PublishedAt = &now
	}

	if err := h.writeRepo.SaveArticle(ctx, article); err != nil {
		log.Error().Err(err).Str("title", c.Title).Msg("failed to save cms article")
		return err
	}

	log.Info().Str("article_id", article.ID.String()).Msg("cms article created successfully")
	return nil
}
