package filterutil

import (
	"encoding/json"
	"strconv"
)

// Filter holds one parsed filter from the frontend.
// Frontend format: [["field","operator","value"]]
// e.g. [["status","=","active"],["name","like","John"]]
type Filter struct {
	Field    string
	Operator string
	Value    string
}

// Parse parses the frontend filters query param.
// Returns nil on invalid or empty input.
func Parse(raw string) []Filter {
	if raw == "" {
		return nil
	}
	var arr [][]any
	if err := json.Unmarshal([]byte(raw), &arr); err != nil || len(arr) == 0 {
		return nil
	}
	out := make([]Filter, 0, len(arr))
	for _, item := range arr {
		if len(item) < 3 {
			continue
		}
		field, ok1 := item[0].(string)
		op, ok2 := item[1].(string)
		if !ok1 || !ok2 || field == "" {
			continue
		}
		var val string
		switch v := item[2].(type) {
		case string:
			val = v
		case float64:
			val = strconv.FormatFloat(v, 'f', -1, 64)
		case bool:
			if v {
				val = "true"
			} else {
				val = "false"
			}
		}
		out = append(out, Filter{Field: field, Operator: op, Value: val})
	}
	return out
}

// Get returns first filter value for the given field, or "" if not found.
func Get(filters []Filter, field string) string {
	for _, f := range filters {
		if f.Field == field {
			return f.Value
		}
	}
	return ""
}
