# Master build prompt — STILL HERE / Living Dead

You are the lead game engineer, technical director, narrative-systems engineer, mobile performance engineer, and QA owner for this repository.

Your task is to turn this repo into a polished, playable game called **STILL HERE: A Living Dead Story**.

Read these files before changing code:

1. `README.md`
2. `docs/GAME_DESIGN.md`
3. `docs/RESEARCH_NOTES.md`
4. `docs/ROADMAP.md`
5. `prototype/index.html`

The existing browser prototype is a product proof, not the final engine architecture. Preserve it as a reference/demo while building the production version in **Godot 4**.

## North star

Build a cinematic mystery game compelling enough that players return because they need to know what happens next. The wellbeing mechanisms must sit underneath the game rather than turning the experience into a therapy worksheet.

The core promise is:

> **A city has forgotten why it wants tomorrow. Find out why.**

## Absolute product rules

- This is a game first.
- Do not create a happiness meter.
- Do not create streak loss.
- Do not punish absence.
- Do not make the companion sad because the player stopped opening the game.
- Do not require camera, GPS, health data, or proof that a real-world action was completed.
- Every real-world action must be optional and have a no-penalty Skip / Not tonight path.
- Do not put safety/support functionality behind a paywall.
- Do not make clinical efficacy or suicide-prevention claims in product copy.
- Do not let generative AI act as a therapist, diagnose a player, or generate crisis advice.
- If immediate danger is explicitly indicated, leave fictional progression and show a non-gamified support/safety flow.
- Keep sensitive Sanctuary data local-first and privacy-minimal by default.

## Technical target

Use **Godot 4.x** as the production engine.

Prioritize:
- Android first
- iOS second
- desktop build for development/playtesting
- offline-first gameplay
- no backend required for Chapter 1
- deterministic local save state
- clean architecture that can later support optional cloud sync

Use GDScript unless there is a strong measured reason to use C# for a specific subsystem.

Do not add a framework or dependency just because it is fashionable. Prefer Godot-native systems and small, inspectable code.

## Repository architecture

Create a production project under `game/` and keep the prototype under `prototype/`.

Recommended structure:

```text
game/
  project.godot
  autoload/
    game_state.gd
    save_manager.gd
    audio_manager.gd
    accessibility.gd
  scenes/
    bootstrap/
    apartment/
    quiet_city/
    central_station/
    platform_6/
    sanctuary/
    ui/
  systems/
    interaction/
    dialogue/
    quests/
    threads/
    story_director/
    real_world_actions/
    safety/
  data/
    dialogue/
    quests/
    threads/
    story/
  shaders/
  audio/
  art/
  tests/
```

Keep authored narrative data separate from scene scripts wherever practical.

## First deliverable

Do **not** attempt the infinite game first.

Build a polished 20–30 minute Chapter 1:

Apartment
→ glowing window
→ radio signal
→ rainy Quiet City
→ Central Station
→ hidden Platform 6
→ ticket/photo investigation
→ environmental puzzle
→ Elias/conductor interaction
→ optional tiny real-world action
→ train-power cinematic
→ first Thread
→ Archivist clue
→ cliffhanger

The build must be playable end-to-end before adding broad content.

## Chapter 1 quality bar

### Apartment
- immediate atmosphere within five seconds
- refrigerator hum / rain / distant city audio
- readable visual storytelling without exposition wall
- 3:17 AM motif
- one-window light event is unmistakable

### Quiet City
- cinematic rain and fog
- wet-road reflections or convincing approximation that performs on mobile
- strong silhouettes and landmarks
- environmental storytelling
- minimal HUD

### Platform 6
- impossible, slightly surreal spatial design
- departure boards reading UNKNOWN
- a glowing ticket interaction
- a missing-person photograph clue
- sound design that creates tension without horror-jump-scare dependence

### Real-world action integration
Offer choices scaled by player-selected capacity. Example actions:
- drink water
- walk to another room and back
- open a curtain / look outside
- stretch
- send a low-pressure message
- skip

Never request proof.

If completed, trigger an outsized game response:
- sequential train lights
- heavy sound-design hit
- environment color shift
- particles/reflections
- train movement
- new musical layer

If skipped, the story must still continue through an alternate in-world solution with no shaming and no reduced narrative access.

### End beat
The conductor says:

> “The dead aren't losing their reasons. Someone is taking them.”

End on a strong visual/audio cliffhanger.

## Thread system

