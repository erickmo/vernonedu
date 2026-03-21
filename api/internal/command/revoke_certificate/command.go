package revoke_certificate

import "github.com/google/uuid"

type RevokeCertificateCommand struct {
	CertificateID uuid.UUID `validate:"required"`
	Reason        string    `validate:"required"`
}
