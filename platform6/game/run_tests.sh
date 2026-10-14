#!/bin/sh
set -eu
cd "$(dirname "$0")"
# A script can print a Godot error and still return zero. Reject both signals.
godot() {
    godot_log="$(mktemp "${TMPDIR:-/tmp}/platform6-godot-XXXXXX")"
    if command godot "$@" > "$godot_log" 2>&1; then godot_status=0; else godot_status=$?; fi
    cat "$godot_log"
    if grep -Eq '^ERROR:|^SCRIPT ERROR:' "$godot_log"; then godot_status=1; fi
    rm -f "$godot_log"
    return "$godot_status"
}
godot --headless --editor --path . --quit
godot --headless --path . --script tests/test_runner.gd
godot --headless --path . --script tests/runtime_smoke.gd
godot --headless --path . --script tests/integration.gd
godot --headless --path . --script tests/art_physics.gd

godot --headless --path . --script tests/painterly_station.gd
godot --headless --path . --script tests/chapter_enrichment.gd
godot --headless --path . --script tests/sound_motion.gd
godot --headless --path . --script tests/enrichment_regressions.gd

godot --headless --path . --script tests/character_performance.gd

godot --headless --path . --script tests/fair_model.gd
godot --headless --path . --script tests/fair_world_scene.gd
godot --headless --path . --script tests/fair_world_physics.gd
godot --headless --path . --script tests/fair_runtime.gd
godot --headless --path . --script tests/fair_sound.gd

godot --headless --path . --script tests/fair_branch_matrix.gd

godot --headless --path . --script tests/paper_model.gd
godot --headless --path . --script tests/paper_world_scene.gd
godot --headless --path . --script tests/paper_runtime.gd
godot --headless --path . --script tests/paper_reset.gd
godot --headless --path . --script tests/paper_world_physics.gd

metadata_log="${TMPDIR:-/tmp}/platform6-metadata-$$.txt"
godot --headless --path . --script tests/paper_interaction_metadata.gd > "$metadata_log" 2>&1
cat "$metadata_log"
! grep -q '^ERROR:' "$metadata_log"
godot --headless --path . --script tests/audio_shutdown.gd
godot --headless --path . --script tests/paper_shutdown_runtime.gd

godot --headless --path . --script tests/kitchen_model.gd
godot --headless --path . --script tests/kitchen_world_scene.gd
godot --headless --path . --script tests/kitchen_world_physics.gd
godot --headless --path . --script tests/kitchen_runtime.gd
godot --headless --path . --script tests/kitchen_save_failures.gd
godot --headless --path . --script tests/kitchen_sound.gd
godot --headless --path . --script tests/character_rest_pose.gd

godot --headless --path . --script tests/orchard_model.gd
godot --headless --path . --script tests/orchard_world_scene.gd
godot --headless --path . --script tests/orchard_world_physics.gd
godot --headless --path . --script tests/orchard_runtime.gd
godot --headless --path . --script tests/orchard_save_failures.gd
godot --headless --path . --script tests/orchard_sound.gd

# Chapter Six: original checks above remain unchanged.
godot --headless --path . --script tests/return_model.gd
godot --headless --path . --script tests/return_world_scene.gd
godot --headless --path . --script tests/return_world_animation.gd
godot --headless --path . --script tests/return_world_physics.gd
godot --headless --path . --script tests/return_world_farewells.gd
godot --headless --path . --script tests/return_runtime.gd
godot --headless --path . --script tests/return_save_failures.gd
godot --headless --path . --script tests/return_sound.gd

godot --headless --path . --script tests/return_reachability.gd

# Chapter Seven and the complete authored-campaign flow.
godot --headless --path . --script tests/home_model.gd
godot --headless --path . --script tests/home_world_scene.gd
godot --headless --path . --script tests/home_world_physics.gd
godot --headless --path . --script tests/home_runtime.gd
godot --headless --path . --script tests/home_save_failures.gd
godot --headless --path . --script tests/home_sound.gd
godot --headless --path . --script tests/full_campaign.gd
godot --headless --path . --script tests/campaign_save_failures.gd
godot --headless --path . --script tests/reset_save_warning.gd
godot --headless --path . --script tests/touch_opening.gd
godot --headless --path . --script tests/opening_everyday_motion.gd
godot --headless --path . --script tests/illustrated_graphics.gd

# Original character geometry and runtime-polish regressions.
python3 ../tools/test_authored_character_assets.py
python3 ../tools/test_character_polish.py
godot --headless --path . --script tests/character_motion_polish.gd
godot --headless --path . --script tests/supporting_conversation.gd

# Bounded authored Journey Mode V1, separate from campaign persistence.
godot --headless --path . --script tests/journey_pack.gd
godot --headless --path . --script tests/journey_model.gd
godot --headless --path . --script tests/journey_world.gd
godot --headless --path . --script tests/journey_activity.gd
godot --headless --path . --script tests/journey_runtime.gd

# Firefly-only scenic presentation preserves existing contracts.
godot --headless --path . --script tests/firefly_visual_contract.gd
godot --headless --path . --script tests/firefly_render_cost.gd

# Approved hero expression holds and immediate reduced-motion settling.
godot --headless --path . --script tests/hero_expression.gd

# Approved exported hero geometry regressions.
python3 ../tools/test_hero_warmth.py

# Relaxed body silhouette and imported-pose regressions.
godot --headless --path . --script tests/hero_body_pose.gd
python3 ../tools/test_hero_body.py

# Shared opening/home apartment presentation and preserved geometry contracts.
godot --headless --path . --script tests/opening_scene.gd

# Finished original cast, comfortable controls and transit presentation contracts.
python3 ../tools/test_supporting_character_assets.py
godot --headless --path . --script tests/supporting_cast.gd
godot --headless --path . --script tests/supporting_pause.gd
godot --headless --path . --script tests/supporting_journey.gd
godot --headless --path . --script tests/accessibility_controls.gd
godot --headless --path . --script tests/transit_presentation.gd

godot --headless --path . --script tests/supporting_cast_floor.gd

# Original painted roof/coast depth, budgets and exact opening contracts.
godot --headless --path . --script tests/opening_depth.gd
godot --headless --path . --script tests/opening_depth_mesh.gd

# Physical authored opening, remembered replies and native-input contracts.
godot --headless --path . --script tests/opening_story_flow.gd
godot --headless --path . --script tests/cat_companion.gd
godot --headless --path . --script tests/opening_dialogue_controls.gd
godot --headless --path . --script tests/opening_story_regressions.gd
godot --headless --path . --script tests/opening_tool_attachment.gd

# Consolidated opening music and player/world readability regressions.
python3 ../tools/test_opening_soundtrack.py
godot --headless --path . --script tests/opening_soundtrack.gd
godot --headless --path . --script tests/opening_camera_readability.gd
godot --headless --path . --script tests/opening_readability.gd
python3 ../tools/test_opening_depth_art.py
