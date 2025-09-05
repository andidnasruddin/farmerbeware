1. Look at 1_GameManagerSystem.md
2. Use CODING_STYLE.md
3. Check godot.project and git for latest push to repo updates.
4. Read AGENTS.md
5. Create a thorough step-by-step Todo list of implementing 4_TimeSystem.md
6. DO NOT EDIT FILES. ONLY VIEW FILES.
7. Provide clear step by step of implementing code and features to the user, since they are a beginner
8. Code must use tabs and not spaces. Godot 4.4 doesn't read spaces.

```
Here is a thorough, ordered TODO that follows 4_TimeSystem.md exactly, designed to minimize risks and make implementation smooth. I will wait for your confirmation before starting Step 1.

Implementation Order

Step 1: Autoload Reorder (no code changes yet)

Update project.godot:[autoload] to match 4_TimeSystem.md:
GameManager → GridValidator → GridManager → TimeManager → EventManager → InteractionSystem → (rest unchanged).
Update header comments in scripts/managers/TimeManager.gd (AUTOLOAD #4) and scripts/managers/EventManager.gd (AUTOLOAD #5).
Sanity checks: boot once; verify all autoloads show in Output; confirm EventManager logs “TimeManager connected”.
Step 2: Core Timeflow Alignment (Planning infinite; time-only-in-farming)

Gate ticking: in TimeManager._process, only add time in FARMING phases (MORNING, MIDDAY, EVENING).
Planning infinite: disable auto-advance in PLANNING; expose a Start Day trigger (no time passes in PLANNING).
Keep NIGHT/TRANSITION non-ticking; they handle results and day setup only.
Ensure warnings (60s/30s/10s/5s) still emit based on remaining time in FARMING phases.
Respect game_speed everywhere.
Step 3: DayNightCycle (scripts/time/DayNightCycle.gd)

Add component to compute hour/min from FARMING progress (6:00 → 18:00).
API: get_hour(), get_minute(), get_time_string(), get_time_percent().
Signals: time_updated(hour, minute) during FARMING only.
Reset to 6:00 on TimeManager.day_started.
Step 4: Start Day Countdown (scripts/time/CountdownController.gd + scenes/time/CountdownOverlay.tscn)

Overlay with big number, pulse, cancel button, and beeps (10 → 0).
Planning flow: user clicks “Start Day” → show countdown → can cancel → at 0 switch to MORNING.
Host-authoritative: host starts/cancels/finishes; broadcasts events; clients apply without echo.
Step 5: Phase Transitions (scripts/time/PhaseController.gd + scenes/time/PhaseTransition.tscn)

Full-screen fade (0.5s) on phase changes, input lock, transition SFX, and validation gates.
Validation gates before FARMING/RESULTS: all players ready, save ok, network synced, resources loaded, no active inputs.
Network sync: host broadcasts phase_change with { from, to, day }.
Step 6: Time Display (Clock HUD) (scripts/time/TimeDisplay.gd + scenes/time/TimeDisplay.tscn)

Digital time (“10:30 AM”), phase badge, day counter, week indicator, sun-arc progress.
Pressure indicators: color/pulse at last hour/30m/10m/1m; optional siren at last 10s.
Subscribe to DayNightCycle.time_updated and TimeManager.phase_changed.
Step 7: Calendar UI (scenes/time/CalendarUI.tscn)

Show week 1–4 and day-in-week; highlight current day.
Optional list of today’s scheduled events (hourly), fed by the scheduler.
Refresh on TimeManager.day_started.
Step 8: Event Scheduler (scripts/events/EventScheduler.gd + resources/schedules/*.tres)

Resource format: array entries { hour: float, type: String, id: String, chance: float }.
On day_started: load by week (resources/schedules/week1_schedule.tres … week4).
On DayNightCycle.time_updated: fire entries when thresholds cross; guard duplicates; apply chance.
Enforce “Flash Contract ALWAYS at 12:00 PM” daily (inject forced entry if missing).
Integrate with EventManager via factory calls or typed events.
Step 9: Weather & Events Visuals

Weather duration: adjust to 2–5 minutes per doc (120–300s) in weather event creation.
Overlays: scenes/events/WeatherOverlay.tscn (rain/fog/storm) and scripts/weather/WeatherEffects.gd.
Popups: scenes/events/EventNotification.tscn for event start/complete.
Coordinate gameplay modifiers through EventManager (auto-water, growth, risks).
Step 10: Difficulty Scaling (scripts/time/DifficultyScaler.gd)

Weekly scaling per doc: +time pressure, +event frequency, +disaster chance, price/quality changes (cap 200%).
Apply at day_started: adjust TimeManager.phase_durations, EventManager.event_probabilities, and scheduler parameters.
Never reduce below safe minimums for phase durations.
Step 11: Multiplayer Sync (host-authoritative)

Host: only source of countdown and phase changes; clients apply on receive.
Events: time/countdown_start, time/countdown_cancel, time/countdown_finish, time/phase_change.
Guards: clients wait for connected_to_server; never echo network events; leave before re-join/host.
Late join: host sends day/phase/time-of-day snapshot to sync new client.
Step 12: Audio Hooks (scripts/managers/AudioManager.gd registrations)

Register SFX IDs: countdown_beep, phase_transition, day_end_bell, tick_tock (optional).
Triggers: beep per second, transition on phase_changed, bell at day end.
Step 13: Testing & Validation

Add tests/time_system_test.tscn to exercise:
Planning infinite → start countdown → MORNING; warnings and UI updates.
DayNightCycle progression and 12:00 Flash Contract injection.
Weather 2–5 minute range fires; overlays show/hide.
Manual net test: two editors; K host, L join; confirm countdown and phase sync; validations hold.
Keep tests/Z_test.tscn passing and extend with get_debug_info() checks for new components.
Step 14: Debug & Telemetry

TimeManager.get_debug_info(): { day, phase, elapsed, remaining, week, day_in_week, game_speed }.
DayNightCycle.get_debug_info(): { hour, minute, percent }.
EventScheduler.get_debug_info(): { pending_today, fired_count }.
Optional F3 overlay lines for time and phase.
Step 15: Documentation & Style

Tabs only for .gd/.tscn; follow docs/CODING_STYLE.md section structure and naming.
Update script headers with accurate AUTOLOAD numbers and brief descriptions.
Keep all new files under:
scripts/time/, scripts/events/, scripts/weather/
scenes/time/, scenes/events/
resources/schedules/
Step 16: Rollout Plan

Implement Steps 2–6 first (core flow, day clock, countdown, transitions, HUD) → quick playtest.
Add Step 8 (scheduler) and Step 9 (weather visuals) → verify 12:00 flash contract and weather durations.
Apply Step 10 (difficulty) → observe week scaling.
Wire Step 11 (network sync) → validate with two instances.
Final polish: audio, debug info, tests.
```
