package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	assignfacilitator "github.com/vernonedu/entrepreneurship-api/internal/command/assign_batch_facilitator"
	create_batch_schedule "github.com/vernonedu/entrepreneurship-api/internal/command/create_batch_schedule"
	"github.com/vernonedu/entrepreneurship-api/internal/command/create_course_batch"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_course_batch"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_course_batch"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/batchschedule"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_course_batch"
	getcoursebatchdetail "github.com/vernonedu/entrepreneurship-api/internal/query/get_course_batch_detail"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_course_batch"
	list_batch_schedules "github.com/vernonedu/entrepreneurship-api/internal/query/list_batch_schedules"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type CourseBatchHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewCourseBatchHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *CourseBatchHandler {
	return &CourseBatchHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateCourseBatchRequest struct {
	CourseID        string `json:"course_id"`
	MasterCourseID  string `json:"master_course_id"`
	BranchID        string `json:"branch_id"` // optional UUID string
	Code            string `json:"code"`
	Name            string `json:"name" validate:"required,min=1"`
	StartDate       string `json:"start_date" validate:"required"`
	EndDate         string `json:"end_date" validate:"required"`
	MinParticipants int    `json:"min_participants"`
	MaxParticipants int    `json:"max_participants" validate:"required,min=1"`
	IsActive        bool   `json:"is_active"`
	WebsiteVisible  bool   `json:"website_visible"`
	Price           int64  `json:"price"`
	PaymentMethod   string `json:"payment_method"`
}

func parseDate(s string) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t, nil
	}
	return time.Parse("2006-01-02", s)
}

type UpdateCourseBatchRequest struct {
	BranchID        string `json:"branch_id"` // optional UUID string
	Name            string `json:"name" validate:"required,min=1"`
	StartDate       string `json:"start_date" validate:"required"`
	EndDate         string `json:"end_date" validate:"required"`
	MinParticipants int    `json:"min_participants"`
	MaxParticipants int    `json:"max_participants" validate:"required,min=1"`
	IsActive        bool   `json:"is_active"`
	WebsiteVisible  bool   `json:"website_visible"`
	Price           int64  `json:"price"`
	PaymentMethod   string `json:"payment_method"`
}

func (h *CourseBatchHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateCourseBatchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	courseID := uuid.Nil
	if req.CourseID != "" {
		if id, err := uuid.Parse(req.CourseID); err == nil {
			courseID = id
		}
	}

	var masterCourseID *uuid.UUID
	if req.MasterCourseID != "" {
		if id, err := uuid.Parse(req.MasterCourseID); err == nil {
			masterCourseID = &id
		}
	}

	var branchID *uuid.UUID
	if req.BranchID != "" {
		if id, err := uuid.Parse(req.BranchID); err == nil {
			branchID = &id
		}
	}

	startDate, err := parseDate(req.StartDate)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid start_date format, use YYYY-MM-DD or RFC3339")
		return
	}

	endDate, err := parseDate(req.EndDate)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid end_date format, use YYYY-MM-DD or RFC3339")
		return
	}

	// Extract creator role and initiator ID from context
	roles := pkgmiddleware.GetRolesFromContext(r.Context())
	creatorRole := ""
	for _, role := range roles {
		if role == "operation_admin" {
			creatorRole = "operation_admin"
			break
		}
		if role == "course_owner" {
			creatorRole = "course_owner"
		}
	}

	initiatorID := uuid.Nil
	if userIDStr := pkgmiddleware.GetUserIDFromContext(r.Context()); userIDStr != "" {
		if id, err := uuid.Parse(userIDStr); err == nil {
			initiatorID = id
		}
	}

	cmd := &create_course_batch.CreateCourseBatchCommand{
		CourseID:        courseID,
		MasterCourseID:  masterCourseID,
		BranchID:        branchID,
		Code:            req.Code,
		Name:            req.Name,
		StartDate:       startDate,
		EndDate:         endDate,
		MinParticipants: req.MinParticipants,
		MaxParticipants: req.MaxParticipants,
		IsActive:        req.IsActive,
		WebsiteVisible:  req.WebsiteVisible,
		Price:           req.Price,
		PaymentMethod:   req.PaymentMethod,
		CreatorRole:     creatorRole,
		InitiatorID:     initiatorID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create course batch command")
		writeError(w, http.StatusInternalServerError, "failed to create course batch")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "course batch created successfully"})
}

