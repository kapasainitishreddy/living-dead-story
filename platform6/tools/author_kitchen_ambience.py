"""Author an original quiet simmer/cup bed with deterministic stdlib synthesis."""
from pathlib import Path
import math, random, struct, wave
rate=22050; duration=12; rng=random.Random(6406)
count=rate*duration; samples=[0.0]*count
# Low pot resonance with soft, irregular bubbles. No recordings or external assets.
for n in range(count):
 t=n/rate
 samples[n]=0.006*math.sin(math.tau*79*t)+0.003*math.sin(math.tau*113*t)
for _ in range(126):
 start=rng.randrange(count); length=rng.randrange(1000,4200); pitch=rng.uniform(180,480)
 for j in range(min(length,count-start)):
  t=j/rate;env=math.sin(math.pi*j/length)**2
  samples[start+j]+=env*0.015*math.sin(math.tau*(pitch*t-130*t*t))
for when in [1.1,4.6,8.35,10.8]:
 start=int(when*rate)
 for j in range(min(int(.45*rate),count-start)):
  t=j/rate
  samples[start+j]+=.035*math.exp(-12*t)*(math.sin(math.tau*1260*t)+.35*math.sin(math.tau*2087*t))
# Matched silence boundaries prevent discontinuous loop edges.
for n in range(count):
 fade=min(1,n/(rate*.2),(count-1-n)/(rate*.2))
 samples[n]*=fade
out=Path(__file__).resolve().parents[1]/'game/assets/original/kitchen_simmer.wav'
with wave.open(str(out),'wb') as w:
 w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate)
 w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,s))*32767)) for s in samples))
print(out)
