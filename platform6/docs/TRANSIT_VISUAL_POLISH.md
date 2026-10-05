# Chapter One carriage and moonlit shore presentation

## Scope and implementation

Original static geometry/material work in game/world/transit_presentation.gd, plus the editable original night illustration game/art/transit/night_view.svg. The existing project-authored apartment wood/plaster/cloth surfaces and station beveled-box geometry are reused. No paid service, downloaded asset, additional runtime dependency or external request is introduced.

Five carriage checkpoints share CarriageArt: passenger, shoreline, return_train, breakfast, complete. Three shore checkpoints share ShoreArt: overlook, camera_choice, optional_action. A narrow build-time hook is controlled by opening/presentation_enabled (default true); the false setting is only a visual fallback and preservation-test baseline.

### Changed scenic nodes

- CarriageArt/Upholstery: SeatCushions, SeatBacks, Armrests. Authored rounded-shell geometry replaces the ten seat cube visuals; original Seat bodies/colliders remain
- CarriageArt/Joinery: SeatFrames, SeatLegs, LowerWallPanels, WindowJambPanels, WindowFramesHorizontal, WindowFramesVertical, DeepWindowSills, CurtainFolds
- CarriageArt/CarriageWindowViews/NightViews: ten outward-facing illustrated night-sea views, original editable SVG
- CarriageArt/EndBulkheads: Walls, PassageDoors, DoorFrames, DoorHandles, PassageWindows. Both ends close visually at the unchanged original boundary collider locations
- CarriageArt/CeilingDetails: SoftVault, RoofCrossRibs, BrassLampBases, WarmLampShades
- CarriageArt/Floorboards: one batch with 84 boards
- ShoreArt/CurvedArch: continuous curved masonry opening at the original arch position/depth and 4.4-high envelope
- ShoreArt/LighthouseSilhouette: TaperedTower, StoneFoot, LanternBalcony, LanternRoof, LanternPosts, BalconyRim, TowerWindows. The original Lighthouse node and beacon remain in their canonical positions
- ShoreArt/ShoreRocks, ShorePebbles, ShoreGrass, WeatheredPaving: deterministic low-poly/painted details around the original floor and clear central approach

Existing carriage side/window/seat and shore pillar/span/lighthouse/boundary visuals are hidden where replaced; no canonical physical object is deleted. Existing transit local lights are restrained shadowless scenic fills. New scenery casts no shadows and adds no lights. Station, apartment, later chapters, story logic and saves are outside this pass.

## Verification and bounded cost

Test-first evidence lives under evidence/completion/transit/:

- red.txt: all eight checkpoint scenic-layer assertions failed before implementation; original collider/marker comparisons already passed
- roof-red.txt: the roof's intended interior face winding failed before correction
- bulkhead-red.txt: missing end-bulkhead assertions failed before end closure
- triangles-red.txt: instanced triangle budgets failed before tessellation reduction
- green.txt: 179 checks, zero failures after the full pass
- Original test_runner, runtime_smoke, sound_motion, chapter_enrichment and enrichment_regressions: 191, 85, 15, 19 and 7 checks respectively, zero failures

The contract compares all existing collider types, dimensions, transforms, names and disabled states across the visual fallback and new presentation for every affected checkpoint. It also compares exact spawn/story marker transforms, action IDs, values and labels. Added layers have no physics, markers, labels or processing. Mesh winding and the arch's unobstructed aperture/envelope are verified. The existing water shader source stays byte-identical; reduced motion still sets its motion_scale to zero and hides existing breakfast steam.

Final added-layer source metrics (not measured GPU draw calls):

| Layer | Descendant nodes (excludes art root) | Visible geometry submissions | Instanced triangles | Visual instances |
| --- | ---: | ---: | ---: | ---: |
| CarriageArt | 27 | 22 | 30,872 | 363 |
| ShoreArt | 13 | 12 | 16,344 | 271 |

Repeated objects use MultiMesh batches. The regression caps are 100 descendant nodes / 28 visible geometry submissions, with 45,000 carriage and 25,000 shore instanced triangles. Edge-biased upholstery samples, zero extra cylinder rings and a small bevel mesh for shallow paving reduced the earlier added geometry from 79,504 carriage / 80,736 shore triangles. These are source-level cost bounds; actual GPU time, draw counts, target-device thermals and memory have not been established by these tests.

## Limits

Matched parent-rendered before/after carriage and shore captures were inspected during the pass. Final end-bulkhead/tessellation captures and the complete consolidated campaign runner are coordinated by the main task. No claim of target-phone, physical-controller, accessibility-user, final environment-art or release acceptance is made by this bounded pass. The approach and landmark sightlines are preserved programmatically; visual puzzle alignment should also be accepted during the consolidated interactive QA.
