"""Original quiet clockwork/reed courtyard bed. No recorded or third-party samples."""
import math, struct, wave
from pathlib import Path
RATE=22050
DURATION=8
samples=[]
notes=[220,261.6256,293.6648,261.6256]
for i in range(RATE*DURATION):
    t=i/RATE
    phase=t%0.5
    click=0.06*math.sin(2*math.pi*1700*phase)*math.exp(-phase*90)
    pulse=t%2.0
    envelope=math.sin(math.pi*min(pulse/1.6,1))**2 if pulse<1.6 else 0
    reed=0.038*envelope*(math.sin(2*math.pi*notes[int(t//2)%4]*t)+0.17*math.sin(2*math.pi*notes[int(t//2)%4]*3*t))
    soft=0.01*math.sin(2*math.pi*110*t)
    edge=min(1,t/0.12,(DURATION-t)/0.12)
    samples.append(struct.pack('<h',int((click+reed+soft)*max(0,edge)*32767)))
p=Path(__file__).resolve().parents[1]/'game/assets/original/fair_clockwork.wav'
with wave.open(str(p),'wb') as w:
    w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(b''.join(samples))
print(p)
