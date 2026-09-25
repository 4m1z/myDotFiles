#!/usr/bin/env python3
"""Build Godfather's original artwork and shell colors (Python 3.11+, librsvg)."""

import math
from pathlib import Path
import random
import shutil
import subprocess
import tomllib
from xml.sax.saxutils import escape, quoteattr


ROOT = Path(__file__).resolve().parent
COLORS = tomllib.loads((ROOT / "colors.toml").read_text())
WIDTH, HEIGHT = 1920, 1080


def element(name, content=None, **attrs):
    attributes = " ".join(
        f"{'xml:space' if key == 'xml_space' else key.replace('_', '-')}={quoteattr(str(value))}"
        for key, value in attrs.items()
    )
    opening = f"<{name} {attributes}"
    return f"{opening}/>" if content is None else f"{opening}>{content}</{name}>"


def group(content, **attrs):
    return element("g", "".join(content), **attrs)


def rect(x, y, width, height, fill, **attrs):
    return element("rect", x=x, y=y, width=width, height=height, fill=fill, **attrs)


def path(d, fill="none", **attrs):
    return element("path", d=d, fill=fill, **attrs)


def circle(x, y, radius, fill, **attrs):
    return element("circle", cx=x, cy=y, r=radius, fill=fill, **attrs)


def text(x, y, value, size, fill, **attrs):
    return element(
        "text", escape(value), x=x, y=y, font_size=size, fill=fill, **attrs
    )


def polygon(points, fill="none", **attrs):
    return element(
        "polygon",
        points=" ".join(f"{x:.2f},{y:.2f}" for x, y in points),
        fill=fill,
        **attrs,
    )


def star(cx, cy, radius, inner=None, count=8, rotation=-math.pi / 2):
    inner = radius * 0.54 if inner is None else inner
    return [
        (
            cx + (radius if i % 2 == 0 else inner) * math.cos(rotation + i * math.pi / count),
            cy + (radius if i % 2 == 0 else inner) * math.sin(rotation + i * math.pi / count),
        )
        for i in range(count * 2)
    ]


def mix(a, b, amount):
    left = tuple(int(a[i:i + 2], 16) for i in (1, 3, 5))
    right = tuple(int(b[i:i + 2], 16) for i in (1, 3, 5))
    return "#" + "".join(f"{round(x * (1 - amount) + y * amount):02x}" for x, y in zip(left, right))


def svg(body, width=WIDTH, height=HEIGHT, title="Godfather", description=""):
    return element(
        "svg",
        element("title", escape(title)) + element("desc", escape(description)) + body,
        xmlns="http://www.w3.org/2000/svg",
        width=width,
        height=height,
        viewBox=f"0 0 {width} {height}",
    )


def definitions():
    return element("defs", f"""
      <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1">
        <stop stop-color="#1E1813"/>
        <stop offset=".55" stop-color="#12100C"/>
        <stop offset="1" stop-color="#080706"/>
      </linearGradient>
      <linearGradient id="night" x1="0" y1="0" x2="0" y2="1">
        <stop stop-color="#0B1220"/>
        <stop offset=".6" stop-color="#16202E"/>
        <stop offset="1" stop-color="#2A2A30"/>
      </linearGradient>
      <radialGradient id="lampglow" cx=".5" cy=".5" r=".5">
        <stop stop-color="#E6C78B" stop-opacity=".55"/>
        <stop offset=".4" stop-color="#C9A86A" stop-opacity=".22"/>
        <stop offset="1" stop-color="#C9A86A" stop-opacity="0"/>
      </radialGradient>
      <linearGradient id="lampshade" x1="0" y1="0" x2="0" y2="1">
        <stop stop-color="#3A5A40"/><stop offset=".5" stop-color="#2A4430"/>
        <stop offset="1" stop-color="#1A2E20"/>
      </linearGradient>
      <linearGradient id="deskwood" x1="0" y1="0" x2="0" y2="1">
        <stop stop-color="#3A2A1E"/><stop offset=".4" stop-color="#2A1E14"/>
        <stop offset="1" stop-color="#171008"/>
      </linearGradient>
      <linearGradient id="whiskey" x1="0" y1="0" x2="0" y2="1">
        <stop stop-color="#D8953B"/><stop offset=".5" stop-color="#A66A25"/>
        <stop offset="1" stop-color="#6B3E14"/>
      </linearGradient>
      <linearGradient id="blindlight" x1="0" y1="0" x2="1" y2="1">
        <stop stop-color="#E8DCC3" stop-opacity=".10"/>
        <stop offset="1" stop-color="#E8DCC3" stop-opacity="0"/>
      </linearGradient>
      <radialGradient id="vignette" r=".75">
        <stop offset=".45" stop-color="#080706" stop-opacity="0"/>
        <stop offset="1" stop-color="#080706" stop-opacity=".78"/>
      </radialGradient>
      <filter id="grain" x="0" y="0" width="100%" height="100%">
        <feTurbulence type="fractalNoise" baseFrequency=".72" numOctaves="3" seed="7" stitchTiles="stitch"/>
        <feColorMatrix type="saturate" values="0"/>
      </filter>
      <clipPath id="window-clip"><rect x="1090" y="120" width="620" height="520"/></clipPath>
    """)


