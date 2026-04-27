package enrollment

import "github.com/shopspring/decimal"

// ResolveInput is the pure-function input for pricing resolution.
type ResolveInput struct {
	BatchPrice         decimal.Decimal
	BatchBulkPrice     *decimal.Decimal
	AgreementBulkPrice *decimal.Decimal
	IsB2B              bool
	Payer              Payer
	Voucher            *Voucher
}

// ResolveOutput holds the resolved pre-voucher price and final price.
type ResolveOutput struct {
	Price      decimal.Decimal // pre-voucher resolved price
	FinalPrice decimal.Decimal // after voucher application
}

// ResolvePrice computes the pre-voucher and final enrollment price.
//
// Precedence (B2B partner-payer):
//  1. BatchBulkPrice (if set)
//  2. AgreementBulkPrice (if set)
//  3. BatchPrice
//
// Voucher only applies for B2C, or B2B with student-payer.
func ResolvePrice(in ResolveInput) ResolveOutput {
	price := resolveBasePrice(in)
	final := price
	if shouldApplyVoucher(in) {
		final = applyVoucher(price, *in.Voucher)
	}
	return ResolveOutput{Price: price, FinalPrice: final}
}

func resolveBasePrice(in ResolveInput) decimal.Decimal {
	if in.IsB2B {
		if in.BatchBulkPrice != nil {
			return *in.BatchBulkPrice
		}
		if in.AgreementBulkPrice != nil {
			return *in.AgreementBulkPrice
		}
	}
	return in.BatchPrice
}

func shouldApplyVoucher(in ResolveInput) bool {
	if in.Voucher == nil {
		return false
	}
	if !in.IsB2B {
		return true
	}
	return in.Payer == PayerStudent
}

func applyVoucher(price decimal.Decimal, v Voucher) decimal.Decimal {
	switch v.DiscountType {
	case DiscountFixed:
		out := price.Sub(v.DiscountValue)
		if out.IsNegative() {
			return decimal.Zero
		}
		return out
	case DiscountPercentage:
		factor := decimal.NewFromInt(1).Sub(v.DiscountValue.Div(decimal.NewFromInt(100)))
		return price.Mul(factor)
	case DiscountFinalPrice:
		return v.DiscountValue
	}
	return price
}
