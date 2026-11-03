package repository

import "testing"

func TestNewlyCoveredDuesIsIdempotent(t *testing.T) {
	months := []string{"2026-03", "2026-04"}
	// Nothing paid yet: both months count, the full amount applies.
	if n, a := NewlyCoveredDues("2026-02", months, 1000); n != 2 || a != 1000 {
		t.Fatalf("fresh: newly=%d applied=%v", n, a)
	}
	// An earlier PENDING transaction already covered 2026-03: only 2026-04 applies.
	if n, a := NewlyCoveredDues("2026-03", months, 1000); n != 1 || a != 500 {
		t.Fatalf("partly covered: newly=%d applied=%v", n, a)
	}
	// Same months committed twice: the second booking applies nothing.
	if n, a := NewlyCoveredDues("2026-04", months, 1000); n != 0 || a != 0 {
		t.Fatalf("fully covered: newly=%d applied=%v", n, a)
	}
	// Member paid further ahead meanwhile.
	if n, a := NewlyCoveredDues("2026-09", months, 1000); n != 0 || a != 0 {
		t.Fatalf("paid ahead: newly=%d applied=%v", n, a)
	}
	// A brand-new member has no last paid month.
	if n, a := NewlyCoveredDues("", months, 1000); n != 2 || a != 1000 {
		t.Fatalf("empty last month: newly=%d applied=%v", n, a)
	}
	if n, _ := NewlyCoveredDues("2026-01", nil, 10); n != 0 {
		t.Fatal("no months")
	}
}
