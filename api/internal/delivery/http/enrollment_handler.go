package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_enrollment"
	grantappaccess "github.com/vernonedu/entrepreneurship-api/internal/command/grant_app_access"
	revokeappaccess "github.com/vernonedu/entrepreneurship-api/internal/command/revoke_app_access"
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

// EnrollStudent godoc
// @Summary      Enroll a student into a course batch
// @Description  Create a new enrollment for a student in a specific course batch. Triggers auto-invoice generation and referral commission if applicable.
// @Tags         enrollments
// @Accept       json
// @Produce      json
// @Param        body  body  CreateEnrollmentRequest  true  "Enrollment data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /enrollments [post]
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

// GetByID godoc
// @Summary      Get an enrollment by ID
// @Description  Retrieve a single enrollment by its unique identifier.
// @Tags         enrollments
// @Produce      json
// @Param        id  path  string  true  "Enrollment ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /enrollments/{id} [get]
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

// List godoc
// @Summary      List enrollments
// @Description  Retrieve a paginated list of enrollments.
// @Tags         enrollments
// @Produce      json
// @Param        offset  query  int  false  "Pagination offset"
// @Param        limit   query  int  false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /enrollments [get]
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

// ListBatchSummary godoc
// @Summary      List enrollment summaries per batch
// @Description  Retrieve a summary of enrollments aggregated by course batch.
// @Tags         enrollments
// @Produce      json
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /enrollments/summary [get]
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

// UpdateStatus godoc
// @Summary      Update enrollment status
// @Description  Update the status of an enrollment (e.g. active, withdrawn, completed).
// @Tags         enrollments
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Enrollment ID (UUID)"
// @Param        body  body  object  true  "Status update (status field)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /enrollments/{id}/status [put]
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

// UpdatePaymentStatus godoc
// @Summary      Update enrollment payment status
// @Description  Update the payment status of an enrollment (e.g. paid, unpaid, partial, overdue).
// @Tags         enrollments
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Enrollment ID (UUID)"
// @Param        body  body  object  true  "Payment status update (payment_status field)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /enrollments/{id}/payment-status [put]
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

// resolveEnrollment looks up an enrollment and returns its student and batch IDs.
func (h *EnrollmentHandler) resolveEnrollment(r *http.Request, enrollmentID uuid.UUID) (*get_enrollment.EnrollmentReadModel, error) {
	result, err := h.qryBus.Execute(r.Context(), &get_enrollment.GetEnrollmentQuery{EnrollmentID: enrollmentID})
	if err != nil {
		return nil, err
	}
	model, ok := result.(*get_enrollment.EnrollmentReadModel)
	if !ok {
		return nil, http.ErrAbortHandler
	}
	return model, nil
}

type GrantAppAccessRequest struct {
	AppName string `json:"app_name"`
}

// GrantAppAccess godoc
// @Summary      Grant app access to a student
// @Description  Grant a student access to a supporting application (e.g. app-student, app-entrepreneur) for the enrollment's batch.
// @Tags         enrollments
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Enrollment ID (UUID)"
// @Param        body  body  GrantAppAccessRequest  true  "App name to grant (defaults to app-student)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /enrollments/{id}/access/grant [post]
func (h *EnrollmentHandler) GrantAppAccess(w http.ResponseWriter, r *http.Request) {
	enrollmentIDStr := chi.URLParam(r, "id")
	enrollmentID, err := uuid.Parse(enrollmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid enrollment id")
		return
	}

	var req GrantAppAccessRequest
	if r.ContentLength > 0 {
		_ = json.NewDecoder(r.Body).Decode(&req)
	}

	model, err := h.resolveEnrollment(r, enrollmentID)
	if err != nil {
		log.Error().Err(err).Msg("failed to resolve enrollment for grant app access")
		writeError(w, http.StatusNotFound, "enrollment not found")
		return
	}

	appName := req.AppName
	if appName == "" {
		appName = "app-student"
	}

	cmd := &grantappaccess.GrantAppAccessCommand{
		StudentID: model.StudentID,
		AppName:   appName,
		BatchID:   model.CourseBatchID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to grant app access")
		writeError(w, http.StatusInternalServerError, "failed to grant app access")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "app access granted"})
}

type RevokeAppAccessRequest struct {
	Reason string `json:"reason"`
}

// RevokeAppAccess godoc
// @Summary      Revoke app access from a student
// @Description  Revoke a student's access to a supporting application for the enrollment's batch.
// @Tags         enrollments
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Enrollment ID (UUID)"
// @Param        body  body  RevokeAppAccessRequest  true  "Revocation reason"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /enrollments/{id}/access/revoke [post]
func (h *EnrollmentHandler) RevokeAppAccess(w http.ResponseWriter, r *http.Request) {
	enrollmentIDStr := chi.URLParam(r, "id")
	enrollmentID, err := uuid.Parse(enrollmentIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid enrollment id")
		return
	}

	var req RevokeAppAccessRequest
	if r.ContentLength > 0 {
		_ = json.NewDecoder(r.Body).Decode(&req)
	}

	model, err := h.resolveEnrollment(r, enrollmentID)
	if err != nil {
		log.Error().Err(err).Msg("failed to resolve enrollment for revoke app access")
		writeError(w, http.StatusNotFound, "enrollment not found")
		return
	}

	reason := req.Reason
	if reason == "" {
		reason = "manual_revoke"
	}

	cmd := &revokeappaccess.RevokeAppAccessCommand{
		StudentID: model.StudentID,
		BatchID:   model.CourseBatchID,
		Reason:    reason,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to revoke app access")
		writeError(w, http.StatusInternalServerError, "failed to revoke app access")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "app access revoked"})
}

func RegisterEnrollmentRoutes(h *EnrollmentHandler, r chi.Router) {
	r.Post("/api/v1/enrollments", h.EnrollStudent)
	r.Get("/api/v1/enrollments/summary", h.ListBatchSummary)
	r.Get("/api/v1/enrollments", h.List)
	r.Get("/api/v1/enrollments/{id}", h.GetByID)
	r.Put("/api/v1/enrollments/{id}/status", h.UpdateStatus)
	r.Put("/api/v1/enrollments/{id}/payment-status", h.UpdatePaymentStatus)
	r.Post("/api/v1/enrollments/{id}/access/grant", h.GrantAppAccess)
	r.Post("/api/v1/enrollments/{id}/access/revoke", h.RevokeAppAccess)
}
