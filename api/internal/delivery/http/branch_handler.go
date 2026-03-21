package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_branch"
	listbranches "github.com/vernonedu/entrepreneurship-api/internal/query/list_branches"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type BranchHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewBranchHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *BranchHandler {
	return &BranchHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterBranchRoutes(h *BranchHandler, r chi.Router) {
	r.Get("/api/v1/branches", h.List)
	r.Post("/api/v1/branches", h.Create)
}

func (h *BranchHandler) List(w http.ResponseWriter, r *http.Request) {
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

func (h *BranchHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name      string `json:"name"`
		City      string `json:"city"`
		Address   string `json:"address"`
		PartnerID string `json:"partner_id"`
		IsActive  bool   `json:"is_active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &create_branch.CreateBranchCommand{
		Name:      body.Name,
		City:      body.City,
		Address:   body.Address,
		PartnerID: body.PartnerID,
		IsActive:  body.IsActive,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create branch")
		writeError(w, http.StatusInternalServerError, "failed to create branch")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "branch created"})
}
