# Maintainers

- SulphShock — release owner, final call on scope cuts.
- Launch: v1.0.0, 2026-10-03. All commits local until launch day; no push, no force-push on public history.

## Release checklist

1. `just diff` clean, `drift.yml` + `build.yml` green from clean checkout.
2. `TESTING.md` matrix fully pasted (no TODO cells left, or explicit out-of-scope).
3. `ls -lh out/*.iso` ≤3.5GB, `(cd out && for f in *.iso; do sha256sum "$f" | tee "$f.sha256"; done)`.
4. CHANGELOG v1.0.0 dated, README verify instructions correct.
5. Tag `v1.0.0`, attach ISO + `.sha256` to GitHub Release.
