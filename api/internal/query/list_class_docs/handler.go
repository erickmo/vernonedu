package list_class_docs

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
)

type ListClassDocsQuery struct {
	Offset int
	Limit  int
	Status string
}

type ClassDocReadModel struct {
	ID                string `json:"id"`
	BatchName         string `json:"batch_name"`
	ModuleName        string `json:"module_name"`
	ClassDate         string `json:"class_date"`
	ScheduledPostDate string `json:"scheduled_post_date"`
	Status            string `json:"status"`
	PostURL           string `json:"post_url"`
}

type ListClassDocsResult struct {
	Data   []*ClassDocReadModel `json:"data"`
	Total  int                  `json:"total"`
	Offset int                  `json:"offset"`
	Limit  int                  `json:"limit"`
}

type Handler struct {
	readRepo marketing.ReadRepository
}

func NewHandler(readRepo marketing.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListClassDocsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	docs, total, err := h.readRepo.ListClassDocs(ctx, q.Offset, q.Limit, q.Status)
	if err != nil {
		log.Error().Err(err).Msg("failed to list class docs")
		return nil, err
	}

	readModels := make([]*ClassDocReadModel, len(docs))
	for i, d := range docs {
		readModels[i] = &ClassDocReadModel{
			ID:                d.ID.String(),
			BatchName:         d.BatchName,
			ModuleName:        d.ModuleName,
			ClassDate:         d.ClassDate.Format("2006-01-02"),
			ScheduledPostDate: d.ScheduledPostDate.Format("2006-01-02"),
			Status:            d.Status,
			PostURL:           d.PostURL,
		}
	}

	return &ListClassDocsResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
