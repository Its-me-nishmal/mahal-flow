# Coding Agent Rule: 100% Stitch UI & HTML Prototype Fidelity

> **MANDATORY RULE FOR ALL FRONTEND WORK (Flutter & Next.js):**

## 1. Single Source of Truth for Visual Design
The directory `stitch_mahal_financial_integrity_system/` contains 35 prototype screens with:
- `screen.png`: The exact visual layout, card composition, hierarchy, colors, and typography.
- `code.html`: The reference Tailwind / CSS implementation, layout structure, and copy.

## 2. Strict Implementation Rules

1. **Before Building Any Screen**:
   - The coding agent MUST inspect the corresponding screen directory in `stitch_mahal_financial_integrity_system/<screen_name>/` (both `screen.png` and `code.html`).
2. **Match Visual Hierarchy Exactly**:
   - Spacing, padding, and alignment must match the Stitch HTML / screenshot.
   - Text sizes, weights, and color contrast must match the exact design tokens (`#146C5B`, `#F7F9F8`, `#17201D`, `#5E6864`, `#E3E8E6`).
   - Cards, borders (1px solid `#E3E8E6`), rounded corners (10px–12px), and status badges must match the reference mockups.
3. **No Deviation / No Generic Substitutes**:
   - Do NOT invent arbitrary layout structures, colors, or alternative navigation schemes.
   - Every Flutter widget or Next.js component must be a direct high-fidelity translation of the Stitch mockup.
4. **Screen Directory Mapping**:
   - Member Dashboard ➔ `stitch_mahal_financial_integrity_system/member_dashboard/`
   - Monthly Dues Payment ➔ `stitch_mahal_financial_integrity_system/monthly_payment_ui/`
   - Voluntary Contribution ➔ `stitch_mahal_financial_integrity_system/contribution_ui/`
   - Payment Success / Pending / Failed ➔ `stitch_mahal_financial_integrity_system/payment_success/`, `payment_pending/`, `payment_failed/`
   - Receipt & History ➔ `stitch_mahal_financial_integrity_system/receipt_details/`, `receipts_history/`
   - Admin Dashboard & Super Admin ➔ `stitch_mahal_financial_integrity_system/admin_dashboard/`, `super_admin_dashboard/`
   - Excel Bulk Import ➔ `stitch_mahal_financial_integrity_system/bulk_excel_import_step_1/`, `bulk_excel_import_preview/`
