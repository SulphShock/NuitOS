# Contributing

Keep it coherent: gruvbox-dark look, working defaults, no dead code. Big features go in userland, not the ISO.

## Rules

- `configs/` is canonical. Edits land via commit; CI drift guard fails on `configs/` vs `iso/airootfs/etc/skel/.config/` divergence.
- Never edit the skel copy directly — edit `configs/`, then mirror to skel (or run the wallpaper/sync section of `scripts/nuit-release.sh`).
- One logical change per commit, imperative subject line. No profanity, no venting — history ships.
- `--dry-run` paths stay read-only. Installer changes need a dry-run transcript in the PR.
- Wallpapers: WebP, max 1920w, each under 2MB. Originals go to the release-asset repo, never the tree.
- Test matrix: update `TESTING.md` with pasted command output, not claims.