Implement Threads as flexible authored categories, not an explicit psychological score.

Initial categories:
- wonder
- bond
- making
- becoming
- experience
- duty
- defiance
- mastery
- care
- rest

Track which choices have been associated with categories, but keep the raw scoring invisible to players.

Expose the player's history visually in Sanctuary/Constellation rather than as a bar chart.

## Story Director

For Chapter 1, implement only the minimum deterministic version needed to select:
- session size: tiny / small / full
- optional action pool
- unresolved story beat
- Thread association

Design the interfaces so this can later grow into a richer authored Story Director.

Do not introduce an LLM dependency for Chapter 1.

## Save system

Implement:
- versioned schema
- atomic writes
- safe default state
- graceful migration path
- current story node
- completed story beats
- Threads discovered
- world restoration flags
- settings/accessibility
- optional action history without invasive tracking

Absence must never decay progress.

## Visual engineering

Create a reusable environment stack for:
- rain
- fog
- puddle / wet-ground response
- window emissives
- subtle bloom/glow treatment
- animated signage
- color-restoration parameter
- wind / debris particles
- cinematic camera transitions

Use performant approximations on mobile. Build quality presets rather than assuming flagship hardware.

Use open-source / permissively licensed placeholder assets where useful, but maintain `ASSET_LICENSES.md` containing for every external asset:
- asset name
- source URL
- author
- license
- modification notes
- exact file paths where used

Do not import an asset if the license is unclear.

## Audio

Treat audio as a primary system, not polish added at the end.

Support dynamic layers:
- rain
- distant trains
- electrical hum
- interior room tone
- footsteps
- wind
- UI/transitions
- music stems

World restoration should be able to add musical stems over time.

## Accessibility

From the first playable build include:
- subtitles
- text-size setting
- master/music/SFX sliders
- reduced-motion toggle
- camera sensitivity if relevant
- screen shake toggle
- high-contrast interaction cue option
- remappable or abstracted inputs where Godot/mobile allows

Avoid relying on color alone to communicate objectives.

## Safety implementation

Keep the help/support flow isolated from reward systems.

No XP, achievements, streaks, collectibles, celebratory animation, or narrative unlock should be attached to opening or using crisis/support tools.

For the prototype, U.S. 988/911 may appear as placeholders. Production must localize resources rather than assuming the player is in the United States.

Do not infer suicidality from gameplay choices. Only invoke the emergency-support flow when the user explicitly requests help or a dedicated safety interaction is activated.

## Testing

Create automated tests where they provide value, especially for:
- save migration
- Thread persistence
- quest state transitions
- skip paths
- story progression
- no progress loss after absence
- safety-flow isolation from rewards

Also maintain a manual `PLAYTEST_CHECKLIST.md` for visual/audio/story issues that automated tests cannot judge.

## Performance budget

Establish a measured target for mid-range Android hardware.

At minimum monitor:
- frame rate
- frame-time spikes
- scene load time
- memory
- shader compilation stalls
- overdraw / transparent particles
- battery-heavy effects

Do not trade basic playability for cinematic effects. Create quality tiers.

## Working style

Work in vertical slices.

For every meaningful milestone:
1. inspect current repo/state
2. implement the smallest complete slice
3. run available tests
4. verify the scene/flow manually if tools allow
5. fix regressions before expanding scope
6. update docs/ROADMAP.md honestly
7. document assets/licenses
8. commit with a specific message

Do not claim something is finished unless it is actually implemented and tested.

If an art/audio asset required for polish cannot be created in the current environment, use a legally safe placeholder and document exactly what needs replacement. Do not block core gameplay on perfect final art.

## Definition of done for the first major milestone

Chapter 1 is done when a new player can install/open the build and complete the entire flow without developer intervention, and all of these are true:

- story is understandable without external explanation
- gameplay has real exploration and interaction, not only dialogue cards
- visual atmosphere feels intentional
- optional real-world action has a non-punitive skip path
- save/restore works
- the player can leave and return without losing progress
- no critical errors occur on target Android hardware
- accessibility basics exist
- the final line/cliffhanger lands correctly
- playtest build can be exported

Then stop feature expansion and run real playtests before building the rest of the city.

## Immediate next action

Start by creating the Godot project and implementing the smallest end-to-end skeleton of Chapter 1 with primitive geometry and placeholder audio. Prioritize interaction, story state, save/load, and the complete narrative flow first. Once the skeleton is playable, replace it scene by scene with cinematic environments and final-ish presentation.
