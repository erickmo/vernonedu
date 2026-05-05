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

// ListBuildings godoc
// @Summary      List buildings
// @Description  Retrieve a paginated list of buildings.
// @Tags         locations
// @Produce      json
// @Param        offset  query  int     false  "Pagination offset"
// @Param        limit   query  int     false  "Pagination limit (default 20)"
// @Param        search  query  string  false  "Search buildings by name or address"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /buildings [get]
func (h *LocationHandler) ListBuildings(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	search := r.URL.Query().Get("search")

	result, err := h.qryBus.Execute(r.Context(), &listbuildings.ListBuildingsQuery{
		Offset: offset,
		Limit:  limit,
		Search: search,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list buildings")
		writeError(w, http.StatusInternalServerError, "failed to list buildings")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// GetBuilding godoc
// @Summary      Get a building by ID
// @Description  Retrieve a single building by its unique identifier.
// @Tags         locations
// @Produce      json
// @Param        id  path  string  true  "Building ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /buildings/{id} [get]
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

// CreateBuilding godoc
// @Summary      Create a new building
// @Description  Create a new building with name, address, and description.
// @Tags         locations
// @Accept       json
// @Produce      json
// @Param        body  body  CreateBuildingRequest  true  "Building data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /buildings [post]
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
	writeJSON(w, http.StatusCreated, map[string]interface{}{"id": cmd.ResultID.String(), "message": "building created successfully"})
}

// UpdateBuilding godoc
// @Summary      Update a building
// @Description  Update an existing building's details.
// @Tags         locations
// @Accept       json
// @Produce      json
// @Param        id    path  string                   true  "Building ID (UUID)"
// @Param        body  body  UpdateBuildingRequest    true  "Updated building data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /buildings/{id} [put]
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

// DeleteBuilding godoc
// @Summary      Delete a building
// @Description  Delete a building by its unique identifier.
// @Tags         locations
// @Produce      json
// @Param        id  path  string  true  "Building ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /buildings/{id} [delete]
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

// ListRooms godoc
// @Summary      List rooms
// @Description  Retrieve a paginated list of rooms, optionally filtered by building.
// @Tags         locations
// @Produce      json
// @Param        building_id  query  string  false  "Filter by Building ID (UUID)"
// @Param        offset       query  int     false  "Pagination offset"
// @Param        limit        query  int     false  "Pagination limit (default 20)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /rooms [get]
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

// GetRoom godoc
// @Summary      Get a room by ID
// @Description  Retrieve a single room by its unique identifier.
// @Tags         locations
// @Produce      json
// @Param        id  path  string  true  "Room ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /rooms/{id} [get]
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

// CreateRoom godoc
// @Summary      Create a new room
// @Description  Create a new room within a building with optional facilities, capacity, and floor.
// @Tags         locations
// @Accept       json
// @Produce      json
// @Param        body  body  CreateRoomRequest  true  "Room data"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /rooms [post]
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

// UpdateRoom godoc
// @Summary      Update a room
// @Description  Update an existing room's details including facilities, capacity, and floor.
// @Tags         locations
// @Accept       json
// @Produce      json
// @Param        id    path  string                true  "Room ID (UUID)"
// @Param        body  body  UpdateRoomRequest     true  "Updated room data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /rooms/{id} [put]
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

// DeleteRoom godoc
// @Summary      Delete a room
// @Description  Delete a room by its unique identifier.
// @Tags         locations
// @Produce      json
// @Param        id  path  string  true  "Room ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /rooms/{id} [delete]
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

// CheckRoomAvailability godoc
// @Summary      Check room availability
// @Description  Check if a room is available during a given time range. Returns conflicting schedules if any.
// @Tags         locations
// @Produce      json
// @Param        id    path  string  true  "Room ID (UUID)"
// @Param        from  query  string  true  "Start time (RFC3339 format)"
// @Param        to    query  string  true  "End time (RFC3339 format)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /rooms/{id}/availability [get]
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
