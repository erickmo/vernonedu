package change_vacancy_status

import "github.com/google/uuid"

type ChangeVacancyStatusCommand struct {
	ID        uuid.UUID
	NewStatus string
}
