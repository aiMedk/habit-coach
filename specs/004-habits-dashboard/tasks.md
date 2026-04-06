# Tasks: Habits Home Screen Dashboard

**Input**: Design documents from `/specs/004-habits-dashboard/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Scope summary**: The AI card infrastructure, offline sync, bottom navigation shell, streak calculation, and entitlement service are **already complete** and require no changes. This feature enhances `DashboardScreen` with a greeting header, animated completion list reorder, 5-minute in-row undo button, bottom stats bar, and free-tier locked rows — plus upgrade prompts on the Challenges and Reviews tabs.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other [P] tasks in the same phase (different files, no dependencies)
- **[Story]**: User story this task serves — [US1]–[US6]

---

## Phase 1: Setup (Baseline Verification)

**Purpose**: Confirm the existing codebase compiles cleanly before any changes are made.

- [x] T001 Run `flutter analyze` in `habit_coach/` and confirm zero errors and zero warnings — this is the baseline that must hold after every subsequent task

**Checkpoint**: Baseline confirmed — safe to proceed

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: New domain entity and provider infrastructure that multiple user stories depend on. Must be complete before any user story phase can be tested.

**⚠️ CRITICAL**: US2 (greeting summary) and US3 (stats bar) cannot be completed without `DailyStats` and `dailyStatsProvider`.

- [x] T002 Create `lib/features/habits/domain/entities/daily_stats.dart` — an immutable value class `DailyStats` with `final int completedCount`, `final int totalCount`, `final int bestStreak`, `final int weekCompletedCount`, `final int weekTotalCount` fields, a `const` constructor, and a `static const empty` zero-value sentinel. No Flutter or Supabase imports — pure Dart only (Constitution I).

- [x] T003 Add abstract method `Future<List<Completion>> getCompletionsForDateRange(String userId, String startDate, String endDate)` to the `CompletionRepository` abstract interface in `lib/features/habits/domain/repositories/completion_repository.dart`. Parameters `startDate` and `endDate` are `YYYY-MM-DD` strings, inclusive. The method returns non-undone completions within the range.

- [x] T004 Implement `getCompletionsForDateRange` in `lib/features/habits/data/repositories/isar_completion_repository.dart` — query Isar for `Completion` objects where `userId == userId`, `isUndone == false`, and `localDate >= startDate && localDate <= endDate`. Return the matching list. Dart string comparison works correctly for `YYYY-MM-DD` format.

- [x] T005 Add `dailyStatsProvider` to `lib/features/habits/presentation/providers/habit_providers.dart` — a `FutureProvider<DailyStats>` that: (1) awaits `habitListProvider` for the active habit list, (2) awaits `todayCompletionsProvider` for today's completions, (3) fans out to `streakProvider(habit.id)` for each habit via `Future.wait` to get all streaks, (4) awaits `completionRepositoryProvider` and calls `getCompletionsForDateRange` with the current user's id and the Monday of the current calendar week through today (compute Monday as `DateTime.now()` minus `weekday - 1` days, format both as `YYYY-MM-DD`), (5) builds and returns `DailyStats(completedCount: todayCompletions.length, totalCount: habits.length, bestStreak: streaks.map((s) => s.currentCount).fold(0, max), weekCompletedCount: weekCompletions.map((c) => c.habitId).toSet().length, weekTotalCount: habits.length)`. Import `dart:math` for `max`.

**Checkpoint**: `DailyStats` entity exists, `getCompletionsForDateRange` is implemented, `dailyStatsProvider` compiles — safe to proceed to user stories

---

## Phase 3: User Story 1 — Today's Habits List with Completion (Priority: P1) 🎯 MVP

**Goal**: Animated habit completion that moves the habit to the bottom of the list, strikethrough on name, and an inline "Undo" button visible for exactly 5 minutes.

**Independent Test**: Log in with a user who has at least 3 habits → verify all appear with circular checkboxes and streak badges → tap one → verify it animates to the bottom with strikethrough within 300ms → verify an "Undo" button appears on that row → verify it disappears after 5 minutes → tap "Undo" on a within-window completion → verify it returns to the active section.

- [ ] T006 [US1] Convert `DashboardScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` in `lib/features/habits/presentation/screens/dashboard_screen.dart`. The screen needs mutable state for the sync-failure banner (added in T021). No new fields are required at this stage — keep all existing widget content identical. This is a structural refactor only to enable `setState` in later tasks.

- [ ] T007 [US1] Refactor `_HabitList` in `lib/features/habits/presentation/screens/dashboard_screen.dart` into a `StatefulWidget` that renders two sections — active habits (top) and completed habits (bottom) — using a single `CustomScrollView` with two `SliverList` sections separated by a `SliverToBoxAdapter` section header. Add a `todayCompletionTimestampByHabit: Map<String, DateTime>` parameter (built in `DashboardScreen` as `{ for (final c in todayCompletions) c.habitId: c.completedAt }`) alongside the existing `completedHabitIds` and `todayCompletionIdByHabit` parameters. Active habits are habits where `!completedHabitIds.contains(habit.id)`; completed habits are habits where `completedHabitIds.contains(habit.id)`, sorted ascending by `todayCompletionTimestampByHabit[habit.id]`. When all habits are completed, show a `SliverFillRemaining` with the congratulatory message "All done for today! 🎉" in place of the active section. When `habits.isEmpty`, show the existing `_EmptyState` widget. Pass `completedAt: todayCompletionTimestampByHabit[habit.id]` to each `_HabitCard` for the undo window check.

- [ ] T008 [US1] Convert `_HabitCard` from `ConsumerWidget` to `ConsumerStatefulWidget` in `lib/features/habits/presentation/screens/dashboard_screen.dart`. Add a `DateTime? completedAt` constructor parameter. In `initState`, if `completedAt != null && HabitDateUtils.isWithinUndoWindow(completedAt!)`, compute the remaining window duration (`completedAt! + 5 minutes - DateTime.now()`) and start a `Timer(remainingDuration, () => setState(() {}))` to rebuild the card when the window expires. Store the timer in `Timer? _undoTimer` and cancel it in `dispose()`.

- [ ] T009 [US1] Add the inline "Undo" button to `_HabitCard` in `lib/features/habits/presentation/screens/dashboard_screen.dart`. When `widget.completedAt != null && HabitDateUtils.isWithinUndoWindow(widget.completedAt!)`, render a `TextButton(child: Text('Undo'), onPressed: _undo)` as a trailing widget in the card `Row`, after the `StreakBadge`. Implement `_undo()` to call `repo.undoCompletion(completionId)`, then `ref.invalidate(todayCompletionsProvider)` and `ref.invalidate(streakProvider(habit.id))`. When undo is tapped, the `_HabitList` rebuilds and moves the habit back to the active section. Remove the `SnackBarAction` undo from the existing completion SnackBar (keep the success SnackBar text only — undo is now in-row).

- [ ] T010 [US1] Wire the `_complete()` method in `_HabitCard` (in `lib/features/habits/presentation/screens/dashboard_screen.dart`) to trigger the animated list transition: instead of the SnackBar having an "Undo" action, remove the `SnackBarAction` from the completion SnackBar (keep the completion success SnackBar without undo — undo is now in-row). The `ref.invalidate(todayCompletionsProvider)` call drives the `_HabitList` to rebuild, which will move the habit from the active `SliverList` to the completed `SliverList`. Wrap the `CustomScrollView` in an `AnimatedSwitcher` or use `AnimatedContainer` at the list level to smooth the transition. The visual transition from active to completed must complete within 300ms — use `duration: const Duration(milliseconds: 250)`.

**Checkpoint**: US1 is independently testable — users can view habits, complete them with animation, and undo within 5 minutes

---

## Phase 4: User Story 2 — Greeting Header and Daily Summary (Priority: P2)

**Goal**: Personalised time-sensitive greeting, today's date, and "X of Y habits completed today" summary at the top of the dashboard.

**Independent Test**: Open the app at different times of day → verify correct greeting prefix → verify today's date in "Sunday, April 5" format → complete some habits → verify the summary line count updates.

- [x] T011 [P] [US2] Create `lib/features/habits/presentation/widgets/dashboard_greeter_widget.dart` — a `ConsumerWidget` named `DashboardGreeterWidget`. It watches `currentUserProvider` and `dailyStatsProvider`. It computes the greeting prefix from `DateTime.now().hour`: hour < 12 → "Good morning", hour < 18 → "Good afternoon", else → "Good evening". The display name is `user.displayName.trim().isEmpty ? user.email.split('@').first : user.displayName`. The date is formatted with `DateFormat('EEEE, MMMM d').format(DateTime.now())` from the `intl` package. The summary line is `"${stats.completedCount} of ${stats.totalCount} habits completed today"`. Render as a `Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8))` containing a `Column(crossAxisAlignment: CrossAxisAlignment.start)` with: greeting text (`textTheme.headlineSmall`), date text (`textTheme.bodyMedium` with `colorScheme.onSurfaceVariant`), and summary text (`textTheme.bodyMedium`). Loading and error states for the async providers should render `const SizedBox.shrink()`.

- [x] T012 [US2] Add `DashboardGreeterWidget()` as the first child in `DashboardScreen`'s body `Column` in `lib/features/habits/presentation/screens/dashboard_screen.dart` — placed above `_AiCard()` and the `Expanded` habits list section. Import `dashboard_greeter_widget.dart`.

**Checkpoint**: US2 is independently testable — greeting, date, and summary are visible and reactive to completions

---

## Phase 5: User Story 3 — Bottom Stats Bar (Priority: P3)

**Goal**: A persistent stats bar pinned at the bottom of the dashboard showing best streak and this week's habit completion rate.

**Independent Test**: Open the dashboard → verify "Best streak: X days" shows the highest current streak across all habits → verify "This week: X/Y habits" shows correct week counts → complete a habit and verify counts update.

- [x] T013 [P] [US3] Create `lib/features/habits/presentation/widgets/bottom_stats_bar.dart` — a `StatelessWidget` named `BottomStatsBar` that accepts a `final DailyStats stats` constructor parameter. Renders a `Container` with `color: colorScheme.surfaceContainerHighest` and `padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)` containing a `Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly)` with two stat items. Each stat item is a `Column` with a `Text` label (bodySmall, `colorScheme.onSurfaceVariant`) and a `Text` value (labelLarge, bold). Left item: label "Best streak", value "${stats.bestStreak} days". Right item: label "This week", value "${stats.weekCompletedCount}/${stats.weekTotalCount} habits". Add a `Divider(height: 1)` above the container.

- [x] T014 [US3] Add `BottomStatsBar` to `DashboardScreen` in `lib/features/habits/presentation/screens/dashboard_screen.dart`. Watch `dailyStatsProvider` in the `DashboardScreen` build method. Change `Scaffold.body` to a `Column` that contains: `[DashboardGreeterWidget(), _AiCard(), Expanded(child: habitList), statsBarOrLoading]` — where `statsBarOrLoading` is `dailyStatsAsync.when(loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(), data: (stats) => BottomStatsBar(stats: stats))`. The `BottomStatsBar` sits between the habits list and the `FloatingActionButton`, always visible (not scrollable). Import `bottom_stats_bar.dart`.

**Checkpoint**: US3 is independently testable — stats bar visible, correct values, updates on completion

---

## Phase 6: User Story 4 — AI Coaching Prompt Card (Priority: P4)

**Goal**: Verify that the already-implemented AI card infrastructure correctly satisfies FR-010 through FR-014 with no new code required.

**Independent Test**: Log in as Pro user between 5AM–noon → verify morning card "Ready for your check-in?" appears → tap Start → verify card disappears → force-close and reopen → verify card is still gone for the window → log in as free user in same window → verify locked preview card with "Upgrade to Pro" appears.

- [x] T015 [US4] Verify `_AiCard` in `lib/features/habits/presentation/screens/dashboard_screen.dart` satisfies all AI card requirements: (1) confirm `morningCardVisibilityProvider` gates `MorningPromptCard` (5AM–noon, Pro only) — FR-010, (2) confirm `eveningCardVisibilityProvider` gates `EveningPromptCard` (6PM–midnight, Pro only) — FR-011, (3) confirm tapping Start navigates to chat and suppresses the card — FR-012, (4) confirm dismissal suppresses the card for the session — FR-013, (5) confirm `AiPreviewCard` renders for free-tier users during windows — FR-014, (6) confirm `MainShell` in `lib/core/widgets/main_shell.dart` renders exactly 4 `NavigationDestination` items (Home, Challenges, Reviews, Settings) and the bar is always visible — FR-009. If any gap is found, patch the relevant widget. Document all verification results in code comments.

**Checkpoint**: US4 requirements are verified as satisfied by existing implementation

---

## Phase 7: User Story 5 — Free Tier Habit Limit and Upgrade Prompts (Priority: P5)

**Goal**: Free-tier users see their first 3 habits fully interactive; habits beyond 3 are locked with an upgrade prompt. Challenges and Reviews tabs show an upgrade banner for free users.

**Independent Test**: Log in as free user with 5 habits → verify habits 1–3 have checkboxes → verify habits 4–5 show lock icon and "Upgrade to Pro" text → tap a locked row → verify navigation to paywall → navigate to Challenges tab → verify upgrade prompt visible → navigate to Reviews tab → verify upgrade prompt visible.

- [x] T016 [US5] Add a private `_LockedHabitRow` `StatelessWidget` in `lib/features/habits/presentation/screens/dashboard_screen.dart` that accepts `final Habit habit`. Renders a `Card(margin: EdgeInsets.zero)` with `InkWell(onTap: () => context.push(AppRoutes.paywall))` containing a `Padding(padding: EdgeInsets.all(16))` with a `Row`: a `Icon(Icons.lock_outline, color: colorScheme.outline)` on the leading edge, a `SizedBox(width: 12)`, an `Expanded` `Column` with the habit name in `titleMedium` style coloured `colorScheme.outline` (greyed out) and a `Text('Upgrade to Pro', style: bodySmall with primary color)` subtitle, and no checkbox.

- [x] T017 [US5] Modify `_HabitList` in `lib/features/habits/presentation/screens/dashboard_screen.dart` to watch `entitlementServiceProvider`. For free-tier users (`!entitlementService.isPro`), limit interactive habit rows to the first `AppConstants.freeTierHabitLimit` (= 3) habits in the active section — habits beyond this index render as `_LockedHabitRow`. Locked rows appear in a third `SliverList` section after the 3 interactive active habits and before the completed section. For the completed section: if a completed habit's index is within the free-tier limit (it was interactive when the user completed it, or they were Pro at the time), show it as a greyed-out completed row with strikethrough but no undo button. Completed habits whose index exceeds the free-tier limit should not appear in the completed section (they could never have been completed while locked).

- [x] T018 [P] [US5] Add a free-tier upgrade prompt to `lib/features/challenges/presentation/screens/challenges_list_screen.dart` — watch `entitlementServiceProvider` (or `isProProvider`); when `!isPro`, replace the screen body with a `Center` child containing a `Column(mainAxisSize: MainAxisSize.min)` with: a lock icon (`Icons.lock_outline`, size 64, `colorScheme.outline`), a `Text('Challenges are a Pro feature', style: titleLarge)`, a `SizedBox(height: 8)`, a `Text('Unlock group challenges and accountability partners.', style: bodyMedium, textAlign: center)`, a `SizedBox(height: 24)`, a `FilledButton(onPressed: () => context.push(AppRoutes.paywall), child: Text('Upgrade to Pro'))`, and a `SizedBox(height: 12)`, and a `TextButton(onPressed: () {}, child: Text('Maybe later'))` that does nothing (dismisses focus — users can navigate away via the bottom nav). This satisfies FR-017 while keeping navigation accessible (Constitution IV: no blocking modals).

- [x] T019 [P] [US5] Add a free-tier upgrade prompt to `lib/features/weekly_review/presentation/screens/reviews_list_screen.dart` — identical pattern to T018. Title text: "Reviews are a Pro feature". Subtitle: "Access your weekly AI reviews and past coaching conversations." Button navigates to `AppRoutes.paywall`.

**Checkpoint**: US5 is independently testable — free-tier locking and upgrade prompts work correctly

---

## Phase 8: User Story 6 — Offline Support and Background Sync (Priority: P6)

**Goal**: Dashboard displays cached data offline and syncs completions automatically on reconnect. Verify existing infrastructure is wired correctly; add the sync-failure banner required by FR-019 scenario 4.

**Independent Test**: Load dashboard with network → disable network → verify habits still display and can be marked complete → re-enable network → verify completions sync without user action → simulate sync failure → verify non-blocking "Some completions could not sync. Will retry shortly." banner appears.

- [x] T020 [US6] Verify `OfflineCompletionQueue` is started during app initialisation. Read `lib/main.dart` and confirm `OfflineCompletionQueue.start()` (or equivalent) is called before `runApp`. If it is not called, add the call in `main()` after `WidgetsFlutterBinding.ensureInitialized()` and Supabase/Isar initialisation. This task may be a no-op if already wired — document the finding in a code comment.

- [x] T021 [US6] Add a sync-failure banner to `DashboardScreen` using a stream-based contract that preserves Clean Architecture (Constitution I — data layer must not import Riverpod or reference presentation providers). Three-step implementation: (1) In `lib/features/habits/data/services/offline_completion_queue.dart`, add a `final StreamController<bool> _syncFailureController = StreamController<bool>.broadcast()` field and a `Stream<bool> get syncFailures => _syncFailureController.stream` getter. In the `_drain()` method, after all retries are exhausted and a sync error persists, call `_syncFailureController.add(true)`. Add `_syncFailureController.close()` to `dispose()`. (2) In `lib/features/habits/presentation/providers/habit_providers.dart`, add `syncFailureProvider` as an `autoDispose StreamProvider<bool>` that watches `offlineQueueProvider` (the provider that exposes the `OfflineCompletionQueue` instance) and returns its `.syncFailures` stream. (3) In `DashboardScreen.build` (in `lib/features/habits/presentation/screens/dashboard_screen.dart`), watch `syncFailureProvider`; when it emits `true`, show a non-blocking `MaterialBanner` with message "Some completions could not sync. Will retry shortly." and a "Dismiss" `TextButton` action that calls `ref.invalidate(syncFailureProvider)` to reset it. Place the banner above `DashboardGreeterWidget` in the body `Column`.

**Checkpoint**: US6 requirements are satisfied — offline display works via existing Isar cache; sync failure surfaces to the user non-destructively

---

## Phase 9: Polish & Quality Gates

**Purpose**: Static analysis, formatting, coverage, and cross-cutting smoke test verification.

- [ ] T022 [P] Create `habit_coach/integration_test/dashboard_smoke_test.dart` — smoke tests for the primary happy paths using mocked Riverpod providers (no live Supabase): (1) US1: pump `DashboardScreen` with 3 habits, tap first checkbox, assert it moves to completed section with strikethrough and "Undo" button visible; also manually verify ≤3 taps from cold launch to first habit completion (SC-001); (2) US2: pump with `displayName = 'Alice'` and hour < 12, assert "Good morning Alice" visible; (3) US3: pump with `DailyStats(bestStreak: 5, weekCompletedCount: 3, weekTotalCount: 5)`, assert "Best streak: 5 days" and "This week: 3/5 habits" visible; also verify that the `DashboardScreen` renders with mocked Isar data before the first network frame (SC-003: cached load ≤1s); (4) US5: pump with 5 habits and free tier, assert first 3 have checkboxes and habits 4–5 have lock icons.

- [ ] T023 Profile the completion animation in Flutter DevTools: run the app on an iPhone 12 simulator and a mid-range Android emulator (Pixel 4 or equivalent), open the Performance overlay, complete 5 habits in rapid succession, confirm the frame timeline stays ≥60fps during list reorder and strikethrough transitions (Constitution III, SC-002). If any frame exceeds 16ms on ≥5% of frames, investigate and fix before marking done. Document the profiling result (fps observed, device) in a code comment on `_HabitList` in `lib/features/habits/presentation/screens/dashboard_screen.dart`.

- [x] T024 Run `flutter analyze` in `habit_coach/` and confirm zero errors, zero warnings (Quality Gate 1). Run `dart format --set-exit-if-changed .` in `habit_coach/` and confirm exit code 0 (Quality Gate 2). Fix any issues found before marking done.

- [x] T025 Run `flutter test --coverage` in `habit_coach/` and confirm domain + data layer line coverage ≥80% for new files: `lib/features/habits/domain/entities/daily_stats.dart`, `lib/features/habits/data/repositories/isar_completion_repository.dart` (new method only). Check `coverage/lcov.info`. Fix coverage gaps if needed.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — BLOCKS all user story work
  - T002 must complete before T003 (entity must exist before interface references it in return type)
  - T003 must complete before T004 (interface before implementation)
  - T002 + T004 must complete before T005 (provider depends on entity type and repo method)
- **Phase 3 (US1)**: Depends on Phase 2 — T006 → T007 → T008 → T009 → T010 sequentially (same file)
- **Phase 4 (US2)**: Depends on Phase 2 (`dailyStatsProvider` must exist) — T011 [P] and T012 sequential
- **Phase 5 (US3)**: Depends on Phase 2 — T013 [P] before T014
- **Phase 6 (US4)**: Depends on Phase 3 (`DashboardScreen` must compile) — single verification task
- **Phase 7 (US5)**: Depends on Phase 3 (`_HabitList` must be in final form) — T016 before T017; T018 [P] and T019 [P] are independent
- **Phase 8 (US6)**: Depends on Phase 3 (dashboard screen must exist) — T020 before T021
- **Phase 9 (Polish)**: Depends on all prior phases — T022 [P] can run in parallel; T023 (DevTools) requires a device/simulator; T024 and T025 depend on T022 and T023

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 only — no other story dependency
- **US2 (P2)**: Depends on Phase 2 (`dailyStatsProvider`) — independent of US1
- **US3 (P3)**: Depends on Phase 2 (`dailyStatsProvider`) — independent of US1/US2
- **US4 (P4)**: Depends on Phase 3 (DashboardScreen must compile) — verification only
- **US5 (P5)**: Depends on Phase 3 (`_HabitList` refactored) — extends the list widget
- **US6 (P6)**: Depends on Phase 3 (dashboard must exist) — adds banner

### Within Phase 2 (Foundational)

T002 → T003 → T004 → T005 must run sequentially (each depends on the previous).

### Within Phase 3 (US1)

T006 → T007 → T008 → T009 → T010 must run sequentially (all touch the same file; each builds on the previous). T008 (StatefulWidget conversion) must complete before T009 (undo button using widget state).

---

## Parallel Opportunities

### Phase 2 after T002 completes

```
T003 (interface) → T004 (implementation) → T005 (provider)   [sequential in same chain]
```

### Within Phase 4 and 5 (after Phase 2 completes)

```
T011 [P]  DashboardGreeterWidget (new file)
T013 [P]  BottomStatsBar (new file)
```
These can be written simultaneously — different files, no dependencies on each other.

### Within Phase 7 (US5, after Phase 3 completes)

```
T018 [P]  Upgrade prompt in ChallengesListScreen
T019 [P]  Upgrade prompt in ReviewsListScreen
```
Different files, no shared state.

---

## Implementation Strategy

### MVP (User Story 1 only — ~5 tasks)

1. T001 — baseline check
2. T002 → T003 → T004 → T005 — DailyStats entity + provider infrastructure
3. T006 → T007 → T008 → T009 → T010 — animated list + in-row undo
4. **STOP and validate**: habits can be completed with animation; undo button visible for 5 minutes

### Incremental Delivery

1. MVP above → US1 working
2. T011, T012 — greeting header (US2)
3. T013, T014 — stats bar (US3)
4. T015 — AI card + bottom nav verification (US4)
5. T016, T017, T018, T019 — free tier gating (US5)
6. T020, T021 — offline sync failure banner (US6)
7. T022, T023, T024, T025 — smoke test + DevTools profiling + quality gates

---

## Notes

- **Already complete (zero tasks)**: AI card widgets, offline queue, connectivity checker, Supabase sync service, Isar repositories (read path), StreakCalculator, EntitlementService, MainShell bottom navigation, `streakProvider`, `habitListProvider`, `todayCompletionsProvider`
- **T010**: The animated transition uses `AnimatedSwitcher` / `AnimatedContainer` at the list level, not `AnimatedList.insertItem` — provider invalidation drives a full `setState` on `_HabitList`. Sorting active/completed and rebuilding the two `SliverList` sections with `AnimatedSwitcher` wrapping each section achieves the visual movement. No `GlobalKey<AnimatedListState>` is needed. If jank is observed during T023 profiling, upgrade to `SliverAnimatedList` for finer-grained animation.
- **T021**: `OfflineCompletionQueue` is a plain Dart class — it cannot import or write to Riverpod providers (Constitution I). The `StreamController`-based approach keeps data→domain→presentation dependency direction clean. The `offlineQueueProvider` (which wraps the queue instance) must already exist or be created as part of T020/T021.
- After T023 passes `flutter analyze`, do NOT add `// ignore:` directives — fix the underlying cause instead.
- GoRouter navigation: always use `context.push(AppRoutes.paywall)` (not `context.go`) for paywall navigation so users can navigate back.
