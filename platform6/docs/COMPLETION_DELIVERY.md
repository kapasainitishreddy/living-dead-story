# STILL HERE: playable campaign delivery · 2026-10-05

## What this build contains

The existing seven authored campaign chapters and ten bounded Journey destinations remain playable. This pass replaces the visible primitive supporting bodies with five original, distinct skinned cast members (Ada, Noor, Rafi, conductor and Jo), preserving the protagonist/Mira assets. Background keepers/workers reuse the authored cast where appropriate; this is not a unique model for every named background person.

Every new body preserves the original 25-bone rig, floor-origin/+Z-forward/1.7 m contract, idle/walk clips and original source files. Chapter-owned serving, carrying and seated staging drives the real bones. Inherited blinks, gaze, listening/breathing and locomotion remain functional. Pause and live reduced-motion changes preserve seated poses. Meaningful props stay visible; retired primitive costume/body handles remain invisible compatibility pivots.

The carriage now has rounded upholstery, wood floorboards, window frames/curtains, a vaulted ceiling, lamps, painted night views and end bulkheads. The shore has a curved arch, tapered lighthouse, rocks, paving and vegetation. The original colliders, interaction markers, landmark ordering and water-motion contract remain intact. Added scenic layers are bounded at 22 carriage geometry submissions / 30,872 instanced triangles and 12 shore submissions / 16,344 triangles. Software-renderer counts are not target-device performance acceptance.

## Repaired regressions

- Chapters One–Four retain unsaved progress when Pause Quit or OS close encounters a failed write. Future-schema source bytes are not overwritten, successful retries preserve the exact in-memory choices, and camera/race/view notices no longer conceal the warning
- Settings labels/toggles/graphics and the private Future Echo date obey text scale, including live changes
- Supporting actors preserve Jo's paper-star prop, suppress duplicate primitive buns, receive nested Journey preferences, freeze during pause and immediately preserve seated bones during preference changes
- Cart-specific leg articulation keeps the actual skinned shoe soles above the existing deck while retaining the seat/root/colliders. CPU-skinned sole minimum 0.594867 m versus deck top 0.570000 m

## Verification

The exact final game/run_tests.sh runner exited 0 with no ERROR, SCRIPT ERROR or FAIL lines. Its audited summaries report 44,871 Godot checks across all 71 registered scripts and five Python exported-asset validation scripts. The suite includes the complete seven-chapter dispatch flow, 108 camera/optional-response/Home combinations, real save failures and all ten Journey destinations. Done and Not tonight remain exactly equivalent in permanent fictional rewards/access, and Mira retains Lower Mill autonomy.

Native screenshots and a short engine-rendered live-animation clip are supplied separately. They are scripted graphical inspection, not human playtest acceptance. A scripted native campaign/Journey route and a fresh Linux standalone smoke result are documented in their actual evidence logs; read those outcomes rather than assuming every proposed check passed.

## Run and save

Editable project: game/project.godot, Godot 4.6.3 Standard. Linux package: STILL-HERE-PLATFORM6.x86_64; no account, server or paid service is needed. The package is unsigned. Do not bypass OS security warnings. Existing local campaign/Journey save formats are retained; no network/device-access API was added.

## Limits that remain

This is a completed bounded playable-build pass, not a store-ready release or the full proposed 15–25-hour game. Character/environment art is still an original procedural indie interpretation, without terrain IK, a running clip or facial blendshapes. Supporting models retain 80–92 mesh nodes, so GPU/mobile profiling remains important. Physical controllers, mobile devices, Windows/Web/macOS runtimes, hardware-GPU performance, human audio listening and independent human playtesting have not been accepted here.

One cosmetic known issue remains: after an unwritable save followed by a successful Start new journey reset, the old warning can remain until the next successful save. The new apartment state is saved and the quit guard remains correct.

All new art is project-authored; original Blender/SVG sources, provenance and existing engine/reference licenses are included. No GitHub push, deployment, third-party asset download or paid generation was performed.
