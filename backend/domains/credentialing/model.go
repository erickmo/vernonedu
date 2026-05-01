package credentialing

import (
	"time"

	"github.com/google/uuid"
)

type CertCategory string

const (
	CertVernonEduCompetence   CertCategory = "vernonedu_competence"
	CertVernonEduParticipation CertCategory = "vernonedu_participation"
	CertPartner               CertCategory = "partner"
)

type CertStatus string

const (
	CertPending CertStatus = "pending"
	CertIssued  CertStatus = "issued"
	CertRevoked CertStatus = "revoked"
)

type CertAction string

const (
	ActionRevoke  CertAction = "revoke"
	ActionReissue CertAction = "reissue"
)

type ActionStatus string

const (
	ActionPending  ActionStatus = "pending"
	ActionApproved ActionStatus = "approved"
	ActionRejected ActionStatus = "rejected"
)

type IssuedOn string

const (
	IssuedOnCompletion IssuedOn = "completion"
	IssuedOnManual     IssuedOn = "manual"
)

type CertificateType struct {
	ID             uuid.UUID    `json:"id"`
	Name           string       `json:"name"`
	Category       CertCategory `json:"category"`
	ValidityMonths *int         `json:"validity_months,omitempty"`
	IsActive       bool         `json:"is_active"`
	CreatedBy      uuid.UUID    `json:"created_by"`
	CreatedAt      time.Time    `json:"created_at"`
	UpdatedAt      time.Time    `json:"updated_at"`
}

type CertificateConfig struct {
	ID                uuid.UUID `json:"id"`
	CourseID          uuid.UUID `json:"course_id"`
	CertificateTypeID uuid.UUID `json:"certificate_type_id"`
	IssuedOn          IssuedOn  `json:"issued_on"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

type Certificate struct {
	ID                  uuid.UUID  `json:"id"`
	EnrollmentID        uuid.UUID  `json:"enrollment_id"`
	CertificateTypeID   uuid.UUID  `json:"certificate_type_id"`
	CertificateConfigID uuid.UUID  `json:"certificate_config_id"`
	CertificateNumber   string     `json:"certificate_number"`
	IssuedAt            time.Time  `json:"issued_at"`
	Status              CertStatus `json:"status"`
	QRCodeURL           *string    `json:"qr_code_url,omitempty"`
	ExpiresAt           *time.Time `json:"expires_at,omitempty"`
	RevokedAt           *time.Time `json:"revoked_at,omitempty"`
	RevokedBy           *uuid.UUID `json:"revoked_by,omitempty"`
	ReissuedFrom        *uuid.UUID `json:"reissued_from,omitempty"`
	PDFPath             *string    `json:"pdf_path,omitempty"`
	PDFHash             *string    `json:"pdf_hash,omitempty"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

// CertificateContext holds joined data needed for PDF rendering.
type CertificateContext struct {
	EnrollmentID uuid.UUID
	StudentName  string
	CourseName   string
	CompletedAt  time.Time
}

// VerificationResult is the public payload returned by verify endpoint.
type VerificationResult struct {
	Valid         bool      `json:"valid"`
	CertificateID uuid.UUID `json:"certificate_id"`
	Number        string    `json:"certificate_number"`
	StudentName   string    `json:"student_name"`
	CourseName    string    `json:"course_name"`
	IssuedAt      time.Time `json:"issued_at"`
}

type CertificateActionRequest struct {
	ID                  uuid.UUID    `json:"id"`
	StudentCertificateID uuid.UUID   `json:"student_certificate_id"`
	Action              CertAction   `json:"action"`
	Reason              string       `json:"reason"`
	RequestedBy         uuid.UUID    `json:"requested_by"`
	ApprovedBy          *uuid.UUID   `json:"approved_by,omitempty"`
	Status              ActionStatus `json:"status"`
	CreatedAt           time.Time    `json:"created_at"`
	UpdatedAt           time.Time    `json:"updated_at"`
	ResolvedAt          *time.Time   `json:"resolved_at,omitempty"`
}
