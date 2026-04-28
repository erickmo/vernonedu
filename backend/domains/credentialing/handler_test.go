//go:build integration

package credentialing_test

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/credentialing"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"github.com/vernonedu/vernonedu2/backend/internal/worker"
)

func newCredSvc(t *testing.T) *credentialing.Service {
	t.Helper()
	pool := newTestPool(t)
	t.Cleanup(pool.Close)
	storageRoot := t.TempDir()
	require.NoError(t, os.MkdirAll(storageRoot, 0o755))
	bus := events.NewBus(zap.NewNop())
	return credentialing.NewService(
		credentialing.NewRepository(pool),
		bus,
		zap.NewNop(),
		worker.NewRendererAdapter(worker.NewPDFGenerator()),
		worker.NewStorageAdapter(worker.NewFSCertStorage(storageRoot)),
		"http://localhost:8080",
	)
}

func buildCredentialingRouter(svc *credentialing.Service, role string) http.Handler {
	h := credentialing.NewHandler(svc)
	r := chi.NewRouter()

	// Public routes
	r.Get("/api/v1/certificates/verify/{number}", h.VerifyCertificate)
	r.Get("/api/v1/certificates/verify-hash/{hash}", h.VerifyByHash)

	// JWT-protected routes
	r.Group(func(r chi.Router) {
		r.Use(func(next http.Handler) http.Handler {
			return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
				uc := &mw.UserContext{ID: uuid.New(), Role: role}
				next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
			})
		})
		r.Get("/api/v1/enrollments/{enrollmentID}/certificates", h.ListCertificates)
		r.Get("/api/v1/certificates/{id}/download", h.DownloadCertificate)
		r.Post("/api/v1/certificates/{id}/actions", h.RequestAction)
		r.Post("/api/v1/certificate-actions/{id}/approve", h.ApproveActionRequest)
	})

	return r
}

func TestCredentialing_VerifyCertificate_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newCredSvc(t)
	router := buildCredentialingRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/certificates/verify/UNKNOWN-0000", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestCredentialing_ListCertificates_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newCredSvc(t)
	router := buildCredentialingRouter(svc, "student")

	enrollmentID := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/enrollments/"+enrollmentID.String()+"/certificates", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestCredentialing_DownloadCertificate_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newCredSvc(t)
	router := buildCredentialingRouter(svc, "student")

	certID := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/certificates/"+certID.String()+"/download", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
