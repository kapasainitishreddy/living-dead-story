# Current Chapter Seven QA

The current seven-chapter authored campaign milestone is documented in ../docs/HOME_QA_REPORT.md. Reports below describe historical milestones and are retained for provenance, not current release certification.

---

# Latest first-chapter enrichment QA — 3 October 2026

## Delivered scope
Original authored choices for the umbrella stranger and Mira, an optional paper-boat window observation, three replayable shared landmark discoveries with replies, and a breakfast postcard hint for the Unfinished Fair. Existing twelve checkpoints and schema v1 are unchanged. All three camera choices and Done/Not tonight have identical permanent outcomes. The fair is a story hint, not a built second chapter.

## Current verification
- Full clean-import/headless suite: 402 checks, zero failures (191 model/save/data, 85 world, 52 integration, 6 physics, 27 station, 19 enrichment, 15 sound/motion, 7 interruption regressions)
- Fresh independent whole-diff review completed. Its interrupted-dialogue, text-scale, guarded-marker, export-notice, fade/camera interruption and order-dependent-prose findings were reproduced and fixed with regression tests
- Actual Godot Compatibility renderer, cloud Mesa llvmpipe LLVM19.1.7, 1280×720: 24 enrichment checks and 52 integration checks pass. Final logs have no script/resource errors; the cloud driver reports unsupported V-Sync. Captures were inspected for dialogue/choice layout
- Exported Linux executable completed the full chapter through actual cloud-desktop keyboard input: umbrella question; control help and pause/resume; paper boat; quieter company; three landmarks; interrupted lighthouse reread and joke; unassisted framing3; Lend; Not tonight; breakfast postcard; souvenir. Saved snapshot confirms complete, all three landmarks, camera_choice lend, action_resolution skipped and platform_six_journey
- Linux standalone additionally passed 180 headless frames without errors. Windows, Linux and Web exports all built successfully; Windows/Web runtimes remain unverified
- Four distinct original 16-second rain-window/rain-roof/rails/surf stems load and crossfade with independent sound settings. Every stem plus original music has zero clipped samples. Audio output uses Dummy on this cloud desktop; human listening quality is unverified
- Source and executable packages include Godot and Sakura Crossing MIT notices. Sakura has no humanoid rigs; this is original Godot gait smoothing and environmental motion informed by its reference, not a port or parity claim

## Remaining limits
Provisional primitive characters, simple scenery outside the painterly station, no production art/animation-quality claim. The full 15–25-hour campaign and mobile version are not built. Physical-controller use, human audio listening, Windows/Web runtime, target GPU smoothness and human accessibility acceptance remain unverified. The cloud renderer is slow and is not a target-device performance result.

Local conversational replies are ephemeral and may repeat after reload; checkpoint/puzzle/camera/optional/completion choices are saved. Long prose scrolls while choices remain docked. Shorter screens can retain spare panel space after a larger screen; readability/progression are unaffected. No therapeutic outcome or play-duration claim is made.

The manual Linux QA interval ran approximately 05:48–05:53 UTC with cloud-tool screenshots and inspection pauses; this is not representative play duration.

## Historical QA notes
The following describes earlier source versions and is retained as history. The latest results above supersede earlier export/status limitations.

# QA report — October 3, 2026

## Verification environment
- Asta cloud Linux desktop, Godot 4.6.3 stable official
- Compatibility / OpenGL 4.5; desktop engine output reports Mesa llvmpipe LLVM 19.1.7 software rendering
- Desktop viewport 1280×720; keyboard/mouse actions through cloud desktop UI
- No physical gamepad was connected or tested

## Automated results
Post-review full suite: 186 model/save/data checks, 32 world checks, 42 runtime integration checks; all pass. Clean headless editor import and startup have zero final script/resource errors. Logs are retained in the local evidence folder outside this deliverable.

Coverage includes legal/rejected/repeated progression; six camera/action outcome combinations; identical permanent flags/souvenir; no absence decay; all twelve checkpoint roundtrips; missing/truncated/corrupt/future/malformed-schema saves; blocked writes and resets; reset backup retention; original authored data; collidable worlds/spawns; synthetic left/right-stick movement; camera obstruction; repeated transition creates one world; text scaling; optional choices docked outside scrolling prose; actual maximum-text puzzle button bounds; dedicated Menu pause restores dialogue choice focus, framed camera and movement gating.

## Interactive observations
An initial keyboard journey completed apartment → umbrella stranger → conductor → passenger → shore → puzzle assist → unopened camera → Not tonight → breakfast → chapter souvenir. Walking, E prompts, menu-arrow focus and Enter confirmation were observed. Dialogue cancel returned control. A new clean runtime resumed the saved completed chapter, and recoverable Start a new journey returned to the apartment.

