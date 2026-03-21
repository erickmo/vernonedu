package update_talentpool_status

import "errors"

var (
	ErrInvalidCommand       = errors.New("invalid update talentpool status command")
	ErrPlacementRecordEmpty = errors.New("placement record wajib diisi jika status 'placed'")
)
