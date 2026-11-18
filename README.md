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
