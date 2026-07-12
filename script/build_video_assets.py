#!/usr/bin/env python3
"""Mundial — final video asset generator.

Rebuilds every finished 1920x1080 card, transparent overlay, lower-third,
thumbnail, QR code, contact sheet, and the MANIFEST from the raw brand
artwork in assets/brand/. Run from the repo root:

    python3 script/build_video_assets.py

Facts baked into cards were live-verified on 2026-07-12:
  hook        0x51f3d18a574c1DeEC5c04d395573cda9248Dd0C4 (checksummed, code on-chain)
  repo        github.com/Tonyflam/2_okx (public)
  tests       77 passing (forge test), incl. fuzz
  status      DEPLOYED on X Layer (chain 196); source verification PENDING;
              liquidity NOT yet seeded — cards must not overstate either.
"""

import hashlib
import os

import qrcode
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND = os.path.join(ROOT, "assets", "brand")
OUT = os.path.join(ROOT, "assets", "video", "ready")
FONT_PATH = os.path.join(ROOT, "assets", "fonts", "SpaceGrotesk-Variable.ttf")

W, H = 1920, 1080
MARGIN = 140  # >=120 px safe margin everywhere
CAPTION_ZONE = 200  # keep critical content above the bottom caption band

NIGHT = (10, 18, 32)
GREEN = (0, 230, 118)
GOLD = (255, 197, 51)
WHITE = (244, 247, 251)
DIM = (154, 168, 190)

HOOK = "0x51f3d18a574c1DeEC5c04d395573cda9248Dd0C4"
REPO = "github.com/Tonyflam/2_okx"
EXPLORER_URL = "https://www.oklink.com/x-layer/address/0x51f3d18a574c1DeEC5c04d395573cda9248Dd0C4"
REPO_URL = "https://github.com/Tonyflam/2_okx"
TEAMS = ["ARGENTINA", "FRANCE", "BRAZIL", "ENGLAND", "SPAIN", "GERMANY", "PORTUGAL", "NETHERLANDS"]


def font(size: int, weight: int = 700) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(FONT_PATH, size)
    f.set_variation_by_axes([weight])
    return f


def tracked_width(d: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, tracking: int) -> float:
    return sum(d.textlength(c, font=f) for c in text) + tracking * max(len(text) - 1, 0)


def draw_tracked(d, xy, text, f, fill, tracking=0, anchor="la"):
    """Draw text with letter-spacing. anchor: la (left) | ma (centred) | ra (right)."""
    x, y = xy
    w = tracked_width(d, text, f, tracking)
    if anchor == "ma":
        x -= w / 2
    elif anchor == "ra":
        x -= w
    for c in text:
        d.text((x, y), c, font=f, fill=fill)
        x += d.textlength(c, font=f) + tracking
    return w


