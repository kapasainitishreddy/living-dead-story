# Apartment Reading Light · source checkpoint

2026-10-04. One bounded scene-presentation pass, shared by Chapter One and Chapter Seven.

## What changed

- Original painted wood/plaster/cloth surfaces and batched floorboards
- Framed rainy city-window, physical visual aperture with rain outside, curtains and a small plant
- Reading lamp, restrained wall/shelf/rug detail, layered bedding and original softly edged Blender table/pillow/duvet/throw
- Wood door with a small hall spill; close-range scene text yields to the interaction HUD
- Static material batches and vertex lighting. Medium apartment uses full resolution without MSAA; High keeps 2× MSAA. Apartment fill lights remain shadowless; other locations keep their previous graphics policy
- Home preserves authored lamp energy and the original proportional 20% sleep softening

No story/save identifiers, schema, reward rules, floorplan, collider, ordinary prop position or writing/privacy behavior changes. The same apartment is used on both visits. Done and Not tonight remain equivalent; both campaign endings remain valid. No network service, paid asset or downloaded third-party art was added.

## What was actually verified

- Clean baseline at the exact prior body + Home/Journey QA checkpoint: 43,960 counted headless assertions, plus original exported-model Python contracts
- Independently extracted final source ZIP: 44,036 counted headless assertions across 61 counter-producing fixtures, zero failures; exported-model Python contracts also passed
- Actual final Compatibility renderer: 14 opening/pause/text-scale/reduced-motion/exit checks, and 271 Home ending/seat/pause/settings/credits/Journey-return checks, zero failures
- Actual native W walking, E interaction, mouse choice confirmation, pause/settings, reduced-motion toggle, quit and reopen. The complete actual schema-2 save compared equal after reopen, with roof checkpoint and reduced motion retained
- Matched actual before/after screenshots and a silent 16-second staged visual clip. The clip uses real game movement and imported scenes at fixed 24fps; it is not a realtime FPS demonstration
- Independent source/pixel review found the Home light-reset bug; a failing regression reproduced it and the corrected proportional behavior passed. Static batches exclude all ordinary movable props; home tickets, tea/steam and seated rig remain separate
- Actual final opening and seated/return-home pixels were inspected

## Measured cloud renderer trade-offs

60 rendered frame intervals per tier, 1280×720, Mesa llvmpipe software renderer. This is a local comparison, not a device-performance guarantee.

| Tier | Before median ms | Final median ms | Final p95 ms | Final draw calls |
|---|---:|---:|---:|---:|
| low | 19.7 | 24.5 | 33.8 | 219 |
| medium | 29.9 | 24.5 | 27.8 | 219 |
| high | 102.5 | 45.9 | 54.9 | 219 |

Medium is faster in this measurement because the apartment's full-resolution painterly surfaces do not use MSAA. High no longer multiplies room-light shadow passes. Low is slightly slower than the simpler baseline. Art and visibility were retained while draw calls were reduced; these measurements do not establish 60fps acceptance on target devices.

## Files and remaining limits

- Open game/project.godot in Godot 4.6.3 Standard and run the project
- Original protagonist/Mira editable Blender files remain under game/assets/characters/*/source
- New furniture authoring source: game/art/apartment/source/apartment_furniture.blend. Original SVG textures and both authoring scripts are included
- Final screenshots/logs are under evidence/opening/final; proof media is delivered separately
- The apartment is more coherent and lived-in, but it is still stylized intermediate environment art. The broad empty floorplan, simple hanging coat/chair and other rooms/train still need further art direction. Test counts establish regression coverage, not beauty or shipping quality
- Physical controllers, hardware-GPU/target-device performance, mobile, Windows/Web/macOS runtimes and human audio acceptance remain unverified
- This is an editable-source checkpoint, with no new standalone package. Existing official 4.6.3 Linux export templates were not present at the checked current runtime locations; historical executables were not relabeled as this build
- Prior named checkpoints are preserved. No public push, deployment, purchase or external asset service was used
