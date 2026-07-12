#!/usr/bin/env python3
"""Mundial — demo video assembler.

Reads assets/video/work/timeline.csv (pipe-separated scene table), builds every
segment with ffmpeg (Ken Burns on stills, trims on raw clips, transparent
overlays), generates the SRT from the same table, concatenates, mixes the
narration (loudnorm -16 LUFS / -1.5 dBTP), burns captions, and renders:

    python3 script/build_demo_video.py            # -> assets/video/review/mundial-demo-review.mp4
    python3 script/build_demo_video.py --final    # -> assets/video/final/mundial-demo-final.mp4

Narration master clock: assets/audio/narration-final.wav|.mp3. If absent, a
silent review render is produced (never a final). Raw clips in
assets/video/raw/ are used when present; otherwise each scene falls back to
the honest terminal renders / proof cards listed in the table.
"""

import csv
import hashlib
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
READY = os.path.join(ROOT, "assets", "video", "ready")
RAW = os.path.join(ROOT, "assets", "video", "raw")
WORK = os.path.join(ROOT, "assets", "video", "work")
SEG = os.path.join(WORK, "segments")
FPS = 30
W, H = 1920, 1080


def sh(cmd: list[str]):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"FAILED: {' '.join(cmd[:8])}...\n{r.stderr[-1600:]}")


def probe(path: str) -> dict:
    r = subprocess.run(["ffprobe", "-v", "quiet", "-print_format", "json",
                        "-show_format", "-show_streams", path], capture_output=True, text=True)
    return json.loads(r.stdout or "{}")


def load_timeline() -> list[dict]:
    rows = []
    with open(os.path.join(WORK, "timeline.csv")) as fh:
        for row in csv.DictReader(fh, delimiter="|"):
            row["dur"] = float(row["dur"])
            rows.append(row)
    return rows


def find_narration() -> str | None:
    for ext in ("wav", "mp3", "m4a"):
        p = os.path.join(ROOT, "assets", "audio", f"narration-final.{ext}")
        if os.path.exists(p):
            return p
    return None


def build_segment(i: int, row: dict) -> str:
    out = os.path.join(SEG, f"seg{i:02d}.mp4")
    dur, frames = row["dur"], round(row["dur"] * FPS)
    src = os.path.join(RAW, row["source"]) if row["kind"] == "clip" else os.path.join(READY, row["source"])
    is_still = row["kind"] == "still"
    used_fallback = False
    if row["kind"] == "clip" and not os.path.exists(src):
        src = os.path.join(READY, row["fallback"])
        is_still = used_fallback = True

    # cache: reuse the segment if it is newer than every input it depends on
    deps = [src, os.path.join(WORK, "timeline.csv")] + \
           [os.path.join(READY, o.lstrip("?")) for o in (row["overlays"] or "").split(";") if o]
    if os.path.exists(out) and all(os.path.getmtime(out) > os.path.getmtime(d)
                                   for d in deps if os.path.exists(d)):
        return out

    inputs, filters = [], []
    if is_still:
        inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{dur + 1}", "-i", src]
        z = {"in": f"min(1+0.07*on/{frames},1.07)",
             "out": f"max(1.07-0.07*on/{frames},1.0)",
             "none": "1.001"}[row["zoom"] or "none"]
        filters.append(
            f"[0:v]scale=2400:1350,zoompan=z='{z}':x='(iw-iw/zoom)/2':y='(ih-ih/zoom)/2'"
            f":d=1:fps={FPS}:s={W}x{H}[v0]")
    else:
        inputs += ["-i", src]
        filters.append(f"[0:v]fps={FPS},scale={W}:{H}:force_original_aspect_ratio=decrease,"
                       f"pad={W}:{H}:(ow-iw)/2:(oh-ih)/2,setsar=1[v0]")

    last, n = "v0", 1
    for ov in [o for o in (row["overlays"] or "").split(";") if o]:
        if ov.startswith("?"):  # clip-only overlay: skip when the fallback still is used
            if used_fallback:
                continue
            ov = ov[1:]
        inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{dur + 1}",
                   "-i", os.path.join(READY, ov)]
        filters.append(f"[{last}][{n}:v]overlay=0:0[v{n}]")
        last, n = f"v{n}", n + 1

    filters.append(f"[{last}]trim=duration={dur},setpts=PTS-STARTPTS,format=yuv420p[vout]")
    sh(["ffmpeg", "-y", *inputs, "-filter_complex", ";".join(filters), "-map", "[vout]",
        "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-r", str(FPS), out])
    return out


