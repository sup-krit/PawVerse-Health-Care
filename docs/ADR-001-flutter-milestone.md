# ADR 001: Flutter first runnable milestone

Status: accepted for this implementation milestone, 2026-09-07.

The user selected two separate mobile apps and authorized implementation on develop branches. Existing HTML files remain interaction/design references. They are not the mobile product.

Use Flutter/Dart with SDK ChangeNotifier and ListenableBuilder for presentation state, typed immutable domain models, and constructor-injected repository interfaces. Use an in-memory demo repository now, with no claim of production identity, persistence, notifications, shared backend, or medical authorization. This avoids adding a state-management dependency before there is evidence it helps. Future HTTP repositories can implement the same interfaces; a production integration still needs backend contracts and policies.

Use native Flutter Material/Cupertino widgets and shared customizable widgets/theme per app. Tailwind is a web convention and does not apply to native Flutter. Use Navigator dialogs/bottom sheets/overlay-based menus rather than clipped inline floating content. Respect safe areas, text scaling, accessible labels and 48px touch targets. Derive colors and information hierarchy from the existing prototype rather than copying its desktop layout.

Acceptance: usable pet-scoped domain flows with explicit demo identity/status, deterministic seed data, loading/error/retry states, meaningful repository/controller/widget tests, static analysis and available build checks. No real patient data or offline health persistence. Do not implement unresolved PRD clinical/breeding policies. Keep backend/cloud/store deployment out of this milestone.

Two apps keep separate repositories and release boundaries. Shared pet IDs may use matching demo identifiers for future contracts, but there is no actual cross-app synchronization yet.
