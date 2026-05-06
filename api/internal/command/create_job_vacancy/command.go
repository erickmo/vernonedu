package create_job_vacancy

import (
	"time"

	"github.com/google/uuid"
)

type CreateJobVacancyCommand struct {
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
	CreatedBy       uuid.UUID
}
