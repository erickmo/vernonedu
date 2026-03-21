package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	approvepayable "github.com/vernonedu/entrepreneurship-api/internal/command/approve_payable"
	cancelpayable "github.com/vernonedu/entrepreneurship-api/internal/command/cancel_payable"
	createpayable "github.com/vernonedu/entrepreneurship-api/internal/command/create_payable"
	markpayablepaid "github.com/vernonedu/entrepreneurship-api/internal/command/mark_payable_paid"
	getpayable "github.com/vernonedu/entrepreneurship-api/internal/query/get_payable"
	getpayablestats "github.com/vernonedu/entrepreneurship-api/internal/query/get_payable_stats"
	listpayables "github.com/vernonedu/entrepreneurship-api/internal/query/list_payables"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type PayableHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewPayableHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *PayableHandler {
	return &PayableHandler{cmdBus: cmdBus, qryBus: qryBus}
}

func RegisterPayableRoutes(h *PayableHandler, r chi.Router) {
	r.Get("/api/v1/finance/payables", h.List)
	r.Get("/api/v1/finance/payables/stats", h.Stats)
	r.Get("/api/v1/finance/payables/{id}", h.Get)
	r.Post("/api/v1/finance/payables", h.Create)
	r.Put("/api/v1/finance/payables/{id}/approve", h.Approve)
	r.Put("/api/v1/finance/payables/{id}/pay", h.Pay)
	r.Put("/api/v1/finance/payables/{id}/cancel", h.Cancel)
}

func (h *PayableHandler) List(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	offset, _ := strconv.Atoi(q.Get("offset"))
	limit, _ := strconv.Atoi(q.Get("limit"))
	if limit == 0 {
		limit = 20
	}

	result, err := h.qryBus.Execute(r.Context(), &listpayables.ListPayablesQuery{
		Type:        q.Get("type"),
		Status:      q.Get("status"),
		BatchID:     q.Get("batch_id"),
		RecipientID: q.Get("recipient_id"),
		DateFrom:    q.Get("date_from"),
		DateTo:      q.Get("date_to"),
		Offset:      offset,
		Limit:       limit,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *PayableHandler) Stats(w http.ResponseWriter, r *http.Request) {
	result, err := h.qryBus.Execute(r.Context(), &getpayablestats.GetPayableStatsQuery{})
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *PayableHandler) Get(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getpayable.GetPayableQuery{ID: id})
	if err != nil {
		writeError(w, http.StatusNotFound, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *PayableHandler) Create(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Type          string  `json:"type"`
		RecipientID   string  `json:"recipient_id"`
		RecipientName string  `json:"recipient_name"`
		BatchID       *string `json:"batch_id"`
		Amount        int64   `json:"amount"`
		BranchID      *string `json:"branch_id"`
		Notes         string  `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	recipientID, err := uuid.Parse(body.RecipientID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid recipient_id")
		return
	}

	cmd := &createpayable.CreatePayableCommand{
		Type:          body.Type,
		RecipientID:   recipientID,
		RecipientName: body.RecipientName,
		Amount:        body.Amount,
		Notes:         body.Notes,
	}

	if body.BatchID != nil {
		bid, err := uuid.Parse(*body.BatchID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid batch_id")
			return
		}
		cmd.BatchID = &bid
	}
	if body.BranchID != nil {
		bid, err := uuid.Parse(*body.BranchID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid branch_id")
			return
		}
		cmd.BranchID = &bid
	}

	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "payable created"})
}

func (h *PayableHandler) Approve(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}

	if err := h.cmdBus.Execute(r.Context(), &approvepayable.ApprovePayableCommand{ID: id}); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "payable approved"})
}

func (h *PayableHandler) Pay(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}

	var body struct {
		PaymentProof string `json:"payment_proof"`
		AccountCode  string `json:"account_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.cmdBus.Execute(r.Context(), &markpayablepaid.MarkPayablePaidCommand{
		ID:           id,
		PaymentProof: body.PaymentProof,
		AccountCode:  body.AccountCode,
	}); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "payable marked as paid"})
}

func (h *PayableHandler) Cancel(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}

	if err := h.cmdBus.Execute(r.Context(), &cancelpayable.CancelPayableCommand{ID: id}); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "payable cancelled"})
}
