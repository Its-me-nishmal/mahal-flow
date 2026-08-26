package agent

import "sync"

type EventType string

const (
	EventPaymentPending   EventType = "PAYMENT_PENDING"
	EventPaymentResolved  EventType = "PAYMENT_RESOLVED"
	EventFraudDetected    EventType = "FRAUD_DETECTED"
	EventMemberOverdue    EventType = "MEMBER_OVERDUE"
	EventExcelUploaded    EventType = "EXCEL_UPLOADED"
	EventAuditFailed      EventType = "AUDIT_FAILED"
	EventAuditCompleted   EventType = "AUDIT_COMPLETED"
)

type Event struct {
	Type    EventType
	Payload map[string]interface{}
}

type EventHandler func(event Event)

type EventBus struct {
	mu       sync.RWMutex
	handlers map[EventType][]EventHandler
}

func NewEventBus() *EventBus {
	return &EventBus{
		handlers: make(map[EventType][]EventHandler),
	}
}

func (b *EventBus) Subscribe(eventType EventType, handler EventHandler) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.handlers[eventType] = append(b.handlers[eventType], handler)
}

func (b *EventBus) Publish(event Event) {
	b.mu.RLock()
	defer b.mu.RUnlock()
	for _, handler := range b.handlers[event.Type] {
		go handler(event)
	}
}