Visual QA found and fixed coplanar carriage-floor flicker, rain appearing indoors, and maximum-text puzzle footer clipping. The separate review also found Menu was dismissing an active conversation; it now preserves pause context. Final reviewed-code visual checks passed at 1280×720 with low graphics, reduced motion and 2x text: enlarged puzzle Back button fully inside viewport; P pauses/restores the actual passenger conversation with its focused choice; arrival pause/resume retains the arrival; PageDown visibly scrolls camera prose; Done and Not tonight remain simultaneously visible. All three landmarks were inspected through actual WASD/E exploration, incorrect alignment was retried, and correct framing reached the camera scene without assist. Take photograph + Done then reached breakfast and the same chapter souvenir.

Representative actual viewport PNGs: apartment, umbrella roof, Platform 6 board, passenger carriage, moonlit overlook and breakfast. Additional evidence captures the maximum-text puzzle and optional-action choices. Each selected delivery PNG was opened and inspected after capture. Audio analysis found both original 32-second mono stems have zero clipped samples; this is a signal check, not a listening-quality pass.

## Unverified or limited
- Audio assets load and separate levels/mute are checked programmatically; human listening quality is unverified in this tool environment
- Physical controller button layout, deadzones on real devices, accessibility with a human tester and controller completion remain unverified
- No formal FPS/performance benchmark; desktop timed keyboard input was responsive, but software rendering is not representative target hardware
- No Windows/macOS/mobile export or standalone executable; matching export templates were not verified
- Original geometry and limb gait are intentionally simple prototype assets; no production animation/art quality claim
- Right-stick vertical pitch retains fixed sensitivity; the slider affects right-stick yaw and mouse look. This reviewed minor is deferred
- Small window sizes outside 1280×720 have not been accepted

## Duration
The initial route included active development and long QA pauses, so its elapsed time is not representative play duration. No 20-minute claim is made. The final camera-choice→optional Done→breakfast→souvenir segment took 95seconds of wall-clock QA time (03:04:40–03:06:15 UTC), including cloud UI calls and screenshot inspection. This is a measured checkpoint segment, not a whole-game duration. The earlier full-route sessions were interrupted by development/review, so no valid uninterrupted end-to-end human play-duration measurement is available.

## Station-first visual update (2026-10-03)
Original procedural art now includes structural canopy arches/panels, tiled
floor, cream/navy train with brass trim/windows/curtains/door, benches, plants,
yellow umbrella, distant architecture, and a rounded original character with
hair, eyes, coat, scarf, boots and satchel. It remains a low-poly prototype,
not Genshin Impact production quality or an exact rendering of the concept.

Actual Godot desktop station pixels inspected before and after, including a
manual forward walk toward the conductor. Avatar faces along the aisle and
turns toward movement; readable fixed board text avoids billboard clipping.
The shadow-enabled station preview measured 187 frames in 10.113 seconds,
about 18.49 average FPS on cloud Mesa llvmpipe software rendering. This is
not a target-device benchmark or proof of smooth frame rate. Existing low
and medium graphics disable shadows; high enables them. The final comparison
image uses the shadow-enabled preview camera at (-1,0.1,5), slightly angled.
The source still starts the complete playable chapter at its normal entrypoint.
Save/model/story/HUD data were not changed by this visual pass.

Final aggregate checks: 186 model/save/data + 80 world + 43 integration +
6 station physics = 315 pass. New visual structure, station ambient contrast,
fixed board lettering and initial avatar orientation had failing tests first.
Station physics verifies the main aisle, floor support, solid train hull and
bench collision. Physical controller, audio listening and exported executables
remain unverified, as in the original report.

Default medium (2x MSAA, shadows disabled) was also captured and inspected;
scene is readable and warm rather than black. It measured 106 frames in
10.111 seconds, about 10.48 FPS on this software renderer. The earlier
shadow-enabled preview used no MSAA and measured 18.49 FPS; these are different
settings and do not isolate shadow cost. Neither meets a smooth-frame-rate
acceptance on this cloud CPU renderer. A GPU target-device test is still needed.
Station wall and reachable structural columns now have solid collision,
verified with actual physics traversal regressions.

## Export/performance continuation (2026-10-03)

Official Godot 4.6.3 export templates downloaded from the vendor archive and
installed only in the task workspace. The downloaded archive SHA256 matches
the official GitHub release asset digest. Archive version/path validation
passed. Unsigned Web, Windows x86-64 and Linux x86-64 exports built without
errors. Linux executable headless 180-frame startup is clean. Windows runtime
is unverified; Web localhost runtime was blocked by cloud-browser extension
policy, not bypassed. Graphical standalone Linux is unverified.

