# Character and natural-motion polish checkpoint

This is a bounded improvement to the existing seven-chapter campaign. It preserves the protagonist/Mira identity, palette, 25-bone rig, 1.7 metre height, floor origin, idle/walk clip contract, local saves and authored story. It is not final character art or a new campaign chapter.

## Actual changes
- Smooth original cheek/jaw contours and shallow rounded noses replace the coarse face stations and wedge noses
- Larger smooth almond eyes retain the existing facial bones; an opened Mira fringe makes eyes/brows readable in the normal carriage camera
- Rounded crowns and smoothly interpolated original hair clumps replace pointed/angular crown transitions
- Mira's front coat and pockets are curved skinned cloth surfaces. Trouser contours nest inside the coat; the previous hip poke-through and fragmented pockets are resolved
- Varied 3.2–6 second quick-close/slow-open blinks, early eye fixation before head movement, held eye darts, restrained breathing/listening tilts/nods and faster start/stop settling replace uniform mechanical motion
- Immediate reduced-motion changes clear secondary eye motion; paused/seated/return staging keeps its existing ownership

All geometry/motion is original project work. No downloaded model, franchise likeness, paid asset, account or external service is introduced. Editable protagonist.blend, mira.blend and camera.blend remain in the source.

## Verified scope
The complete original runner reports 41,346 checks. The new motion suite adds 32 actual-rig checks; exported binary contracts verify both compatible rigs and the new geometry. Final worktree run: 41,378 reported checks, zero failures, exit 0 and no Godot/script errors.

Native graphical scripted staging: Night Kitchen 312/0, Return Platform 45/0, Home 223/0. These cover dinner routes/interruption, departure/skip and the actual seated window pose across pause/preferences. This is 580 graphical checks with 93 new chapter PNGs.

The exported Linux game was also operated with actual keyboard input: movement, pause/resume, interaction, ticket placement, window seating, seated pause, train ending, presentation skip, normal quit and reopening the same profile without reseeding. The saved schema-2 ticket=kettle, ritual=window, ending=train and completed=true remained exact through reopen. The separate delivery QA records fresh-archive recovery verification.

## Visual acceptance
Seven before/after runtime stills use the same camera/lighting. Matched films contain 727 frames each at 24 fps (30.29 seconds), with the protagonist in frame throughout both gait/start/stop passages and a 15-second Mira listening close-up. Independent pixel review approved this bounded pass: open/readable face, coherent coat, planted stop, clean blink reopening and stable camera attachment. The comparison movie is an actual native-runtime capture, not an AI-generated animation.

## Software-rendering benchmark only
Godot 4.6.3 Compatibility, Mesa llvmpipe software renderer, 1280×720, medium tier, fixed stationary station camera, 20 seconds each:
- Before: median 71.490 ms; p95 91.199 ms; 273 samples
- After: median 67.026 ms; p95 79.654 ms; 295 samples

These are environment observations, not an optimization claim or evidence of target GPU/mobile performance. CPU load and sampling variance apply. The movie recorder's GPU timing label also refers to this software renderer. Dummy audio does not establish audible mixing quality.

## Remaining limits
Character art remains intermediate. The camera grip is simplified, with relaxed fingers beneath a wrist-adjacent prop; a small neckline sliver remains. No terrain IK or dedicated running clip is added. Fast movement retains the prior calibrated speed-dependent gait cadence. Other cast members retain their existing intermediate art. Windows/Web/macOS/mobile runtime, physical controller, hearing and hardware GPU acceptance remain unverified. Journey Mode remains unavailable. Do not claim Genshin-level fidelity or production readiness.
