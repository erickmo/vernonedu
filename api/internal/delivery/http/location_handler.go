package http

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	createbuilding "github.com/vernonedu/entrepreneurship-api/internal/command/create_building"
	deletebuilding "github.com/vernonedu/entrepreneurship-api/internal/command/delete_building"
	updatebuilding "github.com/vernonedu/entrepreneurship-api/internal/command/update_building"
	createroom "github.com/vernonedu/entrepreneurship-api/internal/command/create_room"
	deleteroom "github.com/vernonedu/entrepreneurship-api/internal/command/delete_room"
	updateroom "github.com/vernonedu/entrepreneurship-api/internal/command/update_room"
	checkavailability "github.com/vernonedu/entrepreneurship-api/internal/query/check_room_availability"
	getbuilding "github.com/vernonedu/entrepreneurship-api/internal/query/get_building"
	getroom "github.com/vernonedu/entrepreneurship-api/internal/query/get_room"
	listbuildings "github.com/vernonedu/entrepreneurship-api/internal/query/list_buildings"
	listrooms "github.com/vernonedu/entrepreneurship-api/internal/query/list_rooms"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
)

type LocationHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewLocationHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *LocationHandler {
	return &LocationHandler{cmdBus: cmdBus, qryBus: qryBus}
}

// ─── Request bodies ───────────────────────────────────────────────────────────

type CreateBuildingRequest struct {
	Name        string `json:"name" validate:"required"`
	Address     string `json:"address"`
	Description string `json:"description"`
}

type UpdateBuildingRequest struct {
	Name        string `json:"name" validate:"required"`
	Address     string `json:"address"`
	Description string `json:"description"`
}

type CreateRoomRequest struct {
	BuildingID  string   `json:"building_id" validate:"required"`
	Name        string   `json:"name" validate:"required"`
	Capacity    *int     `json:"capacity"`
	Floor       *string  `json:"floor"`
	Facilities  []string `json:"facilities"`
	Description string   `json:"description"`
}

type UpdateRoomRequest struct {
	Name        string   `json:"name" validate:"required"`
	Capacity    *int     `json:"capacity"`
	Floor       *string  `json:"floor"`
	Facilities  []string `json:"facilities"`
	Description string   `json:"description"`
}

// ─── Building handlers ────────────────────────────────────────────────────────

func (h *LocationHandler) ListBuildings(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	result, err := h.qryBus.Execute(r.Context(), &listbuildings.ListBuildingsQuery{Offset: offset, Limit: limit})
	if err != nil {
		log.Error().Err(err).Msg("failed to list buildings")
		writeError(w, http.StatusInternalServerError, "failed to list buildings")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *LocationHandler) GetBuilding(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid building id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getbuilding.GetBuildingQuery{ID: id})
	if err != nil {
		log.Error().Err(err).Msg("failed to get building")
		writeError(w, http.StatusInternalServerError, "failed to get building")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *LocationHandler) CreateBuilding(w http.ResponseWriter, r *http.Request) {
	var req CreateBuildingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &createbuilding.CreateBuildingCommand{
		Name:        req.Name,
		Address:     req.Address,
		Description: req.Description,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create building")
		writeError(w, http.StatusInternalServerError, "failed to create building")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "building created successfully"})
}

func (h *LocationHandler) UpdateBuilding(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid building id")
		return
	}

	var req UpdateBuildingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updatebuilding.UpdateBuildingCommand{
		ID:          id,
		Name:        req.Name,
		Address:     req.Address,
		Description: req.Description,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update building")
		writeError(w, http.StatusInternalServerError, "failed to update building")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "building updated successfully"})
}

func (h *LocationHandler) DeleteBuilding(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid building id")
		return
	}

	cmd := &deletebuilding.DeleteBuildingCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete building")
		writeError(w, http.StatusInternalServerError, "failed to delete building")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "building deleted successfully"})
}

