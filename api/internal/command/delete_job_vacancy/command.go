package delete_job_vacancy

import "github.com/google/uuid"

type DeleteJobVacancyCommand struct{ ID uuid.UUID }
