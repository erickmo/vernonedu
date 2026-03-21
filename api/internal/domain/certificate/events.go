package certificate

import "github.com/google/uuid"

type CertificateIssuedEvent struct {
	EventType     string     `json:"event_type"`
	CertificateID uuid.UUID  `json:"certificate_id"`
	StudentID     *uuid.UUID `json:"student_id,omitempty"`
	CertCode      string     `json:"certificate_code"`
	CertType      string     `json:"cert_type"`
	Timestamp     int64      `json:"timestamp"`
}

func (e *CertificateIssuedEvent) EventName() string      { return "CertificateIssued" }
func (e *CertificateIssuedEvent) EventData() interface{} { return e }

type CertificateRevokedEvent struct {
	EventType     string     `json:"event_type"`
	CertificateID uuid.UUID  `json:"certificate_id"`
	StudentID     *uuid.UUID `json:"student_id,omitempty"`
	CertCode      string     `json:"certificate_code"`
	Reason        string     `json:"reason"`
	Timestamp     int64      `json:"timestamp"`
}

func (e *CertificateRevokedEvent) EventName() string      { return "CertificateRevoked" }
func (e *CertificateRevokedEvent) EventData() interface{} { return e }
