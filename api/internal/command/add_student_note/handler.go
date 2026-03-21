package add_student_note

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo student.WriteRepository
}

func NewHandler(writeRepo student.WriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*AddStudentNoteCommand)
	if !ok {
		return ErrInvalidCommand
	}

	studentID, err := uuid.Parse(c.StudentID)
	if err != nil {
		return fmt.Errorf("invalid student id: %w", err)
	}

	note, err := h.writeRepo.AddNote(ctx, studentID, c.AuthorID, c.AuthorName, c.Content)
	if err != nil {
		log.Error().Err(err).Str("student_id", c.StudentID).Msg("failed to add student note")
		return err
	}

	log.Info().Str("note_id", note.ID.String()).Str("student_id", c.StudentID).Msg("student note added")
	return nil
}
