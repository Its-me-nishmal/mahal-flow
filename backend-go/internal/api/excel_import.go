package api

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/csv"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/mail"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/repository"
	"github.com/xuri/excelize/v2"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// Member-import limits.
const (
	ImportMaxFileBytes = 5 << 20 // 5 MB
	ImportMaxRows      = 2000
	ImportBatchTTL     = 24 * time.Hour
	// importCommitStale is how long a COMMITTING claim is honoured before a
	// retry may take it over (a crashed commit). Inserts are idempotent, so a
	// takeover never duplicates members.
	importCommitStale = 2 * time.Minute
)

// Row statuses.
const (
	ImportRowValid     = "VALID"
	ImportRowDuplicate = "DUPLICATE"
	ImportRowInvalid   = "INVALID"
)

var errUnsupportedSheet = errors.New("unsupported file: upload .xlsx or .csv (save legacy .xls files as .xlsx first)")

// importColumns maps normalised header names (and aliases) to fields.
var importColumns = map[string]string{
	"name": "name", "member_name": "name", "full_name": "name",
	"phone": "phone", "mobile": "phone", "phone_number": "phone", "mobile_number": "phone",
	"house_name": "house_name", "house": "house_name", "family_name": "house_name",
	"monthly_dues": "monthly_dues", "dues": "monthly_dues", "monthly_dues_custom_amount": "monthly_dues", "dues_amount": "monthly_dues",
	"family_head": "family_head", "is_family_head": "family_head", "head": "family_head",
	"family_members_count": "family_members_count", "family_members": "family_members_count", "family_size": "family_members_count",
	"email": "email", "email_address": "email",
	"member_code": "member_code", "code": "member_code",
}

func normaliseHeader(h string) string {
	h = strings.TrimPrefix(h, "\ufeff") // UTF-8 BOM from Excel CSV exports
	h = strings.ToLower(strings.TrimSpace(h))
	h = strings.NewReplacer(" ", "_", "-", "_", ".", "").Replace(h)
	return strings.Trim(h, "_*")
}

// readSheet returns the first worksheet (xlsx) or the CSV records.
func readSheet(filename string, data []byte) ([][]string, error) {
	isZip := len(data) >= 4 && bytes.Equal(data[:4], []byte("PK\x03\x04"))
	isOLE := len(data) >= 8 && bytes.Equal(data[:8], []byte{0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1})
	ext := strings.ToLower(filepath.Ext(filename))
	switch {
	case isOLE:
		return nil, errUnsupportedSheet // legacy binary .xls
	case isZip:
		f, err := excelize.OpenReader(bytes.NewReader(data))
		if err != nil {
			return nil, fmt.Errorf("could not read the spreadsheet: %w", err)
		}
		defer f.Close()
		sheets := f.GetSheetList()
		if len(sheets) == 0 {
			return nil, errors.New("the spreadsheet has no sheets")
		}
		return f.GetRows(sheets[0])
	case ext == ".xlsx" || ext == ".xls":
		return nil, errUnsupportedSheet
	default:
		if !utf8.Valid(data) {
			return nil, errUnsupportedSheet
		}
		r := csv.NewReader(bytes.NewReader(data))
		r.FieldsPerRecord = -1
		r.TrimLeadingSpace = true
		var out [][]string
		for {
			rec, err := r.Read()
			if err == io.EOF {
				break
			}
			if err != nil {
				return nil, fmt.Errorf("could not read the CSV: %w", err)
			}
			out = append(out, rec)
		}
		return out, nil
	}
}

