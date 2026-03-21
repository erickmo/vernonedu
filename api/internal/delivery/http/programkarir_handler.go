package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	submit_testresult "github.com/vernonedu/entrepreneurship-api/internal/command/submit_testresult"
	update_failureconfig "github.com/vernonedu/entrepreneurship-api/internal/command/update_failureconfig"
	upsert_charactertestconfig "github.com/vernonedu/entrepreneurship-api/internal/command/upsert_character_test_config"
	upsert_internshipconfig "github.com/vernonedu/entrepreneurship-api/internal/command/upsert_internship_config"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursetype"
	get_charactertestconfig "github.com/vernonedu/entrepreneurship-api/internal/query/get_character_test_config"
	get_internshipconfig "github.com/vernonedu/entrepreneurship-api/internal/query/get_internship_config"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// ProgramKarirHandler menangani request HTTP untuk fitur khusus program_karir.
type ProgramKarirHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewProgramKarirHandler membuat instance baru ProgramKarirHandler.
func NewProgramKarirHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *ProgramKarirHandler {
	return &ProgramKarirHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// UpsertInternshipConfigRequest adalah request body untuk upsert InternshipConfig.
type UpsertInternshipConfigRequest struct {
	PartnerCompanyName string  `json:"partner_company_name" validate:"required"`
	PartnerCompanyID   *string `json:"partner_company_id"`
	PositionTitle      string  `json:"position_title" validate:"required"`
	DurationWeeks      int     `json:"duration_weeks" validate:"required,min=1"`
	SupervisorName     string  `json:"supervisor_name"`
	SupervisorContact  string  `json:"supervisor_contact"`
	MOUDocumentURL     string  `json:"mou_document_url"`
	IsCompanyProvided  bool    `json:"is_company_provided"`
}

// UpsertCharacterTestConfigRequest adalah request body untuk upsert CharacterTestConfig.
type UpsertCharacterTestConfigRequest struct {
	TestType           string  `json:"test_type" validate:"required"`
	TestProvider       string  `json:"test_provider"`
	PassingThreshold   float64 `json:"passing_threshold"`
	TalentpoolEligible bool    `json:"talentpool_eligible"`
}

// UpdateFailureConfigRequest adalah request body untuk memperbarui ComponentFailureConfig.
type UpdateFailureConfigRequest struct {
	ComponentFailureConfig coursetype.ComponentFailureConfig `json:"component_failure_config"`
}

// SubmitTestResultRequest adalah request body untuk submit hasil tes karakter.
type SubmitTestResultRequest struct {
	ParticipantID    string                 `json:"participant_id" validate:"required"`
	ParticipantName  string                 `json:"participant_name" validate:"required"`
	ParticipantEmail string                 `json:"participant_email" validate:"required"`
	TestResult       map[string]interface{} `json:"test_result"`
	TestScore        *float64               `json:"test_score"`
}

// UpsertInternshipConfig menangani PUT /api/v1/curriculum/versions/{versionID}/internship
func (h *ProgramKarirHandler) UpsertInternshipConfig(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	var req UpsertInternshipConfigRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &upsert_internshipconfig.UpsertInternshipConfigCommand{
		CourseVersionID:    versionID,
		PartnerCompanyName: req.PartnerCompanyName,
		PositionTitle:      req.PositionTitle,
		DurationWeeks:      req.DurationWeeks,
		SupervisorName:     req.SupervisorName,
		SupervisorContact:  req.SupervisorContact,
		MOUDocumentURL:     req.MOUDocumentURL,
		IsCompanyProvided:  req.IsCompanyProvided,
	}
	if req.PartnerCompanyID != nil {
		parsedID, parseErr := uuid.Parse(*req.PartnerCompanyID)
		if parseErr == nil {
			cmd.PartnerCompanyID = &parsedID
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute upsert internship config command")
		writeError(w, http.StatusInternalServerError, "failed to upsert internship config")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "internship config saved successfully"})
}

// GetInternshipConfig menangani GET /api/v1/curriculum/versions/{versionID}/internship
func (h *ProgramKarirHandler) GetInternshipConfig(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	query := &get_internshipconfig.GetInternshipConfigQuery{CourseVersionID: versionID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get internship config query")
		writeError(w, http.StatusInternalServerError, "failed to get internship config")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// UpsertCharacterTestConfig menangani PUT /api/v1/curriculum/versions/{versionID}/character-test
func (h *ProgramKarirHandler) UpsertCharacterTestConfig(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	var req UpsertCharacterTestConfigRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &upsert_charactertestconfig.UpsertCharacterTestConfigCommand{
		CourseVersionID:    versionID,
		TestType:           req.TestType,
		TestProvider:       req.TestProvider,
		PassingThreshold:   req.PassingThreshold,
		TalentpoolEligible: req.TalentpoolEligible,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute upsert character test config command")
		writeError(w, http.StatusInternalServerError, "failed to upsert character test config")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "character test config saved successfully"})
}

// GetCharacterTestConfig menangani GET /api/v1/curriculum/versions/{versionID}/character-test
func (h *ProgramKarirHandler) GetCharacterTestConfig(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	query := &get_charactertestconfig.GetCharacterTestConfigQuery{CourseVersionID: versionID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get character test config query")
		writeError(w, http.StatusInternalServerError, "failed to get character test config")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// UpdateFailureConfig menangani PUT /api/v1/curriculum/types/{typeID}/failure-config
func (h *ProgramKarirHandler) UpdateFailureConfig(w http.ResponseWriter, r *http.Request) {
	typeIDStr := chi.URLParam(r, "typeID")
	typeID, err := uuid.Parse(typeIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid type id")
		return
	}

	var req UpdateFailureConfigRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_failureconfig.UpdateFailureConfigCommand{
		CourseTypeID:           typeID,
		ComponentFailureConfig: &req.ComponentFailureConfig,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update failure config command")
		writeError(w, http.StatusInternalServerError, "failed to update failure config")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "failure config updated successfully"})
}

// SubmitTestResult menangani POST /api/v1/curriculum/versions/{versionID}/submit-test-result
func (h *ProgramKarirHandler) SubmitTestResult(w http.ResponseWriter, r *http.Request) {
	versionIDStr := chi.URLParam(r, "versionID")
	versionID, err := uuid.Parse(versionIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid version id")
		return
	}

	// master_course_id dan course_type_id diambil dari query params untuk fleksibilitas
	masterCourseIDStr := r.URL.Query().Get("master_course_id")
	courseTypeIDStr := r.URL.Query().Get("course_type_id")

	masterCourseID, err := uuid.Parse(masterCourseIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid master_course_id")
		return
	}
	courseTypeID, err := uuid.Parse(courseTypeIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid course_type_id")
		return
	}

	var req SubmitTestResultRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	participantID, err := uuid.Parse(req.ParticipantID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid participant_id")
		return
	}

	cmd := &submit_testresult.SubmitTestResultCommand{
		CourseVersionID:  versionID,
		MasterCourseID:   masterCourseID,
		CourseTypeID:     courseTypeID,
		ParticipantID:    participantID,
		ParticipantName:  req.ParticipantName,
		ParticipantEmail: req.ParticipantEmail,
		TestResult:       req.TestResult,
		TestScore:        req.TestScore,
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute submit test result command")
		writeError(w, http.StatusInternalServerError, "failed to submit test result")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "test result submitted and talent pool entry created"})
}

// RegisterProgramKarirRoutes mendaftarkan semua route program_karir ke router.
func RegisterProgramKarirRoutes(h *ProgramKarirHandler, r chi.Router) {
	r.Put("/api/v1/curriculum/versions/{versionID}/internship", h.UpsertInternshipConfig)
	r.Get("/api/v1/curriculum/versions/{versionID}/internship", h.GetInternshipConfig)
	r.Put("/api/v1/curriculum/versions/{versionID}/character-test", h.UpsertCharacterTestConfig)
	r.Get("/api/v1/curriculum/versions/{versionID}/character-test", h.GetCharacterTestConfig)
	r.Put("/api/v1/curriculum/types/{typeID}/failure-config", h.UpdateFailureConfig)
	r.Post("/api/v1/curriculum/versions/{versionID}/submit-test-result", h.SubmitTestResult)
}
