package convert_lead_to_student

import "github.com/google/uuid"

type ConvertLeadToStudentCommand struct {
	LeadID uuid.UUID `validate:"required"`
}
