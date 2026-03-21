package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createbranch "github.com/vernonedu/entrepreneurship-api/internal/command/create_branch"
	createholiday "github.com/vernonedu/entrepreneurship-api/internal/command/create_holiday"
	deleteholiday "github.com/vernonedu/entrepreneurship-api/internal/command/delete_holiday"
	updatebranch "github.com/vernonedu/entrepreneurship-api/internal/command/update_branch"
	updatecommission "github.com/vernonedu/entrepreneurship-api/internal/command/update_commission_config"
	upsertlevels "github.com/vernonedu/entrepreneurship-api/internal/command/upsert_facilitator_levels"
	getcommission "github.com/vernonedu/entrepreneurship-api/internal/query/get_commission_config"
	getlevels "github.com/vernonedu/entrepreneurship-api/internal/query/get_facilitator_levels"
	listbranches "github.com/vernonedu/entrepreneurship-api/internal/query/list_branches"
	listholidays "github.com/vernonedu/entrepreneurship-api/internal/query/list_holidays"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// SettingsHandler handles all /api/v1/settings/* endpoints.
type SettingsHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewSettingsHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *SettingsHandler {
	return &SettingsHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterSettingsRoutes(h *SettingsHandler, r chi.Router) {
	r.Get("/api/v1/settings/commission", h.GetCommission)
	r.Put("/api/v1/settings/commission", h.UpdateCommission)

	r.Get("/api/v1/settings/facilitator-levels", h.GetFacilitatorLevels)
	r.Put("/api/v1/settings/facilitator-levels", h.UpsertFacilitatorLevels)

	r.Get("/api/v1/settings/branches", h.ListBranches)
	r.Post("/api/v1/settings/branches", h.CreateBranch)
	r.Put("/api/v1/settings/branches/{id}", h.UpdateBranch)

	r.Get("/api/v1/settings/holidays", h.ListHolidays)
	r.Post("/api/v1/settings/holidays", h.CreateHoliday)
	r.Delete("/api/v1/settings/holidays/{id}", h.DeleteHoliday)
}

// ─── Commission ───────────────────────────────────────────────────────────────

func (h *SettingsHandler) GetCommission(w http.ResponseWriter, r *http.Request) {
	result, err := h.qryBus.Execute(r.Context(), &getcommission.GetCommissionConfigQuery{})
	if err != nil {
		log.Error().Err(err).Msg("failed to get commission config")
		writeError(w, http.StatusInternalServerError, "failed to get commission config")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *SettingsHandler) UpdateCommission(w http.ResponseWriter, r *http.Request) {
	var body struct {
		OpLeaderPct        float64 `json:"op_leader_pct"`
		OpLeaderBasis      string  `json:"op_leader_basis"`
		DeptLeaderPct      float64 `json:"dept_leader_pct"`
		DeptLeaderBasis    string  `json:"dept_leader_basis"`
		CourseCreatorPct   float64 `json:"course_creator_pct"`
		CourseCreatorBasis string  `json:"course_creator_basis"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatecommission.UpdateCommissionConfigCommand{
		OpLeaderPct:        body.OpLeaderPct,
		OpLeaderBasis:      body.OpLeaderBasis,
		DeptLeaderPct:      body.DeptLeaderPct,
		DeptLeaderBasis:    body.DeptLeaderBasis,
		CourseCreatorPct:   body.CourseCreatorPct,
		CourseCreatorBasis: body.CourseCreatorBasis,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update commission config")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "commission config updated"})
}

// ─── Facilitator Levels ───────────────────────────────────────────────────────

func (h *SettingsHandler) GetFacilitatorLevels(w http.ResponseWriter, r *http.Request) {
	result, err := h.qryBus.Execute(r.Context(), &getlevels.GetFacilitatorLevelsQuery{})
	if err != nil {
		log.Error().Err(err).Msg("failed to get facilitator levels")
		writeError(w, http.StatusInternalServerError, "failed to get facilitator levels")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *SettingsHandler) UpsertFacilitatorLevels(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Levels []struct {
			Level         int    `json:"level"`
			Name          string `json:"name"`
			FeePerSession int64  `json:"fee_per_session"`
		} `json:"levels"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	inputs := make([]upsertlevels.FacilitatorLevelInput, len(body.Levels))
	for i, l := range body.Levels {
		inputs[i] = upsertlevels.FacilitatorLevelInput{
			Level:         l.Level,
			Name:          l.Name,
			FeePerSession: l.FeePerSession,
		}
	}

	cmd := &upsertlevels.UpsertFacilitatorLevelsCommand{Levels: inputs}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to upsert facilitator levels")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "facilitator levels updated"})
}

// ─── Branches ─────────────────────────────────────────────────────────────────

func (h *SettingsHandler) ListBranches(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	result, err := h.qryBus.Execute(r.Context(), &listbranches.ListBranchesQuery{
		Offset: offset, Limit: limit,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list branches")
		writeError(w, http.StatusInternalServerError, "failed to list branches")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *SettingsHandler) CreateBranch(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name         string `json:"name"`
		Address      string `json:"address"`
		City         string `json:"city"`
		Region       string `json:"region"`
		ContactName  string `json:"contact_name"`
		ContactPhone string `json:"contact_phone"`
		Status       string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createbranch.CreateBranchCommand{
		Name:         body.Name,
		Address:      body.Address,
		City:         body.City,
		Region:       body.Region,
		ContactName:  body.ContactName,
		ContactPhone: body.ContactPhone,
		Status:       body.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create branch")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "branch created"})
}

func (h *SettingsHandler) UpdateBranch(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid branch id")
		return
	}

	var body struct {
		Name         string `json:"name"`
		Address      string `json:"address"`
		City         string `json:"city"`
		Region       string `json:"region"`
		ContactName  string `json:"contact_name"`
		ContactPhone string `json:"contact_phone"`
		Status       string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatebranch.UpdateBranchCommand{
		ID:           id,
		Name:         body.Name,
		Address:      body.Address,
		City:         body.City,
		Region:       body.Region,
		ContactName:  body.ContactName,
		ContactPhone: body.ContactPhone,
		Status:       body.Status,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update branch")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "branch updated"})
}

// ─── Holidays ────────────────────────────────────────────────────────────────

func (h *SettingsHandler) ListHolidays(w http.ResponseWriter, r *http.Request) {
	yearStr := r.URL.Query().Get("year")
	year, _ := strconv.Atoi(yearStr)
	if year == 0 {
		year = time.Now().Year()
	}

	result, err := h.qryBus.Execute(r.Context(), &listholidays.ListHolidaysQuery{Year: year})
	if err != nil {
		log.Error().Err(err).Msg("failed to list holidays")
		writeError(w, http.StatusInternalServerError, "failed to list holidays")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *SettingsHandler) CreateHoliday(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Date string `json:"date"`
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createholiday.CreateHolidayCommand{Date: body.Date, Name: body.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create holiday")
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "holiday created"})
}

func (h *SettingsHandler) DeleteHoliday(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid holiday id")
		return
	}

	cmd := &deleteholiday.DeleteHolidayCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete holiday")
		writeError(w, http.StatusInternalServerError, "failed to delete holiday")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "holiday deleted"})
}