def make_srt(rows: list[dict], path: str):
    def fmt(t):
        ms = round(t * 1000)
        return f"{ms//3600000:02d}:{ms//60000%60:02d}:{ms//1000%60:02d},{ms%1000:03d}"

    def wrap(text, width=42):
        lines, cur = [], ""
        for w_ in text.split():
            if len(cur) + len(w_) + 1 > width and cur:
                lines.append(cur)
                cur = w_
            else:
                cur = f"{cur} {w_}".strip()
        if cur:
            lines.append(cur)
        return lines

    cues, t = [], 0.0
    for row in rows:
        text = row["caption"].strip()
        if text:
            lines = wrap(text)
            # group into cues of <=2 lines, time proportional to characters
            groups, g = [], []
            for ln in lines:
                g.append(ln)
                if len(g) == 2:
                    groups.append(g)
                    g = []
            if g:
                groups.append(g)
            total = sum(len(" ".join(g)) for g in groups)
            gt = t
            for g in groups:
                d = row["dur"] * len(" ".join(g)) / total
                cues.append((gt, min(gt + d, t + row["dur"]) - 0.05, "\n".join(g)))
                gt += d
        t += row["dur"]
    with open(path, "w") as fh:
        for i, (a, b, text) in enumerate(cues, 1):
            fh.write(f"{i}\n{fmt(a)} --> {fmt(b)}\n{text}\n\n")


def main():
    final = "--final" in sys.argv
    os.makedirs(SEG, exist_ok=True)
    rows = load_timeline()
    total = sum(r["dur"] for r in rows)
    print(f"timeline: {len(rows)} scenes, {total:.1f}s")
    assert 105 <= total <= 120, f"duration {total}s outside 105-120s"

    narration = find_narration()
    if final and not narration:
        sys.exit("FINAL requires assets/audio/narration-final.wav|.mp3 — none found.")

    segs = [build_segment(i, row) for i, row in enumerate(rows, 1)]
    print(f"built {len(segs)} segments")

    concat_txt = os.path.join(SEG, "concat.txt")
    with open(concat_txt, "w") as fh:
        fh.writelines(f"file '{s}'\n" for s in segs)
    joined = os.path.join(WORK, "joined.mp4")
    sh(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", concat_txt, "-c", "copy", joined])

    srt = os.path.join(READY, "captions-final.srt")
    make_srt(rows, srt)
    print("captions written")

    outdir = os.path.join(ROOT, "assets", "video", "final" if final else "review")
    os.makedirs(outdir, exist_ok=True)
    out = os.path.join(outdir, "mundial-demo-final.mp4" if final else "mundial-demo-review.mp4")

    audio_in = [ "-i", narration] if narration else \
        ["-f", "lavfi", "-i", f"anullsrc=r=48000:cl=stereo:d={total}"]
    style = ("FontName=Space Grotesk,FontSize=12,PrimaryColour=&H00FBF7F4,BackColour=&H66000000,"
             "BorderStyle=4,Outline=0,Shadow=0,MarginV=12")
    vf = (f"subtitles={srt}:fontsdir={os.path.join(ROOT,'assets','fonts')}:force_style='{style}',"
          f"fade=t=in:st=0:d=0.5,fade=t=out:st={total-0.7:.2f}:d=0.7")
    af = "loudnorm=I=-16:TP=-1.5:LRA=11,apad" if narration else "anull"
    sh(["ffmpeg", "-y", "-i", joined, *audio_in,
        "-filter_complex", f"[0:v]{vf}[v];[1:a]{af}[a]",
        "-map", "[v]", "-map", "[a]", "-t", f"{total}",
        "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-r", str(FPS),
        "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", out])

    info = probe(out)
    v = next(s for s in info["streams"] if s["codec_type"] == "video")
    a = next(s for s in info["streams"] if s["codec_type"] == "audio")
    dur = float(info["format"]["duration"])
    sha = hashlib.sha256(open(out, "rb").read()).hexdigest()
    print(f"\n== {os.path.relpath(out, ROOT)} ==")
    print(f"   {v['width']}x{v['height']} {v['avg_frame_rate']} {v['codec_name']} | "
          f"{a['codec_name']} {a['sample_rate']} Hz | {dur:.2f}s | sha256 {sha[:16]}…")
    checks = [(v["width"], 1920), (v["height"], 1080), (v["codec_name"], "h264"),
              (a["codec_name"], "aac"), (a["sample_rate"], "48000")]
    ok = all(x == y for x, y in checks) and 105 <= dur <= 120.5 and v["avg_frame_rate"] == "30/1"
    print("   QC:", "ALL PASS" if ok else f"CHECK FAILED {checks} dur={dur}")

    # scene-boundary frames for the review contact sheet
    frames_dir = os.path.join(ROOT, "assets", "video", "review", "frames")
    os.makedirs(frames_dir, exist_ok=True)
    t = 0.0
    for i, row in enumerate(rows, 1):
        sh(["ffmpeg", "-y", "-ss", f"{min(t + 0.6, dur - 0.1):.2f}", "-i", out,
            "-frames:v", "1", os.path.join(frames_dir, f"scene{i:02d}.png")])
        t += row["dur"]
    print(f"   scene frames -> {os.path.relpath(frames_dir, ROOT)}")
    if not narration:
        print("   NOTE: silent render (no narration file yet) — review only.")


if __name__ == "__main__":
    main()