def city_skyline(rng):
    """Night city silhouette with lit windows, clipped to the office window."""
    buildings = []
    x = 1090
    while x < 1710:
        w = rng.uniform(50, 110)
        h = rng.uniform(150, 420)
        top = 640 - h
        buildings.append(rect(x, top, w, h, "#0A0E16"))
        # Lit windows: small warm rectangles, deterministic.
        for _ in range(int(w * h / 900)):
            wx = rng.uniform(x + 6, x + w - 12)
            wy = rng.uniform(top + 10, 630)
            if rng.random() < 0.45:
                color = rng.choice(["#E6C78B", "#C9A86A", "#8A97A8"])
                buildings.append(rect(wx, wy, 6, 9, color, opacity=round(rng.uniform(.25, .8), 2)))
        x += w + rng.uniform(2, 10)
    # Moon + haze.
    return group([
        rect(1090, 120, 620, 520, "url(#night)"),
        circle(1590, 220, 34, "#E8DCC3", opacity=.85),
        circle(1578, 212, 30, "#0B1220", opacity=.9),
        *buildings,
        rect(1090, 120, 620, 520, "#C9A86A", opacity=.04),
    ], clip_path="url(#window-clip)")


def rose_bloom(x, y, scale, seed):
    rng = random.Random(seed)
    petals = []
    for ring, (count, radius) in enumerate([(5, 26), (7, 17), (5, 9)]):
        for i in range(count):
            a = math.tau * i / count + rng.uniform(-.2, .2) + ring * .4
            px = math.cos(a) * radius
            py = math.sin(a) * radius
            petals.append(element(
                "ellipse", cx=f"{px:.1f}", cy=f"{py:.1f}", rx="11", ry="7",
                fill=rng.choice(["#7A1E28", "#8B2432", "#6B1620"]),
                stroke="#3A0E14", stroke_width=".8",
                opacity=".9", transform=f"rotate({math.degrees(a):.1f} {px:.1f} {py:.1f})",
            ))
    petals.append(circle(0, 0, 5, "#3A0E14"))
    leaves = [
        path("M0 0Q-24 6 -38 26Q-16 24 0 0Z", "#2E4028", stroke="#1A2418", stroke_width=".8"),
        path("M0 0Q24 8 36 28Q14 24 0 0Z", "#34492E", stroke="#1A2418", stroke_width=".8"),
    ]
    return group(petals + leaves, transform=f"translate({x} {y}) scale({scale})")


