package lead_test

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

func TestNewLead_Success(t *testing.T) {
	l, err := lead.NewLead("Alice", "alice@example.com", "08123456789", "programming", "website", "notes", nil)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.Name != "Alice" {
		t.Errorf("expected name Alice, got %s", l.Name)
	}
	if l.Status != "new" {
		t.Errorf("expected status new, got %s", l.Status)
	}
	if l.Source != "website" {
		t.Errorf("expected source website, got %s", l.Source)
	}
	if l.PicID != nil {
		t.Errorf("expected nil pic_id, got %v", l.PicID)
	}
}

func TestNewLead_DefaultSource(t *testing.T) {
	l, err := lead.NewLead("Bob", "", "", "", "", "", nil)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.Source != "other" {
		t.Errorf("expected default source 'other', got %s", l.Source)
	}
}

func TestNewLead_EmptyName_ReturnsError(t *testing.T) {
	_, err := lead.NewLead("", "email@example.com", "", "", "", "", nil)
	if err == nil {
		t.Fatal("expected error for empty name")
	}
	if err != lead.ErrInvalidName {
		t.Errorf("expected ErrInvalidName, got %v", err)
	}
}

func TestNewLead_WithPicID(t *testing.T) {
	picID := uuid.New()
	l, err := lead.NewLead("Carol", "carol@example.com", "", "design", "referral", "", &picID)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.PicID == nil {
		t.Fatal("expected pic_id to be set")
	}
	if *l.PicID != picID {
		t.Errorf("expected pic_id %v, got %v", picID, *l.PicID)
	}
}

func TestNewCrmLog_Success(t *testing.T) {
	leadID := uuid.New()
	contactedByID := uuid.New()
	followUp := time.Now().Add(24 * time.Hour)

	crmLog := lead.NewCrmLog(leadID, contactedByID, "phone", "interested in product", &followUp)

	if crmLog.LeadID != leadID {
		t.Errorf("expected lead_id %v, got %v", leadID, crmLog.LeadID)
	}
	if crmLog.ContactedByID != contactedByID {
		t.Errorf("expected contacted_by_id %v, got %v", contactedByID, crmLog.ContactedByID)
	}
	if crmLog.ContactMethod != "phone" {
		t.Errorf("expected contact_method phone, got %s", crmLog.ContactMethod)
	}
	if crmLog.Response != "interested in product" {
		t.Errorf("expected response 'interested in product', got %s", crmLog.Response)
	}
	if crmLog.FollowUpDate == nil {
		t.Fatal("expected follow_up_date to be set")
	}
	if crmLog.ID == uuid.Nil {
		t.Error("expected non-nil crm log ID")
	}
}

func TestNewCrmLog_NilFollowUpDate(t *testing.T) {
	leadID := uuid.New()
	contactedByID := uuid.New()

	crmLog := lead.NewCrmLog(leadID, contactedByID, "email", "no response", nil)

	if crmLog.FollowUpDate != nil {
		t.Errorf("expected nil follow_up_date, got %v", crmLog.FollowUpDate)
	}
}

func TestLeadStatus_Enrolled(t *testing.T) {
	l, err := lead.NewLead("Dave", "dave@example.com", "", "", "", "", nil)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	l.Status = "enrolled"
	if l.Status != "enrolled" {
		t.Errorf("expected status enrolled, got %s", l.Status)
	}
}
