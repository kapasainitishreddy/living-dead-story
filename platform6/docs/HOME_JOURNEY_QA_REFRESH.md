# Home and Journey verification refresh

Test-only follow-on to Relaxed Body commit 92ad100. Production story, model, art, audio, rig, save schemas and Journey implementation are unchanged.

The historical Home renderer expected Journey to be unavailable. In the implemented V1 build the real credits button is enabled; emitting it moved into the carriage before old apartment-node assertions. That produced 13 failures on both the prior Hero Warmth checkpoint and Relaxed Body checkpoint. Baseline logs are preserved with the Relaxed Body source.

The updated test retains all seated-body, pause/settings, two equal endings, cinematic completion/skip, apartment exploration and 2x text coverage. It asserts explicit optional entry after either ending, actual ten-destination board controls, campaign snapshot and file equality, separate exact Journey persistence, comfortable Return home, and restored apartment. The Journey fixture path is isolated before initialization. It also scrolls the first actual destination into the viewport and captures it.

Native Linux keyboard/mouse run: seed a completed sleep campaign into disposable isolated local save directories, activate Journey credits entry, pause/resume, walk to and interact with the physical board, scroll real destinations, Return home, Save and leave. Before/after campaign JSON bytes match. Native log has no errors. This is Linux Compatibility/Mesa llvmpipe acceptance only; no physical controller or other platforms claimed.

Independent review found no Critical or Important issues and inspected the initial 259-check native render run and representative ending/seat/credits/board pixels. The final extra first-destination scrolling check was added afterward to strengthen its minor evidence note. Final results and archive validation are recorded in the accompanying verification report.

Art remains intermediate. This checkpoint closes stale QA coverage; it does not claim new art or release readiness.
