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

