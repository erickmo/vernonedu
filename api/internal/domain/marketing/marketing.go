package marketing

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrPostNotFound            = errors.New("post not found")
	ErrClassDocNotFound        = errors.New("class doc post not found")
	ErrPrNotFound              = errors.New("pr schedule not found")
	ErrReferralPartnerNotFound = errors.New("referral partner not found")
	ErrDuplicateReferralCode   = errors.New("referral code already exists")
)

type SocialMediaPost struct {
	ID          uuid.UUID
	Platforms   []string
	ScheduledAt time.Time
	ContentType string // promo|dokumentasi|info|event
	Caption     string
	MediaURL    string
	BatchID     *uuid.UUID
	BatchName   string
	Status      string // scheduled|posted|draft
	PostURL     string
	CreatedBy   uuid.UUID
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type ClassDocPost struct {
	ID                uuid.UUID
	BatchID           uuid.UUID
	SessionID         uuid.UUID
	ModuleName        string
	BatchName         string
	ClassDate         time.Time
	ScheduledPostDate time.Time
	Status            string // scheduled|posted
	PostURL           string
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type PrSchedule struct {
	ID          uuid.UUID
	Title       string
	Type        string // press_release|event|sponsorship|interview|other
	ScheduledAt time.Time
	MediaVenue  string
	PicID       *uuid.UUID
	PicName     string
	Status      string // scheduled|active|completed
	Notes       string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type ReferralPartner struct {
	ID               uuid.UUID
	Name             string
	ContactEmail     string
	ReferralCode     string
	CommissionType   string // percentage|fixed
	CommissionValue  float64
	IsActive         bool
	TotalReferrals   int
	TotalEnrolled    int
	TotalCommission  float64
	PendingCommission float64
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type Referral struct {
	ID                uuid.UUID
	ReferralPartnerID uuid.UUID
	PartnerName       string
	LeadID            *uuid.UUID
	StudentID         *uuid.UUID
	BatchID           *uuid.UUID
	Status            string // pending|enrolled|paid
	Commission        float64
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type MarketingStats struct {
	TotalLeads               int
	LeadsThisMonth           int
	LeadsPrevMonth           int
	LeadToStudentPct         float64
	ScheduledPosts           int
	PostedThisMonth          int
	ActiveReferralPartners   int
	ReferralRevenueThisMonth float64
}

type WriteRepository interface {
	SavePost(ctx context.Context, p *SocialMediaPost) error
	UpdatePost(ctx context.Context, p *SocialMediaPost) error
	DeletePost(ctx context.Context, id uuid.UUID) error
	SaveClassDocPost(ctx context.Context, p *ClassDocPost) error
	UpdateClassDocPostStatus(ctx context.Context, id uuid.UUID, status, postURL string) error
	SavePr(ctx context.Context, p *PrSchedule) error
	UpdatePr(ctx context.Context, p *PrSchedule) error
	DeletePr(ctx context.Context, id uuid.UUID) error
	SaveReferralPartner(ctx context.Context, rp *ReferralPartner) error
	UpdateReferralPartner(ctx context.Context, rp *ReferralPartner) error
	SaveReferral(ctx context.Context, r *Referral) error
}

type ReadRepository interface {
	GetPostByID(ctx context.Context, id uuid.UUID) (*SocialMediaPost, error)
	ListPosts(ctx context.Context, offset, limit int, platform, status, month string) ([]*SocialMediaPost, int, error)
	ListClassDocs(ctx context.Context, offset, limit int, status string) ([]*ClassDocPost, int, error)
	GetPrByID(ctx context.Context, id uuid.UUID) (*PrSchedule, error)
	ListPr(ctx context.Context, offset, limit int, status, prType string) ([]*PrSchedule, int, error)
	GetReferralPartnerByID(ctx context.Context, id uuid.UUID) (*ReferralPartner, error)
	ListReferralPartners(ctx context.Context, offset, limit int, isActive *bool) ([]*ReferralPartner, int, error)
	ListReferrals(ctx context.Context, partnerID uuid.UUID) ([]*Referral, error)
	GetStats(ctx context.Context) (*MarketingStats, error)
}
