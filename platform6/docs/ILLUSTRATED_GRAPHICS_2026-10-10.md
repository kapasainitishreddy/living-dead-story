# Whole-game illustrated graphics checkpoint · 2026-10-10

Implemented in the saved cloud checkout on `platform6-sakura-graphics`, based on the preserved opening-polish commit `452956c9c904f25c06aacb46518e71cf22ee68c1`. That checkpoint descends from the verified newer opening-refresh branch at `6933a1961318e7521257f6c476116f1ffce620ce`. All seven campaign chapters and ten existing Journey destinations remain playable. Story data, original assets, chapter rules and compatible saves are retained.

## Visual implementation

A shared presentation layer grades the actual existing worlds: matte cel shading, restrained cool selective outlines and a fixed paper finish. Opaque original materials are cloned independently; original textures, vertex colours, emission, transparent glass and custom station/water shaders are retained. Each world owns its new resources. Low graphics removes the outline second pass entirely and disables the grain. Medium uses 0.8 pixel ink, high uses 1 pixel ink; existing antialiasing, scaling and shadow settings still apply. Paper grading is below the HUD and touch layers, so prose and controls retain their authored colours.

All added scenery is static, collision-free and interaction-free. There is no animation loop, timer, streak or new save field. Existing window/postcard animation, idle acting, reduced motion, responsive locomotion and touch controls remain available. The established painted skies are preserved; previously flat backgrounds receive restrained horizon gradients without changing authored lighting energy. New radiance maps are 32×32 and detach explicitly when a world exits. This corrected a native GLES shutdown leak exposed by fast scene transitions during the first tour.

| Existing location | Original added presentation |
| --- | --- |
| Chapter One apartment / Chapter Seven Home | Countertop greenery, matte furniture and character contours; shared painted apartment retained |
| Roof | Peripheral pale blossom planters; original layered city and twilight panorama retained |
| Platform / Chapter Six Return Platform | Planters, bench/character contours and restrained cool shadows; station art retained |
| Carriage / breakfast / Journey train | Small greenery, selective joinery/character contours; existing window/postcard presentation retained |
| Moonlit overlook | Coastal grass; original painted coast and sky retained |
| Chapter Two Unfinished Fair | Peripheral blossom planters and shared matte colour treatment |
| Chapter Three Paper Sky | Greenery and shared illustration finish; authored paper/glass preserved |
| Chapter Four Night Kitchen | Herbs/greenery and outlined everyday furniture; warm supper staging retained |
| Chapter Five Quiet Orchard | Bare peripheral branches and grass; authored orchard canopy and observation paths retained |
| Rain Town | Pale blossom masses, layered hills, paving and physical destination sign |
| Unsent Letters Library | Potted leaves, wood floorboards and sign above the bookcase |
| Last-light Arcade | Potted leaves, matte cabinets and grounded destination sign; original checker floor retained |
| Beach Before Sunrise | Coastal grass, shore ribbons, hills and physical destination sign |
| Winter Orchard | Bare branches, root snow, hills and sign; no spring blossom added |
| Rest Room | Linen folds, greenery, floorboards around the original clear rug and wall sign |
| Failed Things Festival | Blossom, greenery, hills, paving and sign above the original bunting |
| Sunrise Cafe | Blossom, greenery, hills, paving and a fascia below the front awning |
| No-destination Road | Peripheral blossom masses, hills and physical destination sign |
| Fireflies at the Field Edge | Small grass accents and shared finish; authored detailed clearing and star sky preserved |

The added meshes stay below 11,000 triangles per world and use MultiMesh batches for repeated foliage, hills and floor pieces. This bounds added geometry; it is not hardware or mobile frame-rate acceptance. Existing scene complexity and selective outline draws remain substantial on the cloud software renderer.

## Fresh verification

The final complete `game/run_tests.sh` finished with exit **0**: clean editor import, **84 Godot test scripts and 7 Python check scripts**, with no `ERROR:`, `SCRIPT ERROR:` or failed assertions. This includes save/load/reset, migration/recovery, failed writes, chapter transitions, physics, all ten Journey activities and input/accessibility regressions.

| Focused result from the final full run | Checks | Failures |
| --- | ---: | ---: |
| Illustrated graphics across 23 world fixtures and tier changes | 3,079 | 0 |
| Successful reset clears stale failed-save warning | 8 | 0 |
| Touch movement, independent fingers, choices and prose | 22 | 0 |
| Opening window/postcard motion, pause and reduced motion | 19 | 0 |
| Full seven-chapter campaign | 4,849 | 0 |
| Campaign save failures | 436 | 0 |
| Accessibility controls | 34 | 0 |
| Journey content / model / world / activity / runtime | 987 / 618 / 320 / 23 / 291 | 0 |

The new graphics contract verifies added mesh budgets, independent material ownership, retained authored skies, collision/target preservation, unchanged model snapshots, tier switching without duplicated art, removal of low-tier ink draws, static reduced-motion scenery and explicit sky cleanup. Native rendered tours separately exercise GPU resource lifetime; headless assertions alone do not establish that.

