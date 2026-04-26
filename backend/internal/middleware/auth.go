package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

type contextKey string

const userContextKey contextKey = "user_context"

// UserContext holds authenticated user info injected into request context.
type UserContext struct {
	ID    uuid.UUID
	Role  string
	Email string
}

// GetUserContext retrieves UserContext from request context. Returns nil if not set.
func GetUserContext(ctx context.Context) *UserContext {
	v, _ := ctx.Value(userContextKey).(*UserContext)
	return v
}

// JWT returns a middleware that validates Bearer tokens and injects UserContext.
func JWT(secret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				apperrors.Render(w, apperrors.ErrUnauthorized)
				return
			}

			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
				apperrors.Render(w, apperrors.ErrUnauthorized)
				return
			}

			tokenStr := parts[1]
			claims := &jwtClaims{}

			token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, apperrors.ErrUnauthorized
				}
				return []byte(secret), nil
			})
			if err != nil || !token.Valid {
				apperrors.Render(w, apperrors.ErrUnauthorized)
				return
			}

			userID, err := uuid.Parse(claims.Subject)
			if err != nil {
				apperrors.Render(w, apperrors.ErrUnauthorized)
				return
			}

			uc := &UserContext{
				ID:    userID,
				Role:  claims.Role,
				Email: claims.Email,
			}

			ctx := context.WithValue(r.Context(), userContextKey, uc)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

type jwtClaims struct {
	jwt.RegisteredClaims
	Role  string `json:"role"`
	Email string `json:"email"`
}
