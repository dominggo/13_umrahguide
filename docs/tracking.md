# Journey Tracking — Architecture & Reference

## 1. Overview

The Panduan Umrah app records the user's physical Umrah journey as a structured timeline.
Tracking begins when the user taps **"Mulakan Umrah"** and ends when they tap **"Tamatkan Umrah ini"**
on the Tahallul step. An incomplete journey (abandoned mid-way) is saved with `completed: false`.

### What is recorded
- **GPS track** — sampled every 5 m of movement or every 15 s, whichever comes first.
- **Events** — discrete journey moments (step entry, doa confirmed, round completed, etc.).
- **Step summaries** — per-step start/end timestamps with completion flag.

---

## 2. Data Files

| File | Location | Purpose |
|------|----------|---------|
| `journey_track.json` | `{appDocDir}/journey_track.json` | Active journey buffer (GPS + events). Atomic write via tmp file. |
| `umrah_history.json` | `{appDocDir}/umrah_history.json` | Completed/abandoned journey records (CRUD via JourneyHistoryProvider). |

### `journey_track.json` shape
```json
{
  "start": "2026-03-01T06:00:00.000Z",
  "active": true,
  "track": [
    { "lat": 21.4225, "lng": 39.8262, "ts": "2026-03-01T06:00:05.000Z" }
  ],
  "events": [
    { "type": "journey_start", "ts": "2026-03-01T06:00:00.000Z", "lat": 21.4225, "lng": 39.8262 }
  ]
}
```

### `umrah_history.json` record shape
```json
{
  "id": "2026-03-01T06:00:00.000Z",
  "startTime": "2026-03-01T06:00:00.000Z",
  "endTime": "2026-03-01T10:30:00.000Z",
  "completed": true,
  "version": 1,
  "notes": null,
  "events": [ ... ],
  "gpsTrack": [ ... ],
  "stepSummaries": [
    {
      "stepId": "tawaf",
      "startedAt": "2026-03-01T07:00:00.000Z",
      "finishedAt": "2026-03-01T08:15:00.000Z",
      "completed": true
    }
  ]
}
```

---

## 3. GPS Sampling Rules

| Condition | Behaviour |
|-----------|-----------|
| First point after journey start | Always recorded |
| Movement ≥ 5 m from last point | Record new point |
| Time ≥ 15 s since last point | Record new point (even if stationary) |
| GPS unavailable | Journey still starts; GPS track remains empty |

Sampling is driven by `Geolocator.getPositionStream(distanceFilter: 5)` combined with a
fallback timer in `LocationProvider._onPosition()`. An autosave timer also flushes the
buffer to disk every 15 s.

---

## 4. Event Types

| Event type (JSON) | Dart enum | When fired |
|-------------------|-----------|-----------|
| `journey_start` | `journeyStart` | `loc.startJourney()` — once at the very beginning |
| `step_start` | `stepStart` | `DoaViewerScreen.initState` post-frame callback — when user opens any of the 5 journey steps |
| `doa_played` | `doaPlayed` | User confirms a `isCheckpoint: true` doa (round substep or non-round special step) |
| `round_confirmed` | `roundConfirmed` | User confirms a Tawaf or Sa'ie round via the checkpoint dialog |
| `journey_end` | `journeyEnd` | At start of `finalizeJourney()` or `snapshotAndClear()` — before state is cleared |

### Event JSON fields
```json
{
  "type": "round_confirmed",
  "substepId": "tawaf_3",
  "ts": "2026-03-01T07:45:00.000Z",
  "lat": 21.4225,
  "lng": 39.8262
}
```
All fields except `type` and `ts` are optional (omitted when null).

---

## 5. Journey Lifecycle

```
User taps "Mulakan Umrah" (Tab 1 or DoaViewerScreen)
  → loc.startJourney()
  → _events.add(journeyStart event)
  → _isJourneyActive = true
  → GPS sampling begins
  → journey_track.json created/updated

User opens DoaViewerScreen for a journey step (ihram/tawaf/solat_tawaf/saie/tahallul)
  → loc.recordStepStart(stepId)
  → loc.logEvent(stepStart)

User reaches isCheckpoint: true doa in a round substep (tawaf/saie pusingan N)
  → Confirm dialog shown
  → If confirmed: prog.confirmRound(roundKey)
                  loc.logEvent(doaPlayed)
                  loc.logEvent(roundConfirmed)
                  loc.recordStepEnd(stepId)

User reaches isCheckpoint: true doa in a non-round special step (ihram/solat_tawaf/tahallul)
  → Confirm dialog shown
  → If confirmed: prog.confirmRound(stepCompletionKey)
                  loc.logEvent(doaPlayed)
                  loc.recordStepEnd(stepId, completed: true)

User taps "Tamatkan Umrah ini" (Tahallul step only)
  → Confirm dialog
  → loc.finalizeJourney()
      → _events.add(journeyEnd)
      → _isJourneyActive = false
      → snapshotJourney() captures all data
      → All internal state cleared
  → history.addOrUpdateJourney(record)
  → prog.clearProgress()
  → Navigate to JourneySummaryScreen

User taps "Batalkan Umrah" (any journey step except tahallul)
  → Confirm dialog
  → loc.snapshotAndClear(notes: 'Umrah tidak lengkap')
      → _events.add(journeyEnd)
      → _isJourneyActive = false
      → snapshotJourney(incomplete: true) captures data
      → All internal state cleared
  → history.addOrUpdateJourney(record)   ← completed: false
  → SnackBar shown; user stays on screen
```

