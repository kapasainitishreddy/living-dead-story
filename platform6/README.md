## November 18, 2026 · camera-aware little discoveries (source integrated; native verification pending)

**Vision:** In the warm single-player 3:17 journey, noticing the cup, postcard or small kindness in front of you should feel intentional. Turning the camera is a gentle way to settle overlapping prompts, not a precision aim challenge or a reward quota.

**Playable increment:** When two objects are similarly close, the actual player now lightly favors the one near the camera's horizontal forward direction. The preference is capped at 0.48 m of *selection score*; real 3.2 m interaction reach, existing 0.28 m stability margin, and E/A/touch action remain intact. A substantially closer object behind the player is still reachable. Prompt, selected object and natural head/eye glance remain a single focus, with no auto-camera turn, new settings/save keys or loss of reduced-motion access.

**Verification:** Added native player_interaction_focus.gd assertions for front/rear ties, camera turns, closer rear objects, action dispatch, reduced-motion targeting and the hard reach limit. Independent geometric score sweeps confirmed the bias bound and no out-of-range acquisition; source contracts and GitHub remote blob readback checked. **Godot import/native suite, actual 1× playthrough, controller/touch/Windows and human accessibility review were not run here** because the Godot executable and full checkout were unavailable. Next: run the platform6/game/run_tests.sh regression gate, rotate beside clustered objects while watching the focus prompt, and test a rear interaction without moving. This is not release sign-off.

## November 18, 2026 · grounded footsteps for unhurried wandering (source-integrated; native verification pending)

**Vision:** Ordinary walks between the 3:17 train, shared soup and optional imagination adventures should have gentle physical feedback, not a reward meter. Shoes only sound when they actually move across the ground.

**Playable increment:** Two distinct, original, local 100 ms cloth-and-sole sounds alternate according to *actual grounded displacement* after collision, not movement input. Running against a wall, being airborne, stopping, entering dialogue or pause resets the cadence instead of accumulating delayed sounds. One near-foot 3D sound source stays within 8 m, uses existing Master/Effects levels, and stops on mute or control lock. The minimum interval is 220 ms, with no camera shake, new save keys, service calls or downloaded samples. Reduced-motion retains audio without visual motion.

**Exact verification:** Added `tests/player_footsteps.gd` to the real Godot test runner, covering left/right sample generation, grounded steps, blocking walls, airborne travel, pause/dialogue, fresh resume, mute and reduced motion. Deterministic contact-policy calculations and source contracts were checked outside Godot. **Godot import/native tests, 1× audio/video playback, real controller/Windows and independent human feel review were not executed here** (engine and complete checkout unavailable). Next: `cd platform6/game && ./run_tests.sh`; listen at normal speed, start/stop and run into a wall, compare mix with rain/soup, then complete controller/accessibility and fresh-process review. This is not release approval.

## November 18, 2026 · touchable paper-market signs and rolling cart (source-integrated; native verification pending)

**Vision:** STILL HERE: PLATFORM 6 is a warm, unscored single-player 3:17 journey. The optional Supermarket of Small Heroes should make small imagined choices physically pleasant; real customers are safe and retain their agency.

**Playable improvement:** Each of the three large drawn market signs now accepts a direct mouse click or touch-to-mouse finger tap. Existing named keyboard/controller buttons remain available. Tapping follows the same reversible, locally saved activity, including changing your mind after completing the route. On the physical miniature board, all four uniquely named cart wheels roll according to actual forward/backward displacement, the three cardboard signs visibly tilt when selected, and a small flag stirs during the moving parade. Pause freezes the wheels; reduced motion settles the wheels and cart immediately. The original seven chapters, both endings, twelve Journey destinations, return choices and browser prototype are preserved.

