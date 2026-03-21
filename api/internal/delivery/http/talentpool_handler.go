package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	update_talentpool_status "github.com/vernonedu/entrepreneurship-api/internal/command/update_talentpool_status"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/talentpool"
	get_talentpool "github.com/vernonedu/entrepreneurship-api/internal/query/get_talentpool"
	list_talentpool "github.com/vernonedu/entrepreneurship-api/internal/query/list_talentpool"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// TalentPoolHandler menangani request HTTP untuk resource TalentPool.
type TalentPoolHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewTalentPoolHandler membuat instance baru TalentPoolHandler.
func NewTalentPoolHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *TalentPoolHandler {
	return &TalentPoolHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// UpdateTalentPoolStatusRequest adalah request body untuk memperbarui status TalentPool.
type UpdateTalentPoolStatusRequest struct {
	Status    string                    `json:"status" validate:"required"` // "placed" | "inactive"
	Placement *PlacementRecordRequest   `json:"placement"`
}

// PlacementRecordRequest adalah data penempatan kerja dari request.
type PlacementRecordRequest struct {
	CompanyName string `json:"company_name"`
	Position    string `json:"position"`
	Notes       string `json:"notes"`
}

// List menangani GET /api/v1/talentpool
func (h *TalentPoolHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}
	status := r.URL.Query().Get("status")
	masterCourseIDStr := r.URL.Query().Get("master_course_id")

	var masterCourseID uuid.UUID
	if masterCourseIDStr != "" {
		if parsed, err := uuid.Parse(masterCourseIDStr); err == nil {
			masterCourseID = parsed
		}
	}

	query := &list_talentpool.ListTalentPoolQuery{
		Offset:         offset,
		Limit:          limit,
		Status:         status,
		MasterCourseID: masterCourseID,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list talent pool query")
		writeError(w, http.StatusInternalServerError, "failed to list talent pool")
		return
	}

	writeJSON(w, http.StatusOK, result)
}

// GetByID menangani GET /api/v1/talentpool/{id}
func (h *TalentPoolHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid talent pool id")
		return
	}

	query := &get_talentpool.GetTalentPoolQuery{TalentPoolID: id}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get talent pool query")
		writeError(w, http.StatusInternalServerError, "failed to get talent pool entry")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// UpdateStatus menangani PUT /api/v1/talentpool/{id}/status
func (h *TalentPoolHandler) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid talent pool id")
		return
	}

	var req UpdateTalentPoolStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_talentpool_status.UpdateTalentPoolStatusCommand{
		TalentPoolID: id,
		Status:       req.Status,
	}

	// Konversi placement jika ada
	if req.Placement != nil {
		cmd.Placement = &talentpool.PlacementRecord{
			CompanyName: req.Placement.CompanyName,
			Position:    req.Placement.Position,
			Notes:       req.Placement.Notes,
		}
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update talent pool status command")
		writeError(w, http.StatusInternalServerError, "failed to update talent pool status")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "talent pool status updated successfully"})
}

// RegisterTalentPoolRoutes mendaftarkan semua route TalentPool ke router.
func RegisterTalentPoolRoutes(h *TalentPoolHandler, r chi.Router) {
	r.Get("/api/v1/talentpool", h.List)
	r.Get("/api/v1/talentpool/{id}", h.GetByID)
	r.Put("/api/v1/talentpool/{id}/status", h.UpdateStatus)
}
