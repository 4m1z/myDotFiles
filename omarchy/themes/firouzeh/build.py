#!/usr/bin/env python3
"""Build Firouzeh's original artwork and shell colors (Python 3.11+, librsvg)."""

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
        f"{key.replace('_', '-')}={quoteattr(str(value))}"
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


def svg(body, width=WIDTH, height=HEIGHT, title="Firouzeh", description=""):
    return element(
        "svg",
        element("title", escape(title)) + element("desc", escape(description)) + body,
        xmlns="http://www.w3.org/2000/svg",
        width=width,
        height=height,
        viewBox=f"0 0 {width} {height}",
    )


def pointed_arch(x, bottom, width, height):
    """A tall four-centred-arch-inspired silhouette with a pointed crown."""
    top, shoulder, mid = bottom - height, bottom - height * 0.51, x + width / 2
    return (
        f"M{x},{bottom} V{shoulder} "
        f"C{x},{top + height * .25} {mid - width * .26},{top + height * .12} {mid},{top} "
        f"C{mid + width * .26},{top + height * .12} {x + width},{top + height * .25} "
        f"{x + width},{shoulder} V{bottom} Z"
    )


def definitions():
    tile = [
        rect(0, 0, 48, 48, "#22454E"),
        polygon(star(24, 24, 22, 12.8), "#285D60", stroke="#73988A", stroke_width=0.65),
        polygon(star(24, 24, 12, 6.9), "#213D50", stroke="#B39D6D", stroke_width=0.55),
        circle(24, 24, 2, "#99AE9D"),
        path("M0 0L10 0 0 10M48 0L38 0 48 10M0 48L0 38 10 48M48 48L38 48 48 38",
             stroke="#547E7A", stroke_width=0.8),
    ]
    return element("defs", f"""
      <linearGradient id="sky" x2="0" y2="1">
        <stop stop-color="{COLORS['background']}"/>
        <stop offset=".58" stop-color="#293C51"/>
        <stop offset="1" stop-color="#717474"/>
      </linearGradient>
      <radialGradient id="afterglow" cx=".68" cy=".64" r=".68">
        <stop stop-color="#CAA684" stop-opacity=".24"/>
        <stop offset="1" stop-color="#CAA684" stop-opacity="0"/>
      </radialGradient>
      <linearGradient id="plaster" x1="0" y1="0" x2="1" y2=".5">
        <stop stop-color="#474C53"/><stop offset=".55" stop-color="#746D66"/>
        <stop offset="1" stop-color="#978675"/>
      </linearGradient>
      <linearGradient id="ground" x2="0" y2="1">
        <stop stop-color="#4B555A"/><stop offset=".42" stop-color="#2A3942"/>
        <stop offset="1" stop-color="{COLORS['background']}"/>
      </linearGradient>
      <linearGradient id="water" x1=".2" y1="0" x2=".8" y2="1">
        <stop stop-color="#35696A"/><stop offset=".4" stop-color="#1B454F"/>
        <stop offset="1" stop-color="#142D3B"/>
      </linearGradient>
      <linearGradient id="recess" x2="0" y2="1">
        <stop stop-color="#0E2632"/><stop offset="1" stop-color="#14242E"/>
      </linearGradient>
      <linearGradient id="doorlight" x2="0" y2="1">
        <stop stop-color="#B78451"/><stop offset=".55" stop-color="#E2BB7B"/>
        <stop offset="1" stop-color="#9F754D"/>
      </linearGradient>
      <linearGradient id="reflection" x2="0" y2="1">
        <stop stop-color="white" stop-opacity=".45"/>
        <stop offset="1" stop-color="white" stop-opacity="0"/>
      </linearGradient>
      <radialGradient id="lamplight">
        <stop stop-color="#DDB877" stop-opacity=".26"/>
        <stop offset="1" stop-color="#DDB877" stop-opacity="0"/>
      </radialGradient>
      <radialGradient id="vignette" r=".75">
        <stop offset=".45" stop-color="#090F18" stop-opacity="0"/>
        <stop offset="1" stop-color="#090F18" stop-opacity=".72"/>
      </radialGradient>
      <pattern id="tiles" width="48" height="48" patternUnits="userSpaceOnUse">
        {''.join(tile)}
      </pattern>
      <pattern id="brick" width="68" height="28" patternUnits="userSpaceOnUse">
        <path d="M0 0H68M0 14H68M34 0V14M0 14V28M68 14V28"
          fill="none" stroke="#D1AA63" stroke-opacity=".08" stroke-width=".7"/>
      </pattern>
      <filter id="grain" x="0" y="0" width="100%" height="100%">
        <feTurbulence type="fractalNoise" baseFrequency=".72" numOctaves="3" seed="23" stitchTiles="stitch"/>
        <feColorMatrix type="saturate" values="0"/>
      </filter>
      <clipPath id="pool-clip"><path d="M1138 816H1352L1650 1080H728Z"/></clipPath>
      <mask id="pool-fade"><rect x="700" y="804" width="980" height="290" fill="url(#reflection)"/></mask>
    """)