**Exact verification:** 14 independent deterministic pointer-target/roll-wrap checks passed; extra native assertions were added to the existing Journey activity/world suites for direct presses, reversals, real wheel motion, pause and reduced motion. **Godot import, native suite execution, 1× audiovisual capture, physical touchscreen/controller and Windows/human playtesting were NOT performed** here because the full local checkout and Godot executable were unavailable. Next: `cd platform6/game && ./run_tests.sh`; click/tap signs in different orders, watch Jo's alternate route at 1×, test pause/reduced motion and reopen after a fresh launch. This is not a release sign-off.

## November 18, 2026 · tactile supermarket marker glides (source-integrated, native verification pending)

**Vision:** STILL HERE: PLATFORM 6 makes the ordinary rewarding to touch. The whimsical paper grocery cart should respond to each reversible marker like a physical toy rather than teleporting. Real shoppers are safe and retain their own agency; there are no real-world rescue tactics, time limits or compulsory tasks.

**Playable increment:** Turning a marker eases the physical cardboard cart from its actual currently shown position to the selected aisle over 0.42 seconds, even if a prior glide is interrupted. Lanterns react immediately. Pause freezes a half-completed movement; reduced-motion mode presents the settled still route and never replays a stale glide when switched back. Completion and Jo's slower demonstration still follow their original paths. All seven chapters, both endings, twelve Journey stops, saves and the old browser prototype remain unchanged.

**Exact verification:** Checked source anchors and the active branch baseline; independent deterministic motion calculations confirm no start jump, half-time smooth displacement, and exact endpoint settlement. Added native journey-world regression checks for successive markers, pause and reduced-motion toggles. **Godot import, native suite, 1× audiovisual footage, controller/Windows, and human playtesting remain unverified** because the engine and complete private checkout are unavailable here. Next: run the existing test runner in platform6/game, then watch rapid route reversals and Jo's demonstration at normal speed, including pause, reduced motion and revisit. Not a release sign-off.

## November 18, 2026 · supermarket paper-cart contact and route fidelity (source candidate)

**Vision:** The Supermarket of Small Heroes is playful make-believe that ends in ordinary care. Every paper sign should change where the little cart actually travels; finishing the arrangement should never jerk it across the table. Nothing asks players to perform a real rescue or rush.

**Changed:** All three reversible aisle markers now bend the animated cardboard cart smoothly toward their respective paper aisles, with the physical stop layout aligned to the routes. The third marker transitions from the existing partial arrangement into a continuous eased cart journey instead of restarting on the far left. Jo's optional demonstration follows all three lanes at the gentler original pace; the reduced-motion scene holds a center-lane still preview and retains each chosen marker lamp. Returning shopping-bag/basket choices, campaign endings, Journey saves and the Living Dead prototype remain unchanged. Native Godot world regression assertions now cover lane-specific geometry, zero-marker paths, the completion boundary, loop wrap, pause and reduced-motion route distinctions.

**Exact verification:** Six independent deterministic route-math checks passed (including three aisle centers, completion continuity, slower Jo continuation, smooth loop and still-mode distinction); source anchors and updated test expectations were checked. **Godot import, native tests, visual/audio capture, real controller/Windows and human playtesting were not run in this worker** because a complete Godot checkout and engine were unavailable. Next run `cd platform6/game && ./run_tests.sh`, then follow the market route through all marker orders and Jo's demonstration after both endings at 1×, including pause, reduced motion and fresh-process revisit. Not a release sign-off.

## November 18, 2026 · The Supermarket of Small Heroes (source-integrated; native playtesting pending)

**Vision:** STILL HERE: PLATFORM 6 is an original warm, single-player 3:17 journey where happiness lives in small things, not in mandatory tasks or a score. This optional whimsical grocery adventure is fictional make-believe, ending with an ordinary act of care. The actual customers are safe, have agency, and do not require rescue.

**Implemented in the Godot working branch:** A twelfth post-ending Journey stop featuring an independent shopkeeper's evening, Jo's imaginary paper-cart route across three large reversible aisle markers, an equally valid watch-Jo demonstration, a procedural walkable market, an animated cardboard cart, reduced-motion still presentation, and three authored story beats. Choices leave a spare paper bag, put a basket aside, or leave the place as found; the first two appear physically on a future visit. The existing separate Journey save schema is reused. Both endings, all seven original campaign chapters, the prior eleven Journey stops and the older browser prototype remain untouched. Catalog, activity, 3D-world, model and two-ending native regression assertions were extended.

