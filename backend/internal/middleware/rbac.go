package middleware

import (
	"net/http"

	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// RequireRole returns middleware that allows only users whose role is in the allowed list.
func RequireRole(roles ...string) func(http.Handler) http.Handler {
	allowed := make(map[string]struct{}, len(roles))
	for _, r := range roles {
		allowed[r] = struct{}{}
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			uc := GetUserContext(r.Context())
			if uc == nil {
				apperrors.Render(w, apperrors.ErrUnauthorized)
				return
			}

			if _, ok := allowed[uc.Role]; !ok {
				apperrors.Render(w, apperrors.ErrForbidden)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
