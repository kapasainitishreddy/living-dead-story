# Opening gameplay and animation checkpoint · 2026-10-10

Implemented in the saved cloud checkout on `platform6-opening-polish`, based exactly on `progress/platform6-opening-refresh-2026-10-05` at `6933a1961318e7521257f6c476116f1ffce620ce`. All seven campaign chapters, ten Journey destinations, story data, original assets and save schema are retained. Earlier milestone reports describe historical runs; this report records new runs.

## Changes

- A successful Start new journey reset clears the visible failed-save notice and warning state for every campaign chapter. Failed resets retain their warning and recoverable data.
- The carriage window lifts its latch before sliding open. The breakfast postcard lifts clear of the table, turns, and settles with the existing kettle-opening hint written on its reverse. Remembered interactions reopen settled, without replaying the gesture. Pause holds motion; Back and reduced motion settle it immediately. Save writes still happen before presentation.
- Stationary object views and a compact dialogue panel let the existing window and postcard share the frame with their text. Large text retains the broad scrolling panel. The player's camera orbit returns on dismissal; reduced motion keeps the exploration camera.
- Actual rendered inspection revealed a latch obscured by the carriage seat and a postcard beneath a cup. Their decorative staging is corrected; the paper boat sits above the finished sill and the obsolete breakfast prototype sphere is hidden. No interaction marker, collider or story consequence changes.
- A local touch layer offers a left thumbstick, right-side camera drag, Interact, Pause and Reset view. It appears automatically on mobile or the first touch; desktop controls remain available. Buttons have at least 64 logical pixels of height; dialogue choices have 52. Text scale updates the touch buttons. Independent fingers can move, look, select dialogue and scroll prose. Pause, routes and focus loss release held gestures. Emulated mouse events cannot double-trigger touch choices.
- Landscape canvas scaling is configured. This is input implementation and cloud coverage, not physical mobile acceptance.

## Fresh verification

Godot **4.6.3 Standard**, official `7d41c59c4`, Compatibility renderer. The complete `game/run_tests.sh` finished with exit **0**: clean editor import, **83 Godot test scripts and 7 Python check scripts**, with no Godot `ERROR:` or `SCRIPT ERROR:`. It includes save/load/reset and chapter-transition regressions across all chapters, migration/recovery, physics and all ten Journey destinations.

| Focused result from the final complete run | Checks | Failures |
| --- | ---: | ---: |
| Reset failed-save warning | 8 | 0 |
| Touch opening | 22 | 0 |
| Everyday motion | 19 | 0 |
| Full campaign | 4,849 | 0 |
| Campaign save failures | 436 | 0 |
| Opening story flow | 38 | 0 |
| Opening dialogue controls | 16 | 0 |
| Opening story regressions | 24 | 0 |
| Accessibility controls | 34 | 0 |
| Journey content/model/world/activity/runtime | 987 / 618 / 320 / 23 / 291 | 0 |

The reset test was first run against the original main script: **8 checks, 2 failures**, reproducing the stale HUD and campaign warnings after a successful disk reset. The patched version passes. Earlier full-suite attempts exposed a timing-dependent animation assertion and a real secondary-finger dialogue selection problem. The timing assertion now samples the tween deterministically; actual touch events select and scroll through the HUD, with modal opening checked immediately. Both problems are covered in the final passing suite. The earlier failing logs are retained beside the final log.

## Rendered evidence and playable checkpoint

The delivery folder `/workspace/platform6-delivery` contains:

- `evidence/full-suite.log`, `reset-before.log`, `reset-after.log` and the earlier full-suite attempts.
- `evidence/before/` and `evidence/after/`: original-baseline and current 1280×720 renderer captures. Current frames show touch exploration, latch lift, open window, postcard turn/reverse and reduced motion at 2× text. The capture script sets existing authored chapter fixtures, dispatches actual interactions and renders the game; it is not an independent human playthrough.
- `evidence/opening-polish.mp4`: 91 actual Godot movie frames at 24 fps, approximately 3.79 seconds. Cloud rendering is slower than realtime.
- `STILL-HERE-PLATFORM6.pck`: newly exported playable pack. Its 180-frame headless boot completed without errors; the pack also opened graphically on local X11 with Mesa llvmpipe. Scripted native X11 keyboard input walked to the original apartment exit, opened its dialogue and confirmed the roof transition; screenshots and the clean runtime log are retained. This checks the packaged keyboard path, not physical hardware or an independent human playthrough. `run.sh` requires Godot 4.6.3 Standard on PATH.
- Editable source archive, commit manifest and licence notices. Exact saved commit and hashes are recorded in the delivery manifest.

Matching standalone export templates are unavailable in this environment. Requests to official template download endpoints returned HTTP 403; no policy bypass was attempted. A new self-contained native executable is **not** supplied. Historical executable claims in earlier documents do not apply to this delivery.

## References and reuse

[Hotpot's directory](https://github.com/HotpotDesign/Game-Assets-And-Resources) was reviewed as a discovery resource; its links do not confer blanket commercial reuse rights. [Sakura Crossing](https://github.com/Kenton-GMI/sakura-crossing) was reviewed for warm light, selective outlines and everyday interaction pacing. Its Three.js source/procedural art is MIT; the bundled stock music is excluded. Existing MIT notices are retained. This checkpoint adds original Godot code/procedural presentation and uses the project's existing original art/music. No new external assets, purchases or stock music were included.

## Remaining limits

Physical Android/iOS touch, safe areas, cutouts, orientation changes, mobile export/signing, gamepads, Windows/macOS/Web runtime, hardware GPU performance and human audio listening remain unrun. Touch coverage uses injected Godot screen events at the project's logical resolution. Graphics evidence uses a software renderer, dummy audio and scripted fixtures. Original character/prop art remains an intermediate stylized milestone. No daily streak, health claim, telemetry or account system was added. No push, merge, publication or deployment was performed.
