package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	archive_mastercourse "github.com/vernonedu/entrepreneurship-api/internal/command/archive_mastercourse"
	create_mastercourse "github.com/vernonedu/entrepreneurship-api/internal/command/create_mastercourse"
	delete_mastercourse "github.com/vernonedu/entrepreneurship-api/internal/command/delete_mastercourse"
	update_mastercourse "github.com/vernonedu/entrepreneurship-api/internal/command/update_mastercourse"
	get_mastercourse "github.com/vernonedu/entrepreneurship-api/internal/query/get_mastercourse"
	list_mastercourse "github.com/vernonedu/entrepreneurship-api/internal/query/list_mastercourse"
	"github.com/vernonedu/entrepreneurship-api/infrastructure/database"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// MasterCourseHandler menangani request HTTP untuk resource MasterCourse.
type MasterCourseHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
	repo   *database.MasterCourseRepository
}

// NewMasterCourseHandler membuat instance baru MasterCourseHandler.
func NewMasterCourseHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus, repo *database.MasterCourseRepository) *MasterCourseHandler {
	return &MasterCourseHandler{cmdBus: cmdBus, qryBus: qryBus, repo: repo}
}

// CreateMasterCourseRequest adalah request body untuk membuat MasterCourse baru.
type CreateMasterCourseRequest struct {
	CourseCode       string   `json:"course_code" validate:"required"`
	CourseName       string   `json:"course_name" validate:"required,min=1"`
	Field            string   `json:"field" validate:"required"`
	CoreCompetencies []string `json:"core_competencies"`
	Description      string   `json:"description"`
	SupportingAppUrl string   `json:"supporting_app_url"`
}

// UpdateMasterCourseRequest adalah request body untuk memperbarui MasterCourse.
type UpdateMasterCourseRequest struct {
	CourseName       string   `json:"course_name" validate:"required,min=1"`
	Field            string   `json:"field" validate:"required"`
	CoreCompetencies []string `json:"core_competencies"`
	Description      string   `json:"description"`
	SupportingAppUrl string   `json:"supporting_app_url"`
}

// Create menangani POST /api/v1/curriculum/courses
func (h *MasterCourseHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateMasterCourseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_mastercourse.CreateMasterCourseCommand{
		CourseCode:       req.CourseCode,
		CourseName:       req.CourseName,
		Field:            req.Field,
		CoreCompetencies: req.CoreCompetencies,
		Description:      req.Description,
		SupportingAppUrl: req.SupportingAppUrl,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create master course command")
		writeError(w, http.StatusInternalServerError, "failed to create master course")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "master course created successfully"})
}

// List menangani GET /api/v1/curriculum/courses
func (h *MasterCourseHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}
	status := r.URL.Query().Get("status")
	field := r.URL.Query().Get("field")

	query := &list_mastercourse.ListMasterCourseQuery{
		Offset: offset,
		Limit:  limit,
		Status: status,
		Field:  field,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list master course query")
		writeError(w, http.StatusInternalServerError, "failed to list master courses")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// GetByID menangani GET /api/v1/curriculum/courses/{id}
func (h *MasterCourseHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid master course id")
		return
	}

	query := &get_mastercourse.GetMasterCourseQuery{MasterCourseID: id}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get master course query")
		writeError(w, http.StatusInternalServerError, "failed to get master course")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Update menangani PUT /api/v1/curriculum/courses/{id}
func (h *MasterCourseHandler) Update(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid master course id")
		return
	}

	var req UpdateMasterCourseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_mastercourse.UpdateMasterCourseCommand{
		MasterCourseID:   id,
		CourseName:       req.CourseName,
		Field:            req.Field,
		CoreCompetencies: req.CoreCompetencies,
		Description:      req.Description,
		SupportingAppUrl: req.SupportingAppUrl,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update master course command")
		writeError(w, http.StatusInternalServerError, "failed to update master course")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "master course updated successfully"})
}

