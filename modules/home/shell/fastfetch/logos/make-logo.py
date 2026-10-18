#!/usr/bin/env python3
"""Turn a logo bitmap into the extruded, pseudo-3D logos in this folder.

The face is drawn with quadrant block characters (2x2 dots per cell) in
truecolor, and the extrusion runs down and to the right, darker the deeper it
goes. A cell that holds two colours sets both fg and bg, so the edge between
face and side stays sharp. Output is raw ANSI, read by fastfetch as a
`file-raw` logo.

Regenerate (Python 3, resvg and ImageMagick, no Python packages):

    curl -fsSLO https://cdn.jsdelivr.net/npm/simple-icons@latest/icons/apple.svg
    resvg -w 1200 -h 1200 --background white apple.svg apple.png
    magick apple.png -colorspace Gray -depth 8 apple.pgm
    python3 make-logo.py apple apple.pgm apple.ans

Same for `nixos`. Optional trailing arguments: width in cells, extrusion
depth in cells, extrusion angle in degrees.
"""
import math
import sys

SX, SY = 6, 12  # dots per terminal cell; cells are about 1:2

APPLE_STRIPES = ("61BB46", "FDB827", "F5821F", "E03A3E", "963D97", "009DDC")
NIX_LIGHT, NIX_DARK = "7EBAE4", "5277C3"
DEFAULT_COLS = {"apple": 34, "nixos": 38}

QUADRANTS = {
    "0000": " ", "1000": "▘", "0100": "▝", "0010": "▖", "0001": "▗",
    "1100": "▀", "0011": "▄", "1010": "▌", "0101": "▐", "1001": "▚",
    "0110": "▞", "1011": "▙", "1110": "▛", "1101": "▜", "0111": "▟", "1111": "█",
}


def load_pgm(path):
    """Read a binary (P5) PGM. Returns width, height and the pixel bytes."""
    with open(path, "rb") as f:
        data = f.read()
    if not data.startswith(b"P5"):
        sys.exit(f"{path}: not a binary PGM (P5)")
    tokens, idx = [], 0
    while len(tokens) < 4:
        while data[idx:idx + 1].isspace():
            idx += 1
        if data[idx:idx + 1] == b"#":
            while data[idx:idx + 1] not in (b"\n", b""):
                idx += 1
            continue
        start = idx
        while not data[idx:idx + 1].isspace():
            idx += 1
        tokens.append(data[start:idx])
    w, h = int(tokens[1]), int(tokens[2])
    return w, h, data[idx + 1:idx + 1 + w * h]


def rgb(hexstr):
    return tuple(int(hexstr[i:i + 2], 16) for i in (0, 2, 4))


def components(mask, gw, gh):
    """4-connected components of a boolean grid: label grid and sizes."""
    lab = [[-1] * gw for _ in range(gh)]
    sizes = []
    for y in range(gh):
        for x in range(gw):
            if not mask[y][x] or lab[y][x] >= 0:
                continue
            cid, stack, n = len(sizes), [(x, y)], 0
            lab[y][x] = cid
            while stack:
                cx, cy = stack.pop()
                n += 1
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < gw and 0 <= ny < gh and mask[ny][nx] and lab[ny][nx] < 0:
                        lab[ny][nx] = cid
                        stack.append((nx, ny))
            sizes.append(n)
    return lab, sizes


def rasterize(pgm, cols, depth, dx, dy):
    """Scale the dark pixels of the bitmap onto a grid of dots."""
    w, h, pix = load_pgm(pgm)
    dark = [i for i in range(w * h) if pix[i] < 128]
    if not dark:
        sys.exit(f"{pgm}: no dark pixels")
    xs = [i % w for i in dark]
    ys = [i // w for i in dark]
    bx0, bx1, by0, by1 = min(xs), max(xs), min(ys), max(ys)

    scale = (cols * SX - math.ceil(depth * dx) - 1) / (bx1 - bx0 + 1)
    rows = math.ceil(((by1 - by0 + 1) * scale + depth * dy + 1) / SY)
    gw, gh = cols * SX, rows * SY

    face = [[False] * gw for _ in range(gh)]
    for gy in range(gh):
        for gx in range(gw):
            hits = 0
            for oy in (0.17, 0.5, 0.83):
                for ox in (0.17, 0.5, 0.83):
                    px = int(bx0 + (gx + ox) / scale)
                    py = int(by0 + (gy + oy) / scale)
                    if bx0 <= px <= bx1 and by0 <= py <= by1 and pix[py * w + px] < 128:
                        hits += 1
            face[gy][gx] = hits >= 5
    return face, gw, gh, rows


def apple_colors(face, gw, gh):
    """Rainbow stripes across the body; the leaf is the top stripe."""
    stripes = [rgb(c) for c in APPLE_STRIPES]
    lab, sizes = components(face, gw, gh)
    body = max(range(len(sizes)), key=sizes.__getitem__)
    body_rows = [y for y in range(gh) if body in lab[y]]
    top, bottom = min(body_rows), max(body_rows)

    def color(x, y):
        if lab[y][x] != body:
            return stripes[0]
        band = int((y - top) / (bottom - top + 1) * len(stripes))
        return stripes[max(0, min(band, len(stripes) - 1))]

    return color


def nixos_colors(face, gw, gh):
    """The six lambdas alternate between the two snowflake blues."""
    light, dark = rgb(NIX_LIGHT), rgb(NIX_DARK)
    lab, sizes = components(face, gw, gh)
    biggest = max(sizes)
    lambdas = [i for i, n in enumerate(sizes) if n > biggest * 0.3]
    centre = {}
    for cid in lambdas:
        pts = [(x, y) for y in range(gh) for x in range(gw) if lab[y][x] == cid]
        centre[cid] = (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))
    around = sorted(lambdas, key=lambda c: math.atan2(centre[c][1] - gh / 2, centre[c][0] - gw / 2))
    tone = {cid: (light if k % 2 == 0 else dark) for k, cid in enumerate(around)}
    return lambda x, y: tone.get(lab[y][x], light)


