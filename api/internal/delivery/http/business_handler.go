package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_business"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_business"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_business"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_business"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_business"
	"github.com/vernonedu/entrepreneurship-api/internal/query/search_business"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	pkgmiddleware "github.com/vernonedu/entrepreneurship-api/pkg/middleware"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type BusinessHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewBusinessHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *BusinessHandler {
	return &BusinessHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateBusinessRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

func (h *BusinessHandler) Create(w http.ResponseWriter, r *http.Request) {
	userIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	if userIDStr == "" {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid user id")
		return
	}

	var req CreateBusinessRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_business.CreateBusinessCommand{UserID: userID, Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create business command")
		writeError(w, http.StatusInternalServerError, "failed to create business")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "business created successfully"})
}

func (h *BusinessHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	businessIDStr := chi.URLParam(r, "id")
	businessID, err := uuid.Parse(businessIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid business id")
		return
	}

	query := &get_business.GetBusinessQuery{BusinessID: businessID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get business query")
		writeError(w, http.StatusInternalServerError, "failed to get business")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *BusinessHandler) List(w http.ResponseWriter, r *http.Request) {
	userIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	if userIDStr == "" {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid user id")
		return
	}

	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &list_business.ListBusinessQuery{UserID: userID, Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list business query")
		writeError(w, http.StatusInternalServerError, "failed to list businesses")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *BusinessHandler) Search(w http.ResponseWriter, r *http.Request) {
	userIDStr := pkgmiddleware.GetUserIDFromContext(r.Context())
	if userIDStr == "" {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid user id")
		return
	}

	name := r.URL.Query().Get("name")
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &search_business.SearchBusinessQuery{UserID: userID, Name: name, Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute search business query")
		writeError(w, http.StatusInternalServerError, "failed to search businesses")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type UpdateBusinessRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

func (h *BusinessHandler) Update(w http.ResponseWriter, r *http.Request) {
	businessIDStr := chi.URLParam(r, "id")
	businessID, err := uuid.Parse(businessIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid business id")
		return
	}

	var req UpdateBusinessRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_business.UpdateBusinessCommand{BusinessID: businessID, Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update business command")
		writeError(w, http.StatusInternalServerError, "failed to update business")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "business updated successfully"})
}

func (h *BusinessHandler) Delete(w http.ResponseWriter, r *http.Request) {
	businessIDStr := chi.URLParam(r, "id")
	businessID, err := uuid.Parse(businessIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid business id")
		return
	}

	cmd := &delete_business.DeleteBusinessCommand{BusinessID: businessID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete business command")
		writeError(w, http.StatusInternalServerError, "failed to delete business")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "business deleted successfully"})
}

func RegisterBusinessRoutes(h *BusinessHandler, r chi.Router) {
	r.Post("/api/v1/businesses", h.Create)
	r.Get("/api/v1/businesses", h.List)
	r.Get("/api/v1/businesses/search", h.Search)
	r.Get("/api/v1/businesses/{id}", h.GetByID)
	r.Put("/api/v1/businesses/{id}", h.Update)
	r.Delete("/api/v1/businesses/{id}", h.Delete)
}