def cypress(x, base, height, width, seed, dark=False):
    rng = random.Random(seed)
    trunk = "#273C3E" if dark else "#3E504B"
    silhouette = "#0E232B" if dark else "#17323A"
    needle = "#264441" if dark else "#37594E"
    outline = (
        "M0 0 C-17 -4 -35 -5 -39 -21 C-44 -36 -29 -47 -36 -64 "
        "C-41 -82 -24 -94 -29 -114 C-34 -139 -14 -149 -20 -170 "
        "C-25 -194 -7 -208 -10 -233 C-12 -251 -3 -272 0 -300 "
        "C4 -274 13 -260 11 -239 C10 -216 27 -201 22 -179 "
        "C18 -163 37 -141 30 -119 C24 -100 42 -86 37 -65 "
        "C32 -49 46 -32 38 -17 C32 -4 13 0 0 0 Z"
    )
    needles = []
    for _ in range(160):
        y = rng.uniform(-279, -12)
        half_width = 36 * ((y + 300) / 300) ** .72
        sx = rng.uniform(-half_width, half_width)
        length = rng.uniform(3, 12)
        needles.append(path(
            f"M{sx:.2f} {y:.2f}q{rng.uniform(-5, 5):.2f} {-length:.2f} "
            f"{rng.uniform(-3, 3):.2f} {-length * 1.7:.2f}",
            stroke=needle, stroke_width=rng.uniform(.45, 1.1), opacity=rng.uniform(.22, .65),
        ))
    return group([
        path("M-2 15L-1 -252 2 -253 4 15Z", trunk),
        path(outline, silhouette),
        element("clipPath", path(outline), id=f"cypress-{seed}"),
        group(needles, clip_path=f"url(#cypress-{seed})"),
        path("M0 -4Q4 -117 0 -265", stroke=needle, stroke_width=.8, opacity=.48),
    ], transform=f"translate({x} {base}) scale({width / 80} {height / 300})")


def rosette(x, y, radius, opacity=1):
    petals = []
    for i in range(8):
        petals.append(path(
            "M0 -8C-9 -19 -7 -30 0 -38C7 -30 9 -19 0 -8Z",
            "#477976", stroke="#9EA787", stroke_width=.6, transform=f"rotate({i * 45})",
        ))
    return group([
        circle(0, 0, 43, "none", stroke="#B5A276", stroke_width=.7),
        *petals,
        polygon(star(0, 0, 9, 5), "#CAB181"),
    ], transform=f"translate({x} {y}) scale({radius / 43})", opacity=opacity)


