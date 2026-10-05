# JourneyPack v1: authored content contract

`game/data/journey_pack.json` contains the finite authored material for Journey Mode. Recombination chooses from this material; it does not generate dialogue, infer a player's wellbeing, or require a network service.

Both campaign endings use the same `campaign_complete` unlock. Destination availability has no calendar deadline, absence penalty, relationship decay, reward multiplier or paid gate. The eight emotional texture tags describe the writing, not a player assessment: `wistful`, `playful`, `tender`, `quiet`, `awe`, `bittersweet`, `hopeful`, `ordinary`.

## Root schema

- `pack_id`: stable string, `platform6_journeys_v1`
- `version`: integer, `1`
- `emotional_texture_tags`: the ordered eight-tag vocabulary above
- `content_policy`: explicit authored-only, local-scene, optional/untracked, no-absence-change, no-reward, no-clinical-claim and no-player-dependent-NPC declarations
- `npc_lives`: dictionary keyed by stable NPC IDs; entries contain `name`, `independent_life`, `current_work`, and `home_base`
- `destinations`: array of the ten destination objects below

## Destination schema

| Field | Type / meaning |
| --- | --- |
| `journey_id` | Stable destination string |
| `title` | Player-facing title |
| `location_scene` | Stable logical location ID; not a resource path |
| `scene_kind` | Unique visual vocabulary string |
| `palette` | Array of exactly three `#RRGGBB` strings |
| `available_time_states` | Nonempty subset of `dawn`, `day`, `dusk`, `night` |
| `weather_profile` | `{states: string[], intensity: number, wet_surfaces: bool, motion_optional: bool}` |
| `lighting_profile` | `{key: string, warmth: number, fog: number}` |
| `music_profile` | `{track: resource_path, gain_db: number, ambience: string}` |
| `required_flags` | `['campaign_complete']` for every destination |
| `excluded_flags` | Empty array for every destination |
| `possible_cast` | Nonempty array of `npc_lives` keys |
| `npc` | Authored primary speaker, a member of `possible_cast` |
| `story_theme_tags` | Authored motif strings, separate from emotional scores |
| `emotional_texture_tags` | Nonempty subset of the root writing-texture vocabulary |
| `activity_tags` | Activity ID plus `optional`, `reversible`, `unscored` |
| `activity_type` | One supported activity ID, listed below |
| `activity_prompt` | Authored activity instructions and the observation alternative |
| `entry_variants` | `{first: string, return: string}` |
| `story_nodes` | Array of exactly three authored scene-beat strings |
| `choice_nodes` | Three `{choice_id, label, response, state_id}` objects |
| `consequence_rules` | Matching `{choice_id, scope: 'destination', set_state, callback}` objects |
| `local_scene_states` | Dictionary of exactly three stable local-state IDs to authored return text; includes `as_found` |
| `returning_location_states` | Array of the three authored values from `local_scene_states` |
| `callback_pool` | `{camera: string, fair: string, sign: string, mira: string}` |
| `tiny_tomorrow_hooks` | One `{hook_id, text, optional: true}` object |
| `estimated_duration` | Integer minutes; guidance, never a timer |
| `accessibility_notes` | Array of actionable presentation requirements |
| `performance_tier` | `low` |

All narrative fields are plain authored strings. Choice IDs are globally unique (`journey.<destination>.<local_state>`). Store the local-state key rather than copying prose into a save. Its display text is available at `local_scene_states[key]`; `as_found` restores the unchanged scene. Rules do not modify campaign history, numeric emotional dimensions, access, NPC plans or rewards. Local modifications can be selected again without farmable effects.

Entries, beats, choices and callbacks are separate recombination layers. `return` means a previously visited location, not a required elapsed number of days. A callback may be displayed when the corresponding campaign memory is known. Camera fragments describe the shared first-shore memory without claiming that the player owns, opened or lent the camera, so each is compatible with all three camera choices. Mira fragments preserve her independently chosen Lower Mill life.

Tiny-tomorrow invitations are private, optional and untracked. Displaying or dismissing them must not set completion flags, change availability, award anything or request proof. Accessibility notes are implementation requirements, not an assertion that the data file implements controls by itself.

## Destination and activity inventory

| Destination ID | Scene kind | Activity | Primary cast |
| --- | --- | --- | --- |
| `rain_town` | `rain_lane` | `rain_routing` | Jo |
| `unsent_letters_library` | `letter_stacks` | `letter_arrangement` | Noor |
| `arcade` | `arcade_cabinet` | `arcade_paddle` | Ada |
| `beach_before_sunrise` | `tidal_dawn` | `constellation_tracing` | Mira |
| `winter_orchard` | `snow_orchard` | `observation` | Jo |
| `rest_room` | `quiet_lounge` | `tea_mixing` | Noor |
| `failed_things_festival` | `crooked_festival` | `letter_arrangement` | Ada |
| `sunrise_cafe` | `morning_cafe` | `tea_mixing` | Mira |
| `no_destination_road` | `open_road` | `observation` | Jo |
| `fireflies` | `lantern_meadow` | `constellation_tracing` | Noor |

The letter activity swaps adjacent public cards labelled STAMP, LETTER and ENVELOPE; sealed private letters stay shut. Tea mixing toggles amber leaf, mint and hibiscus. Fireflies are observation, never moving interaction targets. Three fixed numbered stars support sequential tracing and undo of the last point. The arcade uses left/right controls for a broad paddle, launch/new-rally and watch-demonstration alternatives, with no durable score or required win. Every destination has two local alternatives and a choice to leave the scene unchanged.

## Audio and verification

Profiles explicitly reuse the project's existing original synthesized ambience (`rain_roof`, `rain_window`, `fair_clockwork`, `surf`, `orchard_hush`, `kitchen_simmer`, `rails`). No new composition or unlicensed recording is claimed. All paths are checked against actual files.

Content validation is independent of the Journey model and world renderer:

```sh
godot --headless --path game --script tests/journey_pack.gd
```

The test first failed on the intentionally missing pack, then passed against the authored file. It checks the complete required schema, ten stable/distinct destinations, all supported activities, all eight textures, grounded named cast, three beats, revisit variants, choice/rule/state referential integrity, local-only consequences, optional invitations and existing audio resources. The full project suite remains `game/run_tests.sh`.
