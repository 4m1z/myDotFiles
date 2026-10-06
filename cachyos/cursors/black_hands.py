#!/usr/bin/env python3
"""Make the hand cursors of the ful1e5 Apple (macOS) theme black.

Upstream `apple_cursor` ships `hand1`/`hand2` (which back `pointer`,
`pointing_hand`, `grab`, `grabbing`, ...) as white-with-black-outline in
BOTH the `macOS` and `macOS-White` variants -- they are byte-identical.
macOS itself uses a black hand, so this inverts those bitmaps (black <->
white, antialiased edges included) inside an installed `macOS` theme
directory.

XCursor pixels are premultiplied ARGB: every colour channel must be <=
alpha, and fully transparent pixels must be (0, 0, 0, 0). So the inversion
un-premultiplies, inverts, then re-premultiplies -- and transparent pixels
stay transparent. (A naive 255 - channel inversion turns transparent black
(0,0,0,0) into transparent white (255,255,255,0), which is invalid
premultiplied data and renders as a white square around the hand on
Wayland/Hyprland.)

Idempotent: white artwork is converted to black, files already converted
(including ones broken by the old naive inversion -- detected via invalid
premultiplied pixels and repaired) are left alone on re-runs. Stdlib only.

Usage:
    black_hands.py <theme-dir> [<theme-dir> ...]
"""

import struct
import sys

IMAGE_TYPE = 0xFFFD0002
HAND_FILES = ("hand1", "hand2")


def image_chunks(data):
    """Yield (pos, width, height) for every image chunk in XCursor data."""
    magic, _hlen, _ver, ntoc = struct.unpack_from("<IIII", data, 0)
    if magic != 0x72756358:
        raise ValueError("not an XCursor file")
    for i in range(ntoc):
        typ, _sub, pos = struct.unpack_from("<III", data, 16 + i * 12)
        if typ != IMAGE_TYPE:
            continue
        width, height, _xhot, _yhot, _delay = struct.unpack_from(
            "<IIIII", data, pos + 16
        )
        yield pos, width, height


def white_dominant_data(data):
    """True when the largest image has more white than black opaque pixels."""
    biggest = max(image_chunks(data), key=lambda item: item[1] * item[2])
    pos, width, height = biggest
    start = pos + 36
    black = white = 0
    for j in range(width * height):
        o = start + j * 4
        b, g, r, a = data[o : o + 4]
        if a < 128:
            continue
        lum = (min(255, r * 255 // a) + min(255, g * 255 // a) + min(255, b * 255 // a)) // 3
        if lum < 80:
            black += 1
        elif lum >= 170:
            white += 1
    return white > black


def count_invalid_data(data):
    """Count pixels violating the premultiplied invariant (channel > alpha)."""
    invalid = 0
    for pos, width, height in image_chunks(data):
        start = pos + 36
        for j in range(width * height):
            o = start + j * 4
            if data[o] > data[o + 3] or data[o + 1] > data[o + 3] or data[o + 2] > data[o + 3]:
                invalid += 1
    return invalid


def naive_invert_data(data):
    """Old (broken) inversion: 255 - channel, alpha untouched. Exact inverse."""
    for pos, width, height in image_chunks(data):
        start = pos + 36
        for j in range(width * height):
            o = start + j * 4
            data[o] = 255 - data[o]  # B
            data[o + 1] = 255 - data[o + 1]  # G
            data[o + 2] = 255 - data[o + 2]  # R
            # alpha untouched


def correct_invert_data(data):
    """Premultiplied-safe inversion: transparent stays (0,0,0,0)."""
    for pos, width, height in image_chunks(data):
        start = pos + 36
        for j in range(width * height):
            o = start + j * 4
            b, g, r, a = data[o : o + 4]
            if a == 0:
                data[o] = data[o + 1] = data[o + 2] = 0
                continue
            # Un-premultiply, invert, re-premultiply (integer, rounded).
            ub = min(255, (b * 255 + a // 2) // a)
            ug = min(255, (g * 255 + a // 2) // a)
            ur = min(255, (r * 255 + a // 2) // a)
            ib, ig, ir = 255 - ub, 255 - ug, 255 - ur
            data[o] = (ib * a + 127) // 255
            data[o + 1] = (ig * a + 127) // 255
            data[o + 2] = (ir * a + 127) // 255
            # alpha untouched


def iter_images(path):
    """Yield (position, width, height, bytes) for every image in an XCursor file.

    Kept for backwards compatibility; new code prefers image_chunks().
    """
    with open(path, "rb") as fh:
        data = bytearray(fh.read())
    for pos, width, height in image_chunks(data):
        start = pos + 36
        end = start + width * height * 4
        yield pos, width, height, bytes(data[start:end])


def white_dominant(path):
    """True when the largest image has more white than black opaque pixels."""
    with open(path, "rb") as fh:
        data = bytearray(fh.read())
    return white_dominant_data(data)


def invert_file(path):
    with open(path, "rb") as fh:
        data = bytearray(fh.read())
    if white_dominant_data(data):
        correct_invert_data(data)
    elif count_invalid_data(data) > 0:
        # Broken by the old naive inversion: restore the white original
        # (naive is its own exact inverse), then convert correctly.
        naive_invert_data(data)
        correct_invert_data(data)
    else:
        return False
    with open(path, "wb") as fh:
        fh.write(data)
    return True


def main(argv):
    if not argv:
        print("usage: black_hands.py <theme-dir> [...]", file=sys.stderr)
        return 2
    processed = 0
    for theme_dir in argv:
        for name in HAND_FILES:
            path = f"{theme_dir}/cursors/{name}"
            try:
                with open(path, "rb") as fh:
                    data = bytearray(fh.read())
                try:
                    is_white = white_dominant_data(data)
                    invalid = count_invalid_data(data)
                except (ValueError, struct.error) as exc:
                    print(f"ERROR {path}: {exc}", file=sys.stderr)
                    return 1
                if is_white:
                    correct_invert_data(data)
                    with open(path, "wb") as fh:
                        fh.write(data)
                    print(f"Patched to black: {path}")
                    processed += 1
                elif invalid > 0:
                    naive_invert_data(data)
                    correct_invert_data(data)
                    with open(path, "wb") as fh:
                        fh.write(data)
                    print(f"Repaired to black (was showing white box): {path}")
                    processed += 1
                else:
                    print(f"Already black, skipping: {path}")
            except FileNotFoundError:
                print(f"Not found, skipping: {path}")
            except (ValueError, struct.error, OSError) as exc:
                print(f"ERROR {path}: {exc}", file=sys.stderr)
                return 1
    if processed == 0:
        print("Nothing patched (files already black or missing).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
