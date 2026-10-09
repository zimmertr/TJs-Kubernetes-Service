# 0020. The README stays in TJ's own voice and remains the main guide, and `docs/` holds the reference pages

- Status: Accepted. Supersedes [0018](0018-docs-for-users.md)
- Date: 2026-10-09
- Decider: TJ (review of PR #94)
- Issues and PRs: #94

## Context

[0018](0018-docs-for-users.md) followed Bluebird and made the README an index, moving its prose into `docs/`. PR #94 rewrote TKS's README that way. TJ rejected it: the README is written in his voice and structure, and AI rewrites of READMEs make projects look generated and broken.

## Decision

- The README keeps TJ's structure, voice and formatting: the linked table of contents, `<hr>` between sections, padded tables, and first-person instructions. It stays the main user guide (requirements, instructions, post-install, scaling, troubleshooting).
- The README is kept current: every change to the codebase updates it in the same PR (instructions, requirements, examples, links to `docs/`). Each edit is written in TJ's voice and style to match the surrounding text, never as a rewrite, a new structure or generic AI prose.
- `docs/` holds reference pages the README links to: `CONFIGURATION.md` (generated), `ARCHITECTURE.md`, `SECURITY_GUIDE.md`, `CICD.md` and `decisions/`. They don't restate the README's instructions.
- Docs describe TKS for its users. Maintainer runbooks and one-off host commands stay out. Plans and PRDs live in GitHub issues, not files. Decision records are exempt, and keep dated facts about TJ's environment.
- Docs don't announce work in progress. The README and the docs describe the code on `main`.

## Evidence

None measured. TJ's review comment on PR #94.

## Alternatives rejected

- README as an index (0018): it replaced TJ's writing with generated structure.

## Consequences

- Usage guidance lives in the README, so v2's instruction changes (T22) edit the README in place, in TJ's style.
