package service

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/mahalflow/backend-go/internal/agent"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/repository"
)

// recordingAlerts captures Create; everything else is unused here.
type recordingAlerts struct {
	repository.AlertRepository
	mu   sync.Mutex
	rows []domain.SystemAlert
}

func (r *recordingAlerts) Create(_ context.Context, a *domain.SystemAlert) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.rows = append(r.rows, *a)
	return nil
}

func TestDunningEventsBecomeMemberAlerts(t *testing.T) {
	bus := agent.NewEventBus()
	rec := &recordingAlerts{}
	SubscribeDunningAlerts(bus, rec)
	bus.Publish(agent.Event{Type: agent.EventMemberOverdue, Payload: map[string]interface{}{
		"mahal_id": "MH_A", "member_id": "MEM_1", "template_subject": "Dues", "template_body": "Please pay",
	}})
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		rec.mu.Lock()
		n := len(rec.rows)
		rec.mu.Unlock()
		if n > 0 {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}
	rec.mu.Lock()
	defer rec.mu.Unlock()
	if len(rec.rows) != 1 {
		t.Fatalf("want 1 alert, got %d", len(rec.rows))
	}
	a := rec.rows[0]
	if a.Type != domain.AlertTypeDuesReminder || a.Audience != domain.AudienceMember || len(a.MemberIDs) != 1 || a.MemberIDs[0] != "MEM_1" || a.MahalID != "MH_A" {
		t.Fatalf("alert: %+v", a)
	}
	if a.ID != DunningAlertID("MEM_1", time.Now()) {
		t.Fatalf("id must be per member per day: %s", a.ID)
	}
}
