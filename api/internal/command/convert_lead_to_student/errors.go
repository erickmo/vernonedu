package convert_lead_to_student

import "errors"

var (
	ErrInvalidCommand       = errors.New("invalid convert lead to student command")
	ErrLeadNotFound         = errors.New("lead not found")
	ErrLeadAlreadyConverted = errors.New("lead already enrolled/converted")
)
