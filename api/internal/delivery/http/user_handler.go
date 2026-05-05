package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_user"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_user"
	"github.com/vernonedu/entrepreneurship-api/internal/command/update_user"
	"github.com/vernonedu/entrepreneurship-api/internal/query/get_user"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_user"
	"github.com/vernonedu/entrepreneurship-api/internal/query/search_user"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
	"github.com/vernonedu/entrepreneurship-api/pkg/sortutil"
)

type UserHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewUserHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *UserHandler {
	return &UserHandler{
		cmdBus: cmdBus,
		qryBus: qryBus,
	}
}

type CreateUserRequest struct {
	Name     string   `json:"name"     validate:"required,min=1"`
	Email    string   `json:"email"    validate:"required,email"`
	Password string   `json:"password" validate:"required,min=6"`
	Roles    []string `json:"roles"    validate:"required,min=1"`
}

// Create godoc
// @Summary      Create a new user
// @Description  Create a user with name, email, password, and roles
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        body  body  CreateUserRequest  true  "User creation payload"
// @Success      201  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users [post]
func (h *UserHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &create_user.CreateUserCommand{
		Name:     req.Name,
		Email:    req.Email,
		Password: req.Password,
		Roles:    req.Roles,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create user command")
		writeError(w, http.StatusInternalServerError, "failed to create user")
		return
	}

	writeJSON(w, http.StatusCreated, map[string]string{"message": "user created successfully"})
}

// GetByID godoc
// @Summary      Get user by ID
// @Description  Retrieve a single user by their UUID
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "User ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users/{id} [get]
func (h *UserHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	userIDStr := chi.URLParam(r, "id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}

	query := &get_user.GetUserQuery{UserID: userID}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute get user query")
		writeError(w, http.StatusInternalServerError, "failed to get user")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// List godoc
// @Summary      List users
// @Description  Retrieve a paginated list of users
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        offset  query  int  false  "Pagination offset"
// @Param        limit   query  int  false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users [get]
func (h *UserHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	sort := sortutil.Parse(r.URL.Query().Get("sort"))
	var sortBy, sortDir string
	if sort != nil {
		sortBy = sort.Column
		sortDir = sort.Dir
	}

	query := &list_user.ListUserQuery{Offset: offset, Limit: limit, SortBy: sortBy, SortDir: sortDir}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list user query")
		writeError(w, http.StatusInternalServerError, "failed to list users")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

// Search godoc
// @Summary      Search users by name
// @Description  Search users with pagination and name filter
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        name    query  string  false  "Name to search for"
// @Param        offset  query  int     false  "Pagination offset"
// @Param        limit   query  int     false  "Pagination limit (default 10)"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users/search [get]
func (h *UserHandler) Search(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}

	query := &search_user.SearchUserQuery{Name: name, Offset: offset, Limit: limit}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute search user query")
		writeError(w, http.StatusInternalServerError, "failed to search users")
		return
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

type UpdateUserRequest struct {
	Name string `json:"name" validate:"required,min=1"`
}

// Update godoc
// @Summary      Update user
// @Description  Update a user's name by their ID
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        id    path  string              true  "User ID (UUID)"
// @Param        body  body  UpdateUserRequest  true  "User update payload"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users/{id} [put]
func (h *UserHandler) Update(w http.ResponseWriter, r *http.Request) {
	userIDStr := chi.URLParam(r, "id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}

	var req UpdateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	cmd := &update_user.UpdateUserCommand{UserID: userID, Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update user command")
		writeError(w, http.StatusInternalServerError, "failed to update user")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "user updated successfully"})
}

// Delete godoc
// @Summary      Delete user
// @Description  Delete a user by their ID
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "User ID (UUID)"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users/{id} [delete]
func (h *UserHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userIDStr := chi.URLParam(r, "id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid user id")
		return
	}

	cmd := &delete_user.DeleteUserCommand{UserID: userID}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute delete user command")
		writeError(w, http.StatusInternalServerError, "failed to delete user")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "user deleted successfully"})
}

func RegisterUserRoutes(h *UserHandler, r chi.Router) {
	r.Post("/api/v1/users", h.Create)
	r.Get("/api/v1/users", h.List)
	r.Get("/api/v1/users/search", h.Search)
	r.Get("/api/v1/users/{id}", h.GetByID)
	r.Put("/api/v1/users/{id}", h.Update)
	r.Delete("/api/v1/users/{id}", h.Delete)
}
