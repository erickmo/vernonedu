package errors

import (
	"encoding/json"
	"net/http"
)

// AppError is a domain error with HTTP semantics.
type AppError struct {
	Code       string `json:"code"`
	Message    string `json:"message"`
	HTTPStatus int    `json:"-"`
}

func (e *AppError) Error() string { return e.Message }

// New creates an AppError.
func New(code, message string, status int) *AppError {
	return &AppError{Code: code, Message: message, HTTPStatus: status}
}

// Sentinel errors — use errors.Is or type-assert to check.
var (
	ErrNotFound     = New("NOT_FOUND", "resource not found", http.StatusNotFound)
	ErrUnauthorized = New("UNAUTHORIZED", "authentication required", http.StatusUnauthorized)
	ErrForbidden    = New("FORBIDDEN", "insufficient permissions", http.StatusForbidden)
	ErrConflict     = New("CONFLICT", "resource already exists", http.StatusConflict)
	ErrValidation   = New("VALIDATION_ERROR", "validation failed", http.StatusUnprocessableEntity)
	ErrInternal     = New("INTERNAL_ERROR", "internal server error", http.StatusInternalServerError)
	ErrAutoCreatedReadOnly = New("AUTO_CREATED_READ_ONLY", "auto-created resources cannot be modified via manual API", http.StatusForbidden)
)

type errResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

// Render writes a JSON error response. Handles *AppError and generic errors.
func Render(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")

	var appErr *AppError
	switch e := err.(type) {
	case *AppError:
		appErr = e
	default:
		appErr = ErrInternal
	}

	w.WriteHeader(appErr.HTTPStatus)
	_ = json.NewEncoder(w).Encode(errResponse{
		Code:    appErr.Code,
		Message: appErr.Message,
	})
}

// Validationf creates a validation error with a custom message.
func Validationf(msg string) *AppError {
	return New("VALIDATION_ERROR", msg, http.StatusUnprocessableEntity)
}

// NotFoundf creates a not-found error with a custom message.
func NotFoundf(msg string) *AppError {
	return New("NOT_FOUND", msg, http.StatusNotFound)
}

// Conflictf creates a conflict error with a custom message.
func Conflictf(msg string) *AppError {
	return New("CONFLICT", msg, http.StatusConflict)
}