def extrude(face, gw, gh, depth, dx, dy, face_color):
    """For each dot behind the face: how deep it sits (0..1) and its source colour."""
    steps = []
    for k in range(1, depth + 1):
        step = (round(k * dx), round(k * dy))
        if not steps or steps[-1][1:] != step:
            steps.append((k, *step))
    side = [[None] * gw for _ in range(gh)]
    for gy in range(gh):
        for gx in range(gw):
            if face[gy][gx]:
                continue
            for k, ox, oy in steps:
                sx, sy = gx - ox, gy - oy
                if 0 <= sx < gw and 0 <= sy < gh and face[sy][sx]:
                    side[gy][gx] = (k / depth, face_color(sx, sy))
                    break
    return side


def shade(frac, base):
    """Side colour: the face colour, darker the deeper it sits."""
    f = 0.60 - 0.34 * frac
    return tuple(int(c * f) for c in base)


def quadrant_color(face, side, face_color, x0, y0):
    """Colour of one quadrant of a cell (half its width and height), or None."""
    n_face, face_votes, side_dots = 0, {}, []
    for y in range(y0, y0 + SY // 2):
        for x in range(x0, x0 + SX // 2):
            if face[y][x]:
                n_face += 1
                c = face_color(x, y)
                face_votes[c] = face_votes.get(c, 0) + 1
            elif side[y][x]:
                side_dots.append(side[y][x])
    half = (SX // 2) * (SY // 2) / 2
    filled = n_face + len(side_dots)
    if n_face >= half or (filled >= half and n_face >= len(side_dots)):
        return max(face_votes, key=face_votes.get)
    if filled >= half:
        frac = sum(d for d, _ in side_dots) / len(side_dots)
        bases = {}
        for _, b in side_dots:
            bases[b] = bases.get(b, 0) + 1
        return shade(frac, max(bases, key=bases.get))
    return None


def cell(quads):
    """Pick a quadrant character plus fg/bg colours for four quadrant colours."""
    filled = [c for c in quads if c]
    if not filled:
        return " ", None, None
    counts = {}
    for c in filled:
        counts[c] = counts.get(c, 0) + 1
    ranked = sorted(counts, key=lambda c: -counts[c])
    if len(filled) < 4:  # some quadrant is empty, so only fg is free
        pattern = "".join("1" if c else "0" for c in quads)
        return QUADRANTS[pattern], ranked[0], None
    if len(ranked) == 1:
        return "█", ranked[0], None
    a, b = ranked[0], ranked[1]

    def dist(p, q):
        return sum((i - j) ** 2 for i, j in zip(p, q))

    pattern = "".join("1" if dist(c, a) <= dist(c, b) else "0" for c in quads)
    return QUADRANTS[pattern], a, b


def render(kind, pgm, cols, depth_cells, angle):
    dx, dy = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    depth = int(depth_cells * SX)
    face, gw, gh, rows = rasterize(pgm, cols, depth, dx, dy)
    face_color = (apple_colors if kind == "apple" else nixos_colors)(face, gw, gh)
    side = extrude(face, gw, gh, depth, dx, dy, face_color)

    lines = []
    for cy in range(rows):
        out, current = [], (None, None)
        for cx in range(cols):
            quads = [
                quadrant_color(face, side, face_color, cx * SX + qx * (SX // 2), cy * SY + qy * (SY // 2))
                for qy in (0, 1)
                for qx in (0, 1)
            ]
            char, fg, bg = cell(quads)
            if (fg, bg) != current:
                seq = "\x1b[0m"
                if fg:
                    seq += "\x1b[38;2;%d;%d;%dm" % fg
                if bg:
                    seq += "\x1b[48;2;%d;%d;%dm" % bg
                out.append(seq)
                current = (fg, bg)
            out.append(char)
        out.append("\x1b[0m")
        lines.append("".join(out))

    def blank(line):
        return line.replace("\x1b[0m", "").strip() == ""

    while lines and blank(lines[0]):
        lines.pop(0)
    while lines and blank(lines[-1]):
        lines.pop()
    return lines


def main():
    if len(sys.argv) < 4 or sys.argv[1] not in DEFAULT_COLS:
        sys.exit("usage: make-logo.py {apple|nixos} in.pgm out.ans [cols] [depth] [angle]")
    kind, src, dst = sys.argv[1:4]
    cols = int(sys.argv[4]) if len(sys.argv) > 4 else DEFAULT_COLS[kind]
    depth = float(sys.argv[5]) if len(sys.argv) > 5 else 4
    angle = float(sys.argv[6]) if len(sys.argv) > 6 else 40
    lines = render(kind, src, cols, depth, angle)
    with open(dst, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"{dst}: {len(lines)} rows x {cols} cols")


if __name__ == "__main__":
    main()
