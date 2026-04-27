package enrollment

import (
	"testing"

	"github.com/shopspring/decimal"
)

func dec(v int64) decimal.Decimal { return decimal.NewFromInt(v) }
func decPtr(v int64) *decimal.Decimal {
	d := decimal.NewFromInt(v)
	return &d
}

func assertEq(t *testing.T, got, want decimal.Decimal, label string) {
	t.Helper()
	if !got.Equal(want) {
		t.Fatalf("%s: got %s, want %s", label, got.String(), want.String())
	}
}

func TestResolve_B2B_PartnerPayer_BatchBulkPrice_Wins(t *testing.T) {
	out := ResolvePrice(ResolveInput{
		BatchPrice:         dec(1000),
		BatchBulkPrice:     decPtr(800),
		AgreementBulkPrice: decPtr(700),
		IsB2B:              true,
		Payer:              PayerPartner,
	})
	assertEq(t, out.Price, dec(800), "price")
	assertEq(t, out.FinalPrice, dec(800), "final")
}

func TestResolve_B2B_PartnerPayer_AgreementBulkPrice_Used(t *testing.T) {
	out := ResolvePrice(ResolveInput{
		BatchPrice:         dec(1000),
		BatchBulkPrice:     nil,
		AgreementBulkPrice: decPtr(700),
		IsB2B:              true,
		Payer:              PayerPartner,
	})
	assertEq(t, out.Price, dec(700), "price")
	assertEq(t, out.FinalPrice, dec(700), "final")
}

func TestResolve_B2B_PartnerPayer_FallbackToBatchPrice(t *testing.T) {
	out := ResolvePrice(ResolveInput{
		BatchPrice: dec(1000),
		IsB2B:      true,
		Payer:      PayerPartner,
	})
	assertEq(t, out.Price, dec(1000), "price")
	assertEq(t, out.FinalPrice, dec(1000), "final")
}

func TestResolve_B2B_StudentPayer_VoucherApplies(t *testing.T) {
	v := &Voucher{DiscountType: DiscountFixed, DiscountValue: dec(100)}
	out := ResolvePrice(ResolveInput{
		BatchPrice: dec(500),
		IsB2B:      true,
		Payer:      PayerStudent,
		Voucher:    v,
	})
	assertEq(t, out.Price, dec(500), "price")
	assertEq(t, out.FinalPrice, dec(400), "final")
}

func TestResolve_B2B_PartnerPayer_VoucherIgnored(t *testing.T) {
	v := &Voucher{DiscountType: DiscountFixed, DiscountValue: dec(100)}
	out := ResolvePrice(ResolveInput{
		BatchPrice:     dec(500),
		BatchBulkPrice: decPtr(400),
		IsB2B:          true,
		Payer:          PayerPartner,
		Voucher:        v,
	})
	assertEq(t, out.Price, dec(400), "price")
	assertEq(t, out.FinalPrice, dec(400), "final (voucher ignored)")
}

func TestResolve_B2C_NoVoucher(t *testing.T) {
	out := ResolvePrice(ResolveInput{
		BatchPrice: dec(200),
		IsB2B:      false,
		Payer:      PayerStudent,
	})
	assertEq(t, out.Price, dec(200), "price")
	assertEq(t, out.FinalPrice, dec(200), "final")
}

func TestResolve_B2C_FixedAmountVoucher(t *testing.T) {
	v := &Voucher{DiscountType: DiscountFixed, DiscountValue: dec(50)}
	out := ResolvePrice(ResolveInput{
		BatchPrice: dec(200),
		IsB2B:      false,
		Voucher:    v,
	})
	assertEq(t, out.FinalPrice, dec(150), "final")
}

func TestResolve_B2C_FixedAmountVoucher_CapsAtZero(t *testing.T) {
	v := &Voucher{DiscountType: DiscountFixed, DiscountValue: dec(300)}
	out := ResolvePrice(ResolveInput{
		BatchPrice: dec(200),
		IsB2B:      false,
		Voucher:    v,
	})
	assertEq(t, out.FinalPrice, dec(0), "final")
}

func TestResolve_B2C_PercentageVoucher(t *testing.T) {
	v := &Voucher{DiscountType: DiscountPercentage, DiscountValue: dec(10)}
	out := ResolvePrice(ResolveInput{
		BatchPrice: dec(200),
		IsB2B:      false,
		Voucher:    v,
	})
	assertEq(t, out.FinalPrice, dec(180), "final")
}

func TestResolve_B2C_FixedFinalPriceVoucher(t *testing.T) {
	v := &Voucher{DiscountType: DiscountFinalPrice, DiscountValue: dec(99)}
	out := ResolvePrice(ResolveInput{
		BatchPrice: dec(500),
		IsB2B:      false,
		Voucher:    v,
	})
	assertEq(t, out.Price, dec(500), "price")
	assertEq(t, out.FinalPrice, dec(99), "final")
}
