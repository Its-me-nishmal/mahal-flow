package service

import (
	"encoding/json"
	"net/http"
)

func decodeJSON(r *http.Request, out interface{}) error {
	return json.NewDecoder(r.Body).Decode(out)
}
