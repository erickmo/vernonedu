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

// Create godoc
// @Summary      Create a new student
// @Description  Register a new student with name, email, phone, and optional department.
// @Tags         students
// @Accept       json
// @Produce      json
// @Param        body  body  CreateStudentRequest  true  "Student data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students [post]
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

// GetByID godoc
// @Summary      Get a student by ID
// @Description  Retrieve a single student by their unique identifier.
// @Tags         students
// @Produce      json
// @Param        id  path  string  true  "Student ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students/{id} [get]
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

// List godoc
// @Summary      List students
// @Description  Retrieve a paginated list of students.
// @Tags         students
// @Produce      json
// @Param        offset  query  int  false  "Pagination offset"
// @Param        limit   query  int  false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students [get]
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

// Update godoc
// @Summary      Update a student
// @Description  Update an existing student's profile information.
// @Tags         students
// @Accept       json
// @Produce      json
// @Param        id    path  string                  true  "Student ID (UUID)"
// @Param        body  body  UpdateStudentRequest     true  "Updated student data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students/{id} [put]
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

// Delete godoc
// @Summary      Delete a student
// @Description  Soft-delete a student by their unique identifier.
// @Tags         students
// @Produce      json
// @Param        id  path  string  true  "Student ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students/{id} [delete]
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

// GetEnrollmentHistory godoc
// @Summary      Get student enrollment history
// @Description  Retrieve the full enrollment history for a specific student.
// @Tags         students
// @Produce      json
// @Param        id  path  string  true  "Student ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students/{id}/enrollment-history [get]
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

// GetRecommendations godoc
// @Summary      Get student course recommendations
// @Description  Retrieve course recommendations for a specific student based on their history and profile.
// @Tags         students
// @Produce      json
// @Param        id  path  string  true  "Student ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students/{id}/recommendations [get]
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

// GetNotes godoc
// @Summary      Get student notes
// @Description  Retrieve all notes attached to a student profile.
// @Tags         students
// @Produce      json
// @Param        id  path  string  true  "Student ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students/{id}/notes [get]
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

// AddNote godoc
// @Summary      Add a note to a student
// @Description  Attach a new note to a student profile. Author is derived from the authenticated user.
// @Tags         students
// @Accept       json
// @Produce      json
// @Param        id    path  string           true  "Student ID (UUID)"
// @Param        body  body  AddNoteRequest   true  "Note content"
// @Success      201  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /students/{id}/notes [post]
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
