package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/upsert_bmc"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_bmc"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

// BmcHandler exposes HTTP endpoints for the Business Model Canvas (9 strategic
// blocks per branch).
type BmcHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

// NewBmcHandler builds a new BmcHandler.
func NewBmcHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *BmcHandler {
	return &BmcHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// UpsertBmcRequest is the JSON body accepted by PUT /api/v1/bmc/{branch_id}.
type UpsertBmcRequest struct {
	CustomerSegments      []string `json:"customer_segments"`
	ValuePropositions     []string `json:"value_propositions"`
	Channels              []string `json:"channels"`
	CustomerRelationships []string `json:"customer_relationships"`
	RevenueStreams        []string `json:"revenue_streams"`
	KeyResources          []string `json:"key_resources"`
	KeyActivities         []string `json:"key_activities"`
	KeyPartnerships       []string `json:"key_partnerships"`
	CostStructure         []string `json:"cost_structure"`
}

// Get returns the BMC for a branch. When no canvas exists yet, an empty
// canvas (all blocks as []) is returned with HTTP 200 to simplify the client.
func (h *BmcHandler) Get(w http.ResponseWriter, r *http.Request) {
	branchIDStr := chi.URLParam(r, "branch_id")
	branchID, err := uuid.Parse(branchIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid branch id")
		return
	}

	q := &get_bmc.GetBmcQuery{BranchID: branchID}
	result, err := h.qryBus.Execute(r.Context(), q)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get bmc query")
		writeError(w, http.StatusInternalServerError, "failed to get bmc")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Upsert creates or replaces the BMC for a branch. All 9 blocks are stored as
// provided; missing blocks are treated as empty.
func (h *BmcHandler) Upsert(w http.ResponseWriter, r *http.Request) {
	branchIDStr := chi.URLParam(r, "branch_id")
	branchID, err := uuid.Parse(branchIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid branch id")
		return
	}

	var req UpsertBmcRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	updatedBy := resolveUpdatedBy(r)

	cmd := &upsert_bmc.UpsertBmcCommand{
		BranchID:              branchID,
		UpdatedBy:             updatedBy,
		CustomerSegments:      req.CustomerSegments,
		ValuePropositions:     req.ValuePropositions,
		Channels:              req.Channels,
		CustomerRelationships: req.CustomerRelationships,
		RevenueStreams:        req.RevenueStreams,
		KeyResources:          req.KeyResources,
		KeyActivities:         req.KeyActivities,
		KeyPartnerships:       req.KeyPartnerships,
		CostStructure:         req.CostStructure,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute upsert bmc command")
		writeError(w, http.StatusInternalServerError, "failed to upsert bmc")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "bmc saved successfully"})
}

func resolveUpdatedBy(r *http.Request) *uuid.UUID {
	userIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	if userIDStr == "" {
		return nil
	}
	id, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil
	}
	return &id
}

// RegisterBmcRoutes wires BMC endpoints into the chi router.
func RegisterBmcRoutes(h *BmcHandler, r chi.Router) {
	r.Get("/api/v1/bmc/{branch_id}", h.Get)
	r.Put("/api/v1/bmc/{branch_id}", h.Upsert)
}
