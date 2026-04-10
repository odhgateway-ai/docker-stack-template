# CHANGE LOGS (Developer-facing)

---

## [2.0.0] — 2026-04-09

### Breaking Changes
- `docker-compose.yml` split into 4 module files — must use `dc.sh` (or `-f compose.core.yml -f compose.ops.yml -f compose.access.yml -f compose.apps.yml`) instead of plain `docker compose`
- Env var renames: `DOMAIN` replaces individual `SUBDOMAIN_*` vars; `STACK_NAME` replaces `COMPOSE_PROJECT_NAME`; `PROJECT_NAME` is new (required)
- `TAILSCALE_CLIENT_SECRET` → `TS_AUTHKEY` (standardised Tailscale env naming)
- `APP_PORT` now drives the app container port directly; `SUBDOMAIN_APP`, `SUBDOMAIN_DOZZLE`, etc. removed

### Added
- **`dc.sh`** — main orchestrator: loads `.env`, reads `ENABLE_*` flags, builds `--profile` args, calls all 4 compose files in one command
- **`compose.core.yml`** — caddy + cloudflared, network + volumes definition; always-on
- **`compose.ops.yml`** — dozzle, filebrowser, webssh, webssh-windows; all profile-gated
- **`compose.access.yml`** — tailscale-linux, tailscale-windows; profile-gated
- **`compose.apps.yml`** — parameterised app service (`APP_IMAGE` + `APP_PORT`)
- **`up.sh` / `down.sh` / `logs.sh`** — one-liner shortcuts wrapping `dc.sh`
- **`scripts/validate-env.js`** — checks required vars, format validation (bcrypt, domain, port), subdomain preview
- **`scripts/validate-ts.js`** — Tailscale auth key format check + optional expiry lookup via TS API
- **`scripts/validate-compose.js`** — runs `docker compose config` across all 4 files to catch YAML errors
- **`npm run dockerapp-validate:all`** — combined validation pipeline (env → compose → TS)
- **`docs/DEPLOY.md`** — full deployment guide with mermaid flow diagrams, use cases, security checklist
- Subdomain auto-convention: all routes derived from `${PROJECT_NAME}.${DOMAIN}` pattern
- `DC_VERBOSE=1` debug flag for `dc.sh`
- `HEALTH_PATH` env to customise healthcheck endpoint per image

### Changed
- Image versions pinned (caddy `2.9.1-alpine`, cloudflared `2025.1.0`, dozzle `v8.x`, filebrowser `v2.30.0`, tailscale `stable`)
- Caddy `CADDY_INGRESS_NETWORKS` now uses `${STACK_NAME}_net` (was `app_net`)
- Network name: `${STACK_NAME:-mystack}_net` (dynamic, avoids conflicts between stacks)
- GitHub Actions and Azure Pipelines updated to call `dc.sh up` instead of bare `docker compose up`
- `detect-os.sh` no longer writes `COMPOSE_PROFILES` (profiles now fully managed by `dc.sh`)
- `.env.example` fully rewritten to match new schema

### Removed
- Monolithic `docker-compose.yml` (replaced by 4 module files)
- `SUBDOMAIN_APP`, `SUBDOMAIN_DOZZLE`, `SUBDOMAIN_FILEBROWSER`, `SUBDOMAIN_WEBSSH` env vars
- `TAILSCALE_CLIENT_SECRET` (use `TS_AUTHKEY`)
- Hardcoded `build: ./services/app` in compose (now `APP_IMAGE` param)
- `scripts/generate-cf-config.js` and the generated-config workflow (maintain `cloudflared/config.yml` manually)

---
