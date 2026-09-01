# Project Notes

Running log of infrastructure decisions and current status — the "why" behind things that
aren't obvious from the code itself. Doesn't duplicate what's in `README.md` (setup/run
instructions) or `docs/BACKEND_SPEC.md` (data model/API contract).

## Infrastructure

- **Backend**: Node/Express/Postgres on a VPS, deployed under systemd
  (`tailswipe-backend.service`) with Nginx reverse-proxying to it and a real Let's Encrypt
  cert. Live at `https://api.tailswipe.app`. The backend port itself is firewalled off from
  the public internet — only reachable through the Nginx proxy on 80/443. Postgres is
  `localhost`-only, never exposed externally.
- **Domain**: `tailswipe.app`, registered/managed at Namecheap.
- **iOS build pipeline**: developed on Windows without a local Mac, so a macOS VM handles all
  building, testing, and device installs over SSH. Real (non-adhoc) codesigning doesn't work
  over a plain SSH session (no GUI Security Session access on macOS), so device builds run
  inside an actual Terminal.app window instead. `xcodegen` generates the `.xcodeproj` from
  `project.yml` — the generated project isn't committed (see `.gitignore`).

## Feature status (as of the initial commit)

**Shipped**: swipe deck with filters and super-interest, adopter/lister profiles with real
photo upload, match celebration, adoption requests, real-time chat over WebSocket, email
verification (SMTP-based, 6-digit codes), backend rate limiting, nightly Postgres backups,
real HTTPS.

**Pending**:
- **Push notifications** — fully implemented (device token registration, APNs sender,
  triggers on new messages/matches/requests) but dormant. Apple does not allow the Push
  Notifications capability on a free "Personal Team" Apple ID at all — this needs a paid
  Apple Developer Program membership before it can be turned on. See the commented-out
  `entitlements:` block in `ios/Tailswipe/project.yml` for exactly what to re-enable.
- **Email delivery** — the verification-code flow is fully wired (falls back to
  console-logging the code if SMTP isn't configured), currently pointed at a Mailbaby SMTP
  relay sending from a dedicated `relay.tailswipe.app` subdomain (kept separate from the
  root domain so its existing email-forwarding SPF record never needs touching). SPF for
  the relay subdomain: `v=spf1 include:spf-c.mailbaby.net ip4:<VPS_IP> ~all`.
- **Android app** — not started; planned as a future port of the iOS app once validated.
- **Petfinder sync / shelter bulk-upload tooling** — not started, see `docs/BACKEND_SPEC.md`.

## Why these choices

This is a free, non-profit personal project — no company or funding behind it. Infrastructure
was added incrementally as needs came up rather than provisioned upfront (e.g. the VPS
predates this project and was repurposed; the domain was bought partway through development).
That's why some choices favor "cheapest thing that works" (Gmail SMTP as an initial fallback,
a shared VPS instead of dedicated hosting) over what a funded product might pick.
