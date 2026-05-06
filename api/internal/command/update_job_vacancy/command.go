package update_job_vacancy

import (
	"time"

	"github.com/google/uuid"
)

type UpdateJobVacancyCommand struct {
	ID              uuid.UUID
	Title           string
	Description     string
	PartnerID       uuid.UUID
	DepartmentID    *uuid.UUID
	Location        string
	Type            string
	ExperienceLevel string
	Slots           int
	MinSalary       *int64
	MaxSalary       *int64
	RequiredSkills  []string
	Deadline        *time.Time
}