// parseIndianMobile accepts a 10-digit Indian mobile with an optional +91 /
// 91 / 0 prefix and returns it as +91XXXXXXXXXX.
func parseIndianMobile(raw string) (string, bool) {
	var d strings.Builder
	for _, r := range raw {
		switch {
		case r >= '0' && r <= '9':
			d.WriteRune(r)
		case r == ' ' || r == '-' || r == '+' || r == '(' || r == ')' || r == '.':
		default:
			return "", false
		}
	}
	s := d.String()
	// Excel sometimes stores a phone as a number ("9.84711E+09" is rejected
	// above; "9847112233.0" loses its dot to the filter and gains a 0).
	if strings.HasSuffix(raw, ".0") && len(s) == 11 {
		s = s[:10]
	}
	switch {
	case len(s) == 12 && strings.HasPrefix(s, "91"):
		s = s[2:]
	case len(s) == 11 && strings.HasPrefix(s, "0"):
		s = s[1:]
	}
	if len(s) != 10 || s[0] < '6' {
		return "", false
	}
	return "+91" + s, true
}

func parseYesNo(raw string) (bool, bool) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "", "no", "n", "false", "0":
		return false, true
	case "yes", "y", "true", "1":
		return true, true
	}
	return false, false
}

// parseImportRows validates every data row. existing holds the tenant's
// current phones; a phone already there, or repeated earlier in the file, is
// a DUPLICATE.
func parseImportRows(records [][]string, existing map[string]bool) ([]domain.ImportRow, error) {
	// Header = first non-empty row.
	start := -1
	for i, rec := range records {
		if strings.TrimSpace(strings.Join(rec, "")) != "" {
			start = i
			break
		}
	}
	if start < 0 {
		return nil, errors.New("the file is empty")
	}
	cols := map[string]int{}
	for i, h := range records[start] {
		if field, ok := importColumns[normaliseHeader(h)]; ok {
			if _, dup := cols[field]; !dup {
				cols[field] = i
			}
		}
	}
	if _, ok := cols["name"]; !ok {
		return nil, errors.New("missing required column: name")
	}
	if _, ok := cols["phone"]; !ok {
		return nil, errors.New("missing required column: phone")
	}

	cell := func(rec []string, field string) string {
		i, ok := cols[field]
		if !ok || i >= len(rec) {
			return ""
		}
		return strings.TrimSpace(rec[i])
	}

	seen := map[string]int{} // phone -> spreadsheet row that first used it
	var rows []domain.ImportRow
	for i := start + 1; i < len(records); i++ {
		rec := records[i]
		if strings.TrimSpace(strings.Join(rec, "")) == "" {
			continue // blank line
		}
		if len(rows) >= ImportMaxRows {
			return nil, fmt.Errorf("too many rows: at most %d members per file", ImportMaxRows)
		}
		row := domain.ImportRow{Row: i + 1, Errors: []string{}}
		row.Name = cell(rec, "name")
		row.HouseName = cell(rec, "house_name")
		row.MemberCode = cell(rec, "member_code")
		rawPhone := cell(rec, "phone")

		if row.Name == "" {
			row.Errors = append(row.Errors, "name is required")
		} else if utf8.RuneCountInString(row.Name) > 100 {
			row.Errors = append(row.Errors, "name is longer than 100 characters")
		}
		if utf8.RuneCountInString(row.HouseName) > 100 {
			row.Errors = append(row.Errors, "house name is longer than 100 characters")
		}
		if rawPhone == "" {
			row.Errors = append(row.Errors, "phone is required")
		} else if p, ok := parseIndianMobile(rawPhone); ok {
			row.Phone = p
		} else {
			row.Phone = rawPhone
			row.Errors = append(row.Errors, "phone must be a 10-digit Indian mobile number")
		}
		if v := cell(rec, "monthly_dues"); v != "" {
			amt, err := strconv.ParseFloat(strings.ReplaceAll(strings.TrimPrefix(v, "₹"), ",", ""), 64)
			if err != nil || amt <= 0 || amt > 100000 {
				row.Errors = append(row.Errors, "monthly dues must be a positive amount")
			} else {
				row.MonthlyDues = domain.ToPaise(amt).ToRupees()
			}
		}
		if v := cell(rec, "family_head"); v != "" {
			b, ok := parseYesNo(v)
			if !ok {
				row.Errors = append(row.Errors, "family head must be yes or no")
			}
			row.FamilyHead = b
		}
		if v := cell(rec, "family_members_count"); v != "" {
			n, err := strconv.Atoi(strings.TrimSuffix(v, ".0"))
			if err != nil || n < 0 || n > 100 {
				row.Errors = append(row.Errors, "family members count must be a whole number")
			} else {
				row.FamilyMembersCount = n
			}
		}
		if v := cell(rec, "email"); v != "" {
			if a, err := mail.ParseAddress(v); err != nil || a.Address != v {
				row.Errors = append(row.Errors, "email is not valid")
			}
			row.Email = v
		}

		switch {
		case len(row.Errors) > 0:
			row.Status = ImportRowInvalid
		case existing[row.Phone]:
			row.Status = ImportRowDuplicate
			row.Errors = append(row.Errors, "phone already belongs to a member of this Mahal")
		case seen[row.Phone] > 0:
			row.Status = ImportRowDuplicate
			row.Errors = append(row.Errors, fmt.Sprintf("phone repeats row %d", seen[row.Phone]))
		default:
			row.Status = ImportRowValid
		}
		if row.Phone != "" && seen[row.Phone] == 0 && row.Status != ImportRowInvalid {
			seen[row.Phone] = row.Row
		}
		rows = append(rows, row)
	}
	if len(rows) == 0 {
		return nil, errors.New("the file has a header but no member rows")
	}
	return rows, nil
}