def courtyard_building():
    body = [
        # Low courtyard walls and recessed arcades, lit from the right.
        path("M100 610L560 548H1660L1920 626V820H100Z", "url(#plaster)"),
        path("M100 610L560 548H1660L1920 626V644L1660 564H560L100 628Z", "#8C8171"),
        path("M100 626L560 564H1660L1920 644", stroke="#C1AA87", stroke_width=1.3, opacity=.45),
        path("M100 640L560 578H1660L1920 658", stroke="#25363D", stroke_width=6),
        rect(530, 581, 1160, 220, "url(#brick)"),
    ]
    for i, x in enumerate([554, 704, 854, 1512, 1660, 1808]):
        bottom = 797
        body += [
            path(pointed_arch(x, bottom, 109, 182), "#3D4A4E", stroke="#8E8170", stroke_width=4),
            path(pointed_arch(x + 8, bottom, 93, 168), "#22353F"),
            path(pointed_arch(x + 18, bottom, 73, 146), "#172B36"),
            rect(x + 16, 778, 78, 18, "#344449"),
        ]
        if i in (1, 4):
            body += [
                path(pointed_arch(x + 31, 777, 46, 112), "#695948"),
                path(pointed_arch(x + 35, 777, 38, 106), "#92734D", opacity=.65),
                path(f"M{x + 54} 674V777M{x + 35} 722H{x + 73}", stroke="#323A3A", stroke_width=3),
            ]

    # The pishtaq: warm stone around an intricate turquoise tiled iwan.
    body += [
        path("M1031 804V337H1479V804Z", "#857B69"),
        rect(1031, 337, 448, 12, "#B49A78"),
        rect(1040, 353, 430, 442, "#20414B"),
        rect(1050, 363, 410, 422, "url(#tiles)"),
        rect(1064, 376, 382, 410, "none", stroke="#AF9C6C", stroke_width=1.8),
        rect(1070, 382, 370, 404, "none", stroke="#65A49A", stroke_width=2),
        path(pointed_arch(1087, 795, 336, 392), "#BDAB82"),
        path(pointed_arch(1093, 795, 324, 385), "#2C6769"),
        path(pointed_arch(1103, 795, 304, 370), "#538D85"),
        path(pointed_arch(1112, 795, 286, 359), "url(#recess)"),
        path(pointed_arch(1132, 795, 246, 331), "none", stroke="#315958", stroke_width=1.4),
        path(pointed_arch(1151, 795, 208, 301), "none", stroke="#3C6862", stroke_width=1),
        rosette(1105, 410, 22),
        rosette(1405, 410, 22),
        rect(1042, 790, 426, 12, "#586662"),
        rect(1020, 804, 470, 10, "#8B8A76"),
        rect(1005, 814, 500, 9, "#4E6160"),
        path("M1038 337V804M1472 337V804", stroke="#DBBF8B", stroke_width=1, opacity=.4),
        # Ribbed, honeycomb-like detailing in the vault.
        path("M1255 439V574M1255 474L1189 536 1159 615M1255 474L1321 536 1351 615"
             "M1136 582L1189 536 1255 574 1321 536 1374 582"
             "M1159 615L1202 583 1255 618 1308 583 1351 615",
             stroke="#62887A", stroke_width=1.1, opacity=.55),
        circle(1255, 727, 130, "url(#lamplight)"),
        # A single amber-lit wooden doorway at the end of the recess.
        path(pointed_arch(1207, 790, 96, 165), "#534C40", stroke="#857A5B", stroke_width=2),
        path(pointed_arch(1214, 790, 82, 154), "url(#doorlight)"),
        path("M1255 647V790M1214 699H1296M1214 714H1296", stroke="#5C5443", stroke_width=3),
        path("M1222 720H1247V781H1222ZM1263 720H1288V781H1263Z",
             "#A88454", stroke="#695C43", stroke_width=1.5),
        path("M1255 647L1220 700M1255 660L1230 700M1255 674L1242 700"
             "M1255 647L1290 700M1255 660L1280 700M1255 674L1268 700",
             stroke="#766748", stroke_width=1),
        circle(1250, 748, 1.8, "#F2D8A0"),
        circle(1260, 748, 1.8, "#F2D8A0"),
        path("M1214 790H1296L1370 836H1148Z", "#D1AA63", opacity=.13),
    ]

    # Small hand-laid border tiles add scale without competing with the arch.
    for x in range(1078, 1440, 14):
        body.append(polygon([(x, 357), (x + 4, 353), (x + 8, 357), (x + 4, 361)], "#8BB0A0", opacity=.75))
    for y in range(397, 785, 14):
        for x in (1058, 1452):
            body.append(polygon([(x, y - 3), (x + 3, y), (x, y + 3), (x - 3, y)], "#C1AD7F", opacity=.6))
    return group(body, id="courtyard-building")


