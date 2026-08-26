# 05 — Git Versioning, Branching & Release Strategy

## 1. Semantic Versioning (SemVer 2.0.0)

MahalFlow adheres strictly to `MAJOR.MINOR.PATCH` versioning:
- **MAJOR (v1.0.0)**: Incompatible database schema changes, breaking API contract modifications.
- **MINOR (v1.1.0)**: New agent capabilities, new payment gateway integrations, backwards-compatible API features.
- **PATCH (v1.0.1)**: Bug fixes, dunning optimization, security patches.

---

## 2. Branching Model (Trunk-Based with Release Branches)

```
main (Production: v1.0.0, v1.0.1) ──────────●──────────────●──────────>
                                            ^              ^
                                       (Release PR)   (Hotfix PR)
                                            │              │
develop (Staging Integration) ───────●──────┴───────●──────┴──────────>
                                     ^              ^
                                (Feature PR)   (Agent PR)
                                     │              │
feature/member-autopay ──────────────┘              │
feature/agent-rlaif-memory ─────────────────────────┘
```

- `main`: Always deployable to production. Only receives tagged release PRs and critical hotfixes.
- `develop`: Integration staging branch for ongoing sprint deliverables.
- `feature/<ticket-or-name>`: Scoped feature development.
- `fix/<ticket-or-name>`: Bug fixes targeting develop.
- `hotfix/<version>`: Immediate production security/payment fixes branched directly from `main`.

---

## 3. Conventional Commit Guidelines

Every commit must follow the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <short summary>

[optional body explaining motivation]

[optional footer(s) like BREAKING CHANGE or Closes #123]
```

### Allowed Types
| Type | Purpose | Example |
|---|---|---|
| `feat` | New user/system feature | `feat(dues): add multi-month bulk payment support` |
| `fix` | Bug fix in code or calculations | `fix(recon): resolve race condition in pending webhook check` |
| `agent` | Multi-agent logic or prompt updates | `agent(dunning): improve Malayalam WhatsApp reminder context` |
| `perf` | Performance improvement | `perf(mongo): add compound index for member last_paid_month` |
| `docs` | Documentation only | `docs(api): add Razorpay webhook signature verification spec` |
| `refactor`| Code refactoring without behavior changes | `refactor(auth): simplify JWT claims extraction middleware` |
| `test` | Adding or updating tests | `test(receipts): add SHA-256 chain integrity unit tests` |
| `chore` | Build tasks, package updates | `chore(deps): update mongo-driver to v2.0.0` |

---

## 4. Release Tagging & Changelog Workflow

1. Create a release branch: `git checkout -b release/v1.1.0`
2. Update version constants in `backend-go/cmd/api/main.go`, `web-admin/package.json`, and `mobile-flutter/pubspec.yaml`.
3. Generate `CHANGELOG.md` automatically via git log tooling.
4. Merge release branch into `main` and `develop`.
5. Tag the commit on `main`: `git tag -a v1.1.0 -m "Release v1.1.0: AutoPay and Multi-Language Dunning Agent"`
6. Push tags: `git push origin v1.1.0`