func (h *CourseBatchHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	courseBatchIDStr := chi.URLParam(r, "id")
	courseBatchID, err := uuid.Parse(courseBatchIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course batch id")
		return
	}

	query := &get_course_batch.GetCourseBatchQuery{CourseBatchID: courseBatchID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get course batch query")
		writeError(w, http.StatusInternalServerError, "failed to get course batch")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *CourseBatchHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_course_batch.ListCourseBatchQuery{Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list course batch query")
		writeError(w, http.StatusInternalServerError, "failed to list course batches")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (h *CourseBatchHandler) Update(w http.ResponseWriter, r *http.Request) {
	courseBatchIDStr := chi.URLParam(r, "id")
	courseBatchID, err := uuid.Parse(courseBatchIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course batch id")
		return
	}

	var req UpdateCourseBatchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	var updateBranchID *uuid.UUID
	if req.BranchID != "" {
		if id, err := uuid.Parse(req.BranchID); err == nil {
			updateBranchID = &id
		}
	}

	startDate, err := parseDate(req.StartDate)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid start_date format, use YYYY-MM-DD or RFC3339")
		return
	}

	endDate, err := parseDate(req.EndDate)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid end_date format, use YYYY-MM-DD or RFC3339")
		return
	}

	cmd := &update_course_batch.UpdateCourseBatchCommand{
		CourseBatchID:   courseBatchID,
		BranchID:        updateBranchID,
		Name:            req.Name,
		StartDate:       startDate,
		EndDate:         endDate,
		MinParticipants: req.MinParticipants,
		MaxParticipants: req.MaxParticipants,
		IsActive:        req.IsActive,
		WebsiteVisible:  req.WebsiteVisible,
		Price:           req.Price,
		PaymentMethod:   req.PaymentMethod,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update course batch command")
		writeError(w, http.StatusInternalServerError, "failed to update course batch")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course batch updated successfully"})
}

func (h *CourseBatchHandler) Delete(w http.ResponseWriter, r *http.Request) {
	courseBatchIDStr := chi.URLParam(r, "id")
	courseBatchID, err := uuid.Parse(courseBatchIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course batch id")
		return
	}

	cmd := &delete_course_batch.DeleteCourseBatchCommand{CourseBatchID: courseBatchID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete course batch command")
		writeError(w, http.StatusInternalServerError, "failed to delete course batch")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course batch deleted successfully"})
}

func (h *CourseBatchHandler) GetDetail(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	batchID, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course batch id")
		return
	}

	query := &getcoursebatchdetail.GetCourseBatchDetailQuery{CourseBatchID: batchID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get course batch detail query")
		writeError(w, http.StatusInternalServerError, "failed to get course batch detail")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type AssignFacilitatorRequest struct {
	FacilitatorID string `json:"facilitator_id"` // empty = unassign
}

func (h *CourseBatchHandler) AssignFacilitator(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	if _, err := uuid.Parse(idStr); err != nil {
		writeError(w, http.StatusBadRequest, "invalid course batch id")
		return
	}

	var req AssignFacilitatorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &assignfacilitator.AssignBatchFacilitatorCommand{
		BatchID:       idStr,
		FacilitatorID: req.FacilitatorID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to assign facilitator")
		writeError(w, http.StatusInternalServerError, "failed to assign facilitator")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "facilitator assigned successfully"})
}

// CreateSchedule handles POST /api/v1/course-batches/{id}/schedules
func (h *CourseBatchHandler) CreateSchedule(w http.ResponseWriter, r *http.Request) {
	batchIDStr := chi.URLParam(r, "id")
	batchID, err := uuid.Parse(batchIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid batch id")
		return
	}

	var body struct {
		ModuleID        string    `json:"module_id"`
		RoomID          string    `json:"room_id"`
		ScheduledAt     time.Time `json:"scheduled_at"`
		DurationMinutes int       `json:"duration_minutes"`
		Notes           string    `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if body.DurationMinutes == 0 {
		body.DurationMinutes = 60 // default 60 minutes
	}

	cmd := &create_batch_schedule.CreateBatchScheduleCommand{
		CourseBatchID:   batchID,
		ModuleID:        body.ModuleID,
		RoomID:          body.RoomID,
		ScheduledAt:     body.ScheduledAt,
		DurationMinutes: body.DurationMinutes,
		Notes:           body.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		if errors.Is(err, batchschedule.ErrRoomConflict) {
			writeError(w, http.StatusConflict, "room is already booked for the requested time slot")
			return
		}
		log.Error().Err(err).Msg("failed to create batch schedule")
		writeError(w, http.StatusInternalServerError, "failed to create schedule")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "schedule created successfully"})
}

// ListSchedules handles GET /api/v1/course-batches/{id}/schedules
func (h *CourseBatchHandler) ListSchedules(w http.ResponseWriter, r *http.Request) {
	batchIDStr := chi.URLParam(r, "id")
	batchID, err := uuid.Parse(batchIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid batch id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &list_batch_schedules.ListBatchSchedulesQuery{CourseBatchID: batchID})
	if err != nil {
		log.Error().Err(err).Msg("failed to list batch schedules")
		writeError(w, http.StatusInternalServerError, "failed to list schedules")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func RegisterCourseBatchRoutes(h *CourseBatchHandler, r chi.Router) {
	r.Post("/api/v1/course-batches", h.Create)
	r.Get("/api/v1/course-batches", h.List)
	r.Get("/api/v1/course-batches/{id}/detail", h.GetDetail)
	r.Put("/api/v1/course-batches/{id}/facilitator", h.AssignFacilitator)
	r.Post("/api/v1/course-batches/{id}/schedules", h.CreateSchedule)
	r.Get("/api/v1/course-batches/{id}/schedules", h.ListSchedules)
	r.Get("/api/v1/course-batches/{id}", h.GetByID)
	r.Put("/api/v1/course-batches/{id}", h.Update)
	r.Delete("/api/v1/course-batches/{id}", h.Delete)
}