def pomegranate_branch():
    rng = random.Random(41)
    branches, leaves, fruit = [], [], []

    def twig(x, y, length, angle, depth):
        end_x = x + math.cos(angle) * length
        end_y = y + math.sin(angle) * length
        bend = rng.uniform(-14, 14)
        branches.append(path(
            f"M{x:.2f} {y:.2f}Q{(x + end_x) / 2:.2f} {(y + end_y) / 2 + bend:.2f} {end_x:.2f} {end_y:.2f}",
            stroke="#16282D", stroke_width=depth * 1.7 + 1, stroke_linecap="round",
        ))
        if depth:
            for turn in (-.55, .48):
                twig(end_x, end_y, length * rng.uniform(.55, .77), angle + turn, depth - 1)
        if depth < 3:
            for t in (.35, .62, .88):
                px, py = x + (end_x - x) * t, y + (end_y - y) * t
                for side in (-1, 1):
                    rotation = math.degrees(angle) + side * rng.uniform(25, 65)
                    size = rng.uniform(.65, 1.25)
                    leaves.append(path(
                        "M0 0Q12 -12 32 0Q13 8 0 0Z", rng.choice(["#1C3739", "#28443F", "#345148"]),
                        transform=f"translate({px:.2f} {py:.2f}) rotate({rotation:.2f}) scale({size:.2f})",
                    ))
        if depth == 0 and rng.random() < .35:
            r = rng.uniform(8, 13)
            fruit.extend([
                path(f"M{end_x:.2f} {end_y:.2f}v12", stroke="#253D37", stroke_width=1.4),
                circle(end_x, end_y + 12 + r, r, rng.choice(["#8E4856", "#A55460", "#773E4D"])),
                path("M-4 0L-5 -5 -1 -3 1 -6 3 -3 6 -5 4 1Z", "#A87363",
                     transform=f"translate({end_x:.2f} {end_y + 12:.2f})"),
                path(f"M{end_x - r * .55:.2f} {end_y + 12 + r * .65:.2f}q-2 5 0 8",
                     stroke="#D1977B", stroke_width=1, opacity=.5),
            ])

    twig(-50, 68, 216, -.1, 4)
    twig(-30, 78, 155, .8, 3)
    return group(branches + leaves + fruit)


