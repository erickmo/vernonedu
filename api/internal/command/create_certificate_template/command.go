package create_certificate_template

type CreateCertificateTemplateCommand struct {
	Name         string                 `validate:"required"`
	Type         string                 `validate:"required,oneof=participant competency"`
	TemplateData map[string]interface{}
}