// ─── Room handlers ────────────────────────────────────────────────────────────

func (h *LocationHandler) ListRooms(w http.ResponseWriter, r *http.Request) {
	buildingID := r.URL.Query().Get("building_id")
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}

	result, err := h.qryBus.Execute(r.Context(), &listrooms.ListRoomsQuery{
		BuildingID: buildingID,
		Offset:     offset,
		Limit:      limit,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list rooms")
		writeError(w, http.StatusInternalServerError, "failed to list rooms")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *LocationHandler) GetRoom(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid room id")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &getroom.GetRoomQuery{ID: id})
	if err != nil {
		log.Error().Err(err).Msg("failed to get room")
		writeError(w, http.StatusInternalServerError, "failed to get room")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *LocationHandler) CreateRoom(w http.ResponseWriter, r *http.Request) {
	var req CreateRoomRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	buildingID, err := uuid.Parse(req.BuildingID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid building_id")
		return
	}

	cmd := &createroom.CreateRoomCommand{
		BuildingID:  buildingID,
		Name:        req.Name,
		Capacity:    req.Capacity,
		Floor:       req.Floor,
		Facilities:  req.Facilities,
		Description: req.Description,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create room")
		writeError(w, http.StatusInternalServerError, "failed to create room")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "room created successfully"})
}

func (h *LocationHandler) UpdateRoom(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid room id")
		return
	}

	var req UpdateRoomRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &updateroom.UpdateRoomCommand{
		ID:          id,
		Name:        req.Name,
		Capacity:    req.Capacity,
		Floor:       req.Floor,
		Facilities:  req.Facilities,
		Description: req.Description,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update room")
		writeError(w, http.StatusInternalServerError, "failed to update room")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "room updated successfully"})
}

func (h *LocationHandler) DeleteRoom(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid room id")
		return
	}

	cmd := &deleteroom.DeleteRoomCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete room")
		writeError(w, http.StatusInternalServerError, "failed to delete room")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "room deleted successfully"})
}

func (h *LocationHandler) CheckRoomAvailability(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid room id")
		return
	}

	fromStr := r.URL.Query().Get("from")
	toStr := r.URL.Query().Get("to")
	if fromStr == "" || toStr == "" {
		writeError(w, http.StatusBadRequest, "from and to query params are required")
		return
	}

	from, err := time.Parse(time.RFC3339, fromStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid 'from' datetime, use RFC3339 format")
		return
	}
	to, err := time.Parse(time.RFC3339, toStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid 'to' datetime, use RFC3339 format")
		return
	}
	if !to.After(from) {
		writeError(w, http.StatusBadRequest, "'to' must be after 'from'")
		return
	}

	result, err := h.qryBus.Execute(r.Context(), &checkavailability.CheckRoomAvailabilityQuery{
		RoomID: id,
		From:   from,
		To:     to,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to check room availability")
		writeError(w, http.StatusInternalServerError, "failed to check room availability")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// ─── Route registration ───────────────────────────────────────────────────────

func RegisterLocationRoutes(h *LocationHandler, r chi.Router) {
	// Buildings
	r.Get("/api/v1/buildings", h.ListBuildings)
	r.Get("/api/v1/buildings/{id}", h.GetBuilding)
	r.Post("/api/v1/buildings", h.CreateBuilding)
	r.Put("/api/v1/buildings/{id}", h.UpdateBuilding)
	r.Delete("/api/v1/buildings/{id}", h.DeleteBuilding)

	// Rooms
	r.Get("/api/v1/rooms", h.ListRooms)
	r.Get("/api/v1/rooms/{id}", h.GetRoom)
	r.Post("/api/v1/rooms", h.CreateRoom)
	r.Put("/api/v1/rooms/{id}", h.UpdateRoom)
	r.Delete("/api/v1/rooms/{id}", h.DeleteRoom)
	r.Get("/api/v1/rooms/{id}/availability", h.CheckRoomAvailability)
}
