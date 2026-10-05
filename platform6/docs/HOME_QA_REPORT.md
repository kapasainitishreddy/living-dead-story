# Chapter Seven and authored-campaign QA

## Verified scope

Product revision: `6a1559bd6e72955cd9773c9b9beb17a262ee7c69` (Godot 4.6.3 Standard).

Chapters One–Seven are playable. Chapter Seven returns to the actual original apartment through shared geometry and shared ordinary props. Ticket placements (kettle/drawer/pocket), ordinary rituals (tea/seated window/neither), and both endings are remembered. TAKE THE TRAIN and GO BACK TO SLEEP both mark the campaign complete with identical prior rewards, fictional dimensions, NPC state and completion access. The ongoing JourneyPack/Journey Mode system is not implemented and is visibly unavailable.

## Automated acceptance

The final complete runner exited 0: **41,346 checks, zero failures**, with no ERROR or SCRIPT ERROR lines. Every earlier Chapter One–Six test script is retained; the fresh frozen six-chapter baseline had 29,831 checks. Existing generic cases expand with the additional neutral state, so the current total is not a simple sum of the old count and new tests.

Chapter Seven coverage includes:

- Model/save/trace compatibility and malformed input: 5,087 checks
- Exact shared apartment, physical saved choices and static seated rig: 225 checks
- World physics and interaction reachability: 164 checks
- Main/HUD integration, all 18 final-choice combinations, seated frame stability and accessibility: 425 checks
- Failed-save leave/pause Quit/OS-close protection: 14 checks
- Quiet music-free home sound profile: 7 checks
- Full authored-campaign integration: 4,849 checks, including genuine Chapters One–Seven dispatch, 18 real HUD final routes, 108 earlier camera/Done–Not tonight combinations, checkpoint interruptions, synthetic controller input, pause/skip, text scale and truthful unavailable continuation

Choices save before their physical presentation. Reopening accepted choices or completed endings never requires replay. Genuine sparse legacy saves retain explicit compatibility, while reordered, inconsistent and malformed traces reject atomically. The aggregate runner now rejects engine/script errors even when Godot itself returns zero; a deliberate zero-exit error fixture verified this guard.

## Native graphical acceptance

The final native Compatibility-renderer run used the exact frozen product revision: **223 checks, zero failures**, producing 37 viewport PNGs. It covers both normal-motion ending holds, skips, pause/resume, maximum-text controls/credits, disabled/no-op continuation, the actual seated original protagonist, every-bone freeze through paused text/reduced-motion settings, and one walking protagonist on return to exploration.

Pixel inspection found and corrected two seating defects: Godot re-enabled actor processing during scene entry and reset the pose on subsequent frames; the shared chair initially faced the wrong direction. Processing is now stopped after rig initialization, and the same chair in both visits supports the window-facing actor correctly. Final seated and paused screenshots were inspected after the corrections.

## Exported Linux keyboard/save acceptance

The unsigned Linux Desktop executable exported successfully and passed a separate 180-frame headless smoke. It was then run as its standalone binary on the cloud desktop with actual keyboard input, not through the editor:

1. Started from a strictly valid completed six-chapter journey with Mira's borrowed camera, Thanks farewell and Not tonight retained
2. Walked to the real labelled home interaction with W and opened it with E
3. Chose kettle + tea + TAKE THE TRAIN in one independent profile; drawer + seated window + GO BACK TO SLEEP in another
4. Paused each normal-motion ending with P, resumed, and let the quiet hold finish without skipping
5. Read the retained ending/credits and saved/left
6. Reopened each exact local save without reseeding, observed direct retained completion without replay, returned to the room and quit through pause

Actual desktop JSON files were copied, not reconstructed: **34 native-save checks, zero failures**. Both restore strictly, retain their distinct choices and all six earlier chapters, and have identical prior rewards, NPC autonomy, fictional dimensions, settings and legacy-compatibility state. Four native runtime/reopen logs contain no ERROR or SCRIPT ERROR lines. Eleven native standalone PNGs document the real input/reopen routes.

## Independent review and source recovery

Independent code and actual-pixel review of the frozen revision found **no remaining Critical or Important findings**. It reran the model/runtime/world/physics/durability/sound checks plus 166 hostile malformed snapshots and verified clean engine output. Earlier chronological-save, malformed-value and seating findings were corrected and retested.

Final compact-source acceptance is recorded alongside this report in `SOURCE_RECOVERY_VERIFICATION.txt` and `fresh-source-suite.txt`: a clean extraction must pass the same complete runner, and every archived entry must match both the frozen source and extracted files before and after testing. Editable `.blend` sources remain included. Generated `.godot` imports, executable packages and screenshot/log evidence are kept outside the compact source archive.

## Limits

This is a tested Chapter Seven/full authored-campaign-flow milestone, not production completion or store certification. Character and environment art remain intermediate. The cloud renderer is Mesa llvmpipe and audio driver is Dummy; this does not establish hardware-GPU performance or audible listening acceptance. Physical controller hardware, mobile, Windows/Web runtime, macOS export and full release balancing remain unverified. Synthetic controller checks do not establish hardware acceptance.

No paid assets, VPS, public hosting, GitHub push, account, analytics, runtime AI, device camera/microphone access, absence penalty or clinical claim was added. Done and Not tonight remain equally consequential and private from NPCs; Mira's Lower Mill life remains independent.
