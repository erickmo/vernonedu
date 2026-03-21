package list_cms_media

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/cms"
)

type ListCmsMediaQuery struct {
	Offset int
	Limit  int
}

type CmsMediaReadModel struct {
	ID        string    `json:"id"`
	URL       string    `json:"url"`
	FileName  string    `json:"file_name"`
	FileType  string    `json:"file_type"`
	FileSize  int64     `json:"file_size"`
	CreatedAt time.Time `json:"created_at"`
}

type ListResult struct {
	Data   []*CmsMediaReadModel `json:"data"`
	Total  int                  `json:"total"`
	Offset int                  `json:"offset"`
	Limit  int                  `json:"limit"`
}

type Handler struct {
	readRepo cms.MediaReadRepository
}

func NewHandler(r cms.MediaReadRepository) *Handler {
	return &Handler{readRepo: r}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCmsMediaQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	if q.Limit == 0 {
		q.Limit = 20
	}

	media, total, err := h.readRepo.ListMedia(ctx, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list cms media")
		return nil, err
	}

	result := make([]*CmsMediaReadModel, len(media))
	for i, m := range media {
		result[i] = &CmsMediaReadModel{
			ID:        m.ID.String(),
			URL:       m.URL,
			FileName:  m.FileName,
			FileType:  m.FileType,
			FileSize:  m.FileSize,
			CreatedAt: m.CreatedAt,
		}
	}

	return &ListResult{
		Data:   result,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
