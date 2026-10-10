# Current cloud checkpoint · 2026-10-10

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

