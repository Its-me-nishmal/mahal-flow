package logger

import (
	"os"
	"time"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

var Log zerolog.Logger

func InitLogger(serviceName string, isDev bool) {
	zerolog.TimeFieldFormat = time.RFC3339Nano

	if isDev {
		Log = zerolog.New(zerolog.ConsoleWriter{Out: os.Stdout, TimeFormat: time.Kitchen}).
			With().
			Timestamp().
			Str("service", serviceName).
			Logger()
	} else {
		Log = zerolog.New(os.Stdout).
			With().
			Timestamp().
			Str("service", serviceName).
			Logger()
	}

	log.Logger = Log
}

// MaskPhone masks phone numbers for PII compliance (+91 98****1234)
func MaskPhone(phone string) string {
	if len(phone) < 8 {
		return "[MASKED]"
	}
	return phone[:5] + "****" + phone[len(phone)-3:]
}

// MaskSecret masks sensitive API keys/tokens
func MaskSecret(secret string) string {
	if len(secret) == 0 {
		return ""
	}
	return "••••••••" + secret[max(0, len(secret)-4):]
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