**Exact verification:** Twelve destination records and the previous eleven authored records were checked structurally; authored game scripts/tests are source-integrated only. **Godot 4.6.3 compilation, native regressions, 1× visual/audio footage, real controller/Windows and independent human playtests were not run in this environment.** Next release-quality gate: run `cd platform6/game && ./run_tests.sh` in a complete Godot checkout, play the market after both endings, verify saved choice after fresh-process reopen, and inspect walking, paper route and reduced-motion modes. This is not a release claim.

## November 18, 2026 · optional hands-on soup stirring (source integrated)

**Touch follow-through:** The game's real on-screen Interact button is now visible and wired only during the optional Help stirring window; walk/look controls remain locked to the dinner close-up. The same gate owns E, controller A and touch. Added native finger-press/release assertions plus paused control availability. Source and timing checks passed; actual Godot execution is still unrun.


**Vision:** STILL HERE: PLATFORM 6 finds happiness in small things: gently helping Noor stir a pot should feel responsive and warm, not like a scored cooking challenge. The 3:17 journey, Mira's plans and all sit/watch choices stay intact.

**Implemented:** During the existing 4.5-second Night Kitchen **Help** gesture, up to three optional E/A/touch presses add distinct, short physical ladle circles, soup-surface turns and local soft stir sounds. A brief cooldown prevents holding the button from spamming. Automatic preparation continues with zero presses; soup is served identically, with no new save fields or rewards. Sit/watch do not ask for input. Pausing, skipping, finishing, and reduced motion settle safely. New actual-scene test `tests/kitchen_stir_input.gd` covers interaction, spoon/soup response, sounds, limits, pause and reduced motion.

**Verified this session:** GDScript source contracts, offline motion/timing calculations and exact GitHub tree/blob readback after the commit. **Not executed:** Godot 4.6.3 import/native regression, normal-speed visual/audio capture, controller/human testing. Next: run `cd platform6/game && ./run_tests.sh`, test E/A/touch during Help at 1×, and compare zero-press and three-press paths and fresh reopening. Do not call this a released build.

## November 18, 2026 · Night Kitchen original gesture foley (source integrated)

**Vision:** Small ordinary sounds should make stirring soup, scattering herbs, serving a bowl, tearing bread and passing cups feel intimate and rewarding, without a cooking score or mandatory task.

**Implemented:** Actual Kitchen gesture animation emits six authored one-shot cue types at motion thresholds. The existing audio director creates short original deterministic mono 16-bit sounds locally, caches them and honors Master/Effects mute. Optional help produces separate stirring, herb and serving cues; bread/cup/pepper get quieter contact cues. Pauses freeze gesture time; reduced-motion and forced completion avoid stacks of late sounds. Existing spoken captions, saved states and sit/watch choices remain intact. Kitchen sound and world tests now assert cue encoding, order, lifecycle and muting.

**Verified:** Source anchors and deterministic signal-envelope math inspected; exact private commit/blob readback is required. **Not executed:** Godot 4.6.3 import/native tests, 1x audible capture, physical controller and human evaluation. Next: run the native test suite, listen at normal speed to help/sit/watch, verify pause, reduced motion and zero Effects volume. This is not release signoff.

## November 18, 2026 · steady interaction focus between close discoveries (source integrated)

**Creative vision:** STILL HERE: PLATFORM 6 should make wandering, shared cooking and small kindnesses rewarding in themselves. When the player's cup, postcard and other nearby objects overlap, the interaction prompt and character glance should feel intentional rather than jitter with every tiny footstep.

