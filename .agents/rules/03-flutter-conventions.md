# Coding Agent Rule: Flutter Mobile Conventions

1. **State Management**:
   - Use `flutter_riverpod` (v2.x) with `NotifierProvider` / `AsyncNotifierProvider`.
   - Keep business logic inside StateNotifiers; widgets should strictly render UI.

2. **Design Tokens**:
   - Use `AppColors.primary` (`#146C5B`), `AppColors.background` (`#F7F9F8`), `AppColors.surface` (`#FFFFFF`).
   - Use `GoogleFonts.inter` for all typography.
   - Spacing: 8px grid system (`8`, `16`, `24`, `32`).
   - Border radius: 10px on buttons and text fields, 12px on cards.

3. **Financial Display**:
   - Currency format: `₹1,500` (Indian numbering system with `intl` `NumberFormat.currency(symbol: '₹', locale: 'en_IN')`).
   - Display pending months clearly in checklist cards.
   - Distinct screens for **Monthly Dues** vs **Voluntary Contribution**.

4. **Error & Offline Resilience**:
   - Always wrap network calls with error states (`Try Again` button).
   - Disable payment buttons immediately upon tap to avoid accidental double-clicks.