def courtyard():
    rng = random.Random(32)
    body = [definitions(), rect(0, 0, WIDTH, HEIGHT, "url(#sky)"), rect(0, 0, WIDTH, 850, "url(#afterglow)")]

    # Sparse stars and a slim crescent in the quiet part of the sky.
    for _ in range(76):
        x, y = rng.uniform(100, 1870), rng.uniform(36, 462)
        body.append(circle(round(x, 2), round(y, 2), round(rng.uniform(.45, 1.1), 2), "#E6DAC4", opacity=round(rng.uniform(.12, .52), 2)))
    body += [
        path("M852 178A27 27 0 1 0 880 217A30 30 0 0 1 852 178Z", "#DDCFAB", opacity=.9),
        path("M0 515L105 477 180 493 297 416 391 466 520 421 610 472 729 443 863 491"
             "L1000 465 1128 511 1260 485 1416 524 1525 466 1660 445 1790 495 1920 467V750H0Z", "#354857", opacity=.55),
        path("M0 570L164 540 274 566 408 501 525 532 676 501 790 543 976 515"
             "L1170 563 1350 544 1500 574 1658 506 1822 551 1920 528V803H0Z", "#304452", opacity=.75),
        # Distant garden silhouettes.
        cypress(591, 655, 238, 44, 3),
        cypress(922, 639, 232, 44, 4),
        cypress(1547, 673, 274, 52, 5),
        rect(0, 792, WIDTH, 288, "url(#ground)"),
        courtyard_building(),
    ]

    # Slate paving: long perspective lines and irregular shallow joints.
    for end in (-1400, -620, -80, 390, 770, 1730, 2210, 2750):
        body.append(path(f"M1255 792L{end} 1130", stroke="#87938A", stroke_width=.9, opacity=.12))
    for y in (834, 866, 911, 973, 1056):
        body.append(path(f"M0 {y}Q970 {y - 13} 1920 {y + 2}", stroke="#85938A", stroke_width=1, opacity=.13))

    body += [
        # Narrow garden beds framing the pool approach.
        path("M306 797H923L589 1080H0Z", "#142C32"),
        path("M306 797H923L910 808H308L0 1050V1026Z", "#58675F", opacity=.65),
        path("M1520 803H1818L1920 884V1080H1792Z", "#142B31"),
        path("M1515 797H1828L1920 866V882L1819 808H1525Z", "#7D8070", opacity=.5),
        cypress(516, 855, 493, 109, 11),
        cypress(696, 813, 348, 78, 12),
        cypress(1732, 907, 698, 171, 13, dark=True),
        cypress(1632, 822, 448, 95, 14),
        # Limestone coping, a tiled inner lip, then the water itself.
        path("M1116 800H1377L1720 1080H663Z", "#758D86"),
        path("M1123 805H1370L1698 1080H685Z", "#1E4D54"),
        path("M1131 811H1360L1671 1080H710Z", "#46918A"),
        path("M1138 816H1352L1650 1080H728Z", "url(#water)"),
        group([
            element("use", href="#courtyard-building", transform="translate(0 1614) scale(1 -1)"),
        ], clip_path="url(#pool-clip)", mask="url(#pool-fade)"),
        path("M1138 816H1352M1138 816L728 1080", stroke="#93BCAF", stroke_width=1.2, opacity=.65),
    ]
    ripples = []
    for _ in range(130):
        y = rng.uniform(823, 1080)
        fraction = (y - 816) / 264
        x = rng.uniform(1140 - 410 * fraction, 1352 + 298 * fraction)
        length = rng.uniform(4, 28) * (.45 + fraction)
        ripples.append(path(
            f"M{x:.2f} {y:.2f}q{length / 2:.2f} -1 {length:.2f} 0",
            stroke=rng.choice(["#83B9AD", "#3B7779", "#122F3D", "#769B94"]),
            stroke_width=rng.uniform(.6, 1.5), opacity=rng.uniform(.14, .48),
        ))
    for y, width in [(836, 25), (842, 44), (851, 33), (862, 59), (877, 48), (896, 30), (913, 42), (938, 21)]:
        ripples.append(path(f"M{1255 - width / 2} {y}h{width}", stroke="#D1AA63", stroke_width=1.4, opacity=.36))
    body.append(group(ripples, clip_path="url(#pool-clip)"))

    # A low fountain bowl and a thread of water.
    body += [
        element("ellipse", cx=1252, cy=927, rx=35, ry=8, fill="none", stroke="#8AA99D", stroke_width=.8, opacity=.4),
        path("M1230 916Q1253 944 1276 916Z", "#698C83"),
        element("ellipse", cx=1253, cy=916, rx=23, ry=5, fill="#244B51", stroke="#96A98E", stroke_width=1),
        path("M1253 916V873Q1253 865 1256 864", stroke="#B1C2A5", stroke_width=1, opacity=.75),
        path("M1257 864Q1261 877 1262 900", stroke="#84AA9E", stroke_width=.7, opacity=.5),
        # Foreground cypresses create depth and a dark natural frame.
        cypress(255, 986, 799, 207, 17, dark=True),
        cypress(92, 1080, 647, 192, 18, dark=True),
        pomegranate_branch(),
    ]

    # Tiny leaves along the garden edges, like detail in a miniature painting.
    for _ in range(170):
        x = rng.uniform(336, 865)
        y = rng.uniform(845, 1060)
        if x > 923 - (y - 797) * 1.2:
            continue
        body.append(path(
            "M0 0Q-5 -8 -1 -13Q5 -7 0 0Z", rng.choice(["#2F5148", "#49654F", "#3B6155"]),
            transform=f"translate({x:.1f} {y:.1f}) rotate({rng.uniform(-65, 65):.1f})", opacity=.65,
        ))
    body += [
        rect(0, 0, WIDTH, HEIGHT, "url(#vignette)"),
        rect(0, 0, WIDTH, HEIGHT, "#FFFFFF", filter="url(#grain)", opacity=.035),
    ]
    return "".join(body)


