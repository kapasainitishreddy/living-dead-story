# STILL HERE: PLATFORM 6

A warm, offline Godot game about a quiet night journey: an apartment at 3:17,
a yellow-umbrella stranger, Platform 6, a passenger with an unopened camera, a
moonlit overlook and breakfast on a night train. The tone is wholesome magical
realism. There are no streaks, scores against the player, absence penalties or
guilt mechanics.

## What's in this repository

- `platform6/game/` is the current Godot 4.6.3 project (Chapters One–Seven plus Journey Mode V1).
- `platform6/docs/` holds milestone, QA and art notes for the current game.
- `platform6/tools/` holds asset and regression helper scripts.
- `prototype/` is the original browser prototype, kept for history.
- `docs/archive/` holds the earlier "Living Dead" mystery concept documents
  (game design, research notes, roadmap and agent build prompts). They describe
  an older direction and **do not** describe the current game.

## Run

1. Install Godot 4.6.3 Standard from https://godotengine.org/download/
2. Import `platform6/game/project.godot` in the Project Manager and press F5,
   or run `godot --path platform6/game` from a terminal.

Controls, saves and chapter notes are in [`platform6/game/README.md`](platform6/game/README.md).

## Test

```sh
cd platform6/game && ./run_tests.sh
```

## Assets and privacy

Original Godot/Blender/SVG geometry and synthesized audio; see
`platform6/game/ASSET_LICENSES.md`. The game makes no network requests and uses
no accounts, analytics, camera, microphone or runtime AI.

## Not a health product

STILL HERE is a game. It is not therapy, treatment or a clinical tool and makes
no claims about mental-health outcomes. If you are struggling, please reach out
to someone you trust or a local support service.