The first complete suite passed before the final sign/sky cleanup refinement. Early capture attempts finished all locations but reported GLES cubemap allocations at shutdown. A no-sky diagnostic isolated this to the new skies; retaining authored panoramas reduced it, and explicitly detaching owned sky resources removed it in a complete native diagnostic tour. Those failed and diagnostic logs are retained. The final capture and suite are reported separately; earlier tests are not reused as fresh passes.

## Actual rendered evidence and playable checkpoint

Cloud delivery folder: `/workspace/platform6-graphics-delivery`. Its evidence uses Godot 4.6.3 Standard, official `7d41c59c4`, OpenGL Compatibility on Mesa 25.0.7 llvmpipe (LLVM 19.1.7). Render size is 1280×720, medium graphics. The comprehensive tour uses canonical model action sequences through all seven chapters, the Journey train and all ten destinations, then renders the real runtime. Reduced motion fixes the comparison camera and scenery. These are actual engine frames from a scripted walkthrough, not an independent human playthrough.

- `evidence/full-suite-final.log`: final complete passing suite; earlier attempts and diagnostics remain separate.
- `evidence/before/` and `evidence/final/`: matching baseline and final renderer screenshots of 23 world fixtures, plus the actual train-window interaction. Every final location frame was visually inspected.
- `evidence/illustrated-tour.mp4`: 611 actual Godot movie frames at 24 fps, **25.46 seconds**, held long enough to inspect each location. The native tour exited **0**, with no Godot errors or leaked texture messages.
- `evidence/opening-motion/` and `evidence/opening-motion.mp4`: a fresh native run of the existing opening capture on the final source, with touch exploration, latch lift, open window, postcard turn/reverse and reduced motion at 2× text. **91 frames / 3.79 seconds**, exit **0**, no Godot errors.
- `evidence/render-observations.json`: matching single-frame draw/triangle observations, including added ink draw cost. Largest new geometry budget: **10,872 triangles** in Rain Town. For example, the station changes from 298 to 320 visible draws; the orchard from 703 to 768. These observations include outline redraws and are not performance acceptance.
- `checkpoint/STILL-HERE-PLATFORM6.pck` and `checkpoint/run.sh`: newly exported playable pack. Pack export and 180-frame headless boot completed without Godot errors. `run.sh` requires official Godot 4.6.3 Standard on PATH. The native packaged keyboard path is recorded in `evidence/pack-native.log` and screenshots.
- Complete editable source, the saved-commit manifest, SHA-256 hashes and original licence notices accompany the checkpoint.

The exported pack also passed a fresh native X11 keyboard walkthrough: W moved
to the apartment door, E opened the existing choice and Enter reached the roof.
Reading the actual saved JSON confirmed `checkpoint_id: roof`; a fresh launch
using that save restored the roof. Both native sessions exited **0** with no
Godot errors. The external QA capture harness supplied isolated save paths and
screenshots; it did not advance the model or teleport the player.

The before images come from an isolated archive of exact commit `452956c9c904f25c06aacb46518e71cf22ee68c1` with the same capture fixtures and preferences. They do not replace fresh validation of the new source. Draw/triangle samples are frame observations, not a smoothness benchmark. Software rendering is slower than realtime; video time is the specified capture time, not observed hardware performance.

## Reference and reuse review

[Sakura Crossing](https://github.com/Kenton-GMI/sakura-crossing), its MIT license and `src/core/toon.js` were reviewed for stepped light, cool shadow tints, selective contours and pale painted foliage. The existing full MIT notice is retained. This pass is original Godot implementation and procedural art, with no copied Three.js code, stock music or imported third-party art. [Hotpot's directory](https://github.com/HotpotDesign/Game-Assets-And-Resources) does not grant blanket reuse permission; no directory asset was downloaded or included. The original project art/music and source notices are preserved; no purchase or paid generation was needed. See `game/ASSET_LICENSES.md`.

## Remaining limits and delivery status

This completes the requested whole-game illustrated pass as a saved playable milestone. The existing character meshes and compact Journey environments remain intermediate production art; this is not visual parity with the reference or a store-ready release. Physical Android/iOS touch, safe areas/cutouts, rotation, platform exports/signing, gamepads, Windows/macOS/Web runtime, hardware-GPU performance and human audio listening remain unrun. Synthetic touch/controller coverage and cloud renderer frames cannot establish physical-device acceptance.

Matching standalone export templates are unavailable in this environment; official endpoints returned HTTP 403. The playable pack requires Godot 4.6.3 Standard. Library delivery is separately blocked: the approved prepared upload helper failed at read-only connection discovery with tunnel HTTP 403, before any upload. Nothing was written to Library. No alternate endpoint, credential change or policy bypass was attempted. Cloud file paths are not claimed as successful user download delivery.

No push, merge, publication, deployment, security-setting or credential change was performed.
