"""metrics.jsonl özeti: kaydırma sırasındaki kare süreleri ve akışın yüklenme durumu."""
import json
import sys

samples = [json.loads(line) for line in open(sys.argv[1]) if line.strip()]
frames = sorted(f for s in samples for f in s["frames"])
if frames:
    def q(p):
        return frames[int(p * (len(frames) - 1))]
    print(f"kare: {len(frames)} adet  p50={q(.5)}ms  p90={q(.9)}ms  p99={q(.99)}ms  en kötü={frames[-1]}ms")
    print(f"  >25ms: {sum(f > 25 for f in frames)}  >50ms: {sum(f > 50 for f in frames)}  >100ms: {sum(f > 100 for f in frames)}")
else:
    print("kaydırma sırasında kare yok")
print("saniye  yol  y  sayfa  native(ofset/boy)  gönderi(gizli/reels)  kaydırma  en kötü kare")
jumps = sum(1 for a, b in zip(samples, samples[1:]) if b["y"] < a["y"] - 2000)
print(f"başa sıçrama: {jumps}  en fazla gönderi: {max((s['articles'] for s in samples), default=0)}  görülen reels: {max((s.get('reels', 0) for s in samples), default=0)}  veriden çıkarılan reels: {max((s.get('removedReels', 0) for s in samples), default=0)}")
start = samples[0]["t"] if samples else 0
for s in samples:
    worst = max(s["frames"]) if s["frames"] else 0
    print(f'{(s["t"] - start) / 1000:6.0f}  {s["path"][:12]:12} {s["y"]:6} {s["docH"]:6}  '
          f'{s["nativeOffset"]:6}/{s["nativeContent"]:6}  {s["articles"]:3}({s["hidden"]}/{s.get("reels", "-")})  {s["scrolls"]:4}  {worst:6}')
