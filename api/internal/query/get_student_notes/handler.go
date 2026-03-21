package get_student_notes

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
)

type GetStudentNotesQuery struct {
	StudentID string
}

type NoteReadModel struct {
	ID         uuid.UUID `json:"id"`
	StudentID  uuid.UUID `json:"student_id"`
	AuthorID   string    `json:"author_id"`
	AuthorName string    `json:"author_name"`
	Content    string    `json:"content"`
	CreatedAt  string    `json:"created_at"`
}

type Handler struct {
	readRepo student.ReadRepository
}

func NewHandler(readRepo student.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetStudentNotesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	studentID, err := uuid.Parse(q.StudentID)
	if err != nil {
		return nil, ErrInvalidQuery
	}

	items, err := h.readRepo.GetNotes(ctx, studentID)
	if err != nil {
		log.Error().Err(err).Str("student_id", q.StudentID).Msg("failed to get student notes")
		return nil, err
	}

	result := make([]*NoteReadModel, len(items))
	for i, item := range items {
		result[i] = &NoteReadModel{
			ID:         item.ID,
			StudentID:  item.StudentID,
			AuthorID:   item.AuthorID,
			AuthorName: item.AuthorName,
			Content:    item.Content,
			CreatedAt:  item.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		}
	}

	return result, nil
}
