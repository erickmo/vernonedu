package list_lead

type ListLeadQuery struct {
	Offset   int
	Limit    int
	Status   string
	Source   string
	Interest string
}
