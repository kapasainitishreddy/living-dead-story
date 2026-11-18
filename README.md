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

## Night development · November 17, 2026 (shelter route readability)

**New, source-integrated:** the paper cats now follow continuous eased loops *through their own three cardboard gates*, rather than jumping across the tabletop at the end of a straight-line run. Turning any gate visibly bends that figure's route; Jo's optional demonstration has a slower cadence. Reduced-motion players see a still mid-route pose reflecting the same gate choices, not a blank or misleading substitute. Real shelter cats remain resting; the local save format, authored ending and previous Journey stops do not change.

**Verification:** deterministic movement-math checks for movement, gate effect, wrap continuity and Jo's separate cadence passed offline. The existing Godot world regression now asserts gate-path difference, the non-teleporting loop, spectator cadence and the reduced-motion alternative, but **has not been executed in Godot on this run**. Neither 1x video nor a human/controller review was made. In a Godot 4.6.3 checkout run `cd platform6/game && ./run_tests.sh`, then watch the shelf in normal speed, pause/resume and fresh-process revisit. Next blocker: actual Godot import/runtime access. The heart of the game remains warm wandering and small acts of care, not chore rewards.

## Godot active development · 17 November 2026 (shelter interaction follow-through)

**Shelter Lantern Parade** now distinguishes your arranged paper route from watching Jo demonstrate. The small tabletop paper cats actually travel along the three lanes after either action, while real shelter cats stay resting; moving a gate resets the parade and lets you start again. Pausing freezes the figures, and reduced-motion mode shows a completed still tableau instead. The original 3:17 campaign, ten earlier Journey stops and separate offline saves remain unchanged. Godot execution of this increment is **not yet verified** in the current environment. See [the native README](platform6/game/README.md) for exact regression coverage and next live check.

**Vision:** a warm, single-player magical-realism journey where movement, animated everyday details, shared cooking and optional imaginary adventures lead to small acts of care, never a chore counter. Supermarket, college and detailed cooking adventures are not yet implemented.

## Godot active development · 17 November 2026

The optional **Shelter Lantern Parade** stop now joins the native Journey on the existing private Godot working branch. After either authored ending, walk into Jo's softly lit animal shelter, turn three reversible cardboard gates for an imaginary cat-freedom parade or watch Jo demonstrate, then leave fresh water, fold a resting towel, or leave the room as it was. Each response is welcome; real cats keep their freedom to choose. The original ten Journey places, seven-chapter 3:17 story and offline save format are preserved. This is source integration with static checks, **not a native Godot gameplay sign-off**; see [production README](platform6/game/README.md).

**Vision:** warm magical realism where small joys, walking and characterful animations, cooking together, friendship and gentle imaginary rescue adventures lead back to an ordinary helpful gesture, never a score or compulsory wellbeing chore. Cooking, college and supermarket quests are still future work.

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