def office():
    rng = random.Random(1931)
    body = [definitions(), rect(0, 0, WIDTH, HEIGHT, "url(#wall)")]

    # Framed picture on the left wall.
    body += [
        rect(120, 130, 420, 320, "#0A0806", stroke="#8A6E42", stroke_width=6),
        rect(140, 150, 380, 280, "#141210"),
        path("M140 430L300 250 360 320 430 230 520 340V430Z", "#1E2A24", opacity=.8),
        circle(460, 200, 22, "#C9A86A", opacity=.5),
        rect(140, 150, 380, 280, "none", stroke="#C9A86A", stroke_width=1, opacity=.25),
    ]

    # Big window with mullions + city.
    body += [
        rect(1060, 90, 680, 580, "#050403", stroke="#3A2E1E", stroke_width=10),
        city_skyline(rng),
        rect(1090, 120, 620, 520, "none", stroke="#2A2118", stroke_width=4),
        rect(1385, 120, 14, 520, "#2A2118"),
        rect(1090, 365, 620, 12, "#2A2118"),
        path("M1090 120L1710 640M1710 120L1090 640", stroke="#E8DCC3", stroke_width=1, opacity=.05),
    ]

    # Venetian-blind light slats washing over wall + desk.
    slats = []
    for i in range(14):
        y = 60 + i * 68
        slats.append(path(f"M0 {y}L1920 {y - 160}L1920 {y - 128}L0 {y + 32}Z", "url(#blindlight)"))
    body.append(group(slats, opacity=.8))
    # Blind shadows: thin dark lines.
    for i in range(15):
        y = 92 + i * 68
        body.append(path(f"M0 {y}L1920 {y - 160}", stroke="#000000", stroke_width=7, opacity=.42))

    # Desk: broad wooden mass + leather inlay + brass edge.
    body += [
        rect(0, 760, WIDTH, 320, "url(#deskwood)"),
        rect(0, 760, WIDTH, 10, "#C9A86A", opacity=.35),
        rect(420, 790, 1080, 150, "#1A1410", rx=6),
        rect(420, 790, 1080, 150, "none", stroke="#C9A86A", stroke_width=1, opacity=.3),
        rect(420, 790, 1080, 6, "#C9A86A", opacity=.15),
    ]

    # Banker's lamp: brass stem + green shade + pool of light.
    body += [
        circle(1490, 700, 210, "url(#lampglow)"),
        rect(1478, 620, 24, 150, "#8A6E42"),
        element("ellipse", cx=1490, cy=775, rx=70, ry=10, fill="#0A0806", opacity=.5),
        path("M1380 620L1600 620L1570 545 1410 545Z", "url(#lampshade)", stroke="#C9A86A", stroke_width=1.5),
        path("M1410 545L1570 545 1555 528 1425 528Z", "#1A2E20", stroke="#C9A86A", stroke_width=1),
        rect(1440, 620, 100, 8, "#E6C78B", opacity=.85),
        circle(1490, 632, 60, "url(#lampglow)", opacity=.5),
    ]

    # Whiskey tumbler with amber pour + highlight.
    body += [
        path("M250 700L270 830L390 830L410 700Z", "#FFFFFF", opacity=.08),
        path("M258 730L262 822L398 822L402 730Z", "url(#whiskey)", opacity=.92),
        path("M258 730L402 730 398 745 262 745Z", "#E8B85A", opacity=.5),
        rect(300, 700, 60, 22, "#FFFFFF", opacity=.06, rx=4),
        path("M272 740L280 815", stroke="#F0D090", stroke_width=3, opacity=.35),
        element("ellipse", cx=330, cy=835, rx=75, ry=9, fill="#000000", opacity=.4),
    ]

    # Rose in a dark vase, right of the whiskey.
    body += [
        path("M545 830L555 700 595 700 605 830Z", "#0E0C0A", stroke="#3A2E1E", stroke_width=1.5),
        path("M575 700L573 620", stroke="#2E4028", stroke_width=4),
        path("M574 660Q540 640 520 645Q545 665 574 660Z", "#34492E"),
        rose_bloom(575, 595, 1.15, 11),
        circle(575, 595, 90, "url(#lampglow)", opacity=.25),
    ]

    # Cigar smoke: slow curls rising from an ashtray.
    smoke = [
        path("M1180 790q-30 -50 10 -90t-10 -90 30 -80", stroke="#B8B0A0",
             stroke_width=5, opacity=.10, stroke_linecap="round"),
        path("M1210 795q-40 -55 5 -100t-5 -95 25 -70", stroke="#B8B0A0",
             stroke_width=3, opacity=.12, stroke_linecap="round"),
        path("M1150 800q-20 -45 15 -80", stroke="#B8B0A0",
             stroke_width=2, opacity=.14, stroke_linecap="round"),
    ]
    body += smoke + [
        element("ellipse", cx=1195, cy=800, rx=55, ry=12, fill="#0A0806", stroke="#3A2E1E", stroke_width=1.5),
        rect(1170, 778, 50, 8, "#3A2A1A", rx=4, transform="rotate(-12 1195 782)"),
        circle(1222, 776, 3, "#C96A2B", opacity=.9),
    ]

    # Papers + fountain pen on the desk.
    body += [
        rect(800, 800, 220, 90, "#D8CBB0", opacity=.88, transform="rotate(-4 910 845)"),
        rect(820, 815, 180, 4, "#3A2A1A", opacity=.4, transform="rotate(-4 910 845)"),
        rect(820, 828, 150, 4, "#3A2A1A", opacity=.3, transform="rotate(-4 910 845)"),
        rect(700, 830, 130, 10, "#0A0806", rx=5, transform="rotate(18 765 835)"),
        polygon([(838, 822), (852, 818), (854, 823), (840, 827)], "#C9A86A"),
    ]

    body += [
        rect(0, 0, WIDTH, HEIGHT, "url(#vignette)"),
        rect(0, 0, WIDTH, HEIGHT, "#FFFFFF", filter="url(#grain)", opacity=.04),
    ]
    return "".join(body)


