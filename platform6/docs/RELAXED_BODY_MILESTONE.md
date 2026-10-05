# Relaxed whole-body checkpoint · 2026-10-04

A bounded improvement to the same original protagonist and Mira, following the separate Hero Warmth checkpoint. Faces, story, supporting cast and environments were not redesigned.

## Visible changes

- Elbows and wrists now rest beside the body rather than maintaining a broad A-pose
- Sleeves follow deltoid fullness, a narrower elbow and a tapered forearm, with longitudinal rings supporting articulation
- The neck tapers and blends into the collar and jaw with distributed chest/neck/head weights
- Resting fingers and their crease geometry curl together
- The five-second idle uses a restrained pelvis/spine counterbalance, shoulder response and relaxed wrist/forearm posture
- Mira has a slightly-forward camera-carrying arm, keeping the same grip origin and camera geometry. Actual neutral camera bounds start 0.107 m in front of the actor; the camera no longer intersects the front coat at rest

All 25 bone names and parent relationships, Root behavior, 1.7 m height, +Z forward, floor-origin feet, normalized weights and five-second idle/one-second walk timing are retained. Arm rest transforms intentionally change; combined arm lengths remain close to baseline. Existing leg/stance cadence is retained. The previous checkpoint remains available for rollback.

## Verification

- Full headless suite: 43,960 checks, zero failures, including 15 actual imported-pose/arm-length/camera-clearance checks
- Original exported asset, prior hero warmth and new body geometry contracts pass
- Actual renderer: 45 Return Platform checks pass, including preparation/departure, pause, skip and camera-choice ownership routes
- Scoped body renderer: 22 checks pass with real close-up pixels for all five farewell poses, tool/strap adjustment, extreme camera slip/catch and the actual seated protagonist. Seated hands remain above the chair and outside the lap centre
- Real comparative animation: 727 frames at 24 fps, 30.29 seconds. It shows main-controller walking/stopping/turning, body-led idle, conversation gaze/blinks and reduced motion. The MP4 is visual-only
- Linux standalone verified with native movement, E interaction, Escape cancellation/repeat, quiet-company progression, pause, live reduced-motion setting, normal quit and save reopen. Eight checks validate the actual native save/reopened save, strict restore and unchanged full snapshot
- Fresh extracted source runs the complete suite; ZIP integrity and byte equivalence with the tested game/tools files are checked before delivery

## Failed historical QA and review limit

The historical home_rendered_qa.gd reports 13 failures on both this build and the unchanged prior Hero Warmth checkpoint. It assumes Journey Mode is unavailable and emits the now-enabled continuation button, then incorrectly searches for apartment nodes in the Journey world. The baseline reproduction is retained in evidence/body/home-baseline-rendered.txt. This is a stale auxiliary QA script, not a silently passed check. Working story code was not changed to satisfy obsolete expectations. Current campaign/Journey headless tests and the scoped seated-body renderer pass.

The independent reviewer confirmed a materially better relaxed silhouette and identified the camera intersection during development. Its final review turn failed due to model capacity and was not completed. Direct rig, socket, clearance, chapter-pose, save and runtime checks were completed independently; no final independent-review pass is claimed.

## Honest quality

This is a meaningful silhouette/pose improvement within intermediate original procedural art. Simplified hands/grip, cloth pinching at some armhole poses, toy-like facial anatomy and primitive carriage surroundings remain. There is no production-grade painted-anime or target-hardware performance claim. The original base was sufficient for this bounded improvement; replacing it with an external base would add retargeting, identity and licensing work without being necessary here.

No paid assets/services, VPS, deployment, GitHub push, analytics or new runtime network access. All seven chapters, ten Journey destinations, non-punitive outcomes, saves, NPC independence, offline privacy, original music and accessibility are preserved by the existing regression coverage. Only Linux software Compatibility rendering was exercised; physical controllers and other OS/mobile targets remain unverified in this pass.
