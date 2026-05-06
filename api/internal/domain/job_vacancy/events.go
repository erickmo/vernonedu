package job_vacancy

import "github.com/google/uuid"

type JobVacancyCreatedEvent struct {
	EventType string    `json:"event_type"`
	VacancyID uuid.UUID `json:"vacancy_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *JobVacancyCreatedEvent) EventName() string {
	return "JobVacancyCreated"
}

func (e *JobVacancyCreatedEvent) EventData() interface{} {
	return e
}

type JobVacancyStatusChangedEvent struct {
	EventType string    `json:"event_type"`
	VacancyID uuid.UUID `json:"vacancy_id"`
	OldStatus string    `json:"old_status"`
	NewStatus string    `json:"new_status"`
	Timestamp int64     `json:"timestamp"`
}

func (e *JobVacancyStatusChangedEvent) EventName() string {
	return "JobVacancyStatusChanged"
}

func (e *JobVacancyStatusChangedEvent) EventData() interface{} {
	return e
}
