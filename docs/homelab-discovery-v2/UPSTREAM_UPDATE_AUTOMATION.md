# Home Lab upstream-update automation binding

This file is the machine-facing implementation companion to `docs/UPSTREAM_UPDATE_PROTOCOL.md`.

## Baseline registry

`tooling/homelab-discovery-v2/upstream-baselines.json` is the authoritative machine-readable registry for update detection. It currently records:

- Core official upstream: `Moonfin-Client/Moonfin-Core` / `main`
- Core accepted upstream base: `f18c45b1fbf9b63871b4f93237179f9706154763`
- Core overlay: `PRYYSE/Moonfin-Core` / `homelab/discovery-v2`
- Smart-TV official upstream: `Moonfin-Client/Smart-TV` / `main`
- Smart-TV accepted upstream base: `384d7cab3642f846463a4308e92d213e51507edf`
- Smart-TV overlay: `PRYYSE/Smart-TV` / `homelab/webos-discovery-v2`
- preserved webOS rollback branch/candidate and protected Android/webOS identities

The accepted base entries are changed only after a replacement update has passed the protocol and is deliberately accepted. Do not advance them merely because upstream moved.

## Impact report workflow

`.github/workflows/homelab-upstream-impact.yml`:

1. fetches the current official Core `main` without merging it;
2. compares the accepted Core base -> official Core head;
3. compares the accepted Core base -> current Home Lab overlay;
4. generates a classified overlap/impact report;
5. fetches the Smart-TV overlay and official Smart-TV `main` separately;
6. generates the equivalent Smart-TV report;
7. publishes both reports as an isolated GitHub Actions artifact and concise job summary.

The generator fails closed if the configured accepted base is not an ancestor of either the official upstream ref or the Home Lab overlay ref. That prevents a force-push/rebased upstream or stale baseline from producing a misleading report.

The workflow never merges, rebases, creates an update branch, changes signing identity, deploys, promotes, or modifies live services.

### Scheduling constraint

GitHub evaluates `schedule` only from a repository's default branch. The Home Lab product overlay intentionally remains isolated on `homelab/discovery-v2`, so the workflow is validated there through `push` and `workflow_dispatch`. Its daily `21:30 UTC` cron is deliberately dormant unless the control workflow is later promoted to the default branch without moving product code there.

Do not contaminate the clean upstream-mirror/default branch merely to activate cron. Until a deliberate control-plane decision is made, run the workflow manually when checking for upstream drift; its implementation and reporting semantics remain the same.

## Isolated update branches

When an update is actioned:

- Core branch prefix: `update/moonfin-`
- Smart-TV branch prefix: `update/webos-`

Create each update branch from the chosen new official upstream base, then reapply only the narrow Home Lab overlay.

The existing release gates now recognise these update branch prefixes:

- Core: `.github/workflows/homelab-discovery-v2.yml`
- Smart-TV/webOS: `.github/workflows/homelab-webos-discovery-v2.yml`

For Core update branches, the narrow-scope gate resolves the merge-base against the current official `Moonfin-Client/Moonfin-Core/main`, so legitimate upstream changes are not misclassified as Home Lab scope expansion. Home Lab changes outside the approved overlay surface still fail the gate.

For Smart-TV update branches, package identity and `index.html` remain fixed; versions may advance but cannot regress below the currently accepted `2.7.0` baseline. The preserved rollback branch/candidate remains untouched.

## Full update gate

A real upstream update is GitHub-integrated only when:

- the generated impact reports have been reviewed, especially all overlapping paths;
- Core focused validation passes on the update branch;
- a Core `[full-build]` candidate passes the existing Web + mobile-beta + Android-TV release gate, including package, Leanback and CI-signing checks;
- the Smart-TV update branch passes its Discovery tests, legacy webOS build, identity check and isolated IPK artifact upload;
- source SHAs and artifact IDs/digests are recorded in `docs/AI_PROJECT_STATE.md` or the update checkpoint.

Production signing, in-place installation and physical/live acceptance remain separate later gates. CI candidates never imply production acceptance.
