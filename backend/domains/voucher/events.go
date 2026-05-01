package voucher

import "github.com/vernonedu/vernonedu2/backend/internal/events"

// RegisterSubscriptions is a no-op: voucher domain fires no events and listens to none.
// The ApplyVoucher flow creates VoucherUsage synchronously at checkout time.
func RegisterSubscriptions(_ events.Bus, _ *Service) {}