def tilework():
    body = [
        definitions(),
        rect(0, 0, WIDTH, HEIGHT, COLORS["background"]),
        element("defs", """
          <radialGradient id="tile-glow" cx=".84" cy=".52" r=".66">
            <stop stop-color="#23434D"/><stop offset="1" stop-color="#111B26"/>
          </radialGradient>
          <clipPath id="medallion"><circle cx="1640" cy="550" r="418"/></clipPath>
        """),
        rect(0, 0, WIDTH, HEIGHT, "url(#tile-glow)"),
    ]
    cx, cy = 1640, 550
    lattice = []
    for row in range(-5, 6):
        for column in range(-5, 6):
            x, y = cx + column * 92, cy + row * 92
            lattice += [
                polygon(star(x, y, 45, 26.4), "none", stroke="#4B8885", stroke_width=.85, opacity=.5),
                polygon(star(x, y, 34, 20), "#1B353F", stroke="#AE9A6E", stroke_width=.65, opacity=.38),
                polygon(star(x, y, 12, 7), "#507C76", opacity=.6),
                path(f"M{x + 45} {y}L{x + 46} {y + 19} {x + 73} {y + 46} {x + 92} {y + 47}",
                     stroke="#4D827E", stroke_width=.8, opacity=.6),
            ]
    body.append(group(lattice, clip_path="url(#medallion)"))
    for radius, stroke, opacity in [(418, "#54B7AE", .4), (429, "#D1AA63", .27), (444, "#54B7AE", .22), (492, "#54B7AE", .12)]:
        body.append(circle(cx, cy, radius, "none", stroke=stroke, stroke_width=1, opacity=opacity))
    for i in range(48):
        a = math.tau * i / 48
        x, y = cx + 462 * math.cos(a), cy + 462 * math.sin(a)
        body.append(polygon(star(x, y, 8.5, 4.8), "none", stroke="#7A927E", stroke_width=.65, opacity=.42))
    body += [
        polygon(star(cx, cy, 188, 108), "#152D37", stroke="#558B83", stroke_width=1.5),
        polygon(star(cx, cy, 166, 95), "none", stroke="#C1A470", stroke_width=.9, opacity=.6),
        polygon(star(cx, cy, 148, 86), "none", stroke="#558B83", stroke_width=.9, opacity=.5),
        rosette(cx, cy, 76, .75),
        rect(0, 0, WIDTH, HEIGHT, "url(#vignette)"),
        rect(0, 0, WIDTH, HEIGHT, "#FFFFFF", filter="url(#grain)", opacity=.028),
    ]
    return "".join(body)


def wordmark():
    return "".join([
        polygon(star(63, 64, 30, 17.5), "none", stroke=COLORS["accent"], stroke_width=1.4),
        polygon(star(63, 64, 16, 9), "none", stroke=COLORS["yellow"], stroke_width=.9),
        text(215, 86, "فیروزه", 72, COLORS["foreground"], font_family="Noto Naskh Arabic", direction="rtl", text_anchor="middle"),
    ])


