package list_lead_sources

import "errors"

var ErrInvalidQuery = errors.New("invalid list lead sources query")

type ListLeadSourcesQuery struct{}
