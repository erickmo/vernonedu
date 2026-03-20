package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_item"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_item"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_item"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_item"
	listitemsbycanvas "github.com/vernonedu/entrepreneurship-api/internal/query/list_items_by_canvas"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type ItemHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewItemHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *ItemHandler {
	return &ItemHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateItemRequest struct {
	BusinessID uuid.UUID `json:"business_id"`
	CanvasType string    `json:"canvas_type"`
	SectionID  string    `json:"section_id"`
	Text       string    `json:"text"`
	Note       string    `json:"note"`
}

func (h *ItemHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_item.CreateItemCommand{
		BusinessID: req.BusinessID,
		CanvasType: req.CanvasType,
		SectionID:  req.SectionID,
		Text:       req.Text,
		Note:       req.Note,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create item command")
		writeError(w, http.StatusInternalServerError, "failed to create item")
		return
	}

	created := cmd.CreatedItem
	writeJSON(w, http.StatusCreated, map[string]interface{}{"data": map[string]interface{}{
		"id":          created.ID,
		"business_id": created.BusinessID,
		"canvas_type": created.CanvasType,
		"section_id":  created.SectionID,
		"text":        created.Text,
		"note":        created.Note,
		"created_at":  created.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		"updated_at":  created.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}})
}

func (h *ItemHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	itemIDStr := chi.URLParam(r, "id")
	itemID, err := uuid.Parse(itemIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid item id")
		return
	}

	query := &get_item.GetItemQuery{ItemID: itemID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get item query")
		writeError(w, http.StatusInternalServerError, "failed to get item")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *ItemHandler) List(w http.ResponseWriter, r *http.Request) {
	businessIDStr := r.URL.Query().Get("business_id")
	if businessIDStr == "" {
		writeError(w, http.StatusBadRequest, "business_id is required")
		return
	}
	businessID, err := uuid.Parse(businessIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid business_id")
		return
	}

	canvasType := r.URL.Query().Get("canvas_type")

	query := &listitemsbycanvas.ListItemsByCanvasQuery{
		BusinessID: businessID,
		CanvasType: canvasType,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list items by canvas query")
		writeError(w, http.StatusInternalServerError, "failed to list items")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type UpdateItemRequest struct {
	Text string `json:"text" validate:"required,min=1"`
	Note string `json:"note"`
}

func (h *ItemHandler) Update(w http.ResponseWriter, r *http.Request) {
	itemIDStr := chi.URLParam(r, "id")
	itemID, err := uuid.Parse(itemIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid item id")
		return
	}

	var req UpdateItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_item.UpdateItemCommand{ItemID: itemID, Text: req.Text, Note: req.Note}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update item command")
		writeError(w, http.StatusInternalServerError, "failed to update item")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "item updated successfully"})
}

func (h *ItemHandler) Delete(w http.ResponseWriter, r *http.Request) {
	itemIDStr := chi.URLParam(r, "id")
	itemID, err := uuid.Parse(itemIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid item id")
		return
	}

	cmd := &delete_item.DeleteItemCommand{ItemID: itemID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete item command")
		writeError(w, http.StatusInternalServerError, "failed to delete item")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "item deleted successfully"})
}

func RegisterItemRoutes(h *ItemHandler, r chi.Router) {
	r.Post("/api/v1/items", h.Create)
	r.Get("/api/v1/items", h.List)
	r.Get("/api/v1/items/{id}", h.GetByID)
	r.Put("/api/v1/items/{id}", h.Update)
	r.Delete("/api/v1/items/{id}", h.Delete)
}
