//go:build integration

package finance_test

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/finance"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

const fakeWebhookSecret = "test-secret"

// createDraftInvoice seeds an invoice we can pay against.
func createDraftInvoice(t *testing.T, svc *finance.Service, f fixture) *finance.Invoice {
	t.Helper()
	ctx := context.Background()
	pay, err := svc.InitiatePayment(ctx, f.enrollmentID, decimal.NewFromInt(1000000), finance.PaymentFull)
	require.NoError(t, err)

	due := time.Now().AddDate(0, 0, 14)
	inv := &finance.Invoice{
		EnrollmentID:   f.enrollmentID,
		PaymentID:      pay.ID,
		BilledTo:       "student",
		StudentID:      &f.studentID,
		IssuedDate:     time.Now(),
		DueDate:        &due,
		Subtotal:       decimal.NewFromInt(1000000),
		DiscountAmount: decimal.Zero,
		TotalAmount:    decimal.NewFromInt(1000000),
		CreatedBy:      f.creatorID,
	}
	created, err := svc.CreateInvoice(ctx, inv, []finance.InvoiceLineItem{
		{Label: "Course fee", Amount: decimal.NewFromInt(1000000)},
	})
	require.NoError(t, err)
	return created
}

func TestPaymentGateway_HappyPath_PayThenWebhookSettles(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	log := zap.NewNop()
	gw := finance.NewFakeGateway(fakeWebhookSecret, "https://test.local/pay/")
	svc := finance.NewService(finance.NewRepository(pool), events.NewBus(log), gw, log)
	ctx := context.Background()

	inv := createDraftInvoice(t, svc, f)

	// 1. Initiate charge → returns redirect URL, persists provider_ref.
	redirectURL, err := svc.InitiateInvoicePayment(ctx, inv.ID)
	require.NoError(t, err)
	require.Contains(t, redirectURL, inv.InvoiceNumber)

	got, err := svc.GetInvoiceByID(ctx, inv.ID)
	require.NoError(t, err)
	require.NotNil(t, got.ProviderRef)
	require.Equal(t, inv.InvoiceNumber, *got.ProviderRef)
	require.NotNil(t, got.PaymentProvider)
	require.Equal(t, finance.ProviderFake, *got.PaymentProvider)
	require.Equal(t, finance.InvoiceDraft, got.Status)

	// 2. Webhook arrives → invoice marked paid + paid_at set.
	payload, _ := json.Marshal(map[string]string{
		"order_id": inv.InvoiceNumber,
		"status":   string(finance.OutcomeSettled),
	})
	require.NoError(t, svc.ProcessGatewayWebhook(ctx, payload, fakeWebhookSecret))

	got, err = svc.GetInvoiceByID(ctx, inv.ID)
	require.NoError(t, err)
	require.Equal(t, finance.InvoicePaid, got.Status)
	require.NotNil(t, got.PaidAt)
}

func TestPaymentGateway_BadSignature_Rejected(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	log := zap.NewNop()
	gw := finance.NewFakeGateway(fakeWebhookSecret, "")
	svc := finance.NewService(finance.NewRepository(pool), events.NewBus(log), gw, log)
	ctx := context.Background()

	inv := createDraftInvoice(t, svc, f)
	_, err := svc.InitiateInvoicePayment(ctx, inv.ID)
	require.NoError(t, err)

	payload, _ := json.Marshal(map[string]string{
		"order_id": inv.InvoiceNumber,
		"status":   string(finance.OutcomeSettled),
	})
	err = svc.ProcessGatewayWebhook(ctx, payload, "WRONG-SECRET")
	require.ErrorIs(t, err, finance.ErrInvalidSignature)

	got, err := svc.GetInvoiceByID(ctx, inv.ID)
	require.NoError(t, err)
	require.Equal(t, finance.InvoiceDraft, got.Status)
	require.Nil(t, got.PaidAt)
}

func TestPaymentGateway_DoubleSettle_Idempotent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	log := zap.NewNop()
	gw := finance.NewFakeGateway(fakeWebhookSecret, "")
	svc := finance.NewService(finance.NewRepository(pool), events.NewBus(log), gw, log)
	ctx := context.Background()

	inv := createDraftInvoice(t, svc, f)
	_, err := svc.InitiateInvoicePayment(ctx, inv.ID)
	require.NoError(t, err)

	payload, _ := json.Marshal(map[string]string{
		"order_id": inv.InvoiceNumber,
		"status":   string(finance.OutcomeSettled),
	})
	require.NoError(t, svc.ProcessGatewayWebhook(ctx, payload, fakeWebhookSecret))

	first, err := svc.GetInvoiceByID(ctx, inv.ID)
	require.NoError(t, err)
	require.NotNil(t, first.PaidAt)
	firstPaidAt := *first.PaidAt

	// Replay the same webhook — must succeed (idempotent) and NOT bump paid_at.
	require.NoError(t, svc.ProcessGatewayWebhook(ctx, payload, fakeWebhookSecret))

	second, err := svc.GetInvoiceByID(ctx, inv.ID)
	require.NoError(t, err)
	require.Equal(t, finance.InvoicePaid, second.Status)
	require.NotNil(t, second.PaidAt)
	require.True(t, second.PaidAt.Equal(firstPaidAt), "paid_at must not change on replay")

	// And the gateway/service must reject re-initiating payment on a paid invoice.
	_, err = svc.InitiateInvoicePayment(ctx, inv.ID)
	require.Error(t, err)
}