func countImportRows(rows []domain.ImportRow) (valid, duplicate, invalid int) {
	for _, r := range rows {
		switch r.Status {
		case ImportRowValid:
			valid++
		case ImportRowDuplicate:
			duplicate++
		default:
			invalid++
		}
	}
	return
}

// importRowJSON is the wire shape of a preview row (adds aliases the app reads).
func importRowJSON(r domain.ImportRow) fiber.Map {
	return fiber.Map{
		"row": r.Row, "name": r.Name, "phone": r.Phone,
		"house_name": r.HouseName, "house": r.HouseName,
		"monthly_dues": r.MonthlyDues, "family_head": r.FamilyHead,
		"family_members_count": r.FamilyMembersCount, "email": r.Email, "code": r.MemberCode,
		"status": r.Status, "errors": r.Errors, "error": strings.Join(r.Errors, "; "),
	}
}

func importBatchJSON(b *domain.ImportBatch) fiber.Map {
	rows := make([]fiber.Map, 0, len(b.Rows))
	for _, r := range b.Rows {
		rows = append(rows, importRowJSON(r))
	}
	return fiber.Map{
		"batch_id": b.ID, "upload_id": b.ID, "filename": b.Filename,
		"total_rows": b.Total, "valid_rows": b.Valid, "duplicate_rows": b.Duplicate, "invalid_rows": b.Invalid,
		"preview_rows": rows, "expires_at": b.ExpiresAt, "status": b.Status,
	}
}

// SetImportBatches wires storage for Excel member imports (nil = imports offline).
func (h *Handler) SetImportBatches(r repository.ImportBatchRepository) { h.importRepo = r }

