package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	create_coursemodule "github.com/vernonedu/entrepreneurship-api/internal/command/create_coursemodule"
	delete_coursemodule "github.com/vernonedu/entrepreneurship-api/internal/command/delete_coursemodule"
	update_coursemodule "github.com/vernonedu/entrepreneurship-api/internal/command/update_coursemodule"
	get_coursemodule "github.com/vernonedu/entrepreneurship-api/internal/query/get_coursemodule"
	list_coursemodule "github.com/vernonedu/entrepreneurship-api/internal/query/list_coursemodule"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// CourseModuleHandler menangani request HTTP untuk resource CourseModule.
type CourseModuleHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewCourseModuleHandler membuat instance baru CourseModuleHandler.
func NewCourseModuleHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *CourseModuleHandler {
	return &CourseModuleHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// CreateCourseModuleRequest adalah request body untuk membuat CourseModule baru.
type CreateCourseModuleRequest struct {
	ModuleCode          string   `json:"module_code" validate:"required"`
	ModuleTitle         string   `json:"module_title" validate:"required,min=1"`
	DurationHours       float64  `json:"duration_hours"`
	Sequence            int      `json:"sequence" validate:"required,min=1"`
	ContentDepth        string   `json:"content_depth"`
	Topics              []string `json:"topics"`
	PracticalActivities []string `json:"practical_activities"`
	AssessmentMethod    string   `json:"assessment_method"`
	ToolsRequired       []string `json:"tools_required"`
	IsReference         bool     `json:"is_reference"`
	RefModuleID         *string  `json:"ref_module_id"`
}

// UpdateCourseModuleRequest adalah request body untuk memperbarui CourseModule.
type UpdateCourseModuleRequest struct {
	ModuleTitle         string   `json:"module_title" validate:"required,min=1"`
	DurationHours       float64  `json:"duration_hours"`
	Sequence            int      `json:"sequence" validate:"required,min=1"`
	ContentDepth        string   `json:"content_depth"`
	Topics              []string `json:"topics"`
	PracticalActivities []string `json:"practical_activities"`
	AssessmentMethod    string   `json:"assessment_method"`
	ToolsRequired       []string `json:"tools_required"`
}

// Create menangani POST /api/v1/curriculum/versions/{versionID}/modules
func (h *CourseModuleHandler) Create(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	var req CreateCourseModuleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_coursemodule.CreateCourseModuleCommand{
		CourseVersionID:     versionID,
		ModuleCode:          req.ModuleCode,
		ModuleTitle:         req.ModuleTitle,
		DurationHours:       req.DurationHours,
		Sequence:            req.Sequence,
		ContentDepth:        req.ContentDepth,
		Topics:              req.Topics,
		PracticalActivities: req.PracticalActivities,
		AssessmentMethod:    req.AssessmentMethod,
		ToolsRequired:       req.ToolsRequired,
		IsReference:         req.IsReference,
	}
	if req.RefModuleID != nil {
		parsedID, parseErr := uuid.Parse(*req.RefModuleID)
		if parseErr == nil {
			cmd.RefModuleID = &parsedID
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create course module command")
		writeError(w, http.StatusInternalServerError, "failed to create course module")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "course module created successfully"})
}

// ListByVersion menangani GET /api/v1/curriculum/versions/{versionID}/modules
func (h *CourseModuleHandler) ListByVersion(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	query := &list_coursemodule.ListCourseModuleQuery{CourseVersionID: versionID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list course module query")
		writeError(w, http.StatusInternalServerError, "failed to list course modules")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetByID menangani GET /api/v1/curriculum/modules/{moduleID}
func (h *CourseModuleHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	moduleIDStr := chi.URLParam(r, "moduleID")
	moduleID, err := uuid.Parse(moduleIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid module id")
		return
	}

	query := &get_coursemodule.GetCourseModuleQuery{ModuleID: moduleID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get course module query")
		writeError(w, http.StatusInternalServerError, "failed to get course module")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Update menangani PUT /api/v1/curriculum/modules/{moduleID}
func (h *CourseModuleHandler) Update(w http.ResponseWriter, r *http.Request) {
	moduleIDStr := chi.URLParam(r, "moduleID")
	moduleID, err := uuid.Parse(moduleIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid module id")
		return
	}

	var req UpdateCourseModuleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_coursemodule.UpdateCourseModuleCommand{
		ModuleID:            moduleID,
		ModuleTitle:         req.ModuleTitle,
		DurationHours:       req.DurationHours,
		Sequence:            req.Sequence,
		ContentDepth:        req.ContentDepth,
		Topics:              req.Topics,
		PracticalActivities: req.PracticalActivities,
		AssessmentMethod:    req.AssessmentMethod,
		ToolsRequired:       req.ToolsRequired,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update course module command")
		writeError(w, http.StatusInternalServerError, "failed to update course module")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course module updated successfully"})
}

// Delete menangani DELETE /api/v1/curriculum/modules/{moduleID}
func (h *CourseModuleHandler) Delete(w http.ResponseWriter, r *http.Request) {
	moduleIDStr := chi.URLParam(r, "moduleID")
	moduleID, err := uuid.Parse(moduleIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid module id")
		return
	}

	cmd := &delete_coursemodule.DeleteCourseModuleCommand{ModuleID: moduleID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete course module command")
		writeError(w, http.StatusInternalServerError, "failed to delete course module")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course module deleted successfully"})
}

// RegisterCourseModuleRoutes mendaftarkan semua route CourseModule ke router.
func RegisterCourseModuleRoutes(h *CourseModuleHandler, r chi.Router) {
	r.Post("/api/v1/curriculum/versions/{versionID}/modules", h.Create)
	r.Get("/api/v1/curriculum/versions/{versionID}/modules", h.ListByVersion)
	r.Get("/api/v1/curriculum/modules/{moduleID}", h.GetByID)
	r.Put("/api/v1/curriculum/modules/{moduleID}", h.Update)
	r.Delete("/api/v1/curriculum/modules/{moduleID}", h.Delete)
}
