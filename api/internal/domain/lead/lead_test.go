package lead_test

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

func TestNewLead_Success(t *testing.T) {
	sourceID := uuid.New()
	l, err := lead.NewLead("Alice", "alice@example.com", "08123456789", &sourceID, "notes", nil)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.Name != "Alice" {
		t.Errorf("expected name Alice, got %s", l.Name)
	}
	if l.Status != "new" {
		t.Errorf("expected status new, got %s", l.Status)
	}
	if l.SourceID == nil || *l.SourceID != sourceID {
		t.Errorf("expected source_id %v, got %v", sourceID, l.SourceID)
	}
}

func TestNewLead_EmptyPhone_ReturnsError(t *testing.T) {
	_, err := lead.NewLead("Bob", "", "", nil, "", nil)
	if err == nil {
		t.Fatal("expected error for empty phone")
	}
	if err != lead.ErrPhoneRequired {
		t.Errorf("expected ErrPhoneRequired, got %v", err)
	}
}

func TestNewLead_EmptyName_ReturnsError(t *testing.T) {
	_, err := lead.NewLead("", "email@example.com", "0812345", nil, "", nil)
	if err == nil {
		t.Fatal("expected error for empty name")
	}
	if err != lead.ErrInvalidName {
		t.Errorf("expected ErrInvalidName, got %v", err)
	}
}

func TestNewLead_NilSourceID(t *testing.T) {
	l, err := lead.NewLead("Carol", "carol@example.com", "081234", nil, "", nil)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.SourceID != nil {
		t.Errorf("expected nil source_id, got %v", l.SourceID)
	}
}

func TestNewLead_WithPicID(t *testing.T) {
	picID := uuid.New()
	l, err := lead.NewLead("Dave", "dave@example.com", "081234", nil, "", &picID)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.PicID == nil || *l.PicID != picID {
		t.Errorf("expected pic_id %v, got %v", picID, l.PicID)
	}
}

func TestNewLeadSource_Success(t *testing.T) {
	s := lead.NewLeadSource("Referral")
	if s.Name != "Referral" {
		t.Errorf("expected name Referral, got %s", s.Name)
	}
	if !s.IsActive {
		t.Error("expected is_active true")
	}
	if s.ID == uuid.Nil {
		t.Error("expected non-nil ID")
	}
}

func TestNewLeadInterest_Success(t *testing.T) {
	leadID := uuid.New()
	entityID := uuid.New()
	i := lead.NewLeadInterest(leadID, "master_course", entityID)
	if i.LeadID != leadID {
		t.Errorf("expected lead_id %v", leadID)
	}
	if i.EntityType != "master_course" {
		t.Errorf("expected entity_type master_course, got %s", i.EntityType)
	}
	if i.EntityID != entityID {
		t.Errorf("expected entity_id %v", entityID)
	}
}

func TestNewCrmLog_Success(t *testing.T) {
	leadID := uuid.New()
	contactedByID := uuid.New()
	followUp := time.Now().Add(24 * time.Hour)

	crmLog := lead.NewCrmLog(leadID, contactedByID, "phone", "interested", &followUp)

	if crmLog.LeadID != leadID {
		t.Errorf("expected lead_id %v", leadID)
	}
	if crmLog.ContactMethod != "phone" {
		t.Errorf("expected contact_method phone, got %s", crmLog.ContactMethod)
	}
	if crmLog.FollowUpDate == nil {
		t.Fatal("expected follow_up_date to be set")
	}
}

func TestNewCrmLog_NilFollowUpDate(t *testing.T) {
	crmLog := lead.NewCrmLog(uuid.New(), uuid.New(), "email", "no response", nil)
	if crmLog.FollowUpDate != nil {
		t.Errorf("expected nil follow_up_date")
	}
}
