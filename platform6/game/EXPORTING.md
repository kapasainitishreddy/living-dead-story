# Illustrated graphics cloud checkpoint (2026-10-10)

The current checkpoint covers all seven chapters and ten Journey destinations.
Run `godot --main-pack STILL-HERE-PLATFORM6.pck` with Godot 4.6.3 Standard,
or open the editable `platform6/game/project.godot` and press F5.
The PCK accompanies editable source and renderer evidence in the cloud delivery
folder. Matching standalone templates remain unavailable (official requests
returned HTTP 403); no new self-contained executable or mobile export is supplied.
See [current validation and limits](../docs/ILLUSTRATED_GRAPHICS_2026-10-10.md).
Local cloud files have not been uploaded to the user's Library: its prepared
upload connection returned HTTP 403 before any write. No download delivery is
claimed. Earlier package notes below are historical.

---

# Opening polish cloud checkpoint (2026-10-10)

The current delivery provides `STILL-HERE-PLATFORM6.pck`, `run.sh` and editable source. Install Godot 4.6.3 Standard and run `godot --main-pack STILL-HERE-PLATFORM6.pck`, or open the source project at `platform6/game/project.godot`. The newly exported pack passed 180 headless boot frames and opened on the cloud X11 Compatibility renderer. Matching standalone templates are unavailable; official download requests returned HTTP 403. No new self-contained executable or mobile export is supplied. See [the fresh checkpoint report](../docs/OPENING_POLISH_2026-10-10.md). All earlier delivery notes below are historical.

---

# Opening refresh delivery (2026-10-05)

The accompanying unsigned Linux x86-64 standalone contains the current opening refresh. Godot’s supported custom-template exporter used the SHA-256-verified Godot 4.6.3 runtime from the prior delivered Linux package. Fresh matching-template storage was unavailable. The original export presets are retained with empty custom-template paths; the temporary export path is not shipped. The newly embedded pack passed 180 headless boot frames and native apartment, roof, dialogue and station checks.

See ../docs/OPENING_REFRESH_2026-10-05.md and BUILD_INFO.json in the archive root for actual verification and remaining limits. Windows/Web/macOS exports are not newly built or verified. The abandoned external --main-pack wrapper is not part of this delivery. Historical notes follow.

---

# Current completion delivery (2026-10-05)

A fresh unsigned Linux x86-64 standalone was exported using the existing matching official Godot 4.6.3.stable templates. Editable source retains all export presets. Only Linux is newly built in this delivery; historical Windows/Web packages below are not current. See ../docs/COMPLETION_DELIVERY.md and the supplied validation report for exact tested outcomes and limits.

---

# Apartment art source checkpoint (2026-10-04)

This checkpoint supplies complete editable source and native-rendered proof media. Run game/project.godot with Godot 4.6.3 Standard. No newly built standalone is included: matching existing official export templates were unavailable in this runtime. Earlier binary-package claims below describe historical milestones. See ../docs/APARTMENT_ART_MILESTONE.md for exact verification and limits.

---

# Chapter Seven current delivery

The STILL HERE authored-campaign milestone supplies a Linux Desktop standalone archive plus complete compact editable source. Earlier Windows/Web packages are historical and were not newly runtime-verified. See ../docs/HOME_QA_REPORT.md for current acceptance evidence and limits. These are unsigned intermediate-art milestones, not store releases.

---

## Historical delivery notes

# Chapter Six current delivery

The Return Platform milestone supplies a Linux Desktop standalone archive plus the complete editable source. Windows/Web packages documented below belong to earlier milestones; they were not newly runtime-verified for Chapter Six. See ../docs/RETURN_QA_REPORT.md for current acceptance evidence and limits.

---

# Chapter Four milestone exports

Current packages implement Chapters One–Four. Chapters Five–Seven remain unavailable. Source ZIP contains an editable project at game/project.godot; QA screenshots and logs are separate so editable source stays compact. Linux runtime is verified; Windows and Web runtime, mobile, physical controllers, audio listening and hardware-GPU performance remain unverified. The packages are unsigned milestones, not store releases.

