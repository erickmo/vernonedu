package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_designthinking"
	"github.com/vernonedu/entrepreneurship-api/internal/query/search_designthinking"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type DesignThinkingHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewDesignThinkingHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *DesignThinkingHandler {
	return &DesignThinkingHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateDesignThinkingRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

// Create godoc
// @Summary      Create design thinking canvas
// @Description  Create a new design thinking canvas with a name
// @Tags         entrepreneurship
// @Accept       json
// @Produce      json
// @Param        body  body  object  true  "Design thinking creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /design-thinkings [post]
func (h *DesignThinkingHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateDesignThinkingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_designthinking.CreateDesignThinkingCommand{Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create design thinking command")
		writeError(w, http.StatusInternalServerError, "failed to create design thinking")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "design thinking created successfully"})
}

// GetByID godoc
// @Summary      Get design thinking by ID
// @Description  Retrieve a single design thinking canvas by its ID
// @Tags         entrepreneurship
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Design thinking ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /design-thinkings/{id} [get]
func (h *DesignThinkingHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	dtIDStr := chi.URLParam(r, "id")
	dtID, err := uuid.Parse(dtIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid design thinking id")
		return
	}

	query := &get_designthinking.GetDesignThinkingQuery{DesignThinkingID: dtID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get design thinking query")
		writeError(w, http.StatusInternalServerError, "failed to get design thinking")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// List godoc
// @Summary      List design thinking canvases
// @Description  Retrieve paginated list of design thinking canvases
// @Tags         entrepreneurship
// @Accept       json
// @Produce      json
// @Param        offset  query  int  false  "Pagination offset"
// @Param        limit   query  int  false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /design-thinkings [get]
func (h *DesignThinkingHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_designthinking.ListDesignThinkingQuery{Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list design thinking query")
		writeError(w, http.StatusInternalServerError, "failed to list design thinkings")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Search godoc
// @Summary      Search design thinking canvases
// @Description  Search design thinking canvases by name with pagination
// @Tags         entrepreneurship
// @Accept       json
// @Produce      json
// @Param        name    query  string  false  "Name search query"
// @Param        offset  query  int     false  "Pagination offset"
// @Param        limit   query  int     false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /design-thinkings/search [get]
func (h *DesignThinkingHandler) Search(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &search_designthinking.SearchDesignThinkingQuery{Name: name, Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute search design thinking query")
		writeError(w, http.StatusInternalServerError, "failed to search design thinkings")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type UpdateDesignThinkingRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

// Update godoc
// @Summary      Update design thinking canvas
// @Description  Update an existing design thinking canvas by ID
// @Tags         entrepreneurship
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Design thinking ID"
// @Param        body  body  object  true  "Design thinking update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /design-thinkings/{id} [put]
func (h *DesignThinkingHandler) Update(w http.ResponseWriter, r *http.Request) {
	dtIDStr := chi.URLParam(r, "id")
	dtID, err := uuid.Parse(dtIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid design thinking id")
		return
	}

	var req UpdateDesignThinkingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_designthinking.UpdateDesignThinkingCommand{DesignThinkingID: dtID, Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update design thinking command")
		writeError(w, http.StatusInternalServerError, "failed to update design thinking")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "design thinking updated successfully"})
}

// Delete godoc
// @Summary      Delete design thinking canvas
// @Description  Delete a design thinking canvas by ID
// @Tags         entrepreneurship
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Design thinking ID"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /design-thinkings/{id} [delete]
func (h *DesignThinkingHandler) Delete(w http.ResponseWriter, r *http.Request) {
	dtIDStr := chi.URLParam(r, "id")
	dtID, err := uuid.Parse(dtIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid design thinking id")
		return
	}

	cmd := &delete_designthinking.DeleteDesignThinkingCommand{DesignThinkingID: dtID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete design thinking command")
		writeError(w, http.StatusInternalServerError, "failed to delete design thinking")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "design thinking deleted successfully"})
}

func RegisterDesignThinkingRoutes(h *DesignThinkingHandler, r chi.Router) {
	r.Post("/api/v1/design-thinkings", h.Create)
	r.Get("/api/v1/design-thinkings", h.List)
	r.Get("/api/v1/design-thinkings/search", h.Search)
	r.Get("/api/v1/design-thinkings/{id}", h.GetByID)
	r.Put("/api/v1/design-thinkings/{id}", h.Update)
	r.Delete("/api/v1/design-thinkings/{id}", h.Delete)
}
