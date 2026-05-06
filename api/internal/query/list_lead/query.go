package list_lead

type ListLeadQuery struct {
	Offset   int
	Limit    int
	Status   string
	SourceID string
	Search   string
	SortBy   string
	SortDir  string
}
