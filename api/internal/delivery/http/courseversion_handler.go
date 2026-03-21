package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	create_courseversion "github.com/vernonedu/entrepreneurship-api/internal/command/create_courseversion"
	promote_courseversion "github.com/vernonedu/entrepreneurship-api/internal/command/promote_courseversion"
	get_courseversion "github.com/vernonedu/entrepreneurship-api/internal/query/get_courseversion"
	list_courseversion "github.com/vernonedu/entrepreneurship-api/internal/query/list_courseversion"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
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

// Create menangani POST /api/v1/curriculum/types/{typeID}/versions
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

// ListByType menangani GET /api/v1/curriculum/types/{typeID}/versions
func (h *CourseVersionHandler) ListByType(w http.ResponseWriter, r *http.Request) {
	typeIDStr := chi.URLParam(r, "typeID")
	typeID, err := uuid.Parse(typeIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid type id")
		return
	}

	query := &list_courseversion.ListCourseVersionQuery{CourseTypeID: typeID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list course version query")
		writeError(w, http.StatusInternalServerError, "failed to list course versions")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetByID menangani GET /api/v1/curriculum/versions/{versionID}
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

// Promote menangani POST /api/v1/curriculum/versions/{versionID}/promote
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

// RegisterCourseVersionRoutes mendaftarkan semua route CourseVersion ke router.
func RegisterCourseVersionRoutes(h *CourseVersionHandler, r chi.Router) {
	r.Post("/api/v1/curriculum/types/{typeID}/versions", h.Create)
	r.Get("/api/v1/curriculum/types/{typeID}/versions", h.ListByType)
	r.Get("/api/v1/curriculum/versions/{versionID}", h.GetByID)
	r.Post("/api/v1/curriculum/versions/{versionID}/promote", h.Promote)
}