**Implementation:** The actual player retains its nearest current live, in-range object until another comes at least 0.28 m closer. A decisive approach switches promptly; leaving the existing 3.2 m range, removing an object or queuing deletion clears stale focus. The same selected object feeds the E/A interaction, existing on-screen prompt and optional head/eye glance. Reduced-motion, camera, original movement speed, save schema and all eleven Journey destinations are unchanged. Added `tests/player_interaction_focus.gd` to the Godot test runner for close targets, interaction dispatch, switching, gaze and removal.

**Verified:** Source integration contracts and 9 deterministic proximity simulations, plus remote GitHub commit/blob readback. **Not executed:** Godot 4.6.3 import/test suite, normal-speed footage, physical controller or human evaluation—the engine and complete checkout are unavailable here. Next release-quality gate: `cd platform6/game && ./run_tests.sh`; then play the adjacent Night Kitchen/shelter prompts and E/A interactions at 1×, including reduced-motion settings. No release claim.

## November 17, 2026 · contextual walking discoveries (late Eastern, source-integrated)

**Vision:** A warm, single-player 3:17 story where wandering, little glances, cooking together and optional imaginary adventures lead naturally to small moments of care—not chores or a reward counter.

**Changed:** At close range, standing still by a real interactive object for 0.2 seconds lets the protagonist's existing animated eyes and head notice it. Moving, changing nearest object, opening dialogue/pause or switching to reduced motion immediately clears attention. The player's camera, walking physics and interaction trigger are untouched; seven chapters, existing eleven Journey stops, prior kitchen/shelter additions, local saves and the original browser prototype remain intact. Added an actual Godot rig/control regression `tests/player_nearby_attention.gd` to the native suite.

**Checks this session:** GitHub file/branch consistency, source integration anchors, offline timing and target-state simulations, and remote commit/blob readback. **Not yet run:** Godot 4.6.3 import and native test, 1x visual/audio footage, controller or independent human walking review, because the complete private checkout and Godot engine are unavailable in this worker. Next: `cd platform6/game && ./run_tests.sh`, then visually inspect closely spaced interactive targets, pause/reduced motion, and a fresh-process save route before calling this playtested. This is not a release.

## November 17, 2026 · shared soup preparation (source integration, Godot runtime pending)

**New playable choreography in the existing Night Kitchen:** Choosing to help rather than sit or watch now stirs the physical soup surface, brings a visible pinch of herbs down through the steam, and then carries the ladle to the player's waiting bowl. The three options remain equally valid, and helping does not create a score, new save field or a compulsory task. Added native scene assertions for stirring, ingredient visibility, serving and settled/reopened state. **Verification this run:** script anchor and math/path consistency checks, plus GitHub remote file and head readback; the actual Godot 4.6.3 suite, footage, controller and human review were **not run** because a native project checkout/engine is unavailable. Next: `cd platform6/game && ./run_tests.sh`, then watch all three dinner modes at 1x and verify pause/reopen. The 3:17 story, seven chapters and shelter quest remain intact. This is not a release.

## Overnight source integration · November 17, 2026

The optional shelter paper parade now guides each figure along a continuous route through its corresponding cardboard gate. Gate position affects its actual path; Jo demonstrates more slowly, and reduced-motion keeps an understandable still version. Static movement-math checks passed 5/5. Godot gameplay tests, video capture, Windows and physical controller tests are **not yet verified**. Original 3:17 story, prior ten Journey stops and local saves are unchanged. See [exact verification plan](game/README.md).

## Night development checkpoint · November 17, 2026

The post-ending optional animal-shelter stop now includes animated *cardboard* cat figures with reversible gates, a separate Jo demonstration and a stationary reduced-motion version. The genuine animals remain resting. Source and regression changes are on the existing private Godot branch; this addition still needs a real Godot import, gameplay and pause/resume capture. The seven-chapter story and earlier ten Journey stops remain intact. See [game status and test plan](game/README.md). No public release.

---
 
# Current cloud checkpoint · 2026-10-10

