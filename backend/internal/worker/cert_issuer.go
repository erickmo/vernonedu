// Package worker contains async background workers for vernonedu2.
//
// cert_issuer.go:
//   Subscribes to enrollment.completed events (via the in-process event bus)
//   and asynchronously issues certificates by delegating to credentialing.Service.
//   This file declares the FX module + adapter types that bridge the
//   worker package's PDF/Storage primitives to the ports defined in
//   the credentialing domain.
package worker

import (
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/domains/credentialing"
	"go.uber.org/fx"
)

// Default verification base URL used when none is configured.
// TODO: derive from config/env in production.
const defaultVerifyBaseURL = "http://localhost:8080"

// rendererAdapter bridges the worker's CertificatePDFData-based renderer to
// the credentialing.PDFRenderer port (positional args).
type rendererAdapter struct{ inner PDFGenerator }

// NewRendererAdapter wires worker.PDFGenerator into credentialing.PDFRenderer.
func NewRendererAdapter(inner PDFGenerator) credentialing.PDFRenderer {
	return &rendererAdapter{inner: inner}
}

func (a *rendererAdapter) Render(studentName, courseName, certNumber string, issuedAt time.Time, verificationURL string) ([]byte, error) {
	return a.inner.Render(CertificatePDFData{
		StudentName:     studentName,
		CourseName:      courseName,
		CertNumber:      certNumber,
		IssuedAt:        issuedAt,
		VerificationURL: verificationURL,
	})
}

// storageAdapter bridges worker.CertStorage to credentialing.CertStorage.
// Both have identical Save signatures, but the credentialing port omits Load.
type storageAdapter struct{ inner CertStorage }

// NewStorageAdapter wires worker.CertStorage into credentialing.CertStorage.
func NewStorageAdapter(inner CertStorage) credentialing.CertStorage {
	return &storageAdapter{inner: inner}
}

func (a *storageAdapter) Save(certID uuid.UUID, data []byte) (string, error) {
	return a.inner.Save(certID, data)
}

// NewVerifyBaseURL returns the verification URL prefix injected into PDFs.
// Kept as a typed string so FX can distinguish it from other string deps.
type VerifyBaseURL string

func NewVerifyBaseURL() string { return defaultVerifyBaseURL }

// Module wires worker primitives + adapters into the FX graph. Consumers
// (cmd/api, cmd/worker) include this Module to satisfy credentialing.Service
// constructor dependencies (PDFRenderer, CertStorage, baseURL string).
var Module = fx.Options(
	fx.Provide(NewPDFGenerator),
	fx.Provide(func() CertStorage { return NewFSCertStorage("") }),
	fx.Provide(NewRendererAdapter),
	fx.Provide(NewStorageAdapter),
	fx.Provide(NewVerifyBaseURL),
)
