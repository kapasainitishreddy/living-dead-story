# Chapter enrichment Implementation Plan

Goal: enrich the approved existing first chapter with original choices, shared exploration, distinct sound and legible controls.
Architecture: retain ChapterModel and schema v1 unchanged. Authored local dialogue transitions are presentation-only and guarded by checkpoint; AudioDirector chooses original synthesized loops; Player keeps orbit stable in reduced motion.
Tech Stack: Godot 4.6.3, GDScript, JSON, Python synthesis
Spec: /workspace/shared/still-here-planning/2026-10-03-platform-six-design.md and research brief; user approved bounded implementation on 2026-10-03.

Global Constraints: preserve 12 checkpoints and old save compatibility; all camera/optional resolutions keep equal permanent outcomes; no clinical claims, paid assets, runtime AI or third-party music.
Review Focus: repeated/invalid dialogue navigation, Back/pause context restoration, large text choices, sound muting during crossfade, reduced-motion framing without snapping.

1. Authored branching dialogue and shared discovery
- Write failing enrichment tests for original dialogue branches, checkpoint legality, exploration objects and equal state on local replies
- Add JSON local branches, guard dispatch, meaningful landmark responses and optional train object inspection
- Run focused tests and complete global suite; commit
2. Location sound and camera/control comfort
- Write failing tests for location profiles, distinct streams, zero-level mute and stable reduced-motion frame
- Generate original rain/rails/surf loops, crossfade with two ambience players; preserve orbit for reduced motion, add control help
- Run focused tests and global suite; commit
3. Reference-based ambient animation, QA and delivery
- Inspect MIT Sakura animation reference; adapt bounded environment animation with attribution, testing first
- Actual Godot renderer QA of branches, pause/back, controls and route; capture evidence
- Independent whole-diff review, fix important findings with red/green tests
- Fresh suite, exports, source package, hashes and confirmed Library deliverables
