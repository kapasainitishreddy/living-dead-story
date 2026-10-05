# Protagonist and Mira: first character milestone

2026-10-03. Worktree branch: feature/platform-six-character-milestone, based on 1a838ac. User-approved original painterly magical-realism production direction. This milestone replaces protagonist and Mira only; it does not claim the full campaign or final cast is complete.

## Accepted direction
Original stylized adult characters with defined face contours, readable eyes/brows, distinct hair/clothing silhouettes, skinned mesh rigs and blended idle/walk performance. Protagonist: midnight jacket, cream scarf, warm chestnut asymmetric hair. Mira: terracotta coat, teal underlayer, dark bob. Retain night station identity, existing authored chapter/audio/collision/save/accessibility. No franchise likenesses, paid resources, external downloads, publishing, Git push or browser login.

## Implementation responsibilities
1. Author reproducible original Blender mesh/armature sources and glTF assets
2. Integrate reusable Godot AnimationTree performer, restrained gaze/conversation, head/hand prop sockets and reduced-motion preferences
3. Test contract first, keep existing 402-check chapter suite green
4. Capture actual fixed-camera before/after station and passenger portraits/two-shots in Godot 4.6.3 Compatibility and a bounded animation proof
5. Inspect visual deformation, face visibility and prop placement; document unachieved production requirements honestly

## Baseline
All 402 existing checks pass: 191 model/save, 85 runtime world, 52 integration, 6 physics, 27 painterly station, 19 chapter enrichment, 15 sound/motion, 7 regression. Writable HOME/XDG directories are required for the shell container; default HOME causes an environment-only startup crash. Native renderer: Mesa llvmpipe (LLVM 19.1.7, 256 bits), OpenGL 4.5 Compatibility. This is software-renderer QA, not target hardware performance.

Actual before frames: evidence/characters/baseline/*.png. Renderer QA uses tests/character_rendered_qa.gd; portraits are actual gameplay-world character geometry under existing light, with a close-up QA camera and HUD hidden where needed. Concept images are not runtime evidence.

## Explicit production limits to assess
This initial idle/walk/turn/conversation stage is not a full authored sit/stand/special animation library, final anime illustration quality, or final seven-character cast. No target-GPU/mobile performance claim. Preserve neutral reward-equivalent Done/Not tonight and schema1 saves; schema2 and Chapter2 remain later milestones.

## Verified delivery checkpoint
Final original GLBs: 25 joints each; 1.7 m height; floor-aligned soles; normalized skin weights; protagonist 5,295 triangles, Mira 5,017. Contoured facial eye/brow/mouth bones; original 5 s idle and 1 s grounded walk. Calibrated reference speed 1.3165 m/s and bounded 3.2x time scaling preserve the existing 4.2 m/s gameplay speed. Finger silhouettes follow hand bones; fingers are not individually rigged. No root-motion/terrain IK or full running/sit/stand/special clip library.

Fresh default suite passes 470 checks: all existing 402 plus 68 actual imported-rig, skinning, looping, blend, turn, eye/head bounds, repeated gaze, blink, socket, preference, cadence and measured stance-foot/ankle-drift checks. Log: evidence/characters/tests-final.txt. The original Chapter1 progression/schema1/reward-equivalence suite is unchanged.

Final actual-runtime stills are in evidence/characters/runtime/. Fixed-camera before/after portrait comparison and an additional listening-aligned Mira view are supplied. Closed hair/scalp contour and shoulder seams were iteratively checked in the actual station/carriage; no asset studio render is used as runtime proof. 11.07 s proof video records idle, movement, stop, turn, listening, reduced motion, Mira gaze and camera socket. Offline 30 fps recording is not a gameplay framerate claim.

Performance: same stationary station camera, 1280x720 medium, 2x MSAA, shadows off, 5 s warmup and 60 s sample. Baseline median 192.3 ms/p95 230.707 ms (309 samples, 320 drawcalls,182,498 primitives); final median 182.975 ms/p95 218.258 ms (324 samples, 386 drawcalls,134,259 primitives). Observed p95 ratio 0.946 passes the <=1.10 content-cost gate; this is one software-llvmpipe pair, not a robust speedup or target hardware result. Repeatable-route/GPU/mobile performance remains unverified. The benchmark harness initially released two render resources too late at shutdown; waiting an additional render frame fixed it, verified in a separate verbose 1 s cleanup check. No gameplay/resource edits were needed for this harness cleanup.

Linux release export succeeded; its isolated 180-frame headless smoke exits 0 without errors/warnings. New unsigned Linux/source ZIPs, native stills, MP4 and PDF report live in delivery/character-milestone/. Prior delivery builds were left untouched. No Git push/public hosting/login/cloud sync occurred.

Remaining art/presentation work: finer low-poly face/hair/clothing finish, richer expressions, separate authored running/sit/stand/special motions, terrain foot-lock and better dialogue-shot composition. Existing accessible dialogue panel can obscure the actors during conversation. This checkpoint demonstrates a genuine original rigged-character upgrade; it is not final production art acceptance or a completed campaign.
