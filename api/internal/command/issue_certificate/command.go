package issue_certificate

type IssueCertificateCommand struct {
	TemplateID          string `validate:"required"`
	StudentID           string
	BatchID             string
	CourseID            string
	Type                string `validate:"required,oneof=participant competency"`
	VerificationBaseURL string
}
