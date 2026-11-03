package api

import "os"

// Every test in this package signs and verifies tokens; the production code has
// no default secret, so provide one before the key is first loaded.
func init() {
	_ = os.Setenv("JWT_SECRET", "test-secret-test-secret-test-secret-0123456789")
}
