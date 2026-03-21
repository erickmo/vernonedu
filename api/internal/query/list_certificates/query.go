package list_certificates

type ListCertificatesQuery struct {
	StudentID string
	BatchID   string
	Type      string
	Status    string
	Offset    int
	Limit     int
}