322 floor tiles preserve their original transform, tone and roughness in
12 MultiMesh groups. Identical box geometry/materials share resources.
Same medium preset and camera short benchmark:10.426FPS before,10.838FPS after
on Mesa llvmpipe,1280×720, 2× MSAA, shadows disabled. About4% difference can include
noise and does not meet a smoothness acceptance. Art pixels inspected.
Right-stick pitch sensitivity now matches yaw/mouse scaling, verified with
synthetic controller input regression. No physical controller was connected.

Actual full keyboard route completed 04:27:36–04:33:20UTC (includes tool/read
and screenshot overhead): apartment→roof→station/conductor→passenger→shore,
all three landmarks, wrong framing retry then unassisted correct framing,
lend camera, Not tonight, breakfast, final souvenir. Passenger pause/resume kept
conversation and focus. A separate unique QA save left original save untouched.
Concrete QA fixes RED→GREEN: near-camera marker labels no longer obscure the
scene; successful transition clears obsolete retry prose before new save status.
Both were visually checked in a targeted real Godot scenario after fixing.

Sakura Crossing toon/post/outline sources were inspected read-only as a visual
reference. Its stepped hue-shifted lighting and extra ink/outline passes were
not copied or executed; no music/assets were imported. Additional outline/
postprocessing architecture is deferred pending scope and performance review.

Final suite:326 checks pass (186 model/save/authored data,85 world/resource/
transform checks,49 actual-runtime integration checks,6 station-physics checks).
The runtime integration now completes an unassisted/lend/skipped journey,
verifies ending UI and reloads the actual persisted completion. Transform
computation is tested in the pure helper used to populate MultiMesh; headless
RenderingServer transform getters return zero and cannot verify GPU buffers.
Actual before/after viewport pixels verify the rendered layout separately.

## Painterly station milestone (2026-10-03)

Station-only authored visual layer now includes an original 1024×512 surface
atlas, reusable opaque three-band lavender/cream material, full-face box UVs,
chamfered train visual, landscape travel posters, clock, quiet painted distant
facades and gradual ordinary depth fog. Original story, controls, interaction
markers, saves, collision transforms/classes/dimensions and other locations
are unchanged. Standard-material fallback is available with
station/painterly_enabled=false. Fragment lighting is explicitly retained.
Characters remain provisional procedural geometry; this is not a finished
anime-character or reference-quality art claim. No screen-space or inverted-hull
ink is shipped in this milestone. Existing spring arm and no-bob camera are
retained; there is no added automatic motion or reduced-motion bypass.

Fresh full run_tests.sh passes 353 headless checks: 186 model/save/data,
85 runtime world, 49 integration, 6 station physics and 27 station presentation.
The UV and Compatibility-albedo issues found by independent review were fixed
with failing checks first. The original smoke test's BoxMesh.size assumption
was updated to geometric bounds for the new ArrayMesh; extent checks remain.
Actual MultiMesh-transform assertions run only with a real display because
Godot's dummy headless RenderingServer returns identity for server reads.

Actual Compatibility shader compilation is clean. A rendered 94-check desktop
QA run passes low/medium/high settings, standard fallback and restoration,
60-second continuous orbit, actual W movement, E conductor dialogue and Enter
boarding to passenger. The initial QA looked in the wrong HUD container for
boarding; the choice was visibly present in the footer, and the corrected
harness confirms keyboard progression. High has strong patterned/diagonal
shadows, also present in fallback-high; the painterly floor makes their contrast
stronger. Medium is the preferred reviewed view. No UV swimming, flashing atlas
seams or fog jumps were observed on the inspected medium camera route/orbit.

Paired baseline/current measurements use identical 1280×720 medium settings,
MSAA2x, shadows disabled, Compatibility, fixed camera and wall-time-driven
repeatable route on llvmpipe. Each run warms up 12s, then collects 60s stationary
and60s moving. Screenshots are outside timed windows. Final stationary p95:
97.337→90.632ms (-6.9%), median 86.646→80.797ms; draw calls 369→326.
Moving p95: 91.134→86.927ms (-4.6%), median 80.113→76.536ms;
median draws 264→219. Primitives remain essentially unchanged. Both pass the
<=10% p95 regression gate. Average stationary frame rate 11.41→12.28FPS remains
slow software rendering; this does not establish a 30 FPS target-GPU gate.
The initially contended run was retained separately and excluded from the gate.
No platform exports were rebuilt or delivered in this source-only milestone.
Full pixel/raw-frame evidence is in the accompanying paired evidence folder.

Additional actual-display regression checks pass: runtime world 109/109
(including all 24 actual MultiMesh-transform checks), integration 49/49 and
station physics 6/6. These separately validate the real Compatibility runtime.
