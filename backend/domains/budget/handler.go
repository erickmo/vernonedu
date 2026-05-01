package budget

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/zap"
)

// Handler exposes HTTP endpoints for the budget domain.
type Handler struct {
	svc *Service
	log *zap.Logger
}

// NewHandler constructs budget Handler (FX-injectable).
func NewHandler(svc *Service, log *zap.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// ─── Template Items ───────────────────────────────────────────────────────────

func (h *Handler) ListTemplateItems(w http.ResponseWriter, r *http.Request) {
	courseID, err := parseUUID(chi.URLParam(r, "course_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course_id"))
		return
	}
	items, err := h.svc.ListTemplateItems(r.Context(), courseID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) GetTemplateItem(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	item, err := h.svc.GetTemplateItem(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *Handler) CreateTemplateItem(w http.ResponseWriter, r *http.Request) {
	courseID, err := parseUUID(chi.URLParam(r, "course_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course_id"))
		return
	}
	var item CourseBudgetTemplateItem
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	item.CourseID = courseID
	if err := h.svc.CreateTemplateItem(r.Context(), &item); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (h *Handler) UpdateTemplateItem(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	var item CourseBudgetTemplateItem
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	item.ID = id
	if err := h.svc.UpdateTemplateItem(r.Context(), &item); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *Handler) DeleteTemplateItem(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	if err := h.svc.DeleteTemplateItem(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── Batch Items ──────────────────────────────────────────────────────────────

func (h *Handler) ListBatchItems(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "batch_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch_id"))
		return
	}
	items, err := h.svc.ListBatchItems(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) GetBatchItem(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	item, err := h.svc.GetBatchItem(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *Handler) CreateBatchItem(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "batch_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch_id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var item BatchBudgetItem
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	item.CourseBatchID = batchID
	item.CreatedBy = uc.ID
	if err := h.svc.CreateBatchItem(r.Context(), &item); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (h *Handler) UpdateBatchItem(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	var item BatchBudgetItem
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	item.ID = id
	if err := h.svc.UpdateBatchItem(r.Context(), &item); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *Handler) DeleteBatchItem(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	if err := h.svc.DeleteBatchItem(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── Realizations ─────────────────────────────────────────────────────────────

func (h *Handler) ListRealizations(w http.ResponseWriter, r *http.Request) {
	itemID, err := parseUUID(chi.URLParam(r, "item_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid item_id"))
		return
	}
	items, err := h.svc.ListRealizations(r.Context(), itemID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) GetRealization(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	item, err := h.svc.GetRealization(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *Handler) CreateRealization(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	itemID, err := parseUUID(chi.URLParam(r, "item_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid item_id"))
		return
	}
	var item BudgetRealization
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	item.BatchBudgetItemID = itemID
	item.RecordedBy = uc.ID
	if err := h.svc.CreateRealization(r.Context(), &item); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (h *Handler) UpdateRealization(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	var item BudgetRealization
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	item.ID = id
	if err := h.svc.UpdateRealization(r.Context(), &item); err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *Handler) DeleteRealization(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	if err := h.svc.DeleteRealization(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── Summary ──────────────────────────────────────────────────────────────────

func (h *Handler) GetBatchSummary(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "batch_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch_id"))
		return
	}
	summary, err := h.svc.GetBatchSummary(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, summary)
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func parseUUID(s string) (uuid.UUID, error) {
	return uuid.Parse(s)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}
