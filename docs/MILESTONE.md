# Flutter milestone 1

Scope: separate Android/iOS mobile demo, using Flutter SDK state and injected repositories. The web build is a verification harness. See ADR-001. No persistence: closing/restarting resets all changes. Only fictional records; no real authentication, authorization server, uploads, links, notifications, medical formulas or cross-app synchronization.

UX references: `pawverse-health-uiux.html` (pine #214f43, paper #fcfbf6, lime accents, health notebook hierarchy) and the Health PRD review's timeline, appointment and explicit-consent journeys. Translate these into four native tabs: Overview, Records, Care, Sharing. Keep the selected pet visible, native date/time pickers, full-page forms, safe areas, scalable text and Material overlay confirmations. Reuse native controls with a shared theme rather than porting HTML/CSS. App copy is English for this bounded demo; localization is future work.

Deliver: per-pet records with category/date/title validation; read-only verified seed detail; appointments create/complete/cancel with terminal-state protection; medication slot logging once; explicit recipient/record snapshot/expiry consent and immediate demo revoke/expiry check on preview. Seed IDs `pet-milo` and `pet-luna` align by identifier only with the separate Matching demo. Record selection is a DEMO snapshot policy, not approval of unresolved production sharing semantics.

Architecture: immutable typed models -> HealthRepository interface -> memory implementation; ChangeNotifier controller -> ListenableBuilder UI. Repository enforces pet scoping and state transitions. Loading/error/retry and mutations are testable without backend services. Tests must demonstrate denial for other pets, expired/revoked preview, duplicate medication logging and terminal appointment changes.

Deferred: complete PRD trackers, amendments (verified originals read-only), vet workflow, clinic tenancy, clinical policy, persistent/offline health storage, backend/cloud, actual consent/identity and app-store release. Android SDK and macOS/iOS environment are not available here; report those platform build limits honestly.
