package list_job_vacancies

type ListJobVacanciesQuery struct {
	Offset    int
	Limit     int
	Status    string
	PartnerID string
	Type      string
	Search    string
	SortBy    string
	SortDir   string
}