All seven campaign chapters and all ten Journey destinations now have a Sakura
Crossing-inspired illustrated graphics pass: matte cel shading, selective cool
outlines, original foliage and scenic dressing, physical destination signs and
a restrained static paper finish. Existing story, saves, painted art, animation,
touch controls and reduced motion are retained. See [the current graphics report](docs/ILLUSTRATED_GRAPHICS_2026-10-10.md)
for fresh verification and evidence. Run `game/project.godot` in Godot 4.6.3
Standard, or use the playable PCK with that engine. Earlier checkpoint claims
below describe historical runs.

---

## Opening polish checkpoint · 2026-10-10

The opening now includes touch exploration and dialogue controls, a staged window latch and postcard turn, readable object framing, and a regression-covered reset-warning fix. All seven campaign chapters and ten Journey destinations are preserved. See [the fresh checkpoint report](docs/OPENING_POLISH_2026-10-10.md) for tests, evidence and limits. Run `game/project.godot` with Godot 4.6.3 Standard; the current delivery supplies a playable PCK requiring that engine, plus editable source. Earlier export and verification reports below are historical.

---

# Current playable milestone · STILL HERE: authored campaign

The Godot game in game/ now includes Chapters One, Two (The Unfinished Fair) Three (A Sky That Fits Through the Door) Four (A Place Before a Task) Five (The Quiet Orchard) and Six (The Return Platform). Save-v1 migration, local fictional consequences, a configurable animated pond race and all authored fair routes are implemented. Chapter Seven (STILL HERE) closes this authored campaign milestone. See game/README.md and docs/HOME_MILESTONE.md for controls, verification and limits.

The older concept/browser materials below are historical planning, not a description of the current Godot story.

---

# STILL HERE — A Living Dead Story

> **A city has forgotten why it wants tomorrow. Find out why.**

**STILL HERE** is a cinematic mystery game concept in which everyone in a city remains physically alive but slowly loses the ability to want anything. The phenomenon is known as **The Living Dead**. The player investigates disappearing places, reconstructs human stories, restores mysterious **Threads**, and gradually changes the world through choices, puzzles, exploration, and optional tiny real-world actions.

The goal is to build a genuinely compelling game first. Wellbeing-oriented mechanics sit beneath the story and must never become guilt, surveillance, fake therapy, or unsupported clinical claims.

## Current status

This repository currently contains:

- a self-contained playable browser vertical slice
- the core narrative/game-design bible
- research-to-design notes
- an implementation roadmap
- a master Godot build prompt for continuing the production game

The browser prototype is **not** the final game architecture. The production direction is Godot 4, Android first, followed by iOS/desktop as appropriate.

## Play the current prototype

Open:

`prototype/index.html`

It has no external runtime dependencies. It currently demonstrates:

- Quiet City atmosphere
- the 3:17 / Platform 6 mystery
- adaptive tiny/small/full session choices
- optional real-world micro-actions
- a large in-game consequence for a tiny action
- local persistent Threads
- Sanctuary
- zero streak punishment
- a non-gamified help-now flow

## Read before building

1. [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md)
2. [`docs/RESEARCH_NOTES.md`](docs/RESEARCH_NOTES.md)
3. [`docs/ROADMAP.md`](docs/ROADMAP.md)
4. [`AGENT_BUILD_PROMPT.md`](AGENT_BUILD_PROMPT.md)

## Production direction

- **Engine:** Godot 4
- **Language:** GDScript by default
- **Primary target:** Android
- **Architecture:** offline-first, local saves, authored narrative data separated from systems
- **Visual target:** cinematic rain/fog/wet roads, reactive world restoration, strong environment storytelling
- **Safety target:** no streaks, no guilt mechanics, no crisis gamification, no unsupported therapeutic claims

## First real milestone

Build one exceptional 20–30 minute Chapter 1:

Apartment → glowing window → rainy city → Central Station → Platform 6 → Elias/conductor → puzzle → optional real-world action → train awakens → first Thread → Archivist clue → cliffhanger.

Do not build the infinite system before this chapter is genuinely fun and playtested.

## Important

This project explores wellbeing-oriented game design. It is **not** a clinically validated treatment and should not be marketed as one without appropriate research, safety review, and clinical evaluation.

