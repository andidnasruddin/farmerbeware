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

Here’s a concise recap of what we implemented and fixed (Steps 1–10), with key choices and references for future work.

Core Timeflow

Planning infinite: Time does not tick in PLANNING; only in FARMING (MORNING/MIDDAY/EVENING).
Start Day: P opens countdown; host-only begins day via TimeManager.start_day().
Process gating: TimeManager._process() early-returns unless PLAYING and in FARMING; warnings only during FARMING.
Day/Night + HUD

DayNightCycle: Tracks 6:00→18:00 mapped from FARMING progress; emits time_updated(h, m, percent). Spawned from TimeManager to avoid autoload name collision.
TimeDisplay HUD: Shows clock, phase, day/week, and sun progress. Fixed:
Use instance at /root/DayNightCycle (not the class).
Use $ node paths (not %) and add a 0.2s polling fallback.
Stable display: floor minutes to avoid “5:57 AM” jitter.
UIManager: Registers overlays on itself at startup and shows time_display when entering PLAYING.
Countdown (Host‑Authoritative)

Overlay: CountdownOverlay with CountdownController.gd. Keys: P open, C/Esc cancel.
Net events: time/countdown_start|cancel|finish.
Host fixes:
Ignore own network events to prevent recursion/overflow.
Clients show overlay and start locally on receive.
Cancel/finish mirrored to clients.
Dimmer set to IGNORE so Cancel button is clickable.
Phase Transitions

Overlay: PhaseTransition with PhaseController.gd.
Fixes: Use ColorRect.color.a tweening; no ?: ternary; safe tween kill; plays on every phase_changed.
Net: Host broadcasts time/phase_change; clients play fade on receipt.
Calendar

Overlay: CalendarUI with weekly labels and “Today’s Schedule” list.
Fixes:
Remove “extension method” attempt; add _clear_container.
Toggle with Y; added method set_today_schedule(entries).
Scheduler refreshes list when calendar opens (list stays in sync even if opened later).
Event Scheduler

Node: EventScheduler.gd (spawned once).
Loads resources/schedules/weekN_schedule.tres (supports both plain dictionary arrays and typed EventSchedule/Entry).
Guarantees Flash Contract at 12:00 PM if missing.
Fires entries by precise clock:
Uses DayNightCycle percent → hour, and prev/cur hour crossing (prev < target ≤ cur) to avoid early firing.
Net mirroring: Host broadcasts sched/flash, sched/weather; clients mirror effects.
Calendar integration: Builds a display list and dims fired entries.
Weather Overlays

Overlay: WeatherOverlay with WeatherEffects.gd.
Visuals: Darken/Fog/Warm tints; multi-emitter rain layer for robust GPUParticles2D across viewport.
Key fixes:
Godot 4 ParticleProcessMaterial properties use Vector3 (direction, gravity).
Avoid emission_points/emission_rect_extents/enums; build emitters in a “RainLayer”.
Emitters created with emitting=false and _hide_all() after build to prevent particles in PLANNING/countdown.
Event lock: tie visuals to EventManager event_started/event_ended for WEATHER; ignore weather_changed while an event is active.
Rebuild emitters on resize; keep them off unless a weather event is running.
Difficulty Scaler

Node: DifficultyScaler.gd (spawned once).
Captures base phase durations once; on each day:
Applies time pressure (shorter phases) with per-week scaling, dynamic bonus (never decreases), Assist Mode (-20%), and hard minimum seconds.
Multiplies EventManager.event_probabilities (cap), with extra for DISASTER.
GDScript 4 tightened: typed locals, no ambiguous :=, direct enum key int(EventManager.EventType.DISASTER).
Networking

Host-authoritative: Countdown, phase changes, schedule fires all originate on host; clients apply and never echo.
Guards: Host ignores its own network events; clients wait until connected; overlay registration done at UIManager startup to avoid “not registered” warnings.
Late join: Clients receive current day/phase/time via ongoing signals and net events (countdown/phase/weather).
UIManager Edits

Registration at startup:
register_overlay("countdown"|"phase_transition"|"time_display"|"calendar"|"weather_overlay", path)
Helpers to avoid warnings:
show_screen_if_registered, show_overlay_if_registered, hide_overlay_if_active
State handling: In PLAYING, show time_display and weather_overlay; leave “hud” guarded (only if you register one).
GDScript 4 Compliance (common pitfalls fixed)

Avoid ?: ternary; use value if cond else other.
:= always with a type hint or use = for Variant sources (Resource.get).
Use range(n) and typed locals (var i: int).
2D particles use Vector3 for direction/gravity.
Access enums as ints: int(EventManager.EventType.DISASTER).
Input Map

P: Start day (opens countdown)
C/Esc: Cancel countdown
Y: Toggle calendar
(Optional H: Toggle HUD if you kept the handler)
Event/Overlay IDs (cheat sheet)

Net events: time/countdown_start, time/countdown_cancel, time/countdown_finish, time/phase_change, sched/flash, sched/weather
Overlays: countdown, phase_transition, time_display, calendar, weather_overlay
If you’re ready, Step 11 is the host time sync audit:

Verify all time/phase state is authoritative on host and mirrored on clients (including late join sync snapshot).
Add a small host snapshot RPC/event (time/snapshot) with { day, phase, phase_elapsed|percent } on client connect to snap newcomers to the host’s clock.
Ensure no client can trigger phase/clock changes locally (defensive guards remain in place).

# --- Step 11 --- #

Step 11 work that made sync solid:

Host‑only control

Guarded countdown: P works on host; clients send time/countdown_request → host opens/broadcasts.
Random weather checks moved to host only; clients no longer roll weather locally.
Late‑join time snapshot

Added time/snapshot and time/snapshot_request.
Host sends { day, phase, elapsed, duration, percent, speed, paused, hour } to new peers; clients apply via apply_time_snapshot().
Phase/overlay sync

Kept phase fade broadcasts (time/phase_change) and client playback.
Ensured UI overlays (countdown, phase transition, time HUD, weather overlay) are registered/shown reliably.
Weather synchronization (the big fix)

Host decides weather duration and broadcasts sched/weather { id, dur }.
Client first ends any active weather (end_active_weather_events()), then applies host’s weather; duration respected.
Added optional sched/weather_end hard stop from host when a weather event ends.
Weather overlay reacts to EventManager event_started/event_ended, so visuals align with lifecycle.
Networking wiring

TimeManager listens to NetworkManager.event_received, peer_connected, and SceneTree multiplayer.connected_to_server.
Host ignores its own outbound events (no recursion).
Result: countdown works from either window (host‑authoritative), phase changes/fades are mirrored, late‑joiners snap to host time, and weather starts/ends on both peers at the same in‑game moments.