---

## 6. DoaViewerScreen — 5 Persistent Button States

The persistent bottom button is shown only for the 5 journey steps:
`ihram`, `tawaf`, `solat_tawaf`, `saie`, `tahallul`.

| Condition | Button | Action |
|-----------|--------|--------|
| Journey not active (`!loc.isJourneyActive`) | `FilledButton` "Mulakan Umrah" (green) | `loc.startJourney()` + GPS warning if unavailable |
| Journey active, step ≠ `tahallul` | `OutlinedButton` "Batalkan Umrah" (red outline) | Confirmation dialog → `snapshotAndClear` |
| Journey active, step = `tahallul` | `FilledButton` "Tamatkan Umrah ini" (dark green) | Confirmation dialog → `finalizeJourney` → JourneySummaryScreen |

The same "Mulakan Umrah" button also appears in Tab 1 (Panduan Aliran) and is hidden once
`loc.isJourneyActive` becomes true.

---

## 7. Historical Bugs — Root Cause & Fix

### Bug 1 — No `stepStart` event logged
**Root cause:** `LocationProvider.startJourney()` only emitted a `journeyStart` event; individual
step entries were never recorded.
**Fix:** `DoaViewerScreen.initState` post-frame callback now calls `loc.recordStepStart(stepId)`
and `loc.logEvent(stepStart)` for the 5 journey steps when a journey is active.

### Bug 2 — `doaPlayed` event never fired
**Root cause:** Events were only logged from the old JourneyScreen button flow; `DoaViewerScreen`
had no event logging.
**Fix:** `_handleCheckpointForCurrentDoa()` now logs a `doaPlayed` event (with doaTitle) when the
user confirms a `isCheckpoint: true` doa, for both round substeps and special non-round steps.

### Bug 3 — `roundConfirmed` event never fired
**Root cause:** Same as Bug 2 — round confirmation in `_handleCheckpointForCurrentDoa()` only
updated `ProgressProvider` but never logged a journey event.
**Fix:** `_handleCheckpointForCurrentDoa()` now logs `roundConfirmed` with the round key (e.g.
`"tawaf_3"`) after `prog.confirmRound()`. Also logged in `_checkEnteringNewRound()` when the
user confirms the previous round on entering a new round.

### Bug 4 — `stepSummaries` always empty in saved records
**Root cause:** `LocationProvider.snapshotJourney()` always returned `stepSummaries: []`;
`recordStepStart`/`recordStepEnd` methods did not exist.
**Fix:** Added `Map<String, StepSummary> _stepSummaries` field to `LocationProvider`, plus
`recordStepStart()` / `recordStepEnd()` methods. `snapshotJourney()` now returns
`_stepSummaries.values.toList()`. `_stepSummaries` is cleared in both `finalizeJourney()` and
`snapshotAndClear()`.

### Bug 5 — No GPS warning before journey start
**Root cause:** `JourneyScreen._startJourney()` called `loc.startJourney()` without checking
GPS availability.
**Fix:** Both "Mulakan Umrah" buttons (Tab 1 and DoaViewerScreen) now check `loc.gpsAvailable`
and show a SnackBar warning if GPS is unavailable, while still allowing the journey to proceed.

### Bug 6 — `journeyEnd` event missing from `finalizeJourney()` / `snapshotAndClear()`
**Root cause:** `finalizeJourney()` delegated to `snapshotJourney()` without adding a
`journeyEnd` event first. The `endJourney()` method (unused in the finalize path) added the
event, but `finalizeJourney()` did not call it.
**Fix:** Both `finalizeJourney()` and `snapshotAndClear()` now add a `journeyEnd` event and set
`_isJourneyActive = false` before calling `snapshotJourney()`, ensuring `endTime` is captured
correctly and the event appears in every saved record.
