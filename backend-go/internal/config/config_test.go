package config

import (
	"strings"
	"testing"
)

func TestResolveSafetyTestModeDefaultsOff(t *testing.T) {
	for _, env := range []string{"", "development", "production", "prod", "stagng"} {
		tm, _, w := ResolveSafety(env, "", "")
		if tm || len(w) != 0 {
			t.Errorf("env %q, PAYMENT_TEST_MODE unset: testMode=%v warnings=%v; want OFF and silent", env, tm, w)
		}
	}
}

func TestResolveSafetyTestModeOnlyInExplicitDevelopment(t *testing.T) {
	for _, v := range []string{"ON", "on", "true", "1"} {
		if tm, _, w := ResolveSafety("development", v, ""); !tm || len(w) != 0 {
			t.Errorf("development + %q: testMode=%v warnings=%v; want ON", v, tm, w)
		}
	}
	// Production-like, unset and misspelled ENV must force it OFF, loudly.
	for _, env := range []string{"production", "prod", "", "developmnt", "staging"} {
		tm, _, w := ResolveSafety(env, "ON", "")
		if tm {
			t.Errorf("env %q + PAYMENT_TEST_MODE=ON must be forced OFF", env)
		}
		if len(w) != 1 || !strings.Contains(w[0], "PAYMENT_TEST_MODE") {
			t.Errorf("env %q: want one PAYMENT_TEST_MODE warning, got %v", env, w)
		}
	}
	if tm, _, _ := ResolveSafety("development", "OFF", ""); tm {
		t.Error("OFF must stay off")
	}
}

func TestResolveSafetyStandaloneCommit(t *testing.T) {
	if _, sa, _ := ResolveSafety("development", "", "true"); !sa {
		t.Error("standalone commit allowed in development")
	}
	if _, sa, w := ResolveSafety("production", "", "true"); sa || len(w) != 1 {
		t.Errorf("standalone commit must be ignored in production: %v %v", sa, w)
	}
}

func TestCORSAllowOrigins(t *testing.T) {
	if got := CORSAllowOrigins("production", ""); got != "" {
		t.Errorf("production default must send no CORS headers, got %q", got)
	}
	if got := CORSAllowOrigins("", ""); got != "" {
		t.Errorf("unset ENV default must send no CORS headers, got %q", got)
	}
	if got := CORSAllowOrigins("development", ""); !strings.Contains(got, "localhost") || strings.Contains(got, "*") {
		t.Errorf("development default: %q", got)
	}
	if got := CORSAllowOrigins("production", " https://a.example , *, https://b.example "); got != "https://a.example,https://b.example" {
		t.Errorf("explicit list must drop * and trim: %q", got)
	}
	if got := CORSAllowOrigins("production", "*"); got != "" {
		t.Errorf("a lone * must not enable CORS: %q", got)
	}
}