def crest():
    body = [
        definitions(),
        rect(0, 0, WIDTH, HEIGHT, COLORS["background"]),
        element("defs", """
          <radialGradient id="crest-glow" cx=".5" cy=".46" r=".55">
            <stop stop-color="#2A2118"/><stop offset="1" stop-color="#12100C"/>
          </radialGradient>
          <pattern id="damask" width="140" height="140" patternUnits="userSpaceOnUse">
            <path d="M70 10Q85 40 70 70Q55 40 70 10Z" fill="none" stroke="#C9A86A" stroke-width=".7" opacity=".10"/>
            <path d="M70 70Q85 100 70 130Q55 100 70 70Z" fill="none" stroke="#C9A86A" stroke-width=".7" opacity=".08"/>
            <circle cx="0" cy="0" r="2" fill="#C9A86A" opacity=".08"/>
            <circle cx="140" cy="140" r="2" fill="#C9A86A" opacity=".08"/>
          </pattern>
        """),
        rect(0, 0, WIDTH, HEIGHT, "url(#crest-glow)"),
        rect(0, 0, WIDTH, HEIGHT, "url(#damask)"),
    ]
    cx, cy = 960, 500
    # Outer thin rings + tick marks.
    for radius, stroke, opacity, width in [
        (330, "#C9A86A", .35, 1.5), (344, "#C9A86A", .18, 1),
        (380, "#C9A86A", .12, 1), (420, "#7A6A4A", .10, 1),
    ]:
        body.append(circle(cx, cy, radius, "none", stroke=stroke, stroke_width=width, opacity=opacity))
    for i in range(60):
        a = math.tau * i / 60
        r1, r2 = 352, 362
        x1, y1 = cx + r1 * math.cos(a), cy + r1 * math.sin(a)
        x2, y2 = cx + r2 * math.cos(a), cy + r2 * math.sin(a)
        body.append(path(f"M{x1:.1f} {y1:.1f}L{x2:.1f} {y2:.1f}",
                         stroke="#C9A86A", stroke_width=1, opacity=.3))
    # Laurel branches (two mirrored arcs of leaves).
    laurel = []
    for side in (-1, 1):
        for i in range(9):
            t = i / 8
            a = math.pi * (0.72 + t * 0.56) if side < 0 else math.pi * (2.28 - t * 0.56)
            lx, ly = cx + 250 * math.cos(a), cy + 250 * math.sin(a)
            laurel.append(path(
                "M0 0Q-16 -6 -26 -20Q-8 -16 0 0Z", "#4A5A3A",
                stroke="#2A331E", stroke_width=.8, opacity=.85,
                transform=f"translate({lx:.1f} {ly:.1f}) rotate({math.degrees(a) + (90 if side < 0 else -90):.1f})",
            ))
    body.append(group(laurel))
    # The gold signet ring + rose at the centre.
    body += [
        circle(cx, cy, 150, "#171310", stroke="#C9A86A", stroke_width=3),
        circle(cx, cy, 138, "none", stroke="#C9A86A", stroke_width=1, opacity=.5),
        circle(cx, cy, 118, "#1E1813", stroke="#8A6E42", stroke_width=1),
        polygon(star(cx, cy - 88, 10, 5.5, count=5), "#C9A86A", opacity=.9),
        polygon(star(cx - 82, cy + 52, 7, 4, count=5), "#8A6E42", opacity=.7),
        polygon(star(cx + 82, cy + 52, 7, 4, count=5), "#8A6E42", opacity=.7),
    ]
    body.append(rose_bloom(cx, cy + 10, 2.6, 77))
    # Thin gold rules left + right, like an invitation card.
    for y in (880, 892):
        body += [
            path(f"M420 {y}L860 {y}", stroke="#C9A86A", stroke_width=1, opacity=.35),
            path(f"M1060 {y}L1500 {y}", stroke="#C9A86A", stroke_width=1, opacity=.35),
            polygon([(960, y - 7), (967, y), (960, y + 7), (953, y)], "#C9A86A", opacity=.6),
        ]
    body += [
        rect(0, 0, WIDTH, HEIGHT, "url(#vignette)"),
        rect(0, 0, WIDTH, HEIGHT, "#FFFFFF", filter="url(#grain)", opacity=.03),
    ]
    return "".join(body)


