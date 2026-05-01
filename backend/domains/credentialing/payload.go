package credentialing

import (
	"reflect"

	"github.com/google/uuid"
)

// payloadFieldUUID extracts a uuid.UUID-typed field by name from any struct
// (or pointer to struct) using reflection. Used as a last-resort decoder for
// cross-domain event payloads to avoid an import cycle on enrollment.
func payloadFieldUUID(payload any, fieldName string) (uuid.UUID, bool) {
	v := reflect.ValueOf(payload)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}
	if v.Kind() != reflect.Struct {
		return uuid.Nil, false
	}
	f := v.FieldByName(fieldName)
	if !f.IsValid() {
		return uuid.Nil, false
	}
	if id, ok := f.Interface().(uuid.UUID); ok {
		return id, true
	}
	return uuid.Nil, false
}
