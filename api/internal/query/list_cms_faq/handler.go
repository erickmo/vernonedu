package list_cms_faq

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

type ListCmsFaqQuery struct {
	Category string
	PageSlug string
}

type CmsFaqReadModel struct {
	ID        string   `json:"id"`
	Question  string   `json:"question"`
	Answer    string   `json:"answer"`
	Category  string   `json:"category"`
	PageSlugs []string `json:"page_slugs"`
	SortOrder int      `json:"sort_order"`
}

type Handler struct {
	readRepo cms.FaqReadRepository
}

func NewHandler(r cms.FaqReadRepository) *Handler {
	return &Handler{readRepo: r}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCmsFaqQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	faqs, err := h.readRepo.ListFaq(ctx, q.Category, q.PageSlug)
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms faq")
		return nil, err
	}

	result := make([]*CmsFaqReadModel, len(faqs))
	for i, f := range faqs {
		pageSlugs := f.PageSlugs
		if pageSlugs == nil {
			pageSlugs = []string{}
		}
		result[i] = &CmsFaqReadModel{
			ID:        f.ID.String(),
			Question:  f.Question,
			Answer:    f.Answer,
			Category:  f.Category,
			PageSlugs: pageSlugs,
			SortOrder: f.SortOrder,
		}
	}

	return result, nil
}