// Archive menangani POST /api/v1/curriculum/courses/{id}/archive
func (h *MasterCourseHandler) Archive(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid master course id")
		return
	}

	cmd := &archive_mastercourse.ArchiveMasterCourseCommand{MasterCourseID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute archive master course command")
		writeError(w, http.StatusInternalServerError, "failed to archive master course")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "master course archived successfully"})
}

// Delete menangani DELETE /api/v1/curriculum/courses/{id}
func (h *MasterCourseHandler) Delete(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid master course id")
		return
	}

	cmd := &delete_mastercourse.DeleteMasterCourseCommand{MasterCourseID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete master course command")
		writeError(w, http.StatusInternalServerError, "failed to delete master course")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "master course deleted successfully"})
}

// ListBatches menangani GET /api/v1/curriculum/courses/{id}/batches
func (h *MasterCourseHandler) ListBatches(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course id")
		return
	}
	batches, err := h.repo.ListBatchesByMasterCourse(r.Context(), id)
	if err != nil {
		log.Error().Err(err).Msg("failed to list batches by master course")
		writeError(w, http.StatusInternalServerError, "failed to list batches")
		return
	}
	type BatchResponse struct {
		ID              string `json:"id"`
		Name            string `json:"name"`
		StartDate       string `json:"start_date"`
		EndDate         string `json:"end_date"`
		Status          string `json:"status"`
		MaxParticipants int    `json:"max_participants"`
		SessionCount    int    `json:"session_count"`
		Location        string `json:"location"`
		EnrollmentCount int    `json:"enrollment_count"`
	}
	result := make([]BatchResponse, len(batches))
	for i, b := range batches {
		result[i] = BatchResponse{
			ID:              b.ID.String(),
			Name:            b.Name,
			StartDate:       b.StartDate.Format("2006-01-02"),
			EndDate:         b.EndDate.Format("2006-01-02"),
			Status:          b.Status,
			MaxParticipants: b.MaxParticipants,
			SessionCount:    b.SessionCount,
			Location:        b.Location,
			EnrollmentCount: b.EnrollmentCount,
		}
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ListStudents menangani GET /api/v1/curriculum/courses/{id}/students
func (h *MasterCourseHandler) ListStudents(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course id")
		return
	}
	students, err := h.repo.ListStudentsByMasterCourse(r.Context(), id)
	if err != nil {
		log.Error().Err(err).Msg("failed to list students by master course")
		writeError(w, http.StatusInternalServerError, "failed to list students")
		return
	}
	type StudentResponse struct {
		ID            string `json:"id"`
		Name          string `json:"name"`
		Email         string `json:"email"`
		Phone         string `json:"phone"`
		BatchName     string `json:"batch_name"`
		EnrollStatus  string `json:"enroll_status"`
		PaymentStatus string `json:"payment_status"`
		EnrolledAt    string `json:"enrolled_at"`
	}
	result := make([]StudentResponse, len(students))
	for i, s := range students {
		result[i] = StudentResponse{
			ID:            s.ID.String(),
			Name:          s.Name,
			Email:         s.Email,
			Phone:         s.Phone,
			BatchName:     s.BatchName,
			EnrollStatus:  s.EnrollStatus,
			PaymentStatus: s.PaymentStatus,
			EnrolledAt:    s.EnrolledAt.Format("2006-01-02"),
		}
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// RegisterMasterCourseRoutes mendaftarkan semua route MasterCourse ke router.
func RegisterMasterCourseRoutes(h *MasterCourseHandler, r chi.Router) {
	r.Post("/api/v1/curriculum/courses", h.Create)
	r.Get("/api/v1/curriculum/courses", h.List)
	r.Get("/api/v1/curriculum/courses/{id}", h.GetByID)
	r.Put("/api/v1/curriculum/courses/{id}", h.Update)
	r.Post("/api/v1/curriculum/courses/{id}/archive", h.Archive)
	r.Delete("/api/v1/curriculum/courses/{id}", h.Delete)
	r.Get("/api/v1/curriculum/courses/{id}/batches", h.ListBatches)
	r.Get("/api/v1/curriculum/courses/{id}/students", h.ListStudents)
}
