<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0
Modified sections:
  - Technology Standards / State Management: Changed from "BLoC for feature-level state;
    Riverpod for cross-feature DI" → "Riverpod for both feature-level state and cross-feature
    DI. BLoC permitted as alternative but not required."
  - Technology Standards / AI Backend: Changed from "claude-sonnet-4-6 or later" → generic
    "Haiku tier for high-volume low-latency calls, Sonnet tier for complex reasoning"
Added sections: None
Removed sections: None
Templates reviewed:
  - .specify/templates/plan-template.md          ✅ aligned
  - .specify/templates/spec-template.md          ✅ aligned
  - .specify/templates/tasks-template.md         ✅ aligned
  - .specify/templates/agent-file-template.md    ✅ aligned
Dependent artifacts updated:
  - specs/002-ai-coach-accountability/plan.md    ✅ Complexity Tracking documents Riverpod-only deviation
  - specs/002-ai-coach-accountability/tasks.md   ✅ Test tasks added per Quality Gates requirement
Follow-up TODOs:
  - None. All findings resolved.
-->

# Habit Coach Constitution

## Core Principles

### I. Clean Architecture

Every feature MUST be structured in three distinct layers: **domain** (entities, use-cases,
repository interfaces), **data** (repository implementations, remote/local data sources), and
**presentation** (widgets, view-models/blocs). Cross-layer dependencies MUST point inward only
(presentation → domain ← data). No Flutter framework imports are permitted in the domain layer.
Features MUST be organised as self-contained modules under `lib/features/<feature_name>/` with
their own domain, data, and presentation sub-directories.

**Rationale**: Enforces testability at every layer, prevents coupling between UI and business
logic, and allows individual features to be replaced or tested in isolation without affecting the
rest of the app.

### II. Cross-Platform First

The app MUST produce functionally identical behaviour on iOS 16+ and Android 10+ (API 29+).
Platform-specific code MUST be isolated to named platform channels or `dart:io` guards and MUST
NOT bleed into shared business logic. UI MUST follow Material 3 design tokens as the baseline;
platform-specific adaptations (e.g., Cupertino pickers on iOS) are permitted only when they
deliver a measurably better UX and MUST be gated behind a `Platform.isIOS` check in the
presentation layer only.

**Rationale**: A single codebase serving both platforms is the primary cost-efficiency lever.
Allowing platform divergence in shared layers destroys that advantage and doubles maintenance
burden.

### III. Performance by Default

The app MUST maintain ≥60 fps scrolling and animations on the reference devices (iPhone 12 and
a mid-range Android equivalent). Cold start to first interactive frame MUST be ≤2 s on those
devices. Widget rebuilds MUST be minimised: state MUST be scoped to the smallest possible
subtree using BLoC or Riverpod providers. Images MUST be cached and loaded lazily; network
requests MUST be debounced or paginated where applicable. Any deviation requires a documented
justification in the Complexity Tracking table of the relevant plan.

**Rationale**: Habit-tracking is a daily-use app. Perceived sluggishness directly increases
churn and degrades review scores.

### IV. Subscription Monetisation

All premium features MUST be gated exclusively through a centralised `EntitlementService` in the
domain layer. No widget or use-case MUST query subscription status directly from a payment SDK.
Paywall screens MUST present a clear value proposition, display pricing transparently, and handle
restore-purchases and refund states gracefully. In-app purchase receipt validation MUST occur
server-side or via RevenueCat webhooks; client-side-only validation is prohibited. Free-tier
limits MUST degrade gracefully — the app MUST remain functional without a subscription.

**Rationale**: Centralised entitlement management prevents paywall bypass via dead code paths and
makes pricing experiments safe to ship without touching feature code.

### V. AI-Powered Personalisation

AI-driven recommendations and coaching MUST be generated via an authenticated backend service
(never by embedding raw API keys in the client). All user data sent to an AI model MUST be
described in the app's privacy policy and MUST be opt-in where required by App Store / Play
Store guidelines. The presentation layer MUST handle AI response latency with skeleton loaders
and MUST provide a deterministic fallback if the AI service is unavailable. Personalisation
logic MUST be encapsulated in a dedicated `PersonalisationRepository` in the data layer, keeping
the domain layer AI-agnostic.

**Rationale**: AI is a differentiator but also a latency and privacy risk surface. Decoupling
ensures the app works offline and that swapping AI providers requires no domain-layer changes.

## Technology Standards

- **Language**: Dart (latest stable SDK); null safety enforced, no dynamic types in domain layer.
- **Framework**: Flutter (latest stable channel).
- **State Management**: Riverpod (flutter_riverpod) for both feature-level state
  (AsyncNotifier, StreamNotifier) and cross-feature dependency injection. BLoC is
  permitted as an alternative but not required.
- **Navigation**: go_router with typed routes; deep-link support MUST be verified on both
  platforms before each release.
- **Subscriptions**: RevenueCat SDK (PurchasesFlutter); all purchase events MUST be forwarded
  to the analytics pipeline.
- **AI Backend**: Claude API (Haiku tier for high-volume low-latency calls, Sonnet tier
  for complex reasoning) via a secured server-side proxy; direct Anthropic API calls
  from the Flutter client are prohibited.
- **Local Storage**: Hive or Isar for structured data; flutter_secure_storage for credentials
  and entitlement tokens.
- **Testing**: flutter_test (unit + widget), integration_test package (e2e); Mockito or
  mocktail for mocking.

## Quality Gates

All pull requests MUST pass the following gates before merge:

1. **Static analysis**: `flutter analyze` returns zero warnings or errors.
2. **Formatting**: `dart format --set-exit-if-changed .` passes with no diff.
3. **Unit + widget tests**: `flutter test` passes with ≥80% line coverage on domain and
   data layers.
4. **Integration smoke test**: The happy-path flow for any modified feature MUST be covered by
   at least one `integration_test` scenario.
5. **Performance**: Any PR touching animation or list rendering MUST include a DevTools
   timeline screenshot showing ≥60 fps on the reference device.
6. **Constitution Check**: The plan.md Constitution Check table MUST be reviewed and signed off
   before feature work begins.

## Governance

This constitution supersedes all per-feature decisions, style guides, and verbal agreements.
Amendments MUST be proposed as a pull request modifying `.specify/memory/constitution.md`,
include a completed Sync Impact Report, increment the version number per semantic versioning
rules (MAJOR: principle removal/redefinition; MINOR: principle or section addition; PATCH:
wording/clarification), and receive approval from at least one other contributor before merge.

All plans MUST include a Constitution Check section that maps each principle to a concrete
pass/fail gate for the feature in scope. Any complexity violation MUST be logged in the plan's
Complexity Tracking table with a justification.

Compliance review MUST be performed at the start of each sprint and before each App Store /
Play Store submission.

**Version**: 1.1.0 | **Ratified**: 2026-03-23 | **Last Amended**: 2026-03-23
