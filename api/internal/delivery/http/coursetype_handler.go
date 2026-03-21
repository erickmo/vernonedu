package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	create_coursetype "github.com/vernonedu/entrepreneurship-api/internal/command/create_coursetype"
	toggle_coursetype "github.com/vernonedu/entrepreneurship-api/internal/command/toggle_coursetype"
	update_coursetype "github.com/vernonedu/entrepreneurship-api/internal/command/update_coursetype"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursetype"
	get_coursetype "github.com/vernonedu/entrepreneurship-api/internal/query/get_coursetype"
	list_coursetype "github.com/vernonedu/entrepreneurship-api/internal/query/list_coursetype"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// CourseTypeHandler menangani request HTTP untuk resource CourseType.
type CourseTypeHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewCourseTypeHandler membuat instance baru CourseTypeHandler.
func NewCourseTypeHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *CourseTypeHandler {
	return &CourseTypeHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// CreateCourseTypeRequest adalah request body untuk membuat CourseType baru.
type CreateCourseTypeRequest struct {
	TypeName               string                             `json:"type_name" validate:"required"`
	PriceType              string                             `json:"price_type"`
	PriceCurrency          string                             `json:"price_currency"`
	TargetAudience         string                             `json:"target_audience"`
	CertificationType      string                             `json:"certification_type"`
	ExtraDocs              []string                           `json:"extra_docs"`
	ComponentFailureConfig *coursetype.ComponentFailureConfig `json:"component_failure_config"`
	NormalPrice            int64                              `json:"normal_price"`
	MinPrice               int64                              `json:"min_price"`
	MinParticipants        int                                `json:"min_participants"`
	MaxParticipants        int                                `json:"max_participants"`
}

// UpdateCourseTypeRequest adalah request body untuk memperbarui CourseType.
type UpdateCourseTypeRequest struct {
	TargetAudience         string                             `json:"target_audience"`
	CertificationType      string                             `json:"certification_type"`
	ExtraDocs              []string                           `json:"extra_docs"`
	ComponentFailureConfig *coursetype.ComponentFailureConfig `json:"component_failure_config"`
	PriceType              string                             `json:"price_type"`
	PriceMin               *int64                             `json:"price_min"`
	PriceMax               *int64                             `json:"price_max"`
	PriceCurrency          string                             `json:"price_currency"`
	PriceNotes             string                             `json:"price_notes"`
	NormalPrice            int64                              `json:"normal_price"`
	MinPrice               int64                              `json:"min_price"`
	MinParticipants        int                                `json:"min_participants"`
	MaxParticipants        int                                `json:"max_participants"`
}

// Create menangani POST /api/v1/curriculum/courses/{courseID}/types
func (h *CourseTypeHandler) Create(w http.ResponseWriter, r *http.Request) {
	courseIDStr := chi.URLParam(r, "courseID")
	courseID, err := uuid.Parse(courseIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course id")
		return
	}

	var req CreateCourseTypeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_coursetype.CreateCourseTypeCommand{
		MasterCourseID:         courseID,
		TypeName:               req.TypeName,
		PriceType:              req.PriceType,
		PriceCurrency:          req.PriceCurrency,
		TargetAudience:         req.TargetAudience,
		CertificationType:      req.CertificationType,
		ExtraDocs:              req.ExtraDocs,
		ComponentFailureConfig: req.ComponentFailureConfig,
		NormalPrice:            req.NormalPrice,
		MinPrice:               req.MinPrice,
		MinParticipants:        req.MinParticipants,
		MaxParticipants:        req.MaxParticipants,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create course type command")
		writeError(w, http.StatusInternalServerError, "failed to create course type")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "course type created successfully"})
}

// ListByMasterCourse menangani GET /api/v1/curriculum/courses/{courseID}/types
func (h *CourseTypeHandler) ListByMasterCourse(w http.ResponseWriter, r *http.Request) {
	courseIDStr := chi.URLParam(r, "courseID")
	courseID, err := uuid.Parse(courseIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course id")
		return
	}

	query := &list_coursetype.ListCourseTypeQuery{MasterCourseID: courseID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list course type query")
		writeError(w, http.StatusInternalServerError, "failed to list course types")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// GetByID menangani GET /api/v1/curriculum/types/{typeID}
func (h *CourseTypeHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	typeIDStr := chi.URLParam(r, "typeID")
	typeID, err := uuid.Parse(typeIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid type id")
		return
	}

	query := &get_coursetype.GetCourseTypeQuery{CourseTypeID: typeID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get course type query")
		writeError(w, http.StatusInternalServerError, "failed to get course type")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Update menangani PUT /api/v1/curriculum/types/{typeID}
func (h *CourseTypeHandler) Update(w http.ResponseWriter, r *http.Request) {
	typeIDStr := chi.URLParam(r, "typeID")
	typeID, err := uuid.Parse(typeIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid type id")
		return
	}

	var req UpdateCourseTypeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_coursetype.UpdateCourseTypeCommand{
		CourseTypeID:           typeID,
		TargetAudience:         req.TargetAudience,
		CertificationType:      req.CertificationType,
		ExtraDocs:              req.ExtraDocs,
		ComponentFailureConfig: req.ComponentFailureConfig,
		PriceType:              req.PriceType,
		PriceMin:               req.PriceMin,
		PriceMax:               req.PriceMax,
		PriceCurrency:          req.PriceCurrency,
		PriceNotes:             req.PriceNotes,
		NormalPrice:            req.NormalPrice,
		MinPrice:               req.MinPrice,
		MinParticipants:        req.MinParticipants,
		MaxParticipants:        req.MaxParticipants,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update course type command")
		writeError(w, http.StatusInternalServerError, "failed to update course type")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course type updated successfully"})
}

// Toggle menangani POST /api/v1/curriculum/types/{typeID}/toggle
func (h *CourseTypeHandler) Toggle(w http.ResponseWriter, r *http.Request) {
	typeIDStr := chi.URLParam(r, "typeID")
	typeID, err := uuid.Parse(typeIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid type id")
		return
	}

	cmd := &toggle_coursetype.ToggleCourseTypeCommand{CourseTypeID: typeID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute toggle course type command")
		writeError(w, http.StatusInternalServerError, "failed to toggle course type")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "course type toggled successfully"})
}

// RegisterCourseTypeRoutes mendaftarkan semua route CourseType ke router.
func RegisterCourseTypeRoutes(h *CourseTypeHandler, r chi.Router) {
	r.Post("/api/v1/curriculum/courses/{courseID}/types", h.Create)
	r.Get("/api/v1/curriculum/courses/{courseID}/types", h.ListByMasterCourse)
	r.Get("/api/v1/curriculum/types/{typeID}", h.GetByID)
	r.Put("/api/v1/curriculum/types/{typeID}", h.Update)
	r.Post("/api/v1/curriculum/types/{typeID}/toggle", h.Toggle)
}