def cover(path: str, w: int = W, h: int = H) -> Image.Image:
    """Scale-and-crop an image to fill w x h."""
    im = Image.open(path).convert("RGB")
    s = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    return im.crop(((im.width - w) // 2, (im.height - h) // 2, (im.width - w) // 2 + w, (im.height - h) // 2 + h))


def darken(im: Image.Image, top: float, bottom: float) -> Image.Image:
    """Darken with a vertical gradient towards NIGHT (top/bottom opacities 0..1)."""
    grad = Image.new("L", (1, im.height))
    grad.putdata([round(255 * (top + (bottom - top) * y / (im.height - 1))) for y in range(im.height)])
    overlay = Image.new("RGB", im.size, NIGHT)
    return Image.composite(overlay, im, grad.resize(im.size))


def base(bg: str | None, top=0.55, bottom=0.75) -> Image.Image:
    if bg:
        return darken(cover(os.path.join(BRAND, bg)), top, bottom)
    return Image.new("RGB", (W, H), NIGHT)


def rule(d: ImageDraw.ImageDraw, x: int, y: int, w: int = 150, color=GREEN, thick: int = 6):
    d.rectangle([x, y, x + w, y + thick], fill=color)


def kicker(d, y, text, color=GREEN, x=MARGIN, anchor="la"):
    draw_tracked(d, (x, y), text, font(34, 500), color, tracking=14, anchor=anchor)


def qr_tile(url: str, size: int) -> Image.Image:
    """Standard dark-on-light QR in a white rounded tile (reliable scanning)."""
    q = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, border=0, box_size=10)
    q.add_data(url)
    q.make(fit=True)
    code = q.make_image(fill_color="#0A1220", back_color="white").convert("RGB")
    pad = size // 8  # >=4-module quiet zone
    tile = Image.new("RGB", (size, size), "white")
    code = code.resize((size - 2 * pad, size - 2 * pad), Image.NEAREST)
    tile.paste(code, (pad, pad))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=size // 14, fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(tile, (0, 0), mask)
    return out


def shadow_panel(im: Image.Image, box, radius=28, fill=(10, 18, 32, 216)):
    """Translucent night panel to guarantee text contrast over artwork."""
    panel = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle(box, radius=radius, fill=fill)
    return Image.alpha_composite(im.convert("RGBA"), panel)


def save(im: Image.Image, name: str):
    path = os.path.join(OUT, name)
    im.save(path)
    print(f"  wrote {name}  {im.size[0]}x{im.size[1]}")


# ---------------------------------------------------------------- cards ----

def card_00_title():
    im = base("video-title.jpg", 0.45, 0.7)
    d = ImageDraw.Draw(im)
    kicker(d, 330, "UNISWAP V4 HOOK · X LAYER", x=W // 2, anchor="ma")
    draw_tracked(d, (W // 2, 400), "MUNDIAL", font(230, 700), WHITE, tracking=10, anchor="ma")
    rule(d, W // 2 - 75, 700, color=GOLD)
    draw_tracked(d, (W // 2, 740), "THE POOL THAT PLAYS THE WORLD CUP", font(62, 500), GOLD, tracking=6, anchor="ma")
    save(im, "00-title-card.png")


def card_01_tournament():
    im = base("bg-bracket.jpg", 0.5, 0.78)
    d = ImageDraw.Draw(im)
    kicker(d, MARGIN + 20, "ONE KNOCKOUT BRACKET, FULLY ON-CHAIN")
    draw_tracked(d, (MARGIN, MARGIN + 80), "8 TEAMS · 1 POOL · 0 ADMINS", font(96, 700), WHITE, tracking=2)
    # Team chips, two rows of four.
    chip_f = font(40, 500)
    rows = [TEAMS[:4], TEAMS[4:]]
    y = 560
    for row in rows:
        widths = [tracked_width(d, t, chip_f, 3) + 76 for t in row]
        x = (W - (sum(widths) + 36 * 3)) / 2
        for t, cw in zip(row, widths):
            d.rounded_rectangle([x, y, x + cw, y + 92], radius=46, outline=GREEN, width=3,
                                fill=(10, 18, 32, 0))
            draw_tracked(d, (x + cw / 2, y + 24), t, chip_f, WHITE, tracking=3, anchor="ma")
            x += cw + 36
        y += 128
    save(im, "01-tournament-card.png")


def card_02_mechanic():
    im = base("plate-a.jpg", 0.35, 0.6)
    d = ImageDraw.Draw(im)
    kicker(d, 300, "THE CORE MECHANIC")
    draw_tracked(d, (MARGIN, 370), "SWAPS", font(150, 700), WHITE)
    draw_tracked(d, (MARGIN + 560, 370), "→  SHOTS", font(150, 700), GREEN)
    draw_tracked(d, (MARGIN, 560), "VOLUME", font(150, 700), WHITE)
    draw_tracked(d, (MARGIN + 660, 560), "→  GOALS", font(150, 700), GOLD)
    rule(d, MARGIN, 790)
    draw_tracked(d, (MARGIN, 820), "THE MARKET PLAYS THE MATCH", font(48, 500), DIM, tracking=8)
    save(im, "02-mechanic-card.png")


def card_03_score_overlay():
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    panel = [W // 2 - 640, 120, W // 2 + 640, 480]
    im = shadow_panel(im, panel, radius=36, fill=(10, 18, 32, 232))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle(panel, radius=36, outline=GREEN, width=4)
    kicker(d, 165, "QUARTERFINAL 1 — FOUNDRY END-TO-END TEST", x=W // 2, anchor="ma")
    draw_tracked(d, (W // 2, 225), "ARGENTINA 5 — 3 FRANCE", font(104, 700), WHITE, tracking=2, anchor="ma")
    draw_tracked(d, (W // 2, 380), "WINNER: ARGENTINA", font(52, 500), GOLD, tracking=8, anchor="ma")
    save(im, "03-score-overlay.png")


def card_04_golden_goal():
    im = base("visual-goldengoal.jpg", 0.4, 0.66)
    d = ImageDraw.Draw(im)
    kicker(d, 380, "EXTRA TIME · SUDDEN DEATH", color=GOLD, x=W // 2, anchor="ma")
    draw_tracked(d, (W // 2, 440), "GOLDEN GOAL", font(170, 700), GOLD, tracking=6, anchor="ma")
    draw_tracked(d, (W // 2, 680), "SETTLED INSIDE THE SCORING SWAP", font(56, 500), WHITE, tracking=6, anchor="ma")
    save(im, "04-golden-goal-card.png")


def card_05_champion_overlay():
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    panel = [W // 2 - 620, 120, W // 2 + 620, 440]
    im = shadow_panel(im, panel, radius=36, fill=(10, 18, 32, 232))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle(panel, radius=36, outline=GOLD, width=4)
    draw_tracked(d, (W // 2, 175), "CHAMPION CROWNED", font(96, 700), GOLD, tracking=4, anchor="ma")
    draw_tracked(d, (W // 2, 330), "CHAMPIONS POT CLAIMED PRO RATA", font(48, 500), WHITE, tracking=6, anchor="ma")
    save(im, "05-champion-overlay.png")


def card_06_fees():
    im = base("bg-architecture.jpg", 0.55, 0.8)
    d = ImageDraw.Draw(im)
    kicker(d, MARGIN + 10, "DYNAMIC FEES, SET BY THE GAME STATE")
    draw_tracked(d, (MARGIN, MARGIN + 66), "ONE DYNAMIC-FEE POOL", font(88, 700), WHITE)
    tiers = [("NEUTRAL", "0.50%", DIM), ("PLEDGED FAN", "0.25%", WHITE),
             ("LIVE-TEAM FAN", "0.15%", GREEN), ("GOLDEN GOAL", "0.10%", GOLD)]
    y = 400
    for label, pct, color in tiers:
        draw_tracked(d, (MARGIN, y), label, font(52, 500), color, tracking=4)
        draw_tracked(d, (W - MARGIN, y - 14), pct, font(80, 700), color, anchor="ra")
        d.line([MARGIN, y + 92, W - MARGIN, y + 92], fill=(255, 255, 255, 40), width=2)
        y += 110
    save(im, "06-fees-card.png")


def card_07_pot():
    im = base("visual-pot.jpg", 0.45, 0.72)
    d = ImageDraw.Draw(im)
    kicker(d, 300, "THE PRIZE, FUNDED BY PLAY", color=GOLD)
    draw_tracked(d, (MARGIN, 366), "0.20% → CHAMPIONS POT", font(110, 700), GOLD)
    draw_tracked(d, (MARGIN, 560), "WINNING FANS CLAIM PRO RATA", font(58, 500), WHITE, tracking=4)
    draw_tracked(d, (MARGIN, 660), "UNCLAIMED FUNDS → LPs", font(58, 500), GREEN, tracking=4)
    save(im, "07-pot-card.png")


def card_08_trust():
    im = base("plate-b.jpg", 0.5, 0.74)
    d = ImageDraw.Draw(im)
    kicker(d, 230, "WHY YOU CAN TRUST A TOURNAMENT WITH NO REFEREE")
    lines = [("NO OWNER", WHITE), ("NO ORACLE", WHITE), ("NO RANDOMNESS", WHITE), ("SWAPS + TIME", GREEN)]
    y = 306
    for text, color in lines:
        draw_tracked(d, (MARGIN, y), text, font(104, 700), color, tracking=2)
        y += 124
    draw_tracked(d, (MARGIN, y + 16), "77 PASSING TESTS · FUZZED · DEPLOYED ON X LAYER",
                 font(42, 500), DIM, tracking=6)
    save(im, "08-trust-card.png")


def card_09_live_proof():
    im = base("plate-a.jpg", 0.55, 0.78)
    d = ImageDraw.Draw(im)
    kicker(d, MARGIN + 10, "X LAYER MAINNET · CHAIN 196")
    draw_tracked(d, (MARGIN, MARGIN + 56), "LIVE ON X LAYER", font(100, 700), WHITE)
    # Full-width address box — the whole checksummed address must be visible.
    d.rounded_rectangle([MARGIN, 430, W - MARGIN, 580], radius=24, outline=GREEN, width=3)
    draw_tracked(d, (W // 2, 452), "HOOK", font(28, 500), GREEN, tracking=10, anchor="ma")
    draw_tracked(d, (W // 2, 496), HOOK, font(54, 500), WHITE, tracking=0, anchor="ma")
    draw_tracked(d, (MARGIN, 660), REPO, font(56, 500), GOLD, tracking=2)
    # Honest status line — do not imply source verification is done.
    draw_tracked(d, (MARGIN, 760), "DEPLOYED · SOURCE VERIFICATION PENDING",
                 font(36, 500), DIM, tracking=4)
    qr1, qr2 = qr_tile(EXPLORER_URL, 230), qr_tile(REPO_URL, 230)
    draw_tracked(d, (W - MARGIN - 115, 608), "EXPLORER", font(24, 500), DIM, tracking=6, anchor="ma")
    draw_tracked(d, (W - MARGIN - 405, 608), "REPOSITORY", font(24, 500), DIM, tracking=6, anchor="ma")
    im.paste(qr1, (W - MARGIN - 230, 645), qr1)
    im.paste(qr2, (W - MARGIN - 520, 645), qr2)
    save(im, "09-live-proof-card.png")


def card_10_end():
    im = base("video-endcard.jpg", 0.5, 0.72)
    d = ImageDraw.Draw(im)
    draw_tracked(d, (W // 2, 300), "MUNDIAL", font(190, 700), WHITE, tracking=8, anchor="ma")
    draw_tracked(d, (W // 2, 550), "THE POOL THAT PLAYS THE WORLD CUP", font(56, 500), GOLD, tracking=6, anchor="ma")
    kicker(d, 660, "X LAYER · UNISWAP V4", x=W // 2, anchor="ma")
    draw_tracked(d, (W // 2, 730), REPO, font(52, 500), GREEN, tracking=2, anchor="ma")
    draw_tracked(d, (W // 2, 850), "Independent project. Not affiliated with FIFA.",
                 font(30, 400), DIM, anchor="ma")
    save(im, "10-end-card.png")


def thumbnail():
    im = darken(cover(os.path.join(BRAND, "video-thumb.jpg"), 1280, 720), 0.35, 0.62)
    d = ImageDraw.Draw(im)
    draw_tracked(d, (80, 96), "MUNDIAL", font(44, 500), GREEN, tracking=12)
    for i, line in enumerate(["THE POOL", "THAT PLAYS THE", "WORLD CUP"]):
        draw_tracked(d, (80, 200 + i * 122), line, font(104, 700), WHITE if i != 2 else GOLD, tracking=2)
    save(im, "thumbnail-final.png")


def lower_third(name: str, text: str, accent):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    f = font(40, 500)
    tw = tracked_width(d, text, f, 8)
    x0, y0 = MARGIN, H - 340  # sits clear of the burned-caption zone
    d.rounded_rectangle([x0, y0, x0 + tw + 96, y0 + 84], radius=14, fill=(10, 18, 32, 224))
    d.rectangle([x0, y0, x0 + 10, y0 + 84], fill=accent)
    draw_tracked(d, (x0 + 48, y0 + 20), text, f, WHITE, tracking=8)
    save(im, name)


def contact_sheet():
    files = sorted(f for f in os.listdir(OUT) if f.endswith(".png") and f != "contact-sheet.png")
    cols, tw = 4, 460
    th = round(tw * 9 / 16)
    rows = (len(files) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (tw + 20) + 20, rows * (th + 56) + 20), (24, 32, 48))
    d = ImageDraw.Draw(sheet)
    f = font(22, 500)
    for i, name in enumerate(files):
        im = Image.open(os.path.join(OUT, name))
        if im.mode == "RGBA":  # show transparent overlays on checker-dark
            back = Image.new("RGB", im.size, (52, 60, 76))
            back.paste(im, (0, 0), im)
            im = back
        im = im.resize((tw, round(tw * im.height / im.width)), Image.LANCZOS)
        x, y = 20 + (i % cols) * (tw + 20), 20 + (i // cols) * (th + 56)
        sheet.paste(im.convert("RGB"), (x, y))
        d.text((x, y + th + 8), name, font=f, fill=(244, 247, 251))
    sheet.save(os.path.join(OUT, "contact-sheet.png"))
    print("  wrote contact-sheet.png")


def manifest():
    lines = ["# assets/video/ready — finished deliverables", "",
             "Rebuilt by `python3 script/build_video_assets.py`. "
             "Facts live-verified 2026-07-12 (see deployments/xlayer.json).", "",
             "| File | Dimensions | SHA-256 |", "|---|---|---|"]
    for name in sorted(os.listdir(OUT)):
        if not name.endswith(".png"):
            continue
        p = os.path.join(OUT, name)
        with Image.open(p) as im:
            dims = f"{im.width}x{im.height}"
        sha = hashlib.sha256(open(p, "rb").read()).hexdigest()[:16]
        lines.append(f"| {name} | {dims} | `{sha}…` |")
    with open(os.path.join(OUT, "MANIFEST.md"), "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("  wrote MANIFEST.md")


def terminal_renders():
    """Render the REAL demo output (assets/video/work/demo-output.txt) as clean
    terminal frames — wide + three zoom crops. These show genuine forge output
    and always carry the FOUNDRY END-TO-END TEST label in the edit."""
    src = os.path.join(ROOT, "assets", "video", "work", "demo-output.txt")
    if not os.path.exists(src):
        print("  !! demo-output.txt missing — run the narrated demo first; skipping terminal renders")
        return
    raw = [ln.rstrip("\n") for ln in open(src)]
    lines = ["$ forge test --match-contract MundialDemo -vv", ""]
    lines += [ln for ln in raw if ln.strip()][:20]
    mono = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 30)
    mono_b = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf", 30)
    im = Image.new("RGB", (W, H), (13, 17, 26))
    d = ImageDraw.Draw(im)
    # window chrome
    d.rounded_rectangle([60, 40, W - 60, H - 40], radius=18, fill=(16, 22, 34), outline=(42, 52, 70), width=2)
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse([100 + i * 44, 76, 126 + i * 44, 102], fill=c)
    d.text((W // 2 - 120, 78), "bash — forge test", font=mono, fill=(120, 134, 156))
    y = 150
    hot = ("GOLDEN GOAL", "goals:", "Champion", "claimed", "No owner", "PASS", "Every swap")
    for ln in lines:
        color = (200, 210, 226)
        f = mono
        if ln.startswith("$"):
            color = (0, 230, 118)
        elif any(k in ln for k in hot):
            color, f = (255, 197, 51) if "GOLDEN" in ln or "Champion" in ln else (0, 230, 118), mono_b
        d.text((110, y), ln[:100], font=f, fill=color)
        y += 40
    im.save(os.path.join(OUT, "terminal-wide.png"))
    print("  wrote terminal-wide.png")

    def zoom_crop(name, needle, drop=140):
        """Crop 1280x720 so the needle line lands `drop` px below the crop top
        — overlays occupy the upper band, so push cited lines below them."""
        idx = next((i for i, ln in enumerate(lines) if needle in ln), None)
        if idx is None:
            return
        cy = 150 + idx * 40
        top = max(100, min(cy - drop, H - 40 - 720))  # clamp inside the window
        crop = im.crop((60, top, 60 + 1280, top + 720)).resize((W, H), Image.LANCZOS)
        crop.save(os.path.join(OUT, name))
        print(f"  wrote {name}")

    zoom_crop("terminal-goals.png", "Argentina goals", drop=340)
    zoom_crop("terminal-golden.png", "GOLDEN GOAL", drop=160)
    zoom_crop("terminal-champion.png", "Champion (seed", drop=340)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    card_00_title()
    card_01_tournament()
    card_02_mechanic()
    card_03_score_overlay()
    card_04_golden_goal()
    card_05_champion_overlay()
    card_06_fees()
    card_07_pot()
    card_08_trust()
    card_09_live_proof()
    card_10_end()
    thumbnail()
    lower_third("recording-label-foundry.png", "FOUNDRY END-TO-END TEST", GREEN)
    lower_third("recording-label-mainnet.png", "X LAYER MAINNET DEPLOYMENT", GOLD)
    terminal_renders()
    contact_sheet()
    manifest()
    print("done.")