def wordmark():
    return "".join([
        circle(64, 64, 30, "none", stroke=COLORS["accent"], stroke_width=2),
        circle(64, 64, 24, "none", stroke=COLORS["accent"], stroke_width=.8, opacity=.5),
        polygon(star(64, 64, 10, 5.5, count=5), COLORS["accent"]),
        text(252, 80, "GODFATHER", 40, COLORS["foreground"],
             font_family="serif", letter_spacing=6, text_anchor="middle"),
        text(252, 102, "THE FAMILY", 11, COLORS["accent"],
             font_family="sans-serif", letter_spacing=5, text_anchor="middle"),
    ])


def preview(office_body):
    c = COLORS
    body = [
        rect(0, 0, 1600, 1120, c["darker_background"]),
        text(64, 68, "G O D F A T H E R", 25, c["foreground"], font_family="serif", letter_spacing=3),
        text(64, 103, "DON'S OFFICE AT NIGHT — A NOIR STUDY", 11, c["muted"], font_family="monospace", letter_spacing=2),
        text(1518, 88, "GF", 44, c["accent"], font_family="serif", text_anchor="end", opacity=.9),
        element("svg", office_body, x=48, y=140, width=1504, height=846, viewBox="0 0 1920 1080"),
    ]
    # A deliberately labelled UI study, not a fabricated desktop screenshot.
    terminal = [
        rect(0, 0, 690, 392, c["background"], rx=6, stroke=c["accent"], stroke_width=1.2),
        rect(1, 1, 688, 35, c["dark_background"], rx=5),
        text(22, 24, "~/family", 12, c["muted"]),
        text(661, 24, "01", 12, c["accent"], text_anchor="end"),
        text(27, 75, "❯", 16, c["accent"]),
        text(49, 75, "cat ledger.py", 15, c["foreground"]),
        text(27, 112, "# An offer you can't refuse.", 15, c["muted"]),
    ]
    rows = [
        [("from ", "magenta"), ("family ", "foreground"), ("import ", "magenta"), ("Oath", "blue")],
        [],
        [("def ", "magenta"), ("seal_deal", "yellow"), ("(oath: ", "foreground"), ("Oath", "blue"), ("):", "foreground")],
        [("    envelope = ", "foreground"), ('"midnight at the docks"', "green")],
        [("    witness = ", "foreground"), ('"the man behind the desk"', "green")],
        [("    return ", "magenta"), ('f"{oath} / {envelope}"', "green")],
        [],
    ]
    for line_number, spans in enumerate(rows):
        content = "".join(element("tspan", escape(value), fill=c[key]) for value, key in spans)
        terminal.append(element("text", content, x=27, y=147 + line_number * 27, font_size=15, xml_space="preserve"))
    terminal += [
        text(27, 346, "❯", 16, c["accent"]),
        rect(48, 332, 9, 19, c["bright_foreground"]),
    ]
    for i, key in enumerate(("red", "yellow", "green", "cyan", "blue", "magenta")):
        terminal.append(rect(520 + i * 22, 342, 15, 7, c[key], rx=2))
    body.append(group(terminal, transform="translate(94 494)", font_family="CaskaydiaMono Nerd Font, monospace"))
    body += [
        rect(66, 158, 1468, 30, c["background"], rx=3),
        text(82, 178, "◆    1   2   3", 12, c["accent"], font_family="monospace"),
        text(800, 178, "FRI  23:47", 11, c["foreground"], font_family="monospace", text_anchor="middle"),
        text(1518, 178, "EN   ◆  84%", 11, c["foreground"], font_family="monospace", text_anchor="end"),
        rect(1164, 216, 350, 94, c["lighter_background"], rx=5, stroke=c["accent"], stroke_width=1),
        text(1185, 245, "The Family", 11, c["accent"], font_family="monospace"),
        text(1185, 270, "Keep your friends close.", 13, c["foreground"], font_family="serif"),
        text(64, 1023, "PALETTE / UI STUDY", 10, c["muted"], font_family="monospace", letter_spacing=1.5),
    ]
    swatches = [("background", "INK"), ("yellow", "GOLD"), ("foreground", "IVORY"),
                ("red", "WINE"), ("green", "SAGE"), ("blue", "STEEL"), ("muted", "SMOKE")]
    for i, (key, label) in enumerate(swatches):
        x = 64 + i * 212
        body += [
            rect(x, 1042, 31, 31, c[key], rx=3, stroke=mix(c[key], c["foreground"], .15), stroke_width=.6),
            text(x + 43, 1053, label, 10, c["foreground"], font_family="monospace", letter_spacing=1),
            text(x + 43, 1071, c[key], 11, c["muted"], font_family="monospace"),
        ]
    return svg("".join(body), 1600, 1120, "Godfather — palette and UI study")


