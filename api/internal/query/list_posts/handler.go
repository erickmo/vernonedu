package list_posts

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
)

type ListPostsQuery struct {
	Offset   int
	Limit    int
	Platform string
	Status   string
	Month    string // YYYY-MM
}

type PostReadModel struct {
	ID          string   `json:"id"`
	Platforms   []string `json:"platforms"`
	ScheduledAt int64    `json:"scheduled_at"`
	ContentType string   `json:"content_type"`
	Caption     string   `json:"caption"`
	MediaURL    string   `json:"media_url"`
	BatchID     string   `json:"batch_id,omitempty"`
	BatchName   string   `json:"batch_name"`
	Status      string   `json:"status"`
	PostURL     string   `json:"post_url"`
}

type ListPostsResult struct {
	Data   []*PostReadModel `json:"data"`
	Total  int              `json:"total"`
	Offset int              `json:"offset"`
	Limit  int              `json:"limit"`
}

type Handler struct {
	readRepo marketing.ReadRepository
}

func NewHandler(readRepo marketing.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListPostsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	posts, total, err := h.readRepo.ListPosts(ctx, q.Offset, q.Limit, q.Platform, q.Status, q.Month)
	if err != nil {
		log.Error().Err(err).Msg("failed to list posts")
		return nil, err
	}

	readModels := make([]*PostReadModel, len(posts))
	for i, p := range posts {
		rm := &PostReadModel{
			ID:          p.ID.String(),
			Platforms:   p.Platforms,
			ScheduledAt: p.ScheduledAt.Unix(),
			ContentType: p.ContentType,
			Caption:     p.Caption,
			MediaURL:    p.MediaURL,
			BatchName:   p.BatchName,
			Status:      p.Status,
			PostURL:     p.PostURL,
		}
		if p.BatchID != nil {
			rm.BatchID = p.BatchID.String()
		}
		readModels[i] = rm
	}

	return &ListPostsResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
