package list_cms_articles

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

type ListCmsArticlesQuery struct {
	Category string
	Status   string
	Offset   int
	Limit    int
}

type CmsArticleReadModel struct {
	ID               string     `json:"id"`
	Slug             string     `json:"slug"`
	Title            string     `json:"title"`
	Category         string     `json:"category"`
	Content          string     `json:"content"`
	FeaturedImageURL string     `json:"featured_image_url"`
	Status           string     `json:"status"`
	AuthorID         string     `json:"author_id"`
	PublishedAt      *time.Time `json:"published_at"`
	CreatedAt        time.Time  `json:"created_at"`
}

type ListResult struct {
	Data   []*CmsArticleReadModel `json:"data"`
	Total  int                    `json:"total"`
	Offset int                    `json:"offset"`
	Limit  int                    `json:"limit"`
}

type Handler struct {
	readRepo cms.ArticleReadRepository
}

func NewHandler(r cms.ArticleReadRepository) *Handler {
	return &Handler{readRepo: r}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCmsArticlesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	if q.Limit == 0 {
		q.Limit = 20
	}

	articles, total, err := h.readRepo.ListArticles(ctx, q.Category, q.Status, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms articles")
		return nil, err
	}

	result := make([]*CmsArticleReadModel, len(articles))
	for i, a := range articles {
		result[i] = &CmsArticleReadModel{
			ID:               a.ID.String(),
			Slug:             a.Slug,
			Title:            a.Title,
			Category:         a.Category,
			Content:          a.Content,
			FeaturedImageURL: a.FeaturedImageURL,
			Status:           a.Status,
			AuthorID:         a.AuthorID.String(),
			PublishedAt:      a.PublishedAt,
			CreatedAt:        a.CreatedAt,
		}
	}

	return &ListResult{
		Data:   result,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
