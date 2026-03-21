package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_enrollment"
	updateenrollmentpayment "github.com/vernonedu/entrepreneurship-api/internal/command/update_enrollment_payment_status"
	updateenrollmentstatus "github.com/vernonedu/entrepreneurship-api/internal/command/update_enrollment_status"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_enrollment"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_enrollment"
	listenrollmentsummary "github.com/vernonedu/entrepreneurship-api/internal/query/list_enrollment_summary"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type EnrollmentHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewEnrollmentHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *EnrollmentHandler {
	return &EnrollmentHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateEnrollmentRequest struct {
	StudentID     string `json:"student_id" validate:"required"`
	CourseBatchID string `json:"course_batch_id" validate:"required"`
}

func (h *EnrollmentHandler) EnrollStudent(w http.ResponseWriter, r *http.Request) {
	var req CreateEnrollmentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	studentID, err := uuid.Parse(req.StudentID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid student id")
		return
	}

	courseBatchID, err := uuid.Parse(req.CourseBatchID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course batch id")
		return
	}

	cmd := &create_enrollment.CreateEnrollmentCommand{
		StudentID:     studentID,
		CourseBatchID: courseBatchID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create enrollment command")
		writeError(w, http.StatusInternalServerError, "failed to create enrollment")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "enrollment created successfully"})
}

func (h *EnrollmentHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	enrollmentIDStr := chi.URLParam(r, "id")
	enrollmentID, err := uuid.Parse(enrollmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid enrollment id")
		return
	}

	query := &get_enrollment.GetEnrollmentQuery{EnrollmentID: enrollmentID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get enrollment query")
		writeError(w, http.StatusInternalServerError, "failed to get enrollment")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *EnrollmentHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_enrollment.ListEnrollmentQuery{Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list enrollment query")
		writeError(w, http.StatusInternalServerError, "failed to list enrollments")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (h *EnrollmentHandler) ListBatchSummary(w http.ResponseWriter, r *http.Request) {
	query := &listenrollmentsummary.ListEnrollmentSummaryQuery{}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list enrollment summary query")
		writeError(w, http.StatusInternalServerError, "failed to list enrollment summary")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *EnrollmentHandler) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	enrollmentIDStr := chi.URLParam(r, "id")
	enrollmentID, err := uuid.Parse(enrollmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid enrollment id")
		return
	}
	var req struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updateenrollmentstatus.UpdateEnrollmentStatusCommand{
		EnrollmentID: enrollmentID,
		Status:       req.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update enrollment status")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "enrollment status updated"})
}

func (h *EnrollmentHandler) UpdatePaymentStatus(w http.ResponseWriter, r *http.Request) {
	enrollmentIDStr := chi.URLParam(r, "id")
	enrollmentID, err := uuid.Parse(enrollmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid enrollment id")
		return
	}
	var req struct {
		PaymentStatus string `json:"payment_status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updateenrollmentpayment.UpdateEnrollmentPaymentStatusCommand{
		EnrollmentID:  enrollmentID,
		PaymentStatus: req.PaymentStatus,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update enrollment payment status")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "enrollment payment status updated"})
}

func RegisterEnrollmentRoutes(h *EnrollmentHandler, r chi.Router) {
	r.Post("/api/v1/enrollments", h.EnrollStudent)
	r.Get("/api/v1/enrollments/summary", h.ListBatchSummary)
	r.Get("/api/v1/enrollments", h.List)
	r.Get("/api/v1/enrollments/{id}", h.GetByID)
	r.Put("/api/v1/enrollments/{id}/status", h.UpdateStatus)
	r.Put("/api/v1/enrollments/{id}/payment-status", h.UpdatePaymentStatus)
}