def preview(courtyard_body):
    c = COLORS
    body = [
        rect(0, 0, 1600, 1120, c["darker_background"]),
        text(64, 68, "F I R O U Z E H", 25, c["foreground"], font_family="sans-serif"),
        text(64, 103, "AN IRANIAN COURTYARD AT BLUE HOUR", 11, c["muted"], font_family="monospace", letter_spacing=2),
        text(1518, 88, "فیروزه", 64, c["accent"], font_family="Noto Naskh Arabic", direction="rtl"),
        element("svg", courtyard_body, x=48, y=140, width=1504, height=846, viewBox="0 0 1920 1080"),
    ]
    # A deliberately labelled UI study, not a fabricated desktop screenshot.
    terminal = [
        rect(0, 0, 690, 392, c["background"], rx=6, stroke=c["accent"], stroke_width=1.2),
        rect(1, 1, 688, 35, c["dark_background"], rx=5),
        text(22, 24, "~/firouzeh", 12, c["muted"]),
        text(661, 24, "01", 12, c["accent"], text_anchor="end"),
        text(27, 75, "❯", 16, c["accent"]),
        text(49, 75, "cat courtyard.py", 15, c["foreground"]),
        text(27, 112, "# A quiet place to make things.", 15, c["muted"]),
    ]
    rows = [
        [("from ", "magenta"), ("pathlib ", "foreground"), ("import ", "magenta"), ("Path", "blue")],
        [],
        [("def ", "magenta"), ("blue_hour", "yellow"), ("(garden: ", "foreground"), ("Path", "blue"), ("):", "foreground")],
        [("    tiles = ", "foreground"), ('"فیروزه"', "green")],
        [("    light = ", "foreground"), ('"the last amber window"', "green")],
        [("    return ", "magenta"), ('f"{garden} / {tiles} / {light}"', "green")],
        [],
    ]
    for line_number, spans in enumerate(rows):
        content = "".join(element("tspan", escape(value), fill=c[key]) for value, key in spans)
        terminal.append(element("text", content, x=27, y=147 + line_number * 27, font_size=15))
    terminal += [
        text(27, 346, "❯", 16, c["accent"]),
        rect(48, 332, 9, 19, c["bright_foreground"]),
    ]
    for i, key in enumerate(("red", "yellow", "green", "cyan", "blue", "magenta")):
        terminal.append(rect(520 + i * 22, 342, 15, 7, c[key], rx=2))
    body.append(group(terminal, transform="translate(94 494)", font_family="CaskaydiaMono Nerd Font, monospace"))
    body += [
        rect(66, 158, 1468, 30, c["background"], rx=3),
        text(82, 178, "◈    1   2   3", 12, c["accent"], font_family="monospace"),
        text(800, 178, "THU  18:42", 11, c["foreground"], font_family="monospace", text_anchor="middle"),
        text(1518, 178, "EN   ▰  84%", 11, c["foreground"], font_family="monospace", text_anchor="end"),
        rect(1164, 216, 350, 94, c["lighter_background"], rx=5, stroke=c["accent"], stroke_width=1),
        text(1185, 245, "FIRouzeh", 11, c["accent"], font_family="monospace"),
        text(1185, 270, "A little stillness, on your desktop.", 13, c["foreground"], font_family="sans-serif"),
        text(64, 1023, "PALETTE / UI STUDY", 10, c["muted"], font_family="monospace", letter_spacing=1.5),
    ]
    swatches = [("background", "INK"), ("cyan", "GLAZE"), ("foreground", "IVORY"), ("yellow", "GOLD"), ("red", "ANAR"), ("green", "SARV"), ("blue", "LAPIS")]
    for i, (key, label) in enumerate(swatches):
        x = 64 + i * 212
        body += [
            rect(x, 1042, 31, 31, c[key], rx=3, stroke=mix(c[key], c["foreground"], .15), stroke_width=.6),
            text(x + 43, 1053, label, 10, c["foreground"], font_family="monospace", letter_spacing=1),
            text(x + 43, 1071, c[key], 11, c["muted"], font_family="monospace"),
        ]
    return svg("".join(body), 1600, 1120, "Firouzeh — palette and UI study")


def build_shell():
    """Section overrides keep Omarchy's generated sizing and other surfaces."""
    c = COLORS
    card = {
        "background": c["lighter_background"], "background-alpha": 1.0,
        "text": c["foreground"], "border": c["accent"], "border-alpha": .75,
        "scrim": c["darker_background"], "scrim-alpha": .55,
        "selected-background": c["selection_background"], "selected-background-alpha": 1.0,
        "selected-text": c["selection_foreground"], "selected-border": c["accent"], "selected-border-alpha": .6,
    }
    sections = {
        "menu": card,
        "launcher": card,
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
    courtyard_body = courtyard()
    scenes = [
        ("01-blue-hour-courtyard", courtyard_body, "An original illustration of an Iranian garden courtyard: turquoise tilework, a reflecting pool, cypress trees and pomegranates at dusk."),
        ("02-midnight-tilework", tilework(), "An original eight-pointed star medallion on midnight ink, inspired by Iranian geometric tilework."),
    ]
    for name, body, description in scenes:
        source = svg(body, title=f"Firouzeh — {name[3:]}", description=description)
        (artwork / f"{name}.svg").write_text(source + "\n")
        render(source, backgrounds / f"{name}.png", 3840, 2160)
    (artwork / "wordmark.svg").write_text(svg(wordmark(), 340, 128, "Firouzeh — فیروزه") + "\n")
    render(preview(courtyard_body), ROOT / "preview.png", 1600, 1120)
    build_shell()


if __name__ == "__main__":
    main()
