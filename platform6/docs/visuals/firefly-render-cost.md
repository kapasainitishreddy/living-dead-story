# Firefly rendering-cost checkpoint

## Bounded change

Only Firefly render submission changes: its 58 unshaded sphere fireflies now use one MultiMesh with the exact existing positions, random radii, material color and 8-segment/4-ring geometry. Existing invisible MeshInstance3D nodes remain animation/rest proxies, so journey_world retains its original motion, reduced-motion and pause behavior. The batch sync runs after world motion. No texture, foliage cutoff/transforms, terrain, sky, palette, path, lights, camera, collision, story, saves or quality presets changed. High remains available; no lower-detail default was introduced.

## Profiling and rejected approach

Native Godot 4.6.3 Compatibility, Mesa llvmpipe software renderer, 1180x812 viewport, original spawn/camera. Component ablation measured grass ~4–5 ms, canopies/sky each ~2–3 ms. Indexing grass preserved all pixels but did not establish a timing gain, so that candidate was reverted. The retained candidate targets avoidable draw submission rather than removing visual detail.

An alternating A-B-B-A native run uses 30 warmup frames followed by 300 uncapped rendered process-frame intervals per window. Captures occur outside samples. A shows original proxy meshes and hides the batch; B hides proxies and shows the batch. Reduced-motion stationary pose, same process/window/environment, same 111,278 rendered primitives. Both modes include the small batch-sync overhead, making baseline conservative.

| Window | Median wall ms | p95 wall ms | Process monitor ms | Draw calls |
|---|---:|---:|---:|---:|
| baseline A | 61.013 | 70.020 | 68.606 | 278 |
| optimized A | 56.240 | 64.990 | 64.254 | 221 |
| optimized B | 55.263 | 61.959 | 62.040 | 221 |
| baseline B | 59.242 | 66.122 | 63.852 | 278 |

Averaging window medians: 60.128 to 55.752 ms, approximately 7.3% less wall frame time in this run. Draw calls drop by 57, approximately 20.5%. Process monitor values include engine timing and are not GPU-only measurements. Results are software-renderer observations, not hardware FPS certification or proof that the older pre-art baseline has been restored. The original 15-frame QA timings are much shorter and should not be mixed with this controlled run; the later 15-frame gameplay QA overlapped aggregate testing and is not a performance comparison.

## Pixels and behavior

Exact fixed-camera A/B comparisons cover low, medium and high graphics, each at rest/reduced motion and at the same manually advanced animation pose. Five pairs contain zero changed RGB pixels across 958,160 pixels. High animated pose differs at one pixel from blue 132 to 131 (at x625,y468); all geometry, color settings and poses are unchanged. No appearance downgrade is claimed or required.

The original Firefly suite reports 43,643 checks; this checkpoint adds 292 and preserves every prior test command. Full aggregate suite completes with exit 0: 58 reported test summaries, 43,935 checks, zero failures, and no ERROR/SCRIPT ERROR output. Native graphical activity/story/pause/2x text/revisit matrix passes 31 checks. A separate normal-game native test verifies all batch transform origins match animated/rest proxies, plus paused transforms: 466 checks, zero failures and clean shutdown, including automatic rendered-frame ordering without a manual sync call. Dummy headless RenderingServer does not retain transform reads, so the aggregate version checks 292 meaningful state/submission invariants; actual transform reads are required on the native graphical run.

Exported Linux executable was exercised through keyboard/pointer UI: walk to board, E interaction, activity, story advances, three-point star-line choice, return to carriage, revisit Fireflies, normal quit, separate restart without reseeding and normal quit. Saved Firefly visit count 1 and star_line state survive; journey JSON and campaign JSON are semantically identical across restart. Campaign also equals the original completed-campaign fixture. All smoke saves are fresh isolated QA directories.

The first standalone-world graphical test harness exposed two texture teardown leak errors; replacing its construction/cleanup with the normal main-game lifecycle removed them. No production game teardown error occurred. Tests and captures fail on ERROR/SCRIPT ERROR even where Godot exits zero.

## Reproduce and limits

Run `sh game/run_tests.sh` with fresh writable HOME/XDG directories. Native graphics: `godot --audio-driver Dummy --path game --script tests/firefly_render_profile.gd`; `FIREFLY_QA_DIR` selects an absolute evidence directory. `FIREFLY_COMPARE_ONLY=1` skips the ABBA windows and captures the tier/motion matrix. Run `tests/firefly_rendered_qa.gd` for gameplay graphics and `tests/firefly_render_cost.gd` for batch state/transform contracts. Native runs require a real display, not headless. V-Sync unsupported warning is an existing software-driver limitation.

Stop here: measured draw-call reduction and bounded timing improvement are established without art redirection. GPU hardware/controller/audio hardware remain unverified, and further visual reduction awaits the user's art feedback.
