# MahalFlow — AI Coding Agent Guidelines

See [AGENTS.md](file:///d:/Random/MahalFlow/AGENTS.md) for the master context, unbreakable financial invariants, and tech stack guidelines.

## Quick Reference for Gemini / Antigravity Agent
1. Read `.agents/memory/learning_log.md` before starting tasks.
2. Invariants:
   - No partial monthly dues.
   - Contiguous month sequence required.
   - Separate monthly dues from voluntary contributions.
   - Multi-tenant isolation: always include `mahal_id`.
   - Never update/delete receipts; use append-only ledger + SHA-256 receipt hash chaining.
3. Tech Stack: Go (Fiber) + MongoDB 7 + Flutter (Riverpod) + Next.js.
4. Colors: `#146C5B` Emerald, Inter typography, 8px grid.
5. **Stitch UI Fidelity**: All Flutter & Next.js screens MUST 100% replicate the corresponding `screen.png` and `code.html` in `stitch_mahal_financial_integrity_system/<screen_name>/`.
6. On completing tasks or learning new project patterns, update `.agents/memory/learning_log.md`.
