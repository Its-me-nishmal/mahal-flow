package whatsapp

import (
	"errors"
	"fmt"
	"strings"
)

// defaultCountryCode is applied to bare 10-digit numbers. MahalFlow is
// India-first; change this when onboarding a mahal outside India.
const defaultCountryCode = "91"

var (
	// ErrEmptyPhone is returned for a blank number.
	ErrEmptyPhone = errors.New("whatsapp: empty phone number")
	// ErrInvalidPhone is returned when a number cannot be coerced to E.164.
	ErrInvalidPhone = errors.New("whatsapp: invalid phone number")
)

// NormalizePhone converts the loosely-formatted phone numbers found in member
// records into the digits-only E.164 form the Graph API requires (no leading
// "+", country code included).
//
// Handles the shapes that actually appear in imported mahal registers:
//
//	"9876543210"        -> "919876543210"   (bare 10-digit mobile)
//	"09876543210"       -> "919876543210"   (STD trunk prefix)
//	"+91 98765 43210"   -> "919876543210"   (spaces, plus)
//	"+91-98765-43210"   -> "919876543210"   (hyphens)
//	"0091 9876543210"   -> "919876543210"   (ISD prefix)
//
// Numbers already carrying a non-Indian country code are passed through with
// separators stripped, so this does not corrupt international members.
func NormalizePhone(raw string) (string, error) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return "", ErrEmptyPhone
	}

	hadPlus := strings.HasPrefix(trimmed, "+")

	var digits strings.Builder
	for _, r := range trimmed {
		if r >= '0' && r <= '9' {
			digits.WriteRune(r)
		}
	}
	n := digits.String()

	if n == "" {
		return "", fmt.Errorf("%w: %q has no digits", ErrInvalidPhone, raw)
	}

	// "00" ISD prefix is equivalent to a leading "+".
	if !hadPlus && strings.HasPrefix(n, "00") {
		n = strings.TrimPrefix(n, "00")
		hadPlus = true
	}

	if !hadPlus {
		switch {
		case len(n) == 10:
			// Bare national mobile number.
			n = defaultCountryCode + n
		case len(n) == 11 && strings.HasPrefix(n, "0"):
			// National number with the trunk prefix.
			n = defaultCountryCode + n[1:]
		case len(n) == 12 && strings.HasPrefix(n, defaultCountryCode):
			// Already country-coded, just unformatted.
		case len(n) == 13 && strings.HasPrefix(n, "0"+defaultCountryCode):
			n = strings.TrimPrefix(n, "0")
		}
	}

	// E.164 allows at most 15 digits; a country code plus subscriber number is
	// never shorter than 8 in practice. Anything outside that is bad data.
	if len(n) < 8 || len(n) > 15 {
		return "", fmt.Errorf("%w: %q normalized to %q (%d digits)", ErrInvalidPhone, raw, n, len(n))
	}

	// A 12-digit Indian number must start 91 followed by a 6-9 leading mobile
	// digit. Catches transcription slips like a dropped or doubled country code.
	if len(n) == 12 && strings.HasPrefix(n, defaultCountryCode) {
		if c := n[2]; c < '6' || c > '9' {
			return "", fmt.Errorf("%w: %q is not a valid Indian mobile number", ErrInvalidPhone, raw)
		}
	}

	return n, nil
}

// MaskPhone renders a number safe for logs, keeping only the country code and
// last two digits. Member phone numbers are personal data and must not be
// written to logs in full.
func MaskPhone(phone string) string {
	if len(phone) < 4 {
		return "***"
	}
	return phone[:2] + strings.Repeat("*", len(phone)-4) + phone[len(phone)-2:]
}