def build_shell():
    """Section overrides keep Omarchy's generated sizing and other surfaces."""
    c = COLORS
    card = {
        "background": c["lighter_background"], "background-alpha": 1.0,
        "text": c["foreground"], "border": c["accent"], "border-alpha": .75,
        "scrim": c["darker_background"], "scrim-alpha": .65,
        "selected-background": c["selection_background"], "selected-background-alpha": 1.0,
        "selected-text": c["selection_foreground"], "selected-border": c["accent"], "selected-border-alpha": .6,
    }
    sections = {
        "menu": card,
        "launcher": card,
        "popups": {
            "background": c["lighter_background"], "background-alpha": 0.92,
            "text": c["foreground"], "border": c["accent"], "border-alpha": .75,
        },
        "bar": {
            "background": c["dark_background"], "background-alpha": 0.88,
            "text": c["foreground"], "active": c["accent"],
        },
        "notifications": {
            "background": c["lighter_background"], "background-alpha": 1.0,
            "text": c["foreground"], "border": c["accent"], "border-alpha": .8,
            "border-width": 1, "countdown": c["accent"],
        },
        "lock": {
            "background": c["dark_background"], "background-alpha": .95,
            "text": c["foreground"], "placeholder": c["dark_foreground"], "text-error": c["red"],
            "border": c["muted"], "border-active": c["accent"], "border-error": c["red"], "border-alpha": 1.0,
            "selection": c["accent"], "selection-alpha": .35,
        },
    }
    for section, values in sections.items():
        lines = ["# Generated by build.py from colors.toml.", f"[{section}]"]
        lines += [f'{key} = "{value}"' if isinstance(value, str) else f"{key} = {value}" for key, value in values.items()]
        (ROOT / f"shell.{section}.toml").write_text("\n".join(lines) + "\n")


def render(source, destination, width, height):
    subprocess.run(
        ["rsvg-convert", "--width", str(width), "--height", str(height), "--output", str(destination)],
        input=source.encode(), check=True,
    )
    print(f"Built {destination.relative_to(ROOT)} ({width} × {height})", flush=True)


def main():
    if not shutil.which("rsvg-convert"):
        raise SystemExit("Install librsvg (rsvg-convert) to rebuild the artwork. The included PNGs are ready to use.")
    artwork = ROOT / "artwork"
    backgrounds = ROOT / "backgrounds"
    artwork.mkdir(exist_ok=True)
    backgrounds.mkdir(exist_ok=True)
    office_body = office()
    scenes = [
        ("01-don-office", office_body, "An original illustration of a mafia don's office at night: venetian-blind light, banker's lamp, whiskey, rose and a city skyline."),
        ("02-family-crest", crest(), "An original gold signet-ring crest with a rose and laurel on warm black, a quiet geometric companion wallpaper."),
    ]
    for name, body, description in scenes:
        source = svg(body, title=f"Godfather — {name[3:]}", description=description)
        (artwork / f"{name}.svg").write_text(source + "\n")
        render(source, backgrounds / f"{name}.png", 3840, 2160)
    (artwork / "wordmark.svg").write_text(svg(wordmark(), 340, 128, "Godfather — The Family") + "\n")
    render(preview(office_body), ROOT / "preview.png", 1600, 1120)
    build_shell()


if __name__ == "__main__":
    main()
