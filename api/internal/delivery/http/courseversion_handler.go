package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	approve_courseversion "github.com/vernonedu/entrepreneurship-api/internal/command/approve_courseversion"
	create_courseversion "github.com/vernonedu/entrepreneurship-api/internal/command/create_courseversion"
	promote_courseversion "github.com/vernonedu/entrepreneurship-api/internal/command/promote_courseversion"
	reject_courseversion "github.com/vernonedu/entrepreneurship-api/internal/command/reject_courseversion"
	submit_courseversion "github.com/vernonedu/entrepreneurship-api/internal/command/submit_courseversion"
	get_courseversion "github.com/vernonedu/entrepreneurship-api/internal/query/get_courseversion"
	list_courseversion "github.com/vernonedu/entrepreneurship-api/internal/query/list_courseversion"
	list_pending_courseversions "github.com/vernonedu/entrepreneurship-api/internal/query/list_pending_courseversions"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
	"github.com/vernonedu/entrepreneurship-api/pkg/sortutil"
)

// Role keys yang digunakan untuk gating workflow approval (mirror dari pkg/middleware).
const (
	roleCourseOwner = "course_owner"
	roleDeptLeader  = "dept_leader"
)

// CourseVersionHandler menangani request HTTP untuk resource CourseVersion.
type CourseVersionHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewCourseVersionHandler membuat instance baru CourseVersionHandler.
func NewCourseVersionHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *CourseVersionHandler {
	return &CourseVersionHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// CreateCourseVersionRequest adalah request body untuk membuat CourseVersion baru.
type CreateCourseVersionRequest struct {
	VersionNumber string  `json:"version_number" validate:"required"`
	ChangeType    string  `json:"change_type" validate:"required"`
	Changelog     string  `json:"changelog"`
	CreatedBy     *string `json:"created_by"` // UUID opsional
}

// PromoteCourseVersionRequest adalah request body untuk mempromosikan status CourseVersion.
type PromoteCourseVersionRequest struct {
	TargetStatus string  `json:"target_status" validate:"required"` // "review" | "approved"
	ApprovedBy   *string `json:"approved_by"`                        // UUID opsional, wajib jika approved
}

// Create godoc
// @Summary      Create a course version
// @Description  Create a new version of a course type with version number, change type, and changelog
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        typeID  path  string                         true  "Course Type ID (UUID)"
// @Param        body    body  CreateCourseVersionRequest     true  "Course version creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /curriculum/types/{typeID}/versions [post]
func (h *CourseVersionHandler) Create(w http.ResponseWriter, r *http.Request) {
	typeIDStr := chi.URLParam(r, "typeID")
	typeID, err := uuid.Parse(typeIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid type id")
		return
	}

	var req CreateCourseVersionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_courseversion.CreateCourseVersionCommand{
		CourseTypeID:  typeID,
		VersionNumber: req.VersionNumber,
		ChangeType:    req.ChangeType,
		Changelog:     req.Changelog,
	}
	if req.CreatedBy != nil {
		parsedID, parseErr := uuid.Parse(*req.CreatedBy)
		if parseErr == nil {
			cmd.CreatedBy = &parsedID
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create course version command")
		writeError(w, http.StatusInternalServerError, "failed to create course version")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "course version created successfully"})
}

// ListByType godoc
// @Summary      List course versions by type
// @Description  Retrieve all course versions for a given course type
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        typeID  path  string  true  "Course Type ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /curriculum/types/{typeID}/versions [get]
func (h *CourseVersionHandler) ListByType(w http.ResponseWriter, r *http.Request) {
	typeIDStr := chi.URLParam(r, "typeID")
	typeID, err := uuid.Parse(typeIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid type id")
		return
	}

	var sortBy, sortDir string
	if s := sortutil.Parse(r.URL.Query().Get("sort")); s != nil {
		sortBy = s.Column
		sortDir = s.Dir
	}

	query := &list_courseversion.ListCourseVersionQuery{
		CourseTypeID: typeID,
		SortBy:       sortBy,
		SortDir:      sortDir,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list course version query")
		writeError(w, http.StatusInternalServerError, "failed to list course versions")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetByID godoc
// @Summary      Get course version by ID
// @Description  Retrieve a single course version by its UUID
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        versionID  path  string  true  "Course Version ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /curriculum/versions/{versionID} [get]
func (h *CourseVersionHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	query := &get_courseversion.GetCourseVersionQuery{VersionID: versionID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get course version query")
		writeError(w, http.StatusInternalServerError, "failed to get course version")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Promote godoc
// @Summary      Promote course version status
// @Description  Promote a course version to a target status (e.g. review, approved)
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        versionID  path  string                          true  "Course Version ID (UUID)"
// @Param        body       body  PromoteCourseVersionRequest     true  "Promote payload with target_status"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /curriculum/versions/{versionID}/promote [post]
func (h *CourseVersionHandler) Promote(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	var req PromoteCourseVersionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &promote_courseversion.PromoteCourseVersionCommand{
		VersionID:    versionID,
		TargetStatus: req.TargetStatus,
	}
	if req.ApprovedBy != nil {
		parsedID, parseErr := uuid.Parse(*req.ApprovedBy)
		if parseErr == nil {
			cmd.ApprovedBy = &parsedID
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute promote course version command")
		writeError(w, http.StatusInternalServerError, "failed to promote course version")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course version promoted successfully"})
}

// RejectCourseVersionRequest adalah request body untuk reject endpoint.
type RejectCourseVersionRequest struct {
	Reason string `json:"reason" validate:"required"`
}

// Submit godoc
// @Summary      Submit course version for review
// @Description  Submit a course version for review (course_owner role required)
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        versionID  path  string  true  "Course Version ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Security     BearerAuth
// @Router       /curriculum/versions/{versionID}/submit [post]
func (h *CourseVersionHandler) Submit(w http.ResponseWriter, r *http.Request) {
	if !middleware.HasRole(r.Context(), roleCourseOwner) {
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}
	versionID, ok := parseURLParamUUID(w, r, "versionID")
	if !ok {
		return
	}
	userID, ok := parseAuthUserID(w, r)
	if !ok {
		return
	}
	cmd := &submit_courseversion.SubmitCourseVersionCommand{VersionID: versionID, SubmittedBy: userID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to submit course version")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "course version submitted"})
}

// Approve godoc
// @Summary      Approve course version
// @Description  Approve a course version (dept_leader role required)
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        versionID  path  string  true  "Course Version ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Security     BearerAuth
// @Router       /curriculum/versions/{versionID}/approve [post]
func (h *CourseVersionHandler) Approve(w http.ResponseWriter, r *http.Request) {
	if !middleware.HasRole(r.Context(), roleDeptLeader) {
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}
	versionID, ok := parseURLParamUUID(w, r, "versionID")
	if !ok {
		return
	}
	userID, ok := parseAuthUserID(w, r)
	if !ok {
		return
	}
	cmd := &approve_courseversion.ApproveCourseVersionCommand{VersionID: versionID, ApprovedBy: userID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to approve course version")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "course version approved"})
}

// Reject godoc
// @Summary      Reject course version
// @Description  Reject a course version with a reason (dept_leader role required)
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        versionID  path  string                         true  "Course Version ID (UUID)"
// @Param        body       body  RejectCourseVersionRequest     true  "Rejection payload with reason"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Security     BearerAuth
// @Router       /curriculum/versions/{versionID}/reject [post]
func (h *CourseVersionHandler) Reject(w http.ResponseWriter, r *http.Request) {
	if !middleware.HasRole(r.Context(), roleDeptLeader) {
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}
	versionID, ok := parseURLParamUUID(w, r, "versionID")
	if !ok {
		return
	}
	userID, ok := parseAuthUserID(w, r)
	if !ok {
		return
	}
	var req RejectCourseVersionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &reject_courseversion.RejectCourseVersionCommand{
		VersionID:  versionID,
		ApprovedBy: userID,
		Reason:     req.Reason,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to reject course version")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "course version rejected"})
}

// ListPending godoc
// @Summary      List pending course versions
// @Description  Retrieve all course versions pending review (dept_leader role required). Optional department_id filter.
// @Tags         curriculum
// @Accept       json
// @Produce      json
// @Param        department_id  query  string  false  "Filter by Department ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      403  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /curriculum/versions/pending [get]
func (h *CourseVersionHandler) ListPending(w http.ResponseWriter, r *http.Request) {
	if !middleware.HasRole(r.Context(), roleDeptLeader) {
		writeError(w, http.StatusForbidden, "forbidden")
		return
	}
	q := &list_pending_courseversions.ListPendingCourseVersionsQuery{}
	if deptStr := r.URL.Query().Get("department_id"); deptStr != "" {
		if deptID, err := uuid.Parse(deptStr); err == nil {
			q.DepartmentID = &deptID
		}
	}
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to list pending course versions")
		writeError(w, http.StatusInternalServerError, "failed to list pending course versions")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// parseURLParamUUID mengurai URL param sebagai UUID, menulis 400 dan mengembalikan ok=false bila gagal.
func parseURLParamUUID(w http.ResponseWriter, r *http.Request, name string) (uuid.UUID, bool) {
	raw := chi.URLParam(r, name)
	id, err := uuid.Parse(raw)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}

// parseAuthUserID mengambil user ID dari context auth (JWT middleware), 401 bila tidak ada.
func parseAuthUserID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	userIDStr := middleware.GetUserIDFromContext(r.Context())
	id, err := uuid.Parse(userIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return uuid.Nil, false
	}
	return id, true
}

// RegisterCourseVersionRoutes mendaftarkan semua route CourseVersion ke router.
func RegisterCourseVersionRoutes(h *CourseVersionHandler, r chi.Router) {
	r.Post("/api/v1/curriculum/types/{typeID}/versions", h.Create)
	r.Get("/api/v1/curriculum/types/{typeID}/versions", h.ListByType)
	r.Get("/api/v1/curriculum/versions/pending", h.ListPending)
	r.Get("/api/v1/curriculum/versions/{versionID}", h.GetByID)
	r.Post("/api/v1/curriculum/versions/{versionID}/promote", h.Promote)
	r.Post("/api/v1/curriculum/versions/{versionID}/submit", h.Submit)
	r.Post("/api/v1/curriculum/versions/{versionID}/approve", h.Approve)
	r.Post("/api/v1/curriculum/versions/{versionID}/reject", h.Reject)
}
