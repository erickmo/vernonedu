package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	approvestep "github.com/vernonedu/entrepreneurship-api/internal/command/approve_step"
	cancelapproval "github.com/vernonedu/entrepreneurship-api/internal/command/cancel_approval"
	createapproval "github.com/vernonedu/entrepreneurship-api/internal/command/create_approval"
	rejectstep "github.com/vernonedu/entrepreneurship-api/internal/command/reject_step"
	getapproval "github.com/vernonedu/entrepreneurship-api/internal/query/get_approval"
	listapprovals "github.com/vernonedu/entrepreneurship-api/internal/query/list_approvals"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type ApprovalHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewApprovalHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *ApprovalHandler {
	return &ApprovalHandler{cmdBus: cmdBus, qryBus: qryBus}
}

type CreateApprovalRequest struct {
	Type       string `json:"type"`
	EntityType string `json:"entity_type"`
	EntityID   string `json:"entity_id"`
	Reason     string `json:"reason"`
	Steps      []struct {
		ApproverID   string `json:"approver_id"`
		ApproverRole string `json:"approver_role"`
	} `json:"steps"`
}

type ApproveStepRequest struct {
	Comment string `json:"comment"`
}

type RejectStepRequest struct {
	Comment string `json:"comment"`
}

func (h *ApprovalHandler) listApprovals(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	status := r.URL.Query().Get("status")

	var approverID *uuid.UUID
	approverStr := r.URL.Query().Get("approver_id")
	if approverStr != "" && approverStr != "me" {
		id, err := uuid.Parse(approverStr)
		if err == nil {
			approverID = &id
		}
	}

	query := &listapprovals.ListApprovalsQuery{
		Offset:     offset,
		Limit:      limit,
		Status:     status,
		ApproverID: approverID,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list approvals")
		writeError(w, http.StatusInternalServerError, "failed to list approvals")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *ApprovalHandler) getApproval(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid approval id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getapproval.GetApprovalQuery{ID: id})
	if err != nil {
		log.Error().Err(err).Msg("failed to get approval")
		writeError(w, http.StatusNotFound, "approval not found")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *ApprovalHandler) createApproval(w http.ResponseWriter, r *http.Request) {
	var req CreateApprovalRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	entityID, err := uuid.Parse(req.EntityID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid entity_id")
		return
	}

	initiatorID := uuid.Nil
	if claims := r.Context().Value("claims"); claims != nil {
		if c, ok := claims.(map[string]interface{}); ok {
			if sub, ok := c["sub"].(string); ok {
				if id, err := uuid.Parse(sub); err == nil {
					initiatorID = id
				}
			}
		}
	}

	steps := make([]createapproval.StepInput, len(req.Steps))
	for i, s := range req.Steps {
		approverID, err := uuid.Parse(s.ApproverID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid approver_id in step")
			return
		}
		steps[i] = createapproval.StepInput{
			ApproverID:   approverID,
			ApproverRole: s.ApproverRole,
		}
	}

	cmd := &createapproval.CreateApprovalCommand{
		Type:        req.Type,
		EntityType:  req.EntityType,
		EntityID:    entityID,
		InitiatorID: initiatorID,
		Reason:      req.Reason,
		Steps:       steps,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create approval")
		writeError(w, http.StatusInternalServerError, "failed to create approval")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "approval request created"})
}

func (h *ApprovalHandler) approveStep(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	approvalID, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid approval id")
		return
	}

	var req ApproveStepRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		req = ApproveStepRequest{}
	}

	approverID := uuid.Nil
	if claims := r.Context().Value("claims"); claims != nil {
		if c, ok := claims.(map[string]interface{}); ok {
			if sub, ok := c["sub"].(string); ok {
				if id, err := uuid.Parse(sub); err == nil {
					approverID = id
				}
			}
		}
	}

	cmd := &approvestep.ApproveStepCommand{
		ApprovalID: approvalID,
		ApproverID: approverID,
		Comment:    req.Comment,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to approve step")
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "step approved"})
}

func (h *ApprovalHandler) rejectStep(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	approvalID, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid approval id")
		return
	}

	var req RejectStepRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	approverID := uuid.Nil
	if claims := r.Context().Value("claims"); claims != nil {
		if c, ok := claims.(map[string]interface{}); ok {
			if sub, ok := c["sub"].(string); ok {
				if id, err := uuid.Parse(sub); err == nil {
					approverID = id
				}
			}
		}
	}

	cmd := &rejectstep.RejectStepCommand{
		ApprovalID: approvalID,
		ApproverID: approverID,
		Comment:    req.Comment,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to reject step")
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "step rejected"})
}

func (h *ApprovalHandler) cancelApproval(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	approvalID, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid approval id")
		return
	}

	initiatorID := uuid.Nil
	if claims := r.Context().Value("claims"); claims != nil {
		if c, ok := claims.(map[string]interface{}); ok {
			if sub, ok := c["sub"].(string); ok {
				if id, err := uuid.Parse(sub); err == nil {
					initiatorID = id
				}
			}
		}
	}

	cmd := &cancelapproval.CancelApprovalCommand{
		ApprovalID:  approvalID,
		InitiatorID: initiatorID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to cancel approval")
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "approval cancelled"})
}

func RegisterApprovalRoutes(h *ApprovalHandler, r chi.Router) {
	r.Get("/api/v1/approvals", h.listApprovals)
	r.Get("/api/v1/approvals/{id}", h.getApproval)
	r.Post("/api/v1/approvals", h.createApproval)
	r.Put("/api/v1/approvals/{id}/approve", h.approveStep)
	r.Put("/api/v1/approvals/{id}/reject", h.rejectStep)
	r.Put("/api/v1/approvals/{id}/cancel", h.cancelApproval)
}
