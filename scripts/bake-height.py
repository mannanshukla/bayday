#!/usr/bin/env python3
"""Builds a region's elevation grid from Mapzen / AWS Terrain Tiles (Terrarium PNGs).

Usage: python3 scripts/bake-height.py <centre latitude> <centre longitude> <cache folder> <output height.bin> [--land-cover]

The output is 1025 x 1025 little-endian Int16 samples in decimetres, row 0 at the north
edge, covering the 49.28 km square world centred on the given point. No dependencies.

The game treats anything at or below 0.5 m as water. Where rivers and harbours do not sit
at sea level in the elevation data (New York), pass --land-cover: open water is then taken
from the USGS National Land Cover Database, water cells are written at or below zero and
land cells at 0.6 m or higher.
"""
import math, os, struct, sys, urllib.parse, urllib.request, zlib

lat0, lon0, cache, out = float(sys.argv[1]), float(sys.argv[2]), sys.argv[3], sys.argv[4]
land_cover = "--land-cover" in sys.argv
HALF, N, Z = 24640.0, 1025, 12
M_LAT = 111132.92 - 559.82 * math.cos(2 * math.radians(lat0))
M_LON = 111320.0 * math.cos(math.radians(lat0))

def decode(data):
    """Decodes a non-interlaced PNG (RGB, RGBA or palette) to rows of (r, g, b) tuples."""
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    pos, idat, plte = 8, b"", None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            width, height, depth, colour, _, _, interlace = struct.unpack(">IIBBBBB", body)
            assert interlace == 0 and colour in (2, 3, 6), (depth, colour, interlace)
        elif kind == b"PLTE": plte = body
        elif kind == b"IDAT": idat += body
        pos += 12 + length
    channels = {2: 3, 3: 1, 6: 4}[colour]
    bpp = max(1, channels * depth // 8)
    stride = (width * channels * depth + 7) // 8
    raw, rows, prev = zlib.decompress(idat), [], bytearray(stride)
    for y in range(height):
        f = raw[y * (stride + 1)]
        line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if f == 1: line[i] = (line[i] + a) & 255
            elif f == 2: line[i] = (line[i] + b) & 255
            elif f == 3: line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        prev = line
        if colour == 3:
            out = []
            for x in range(width):
                bit = x * depth
                index = (line[bit >> 3] >> (8 - depth - (bit & 7))) & ((1 << depth) - 1)
                out.append(tuple(plte[index * 3:index * 3 + 3]))
            rows.append(out)
        else:
            rows.append([tuple(line[x * channels:x * channels + 3]) for x in range(width)])
    return rows

tiles = {}
def tile(x, y):
    if (x, y) not in tiles:
        path = os.path.join(cache, f"{Z}_{x}_{y}.png")
        if not os.path.exists(path):
            url = f"https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{Z}/{x}/{y}.png"
            with urllib.request.urlopen(url, timeout=60) as r, open(path, "wb") as f:
                f.write(r.read())
        tiles[(x, y)] = decode(open(path, "rb").read())
    return tiles[(x, y)]

def metres(px, py):
    r, g, b = tile(int(px // 256), int(py // 256))[int(py % 256)][int(px % 256)]
    return r * 256 + g + b / 256 - 32768

def sample(lat, lon):
    scale = 256 * 2 ** Z
    px = (lon + 180) / 360 * scale - 0.5
    r = math.radians(lat)
    py = (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * scale - 0.5
    x, y = math.floor(px), math.floor(py)
    a, b = px - x, py - y
    return (metres(x, y) * (1 - a) + metres(x + 1, y) * a) * (1 - b) + (metres(x, y + 1) * (1 - a) + metres(x + 1, y + 1) * a) * b

os.makedirs(cache, exist_ok=True)
cover = None
if land_cover:
    # One image whose pixel centres are the grid points: rows run north to south.
    path = os.path.join(cache, f"land-cover_{lat0}_{lon0}_{N}.png")   # one mask per region
    if not os.path.exists(path):
        pad = HALF + HALF / (N - 1)
        box = f"{lon0 - pad / M_LON},{lat0 - pad / M_LAT},{lon0 + pad / M_LON},{lat0 + pad / M_LAT}"
        layer = "NLCD_2021_Land_Cover_L48"
        query = urllib.parse.urlencode({"service": "WMS", "version": "1.1.1", "request": "GetMap", "layers": layer, "styles": "", "srs": "EPSG:4326", "bbox": box, "width": N, "height": N, "format": "image/png"})
        request = urllib.request.Request(f"https://www.mrlc.gov/geoserver/mrlc_display/{layer}/wms?{query}", headers={"User-Agent": "height-bake/1.0"})
        with urllib.request.urlopen(request, timeout=180) as r, open(path, "wb") as f:
            f.write(r.read())
    cover = decode(open(path, "rb").read())
OPEN_WATER, NO_DATA = (71, 107, 160), (255, 255, 255)
values, wet = [], 0
for j in range(N):
    lat = lat0 - (-HALF + 2 * HALF * j / (N - 1)) / M_LAT
    for i in range(N):
        lon = lon0 + (-HALF + 2 * HALF * i / (N - 1)) / M_LON
        h = sample(lat, lon)
        if h < -500: h = 0.0                      # voids in the source tiles
        if cover:
            c = cover[j][i]
            # Only water near sea level is flattened; a reservoir on a hill keeps its height.
            if h <= 8 and (c == OPEN_WATER or (c == NO_DATA and h <= 1)): h, wet = max(-50.0, min(h, 0.0)), wet + 1
            else: h = max(h, 0.6)
        values.append(max(-32768, min(32767, round(h * 10))))
with open(out, "wb") as f:
    f.write(struct.pack(f"<{N * N}h", *values))
land = sum(1 for v in values if v > 5)
print(f"{out}: {len(tiles)} tiles, min {min(values) / 10} m, max {max(values) / 10} m, {100 * land // len(values)}% land, metres per degree {M_LAT:.1f} lat / {M_LON:.1f} lon")
