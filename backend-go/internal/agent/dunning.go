package agent

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/mahalflow/backend-go/internal/agent/memory"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/logger"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/rs/zerolog/log"
)

const (
	dunningInterval = 1 * time.Hour
)

type DunningLanguage string

const (
	LangEnglish   DunningLanguage = "en"
	LangMalayalam DunningLanguage = "ml"
	LangUrdu      DunningLanguage = "ur"
	LangTamil     DunningLanguage = "ta"
)

type DunningTemplate struct {
	Subject  string
	Body     string
	Language DunningLanguage
}

type DunningAgent struct {
	memberRepo  repository.MemberRepository
	mahalRepo   repository.MahalRepository
	memoryStore memory.MemoryStore
	eventBus    *EventBus
}

func NewDunningAgent(
	memberRepo repository.MemberRepository,
	mahalRepo repository.MahalRepository,
	memoryStore memory.MemoryStore,
	eventBus *EventBus,
) Agent {
	return &DunningAgent{
		memberRepo:  memberRepo,
		mahalRepo:   mahalRepo,
		memoryStore: memoryStore,
		eventBus:    eventBus,
	}
}

func (a *DunningAgent) Name() AgentType { return AgentSmartDunning }

func (a *DunningAgent) Interval() time.Duration { return dunningInterval }

func (a *DunningAgent) Run(ctx context.Context) error {
	log.Info().Str("agent", string(a.Name())).Msg("Starting dunning cycle scan")

	mahals, err := a.mahalRepo.ListAll(ctx)
	if err != nil {
		return err
	}

	for _, mahal := range mahals {
		if err := ctx.Err(); err != nil {
			return err
		}
		if !mahal.Settings.DunningEnabled {
			continue
		}

		overdueMembers, err := a.memberRepo.GetOverdueMembers(ctx, mahal.ID)
		if err != nil {
			log.Warn().Err(err).Str("mahal_id", mahal.ID).Str("agent", string(a.Name())).Msg("Failed to fetch overdue members")
			continue
		}

		for _, member := range overdueMembers {
			if err := ctx.Err(); err != nil {
				return err
			}
			a.processMember(ctx, mahal.ID, member, mahal.Settings.PreferredLanguages)
		}
	}

	log.Info().Str("agent", string(a.Name())).Msg("Dunning cycle complete")
	return nil
}

func (a *DunningAgent) processMember(ctx context.Context, mahalID string, member domain.Member, preferredLangs []string) {
	lang := a.selectLanguage(member, preferredLangs)
	template := a.buildTemplate(member, lang)

	deliveryTime := a.calculateOptimalDeliveryTime(ctx, mahalID, member.ID)

	log.Info().
		Str("agent", string(a.Name())).
		Str("member_id", member.ID).
		Str("language", string(lang)).
		Time("scheduled_delivery", deliveryTime).
		Msg("Dunning reminder prepared")

	a.eventBus.Publish(Event{
		Type: EventMemberOverdue,
		Payload: map[string]interface{}{
			"mahal_id":         mahalID,
			"member_id":        member.ID,
			"member_name":      member.Name,
			"language":         string(lang),
			"template_subject": template.Subject,
			"template_body":    template.Body,
			"delivery_time":    deliveryTime,
		},
	})

	a.recordFeedback(ctx, mahalID, member.ID, template, deliveryTime)
}

func (a *DunningAgent) selectLanguage(member domain.Member, preferredLangs []string) DunningLanguage {
	if len(preferredLangs) > 0 {
		return DunningLanguage(preferredLangs[0])
	}
	return LangEnglish
}

func (a *DunningAgent) buildTemplate(member domain.Member, lang DunningLanguage) DunningTemplate {
	switch lang {
	case LangMalayalam:
		return DunningTemplate{
			Subject:  "MahalFlow - മാസ ഫീസ് ഓർമ്മിപ്പിക്കൽ",
			Body:     fmt.Sprintf("പ്രിയ സഹോദരൻ %s, നിങ്ങളുടെ മാസ ഫീസ് ബാക്കിയുണ്ട്. ദയവായി എത്രയും വേഗം പണമടയ്ക്കുക.", member.Name),
			Language: lang,
		}
	case LangUrdu:
		return DunningTemplate{
			Subject:  "MahalFlow - ماہانہ فیس کی یاد دہانی",
			Body:     fmt.Sprintf("عزیز بھائی %s، آپ کی ماہانہ فیس بقایا ہے۔ براہ کرم جلد از جلد ادائیگی کریں۔", member.Name),
			Language: lang,
		}
	case LangTamil:
		return DunningTemplate{
			Subject:  "MahalFlow - மாதாந்திர கட்டண நினைவூட்டல்",
			Body:     fmt.Sprintf("அன்புள்ள சகோதரர் %s, உங்கள் மாதாந்திர கட்டணம் நிலுவையில் உள்ளது. தயவுசெய்து விரைவில் செலுத்துங்கள்.", member.Name),
			Language: lang,
		}
	default:
		return DunningTemplate{
			Subject:  "MahalFlow - Monthly Dues Reminder",
			Body:     fmt.Sprintf("Dear %s, your monthly dues are pending. Please make the payment at your earliest convenience.", member.Name),
			Language: lang,
		}
	}
}

func (a *DunningAgent) calculateOptimalDeliveryTime(ctx context.Context, mahalID, memberID string) time.Time {
	history, err := a.memoryStore.GetHistoricalContext(ctx, mahalID, string(AgentSmartDunning), 10)
	if err != nil || len(history) == 0 {
		now := time.Now().UTC()
		return time.Date(now.Year(), now.Month(), now.Day(), 20, 0, 0, 0, time.UTC)
	}

	type timeSlot struct {
		hour   int
		score  float64
		count  int
	}
	slots := make(map[int]*timeSlot)

	for _, h := range history {
		t := h.CreatedAt
		hour := t.Hour()
		if slots[hour] == nil {
			slots[hour] = &timeSlot{hour: hour}
		}
		slots[hour].score += h.Outcome.RewardScore
		slots[hour].count++
	}

	bestHour := 20
	bestAvg := 0.0
	for _, slot := range slots {
		if slot.count > 0 {
			avg := slot.score / float64(slot.count)
			if avg > bestAvg {
				bestAvg = avg
				bestHour = slot.hour
			}
		}
	}

	fallbackDegradation := math.Min(float64(len(history))/10.0, 1.0)
	if bestAvg < 0.3 && fallbackDegradation < 0.5 {
		bestHour = 20
	}

	now := time.Now().UTC()
	return time.Date(now.Year(), now.Month(), now.Day(), bestHour, 0, 0, 0, time.UTC)
}

func (a *DunningAgent) recordFeedback(ctx context.Context, mahalID, memberID string, template DunningTemplate, deliveryTime time.Time) {
	record := &memory.FeedbackRecord{
		MahalID:   mahalID,
		AgentType: string(AgentSmartDunning),
		Context: map[string]interface{}{
			"member_id":     memberID,
			"language":      string(template.Language),
			"delivery_time": deliveryTime,
		},
		ActionTaken: fmt.Sprintf("dunning_%s_template", string(template.Language)),
		Outcome: memory.FeedbackOutcome{
			Converted:   false,
			RewardScore: 0.5,
			Notes:       "Reminder scheduled, awaiting member response",
		},
		CreatedAt: time.Now().UTC(),
	}
	if err := a.memoryStore.RecordFeedback(ctx, record); err != nil {
		logger.Log.Warn().Err(err).Str("agent", string(AgentSmartDunning)).Msg("Failed to record dunning feedback")
	}
}