// UploadExcelPreview parses an uploaded .xlsx / .csv member sheet, validates
// every row against the tenant's members, stores the parsed batch for 24h and
// returns the preview. Nothing is written to members until commit.
func (h *Handler) UploadExcelPreview(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	if h.importRepo == nil || h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Import service offline"})
	}
	fh, err := c.FormFile("file")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Upload the member sheet in the 'file' field"})
	}
	if fh.Size > ImportMaxFileBytes {
		return c.Status(fiber.StatusRequestEntityTooLarge).JSON(fiber.Map{"error": fmt.Sprintf("File is larger than %d MB", ImportMaxFileBytes>>20)})
	}
	f, err := fh.Open()
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Could not read the upload"})
	}
	defer f.Close()
	data, err := io.ReadAll(io.LimitReader(f, ImportMaxFileBytes+1))
	if err != nil || len(data) > ImportMaxFileBytes {
		return c.Status(fiber.StatusRequestEntityTooLarge).JSON(fiber.Map{"error": "File is too large"})
	}

	batch, aerr := h.buildImportBatch(c.Context(), tenantID, sessionSubject(c), filepath.Base(fh.Filename), data)
	if aerr != nil {
		return aerr.send(c)
	}
	if err := h.importRepo.Create(c.Context(), batch); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not store the import batch"})
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID: tenantID, Action: "MEMBER_IMPORT_PREVIEWED", Actor: sessionRole(c), EntityID: batch.ID,
			Details: fmt.Sprintf("%s: %d rows (%d valid, %d duplicate, %d invalid)", batch.Filename, batch.Total, batch.Valid, batch.Duplicate, batch.Invalid),
		})
	}
	return c.JSON(importBatchJSON(batch))
}

func (h *Handler) buildImportBatch(ctx context.Context, tenantID, actor, filename string, data []byte) (*domain.ImportBatch, *apiError) {
	records, err := readSheet(filename, data)
	if err != nil {
		return nil, errBadRequest(err.Error())
	}
	existing, err := h.memberRepo.ListPhones(ctx, tenantID)
	if err != nil {
		return nil, &apiError{status: fiber.StatusInternalServerError, msg: "Could not check existing members"}
	}
	rows, err := parseImportRows(records, existing)
	if err != nil {
		return nil, errBadRequest(err.Error())
	}
	valid, dup, invalid := countImportRows(rows)
	now := time.Now().UTC()
	return &domain.ImportBatch{
		ID: "IMP_" + strings.ReplaceAll(uuid.New().String(), "-", "")[:16],
		// Clone: Fiber's header/form strings alias a request buffer it reuses.
		MahalID:   strings.Clone(tenantID),
		Filename:  strings.Clone(filename),
		Status:    repository.ImportStatusPreview,
		Rows:      rows,
		Total:     len(rows),
		Valid:     valid,
		Duplicate: dup,
		Invalid:   invalid,
		CreatedBy: strings.Clone(actor),
		CreatedAt: now,
		ExpiresAt: now.Add(ImportBatchTTL),
	}, nil
}

type CommitImportRequest struct {
	BatchID  string `json:"batch_id"`
	UploadID string `json:"upload_id"`
}

// importMemberID is deterministic per (batch, row), so re-running a commit
// that died half-way inserts the same ids and cannot create duplicates.
func importMemberID(batchID string, row int) string {
	sum := sha256.Sum256([]byte(batchID + ":" + strconv.Itoa(row)))
	return "MEM_I" + hex.EncodeToString(sum[:])[:12]
}