See ../docs/KITCHEN_MILESTONE.md for current tests, recovery provenance and limits. Use the existing commands below with Godot 4.6.3 Standard and matching official export templates.

---

## Historical export notes

# Export and run PLATFORM 6

This is the complete **first-chapter prototype** in Godot 4.6.3. The station
has a visual pass; the other locations still use simpler prototype scenery.
It is not the complete planned multi-chapter game.

## Already-built files

- `STILL-HERE-PLATFORM6-Windows.zip`: unsigned Windows x86-64 executable
- `STILL-HERE-PLATFORM6-Linux.zip`: Linux x86-64 executable
- `STILL-HERE-PLATFORM6-Web.zip`: single-threaded browser export
- `STILL-HERE-PLATFORM6-source.zip`: editable Godot project

All three packages now contain the painterly station plus the enriched first chapter, sound and control changes. Linux's exported executable completed the full route through actual keyboard input on the cloud desktop, including all landmarks, unassisted puzzle, Lend + Not tonight, fair postcard and souvenir. It also passed 180 headless frames. Windows and Web exports built without errors, but their runtimes remain unverified. The cloud browser's earlier localhost test was blocked; its policy was not bypassed.

Each archive contains README/QA instructions and Godot/Sakura Crossing licence notices. The source ZIP is the editable project at its root folder STILL-HERE-PLATFORM6. All builds remain unsigned prototypes. No paid service, VPS or account is needed.

## Export again in Godot

1. Install/open **Godot 4.6.3 Standard** and import `project.godot`
2. Editor → Manage Export Templates → install the matching **4.6.3.stable**
   templates from the [official archive](https://godotengine.org/download/archive/4.6.3-stable/)
3. Project → Export → choose the included Web, Windows Desktop or Linux
   Desktop preset, choose your output folder, then Export Project

No C#/.NET, paid service, account keys or additional SDK was needed for
these three unsigned exports. For command-line builds:

    godot --headless --path /path/to/project --export-release "Web" /output/web/index.html
    godot --headless --path /path/to/project --export-release "Windows Desktop" /output/windows/STILL-HERE-PLATFORM6.exe
    godot --headless --path /path/to/project --export-release "Linux Desktop" /output/linux/STILL-HERE-PLATFORM6.x86_64

Do not sign/publish these builds as store-ready without platform testing.
If an operating-system warning blocks the unsigned executable, do not
bypass it; verify the supplied hash or build from the source yourself.

## Browser build

Keep every exported file together and keep the `index.*` names. Serve the
unzipped folder over HTTP rather than double-clicking `index.html`. On your
own development computer, for example:

    python3 -m http.server 8000 --bind 127.0.0.1 --directory /path/to/web-export

Open `http://127.0.0.1:8000/index.html` in a browser supporting WebAssembly
and WebGL 2.0. Click/focus the game before playing. Audio may need a user
interaction before playback. Browser save persistence, controller and audio
behavior still need browser-specific testing.

## Controls and testing limits

WASD/arrows move, mouse/right stick orbit, E/controller A interacts,
R/right-stick click resets view, P/controller Menu pauses, Esc/B backs out.
Use Settings for graphics, sensitivity, sound, text size and reduced motion.

On the cloud CPU renderer (Mesa llvmpipe, 1280×720, medium 2× MSAA, shadows
off), the matching station samples measured about **10.43 FPS before** and
**10.84 FPS after** batching. Single short samples can include noise; neither
is a smoothness acceptance. A GPU target-device benchmark is needed.
Physical-controller use and human audio listening remain unverified.

See [Godot's export overview](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_projects.html),
[command-line export guide](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html),
and [Web export requirements](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html).


## Chapter Five milestone
The current Chapter Five delivery is in delivery/chapter5: Linux, Windows and Web. Official Godot4.6.3 export templates are used. Standalone Linux completed actual native keyboard cart/pause/reload/finish testing; Windows and Web runtimes are unverified. See ../docs/ORCHARD_QA_REPORT.md. Character art remains intermediate; Chapters Six–Seven remain unimplemented.
