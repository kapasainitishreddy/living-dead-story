from pathlib import Path
import json
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
pdfmetrics.registerFont(TTFont("DejaVu", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"))
R=Path(__file__).resolve().parents[1]
OUT=R/'delivery/character-milestone/Platform-6-Character-Milestone-2026-10-03.pdf'
OUT.parent.mkdir(parents=True,exist_ok=True)
license_path=OUT.parent/'DejaVu-Font-License.txt'
if not license_path.exists():license_path.write_text(Path('/usr/share/doc/fonts-dejavu-core/copyright').read_text())
c=canvas.Canvas(str(OUT),pagesize=(842,595))
c.setTitle('Platform 6 - first character milestone runtime checkpoint')
navy=HexColor('#14223a'); ink=HexColor('#233249'); accent=HexColor('#bb7857')
def txt(x,y,text,size=11,color=ink):
 c.setFillColor(color);c.setFont('DejaVu',size);c.drawString(x,y,text)
def header(title,page):
 c.setFillColor(navy);c.rect(0,521,842,74,fill=1,stroke=0)
 txt(32,562,'STILL HERE / PLATFORM 6',13,HexColor('#e9d7bd'))
 txt(32,537,title,20,HexColor('#ffffff'))
 txt(32,18,'2026-10-03 | Godot 4.6.3 Compatibility | actual runtime evidence',9)
 txt(800,18,str(page),9)
def image(path,x,y,w=373,h=210):
 c.drawImage(ImageReader(str(path)),x,y,width=w,height=h,preserveAspectRatio=True,anchor='c')
def lines(y,items,size=10):
 for item in items:txt(32,y,item,size);y-=18
header('Protagonist: a real mesh-and-rig upgrade',1)
txt(32,495,'BEFORE - existing primitive placeholder',12,accent)
txt(437,495,'AFTER - original contoured, skinned character',12,accent)
image(R/'evidence/characters/baseline/01-protagonist-close.png',32,273)
image(R/'evidence/characters/runtime/01-protagonist-close.png',437,273)
lines(246,[
 'Same station world, camera and lights. QA portrait camera shows the real in-game character; no concept image.',
 'Original face contours, brows, eyes, smile, swept hair, tailored midnight jacket, scarf and individual fingers.',
 'Actual armature, weighted surfaces and AnimationTree idle/walk/turn/conversation blending; no primitive body stack.',
 'Grounded authored stride is linked to movement speed. Eye/head/chest gaze, blink and hand-bone prop sockets.',
 'Reduced motion freezes secondary idle/blink while retaining necessary movement; camera preferences preserved.'
])
lines(132,[
 'CURRENT LEVEL: intermediate stylized 3D art. Clear improvement; not final high-end anime/painterly polish.',
 'Still open: finer face/hair/clothing, full running/sit/stand/special clips, terrain foot-lock IK and richer expressions.',
 'Scope remains protagonist + Mira. Other people and non-station scenery are still provisional.',
 'Chapter 1, schema 1 saves, accessibility, equal Done / Not tonight rewards and original audio are preserved.'
],10)
c.showPage()
header('Mira: distinct design, gaze and an attached camera',2)
txt(32,495,'BEFORE - same generic placeholder',12,accent)
txt(437,495,'AFTER - original Mira in the carriage',12,accent)
image(R/'evidence/characters/baseline/03-mira-close.png',32,273)
image(R/'evidence/characters/runtime/03-mira-close.png',437,273)
lines(246,[
 'Mira has a dark bob, terracotta coat, teal layer, separate readable facial controls and an original camera prop.',
 'The camera follows the actual hand bone. Conversation targets the player; layered head/eye gaze stays bounded.',
 'An 11-second runtime video demonstrates idle, movement, stop, turn, listening, reduced motion and Mira gaze.',
 'The video is offline Movie Maker output encoded at 30 fps, not a claim that cloud gameplay ran at 30 fps.'
])
b=json.loads((R/'evidence/characters/baseline-benchmark.json').read_text())
a=json.loads((R/'evidence/characters/after-benchmark.json').read_text())
lines(149,[
 'VERIFICATION: 470 checks passed: 402 existing chapter/save/accessibility checks + 68 character contracts.',
 f'60-second fixed-camera 1280x720 medium/2x MSAA: baseline median {b["median_ms"]:.1f} ms, p95 {b["p95_ms"]:.1f} ms;',
 f'upgraded median {a["median_ms"]:.1f} ms, p95 {a["p95_ms"]:.1f} ms. Software llvmpipe QA only; no target-GPU claim.',
 'Stationary paired content gate: no more than 10% p95 regression. Route/GPU/mobile performance remain unverified.',
 'New assets are original Blender work; no downloaded character, stock animation, paid asset or franchise model.',
 'Editable source, Linux prototype, runtime stills and video are supplied; licensing details are in ASSET_LICENSES.md.',
 'Existing Godot MIT / Sakura Crossing MIT notices remain. No reference audio was imported.'
],10)
c.save()
from pypdf import PdfReader,PdfWriter
reader=PdfReader(OUT)
writer=PdfWriter()
writer.clone_document_from_reader(reader)
writer.add_attachment("DejaVu-Font-License.txt",(R/"delivery/character-milestone/DejaVu-Font-License.txt").read_bytes())
with OUT.open("wb") as output:writer.write(output)
print(OUT)