// CommitExcelImport inserts the VALID rows of a previewed batch as ACTIVE
// members. Idempotent: a batch commits once; later calls report the original
// counts with status ALREADY_COMMITTED.
func (h *Handler) CommitExcelImport(c *fiber.Ctx) error {
	tenantID, _ := c.Locals("tenant_id").(string)
	tenantID = strings.Clone(tenantID) // stored on every imported member
	if h.importRepo == nil || h.memberRepo == nil {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"error": "Import service offline"})
	}
	var req CommitImportRequest
	_ = c.BodyParser(&req)
	id := strings.TrimSpace(req.BatchID)
	if id == "" {
		id = strings.TrimSpace(req.UploadID)
	}
	if id == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "batch_id is required"})
	}

	batch, err := h.importRepo.ClaimForCommit(c.Context(), tenantID, id, importCommitStale)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not load the import batch"})
	}
	if batch == nil {
		existing, _ := h.importRepo.Get(c.Context(), tenantID, id)
		switch {
		case existing == nil:
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Import batch not found or expired. Upload the file again."})
		case existing.Status == repository.ImportStatusCommitted:
			return c.JSON(commitResultJSON("ALREADY_COMMITTED", existing.ID, existing.Imported, existing.Skipped))
		default:
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "This import is already being committed"})
		}
	}

	imported, skipped, rows := h.commitImportRows(c.Context(), tenantID, batch)
	if err := h.importRepo.MarkCommitted(c.Context(), tenantID, batch.ID, imported, skipped, rows); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Members were imported but the batch could not be closed; retry to finish"})
	}
	if h.auditRepo != nil {
		_ = h.auditRepo.Create(c.Context(), &domain.AuditLog{
			MahalID: tenantID, Action: "MEMBER_IMPORT_COMMITTED", Actor: sessionRole(c), EntityID: batch.ID,
			Details: fmt.Sprintf("%s: imported %d members, skipped %d rows", batch.Filename, imported, skipped),
		})
	}
	return c.JSON(commitResultJSON("COMPLETED", batch.ID, imported, skipped))
}

func commitResultJSON(status, batchID string, imported, skipped int) fiber.Map {
	return fiber.Map{
		"status": status, "batch_id": batchID, "ingestion_batch": batchID,
		"imported": imported, "skipped": skipped,
		"imported_count": imported, "skipped_count": skipped,
	}
}

func (h *Handler) commitImportRows(ctx context.Context, tenantID string, batch *domain.ImportBatch) (imported, skipped int, rows []domain.ImportRow) {
	defaultDues := 0.0
	if h.mahalRepo != nil {
		if m, err := h.mahalRepo.GetByID(ctx, tenantID); err == nil && m != nil {
			defaultDues = m.Settings.DefaultMonthlyDues
		}
	}
	// Re-check phones: members may have been added since the preview.
	existing, _ := h.memberRepo.ListPhones(ctx, tenantID)
	if existing == nil {
		existing = map[string]bool{}
	}
	now := time.Now().UTC()
	rows = batch.Rows
	for i := range rows {
		r := &rows[i]
		if r.Status != ImportRowValid {
			skipped++
			continue
		}
		memberID := importMemberID(batch.ID, r.Row)
		if existing[r.Phone] {
			// Our own insert from a crashed earlier attempt counts as imported.
			if m, _ := h.memberRepo.GetByID(ctx, tenantID, memberID); m != nil {
				imported++
				continue
			}
			r.Status = ImportRowDuplicate
			r.Errors = append(r.Errors, "phone was registered after the preview")
			skipped++
			continue
		}
		dues := r.MonthlyDues
		if dues <= 0 {
			dues = defaultDues
		}
		code := r.MemberCode
		if code == "" {
			code = "M-" + strings.ToUpper(memberID[5:11])
		}
		m := &domain.Member{
			ID: memberID, MahalID: tenantID, MemberCode: code,
			Name: r.Name, Phone: r.Phone, Email: r.Email, HouseName: r.HouseName,
			FamilyHead: r.FamilyHead, FamilyMembersCount: r.FamilyMembersCount,
			MonthlyDuesCustomAmount: r.MonthlyDues,
			Status:                  "ACTIVE",
			LastPaidMonth:           now.AddDate(0, -1, 0).Format("2006-01"),
			OutstandingBalance:      dues,
			ImportBatchID:           batch.ID,
			Version:                 1,
			CreatedAt:               now,
			UpdatedAt:               now,
		}
		if err := h.memberRepo.Create(ctx, m); err != nil {
			if mongo.IsDuplicateKeyError(err) {
				imported++ // inserted by an earlier, interrupted attempt
				existing[r.Phone] = true
				continue
			}
			r.Status = ImportRowInvalid
			r.Errors = append(r.Errors, "could not be saved")
			skipped++
			continue
		}
		existing[r.Phone] = true
		imported++
	}
	return imported, skipped, rows
}
