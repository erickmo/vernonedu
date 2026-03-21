package update_certificate_template

import "github.com/google/uuid"

type UpdateCertificateTemplateCommand struct {
	ID           uuid.UUID              `validate:"required"`
	Name         string                 `validate:"required"`
	TemplateData map[string]interface{}
	IsActive     bool
}
