# Maintainers

- SulphShock — release owner, final call on scope cuts.
- Launch: v1.0.0, 2026-10-03. All commits local until launch day; no push, no force-push on public history.

## Release checklist

1. `just diff` clean, `drift.yml` + `build.yml` green from clean checkout.
2. `TESTING.md` matrix fully pasted (no TODO cells left, or explicit out-of-scope).
3. `ls -lh out/*.iso` ≤2.5GB, `sha256sum out/*.iso > out/NuitOS-1.0.0-x86_64.iso.sha256`.
4. CHANGELOG v1.0.0 dated, README verify instructions correct.
5. Tag `v1.0.0`, attach ISO + `.sha256` to GitHub Release.
