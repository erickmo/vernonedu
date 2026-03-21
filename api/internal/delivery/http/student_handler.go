package http

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_student"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_student"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_student"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_student"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_student_enrollment_history"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_student_notes"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_student_recommendations"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_student"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// studentNoteWriter is a thin interface for writing notes, satisfied by database.StudentRepository.
type studentNoteWriter interface {
	AddNote(ctx context.Context, studentID uuid.UUID, authorID, authorName, content string) (*student.StudentNoteItem, error)
}

type StudentHandler struct {
	cmdBus     commandbus.CommandBus
	qryBus     querybus.QueryBus
	noteWriter studentNoteWriter
}

func NewStudentHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus, noteWriter studentNoteWriter) *StudentHandler {
	return &StudentHandler{
		cmdBus:     cmdBus,
		qryBus:     qryBus,
		noteWriter: noteWriter,
	}
}

type CreateStudentRequest struct {
	Name         string `json:"name" validate:"required,min=1"`
	Email        string `json:"email" validate:"required,email"`
	Phone        string `json:"phone"`
	DepartmentID string `json:"department_id"`
}

type UpdateStudentRequest struct {
	Name         string `json:"name" validate:"required,min=1"`
	Email        string `json:"email" validate:"required,email"`
	Phone        string `json:"phone"`
	DepartmentID string `json:"department_id"`
	IsActive     bool   `json:"is_active"`
}

type AddNoteRequest struct {
	Content string `json:"content" validate:"required,min=1"`
}

func (h *StudentHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateStudentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_student.CreateStudentCommand{
		Name:         req.Name,
		Email:        req.Email,
		Phone:        req.Phone,
		DepartmentID: req.DepartmentID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create student command")
		writeError(w, http.StatusInternalServerError, "failed to create student")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "student created successfully"})
}

func (h *StudentHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	studentIDStr := chi.URLParam(r, "id")
	studentID, err := uuid.Parse(studentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid student id")
		return
	}

	query := &get_student.GetStudentQuery{StudentID: studentID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get student query")
		writeError(w, http.StatusInternalServerError, "failed to get student")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *StudentHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_student.ListStudentQuery{Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list student query")
		writeError(w, http.StatusInternalServerError, "failed to list students")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (h *StudentHandler) Update(w http.ResponseWriter, r *http.Request) {
	studentIDStr := chi.URLParam(r, "id")
	studentID, err := uuid.Parse(studentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid student id")
		return
	}

	var req UpdateStudentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_student.UpdateStudentCommand{
		StudentID:    studentID,
		Name:         req.Name,
		Email:        req.Email,
		Phone:        req.Phone,
		DepartmentID: req.DepartmentID,
		IsActive:     req.IsActive,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update student command")
		writeError(w, http.StatusInternalServerError, "failed to update student")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "student updated successfully"})
}

func (h *StudentHandler) Delete(w http.ResponseWriter, r *http.Request) {
	studentIDStr := chi.URLParam(r, "id")
	studentID, err := uuid.Parse(studentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid student id")
		return
	}

	cmd := &delete_student.DeleteStudentCommand{StudentID: studentID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete student command")
		writeError(w, http.StatusInternalServerError, "failed to delete student")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "student deleted successfully"})
}

func (h *StudentHandler) GetEnrollmentHistory(w http.ResponseWriter, r *http.Request) {
	studentIDStr := chi.URLParam(r, "id")

	query := &get_student_enrollment_history.GetStudentEnrollmentHistoryQuery{StudentID: studentIDStr}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Str("student_id", studentIDStr).Msg("failed to get enrollment history")
		writeError(w, http.StatusInternalServerError, "failed to get enrollment history")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *StudentHandler) GetRecommendations(w http.ResponseWriter, r *http.Request) {
	studentIDStr := chi.URLParam(r, "id")

	query := &get_student_recommendations.GetStudentRecommendationsQuery{StudentID: studentIDStr}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Str("student_id", studentIDStr).Msg("failed to get recommendations")
		writeError(w, http.StatusInternalServerError, "failed to get recommendations")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *StudentHandler) GetNotes(w http.ResponseWriter, r *http.Request) {
	studentIDStr := chi.URLParam(r, "id")

	query := &get_student_notes.GetStudentNotesQuery{StudentID: studentIDStr}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Str("student_id", studentIDStr).Msg("failed to get notes")
		writeError(w, http.StatusInternalServerError, "failed to get notes")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *StudentHandler) AddNote(w http.ResponseWriter, r *http.Request) {
	studentIDStr := chi.URLParam(r, "id")
	studentID, err := uuid.Parse(studentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid student id")
		return
	}

	var req AddNoteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	authorID := pkgmiddleware.GetUserIDFromContext(r.Context())
	authorName := r.Context().Value(pkgmiddleware.ContextKeyEmail)
	authorNameStr := ""
	if authorName != nil {
		authorNameStr, _ = authorName.(string)
	}
	if authorNameStr == "" {
		authorNameStr = authorID
	}

	note, err := h.noteWriter.AddNote(r.Context(), studentID, authorID, authorNameStr, req.Content)
	if err != nil {
		log.Error().Err(err).Str("student_id", studentIDStr).Msg("failed to add note")
		writeError(w, http.StatusInternalServerError, "failed to add note")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]interface{}{
		"data": map[string]interface{}{
			"id":          note.ID.String(),
			"student_id":  note.StudentID.String(),
			"author_id":   note.AuthorID,
			"author_name": note.AuthorName,
			"content":     note.Content,
			"created_at":  note.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		},
	})
}

func RegisterStudentRoutes(h *StudentHandler, r chi.Router) {
	r.Post("/api/v1/students", h.Create)
	r.Get("/api/v1/students", h.List)
	// Specific sub-routes BEFORE parameterized /{id}
	r.Get("/api/v1/students/{id}/enrollment-history", h.GetEnrollmentHistory)
	r.Get("/api/v1/students/{id}/recommendations", h.GetRecommendations)
	r.Get("/api/v1/students/{id}/notes", h.GetNotes)
	r.Post("/api/v1/students/{id}/notes", h.AddNote)
	r.Get("/api/v1/students/{id}", h.GetByID)
	r.Put("/api/v1/students/{id}", h.Update)
	r.Delete("/api/v1/students/{id}", h.Delete)
}
