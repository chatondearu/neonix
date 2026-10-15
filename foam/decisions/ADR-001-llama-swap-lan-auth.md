# ADR-001 — llama-swap LAN access with authentication

- **Status**: accepted
- **Date**: 2026-10-15
- **Tags**: #security #ai
- **GitHub**: [#3](https://github.com/chatondearu/neonix/issues/3) (child of [#2](https://github.com/chatondearu/neonix/issues/2))

## Context

llama-swap listened on `0.0.0.0:9292` with the firewall open and no auth. Unauthenticated LAN (and Docker-bridge) clients could list models and load GPU workloads. KISS audit finding #1. User GO chose option B over localhost-only.

## Decision

Keep llama-swap reachable on the LAN (port 9292 may stay open) and **require authentication** for API access. Reject unauthenticated callers. Provision the secret via env/agenix; never commit it.

## Alternatives rejected

- **Localhost-only bind** — rejected by product GO (option A); breaks intentional LAN clients.
- **Leave open without auth** — rejected; verified abuse path on the live host.

## Consequences

- Clients must send the configured credential.
- Smoke/regression (#8) must assert unauthenticated rejection.
- Workers must not invent a different exposure model without a superseding ADR.
