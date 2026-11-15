#!/usr/bin/env python3
"""Builds a region's elevation grid from Mapzen / AWS Terrain Tiles (Terrarium PNGs).

Usage: python3 scripts/bake-height.py <centre latitude> <centre longitude> <cache folder> <output height.bin> [--land-cover | --surface-water]

The output is 1025 x 1025 little-endian Int16 samples in decimetres, row 0 at the north
edge, covering the 49.28 km square world centred on the given point. No dependencies.

The game treats anything at or below 0.5 m as water. Where rivers and harbours do not sit
at sea level in the elevation data (New York), pass --land-cover: open water is then taken
from the USGS National Land Cover Database, water cells are written at or below zero and
land cells at 0.6 m or higher.

Anywhere else in the world, pass --surface-water: water is taken from the JRC Global Surface
Water occurrence tiles (plus anything below sea level in the elevation data) and written as
a separate bit mask, water.bin, beside the grid. Heights are left as they are, so a river
above sea level keeps its real surface height.
"""
import math, os, struct, sys, urllib.error, urllib.parse, urllib.request, zlib

lat0, lon0, cache, out = float(sys.argv[1]), float(sys.argv[2]), sys.argv[3], sys.argv[4]
land_cover = "--land-cover" in sys.argv
use_surface_water = "--surface-water" in sys.argv
HALF, N, Z = 24640.0, 1025, 12
M_LAT = 111132.92 - 559.82 * math.cos(2 * math.radians(lat0))
M_LON = 111320.0 * math.cos(math.radians(lat0))

def decode(data):
    """Decodes a non-interlaced PNG (RGB, RGBA or palette) to rows of (r, g, b) or (r, g, b, a) tuples."""
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
            rows.append([tuple(line[x * channels:(x + 1) * channels]) for x in range(width)])
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
    r, g, b = tile(int(px // 256), int(py // 256))[int(py % 256)][int(px % 256)][:3]
    return r * 256 + g + b / 256 - 32768

water_tiles = {}
def surface_water(lat, lon):
    """True where the JRC Global Surface Water tiles show water present most of the time."""
    scale = 256 * 2 ** Z
    px = (lon + 180) / 360 * scale
    r = math.radians(lat)
    py = (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * scale
    key = (int(px // 256), int(py // 256))
    if key not in water_tiles:
        path = os.path.join(cache, f"water_{Z}_{key[0]}_{key[1]}.png")
        if not os.path.exists(path):
            url = f"https://storage.googleapis.com/global-surface-water/tiles2021/occurrence/{Z}/{key[0]}/{key[1]}.png"
            try:
                with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "height-bake/1.0"}), timeout=60) as r2, open(path, "wb") as f:
                    f.write(r2.read())
            except urllib.error.HTTPError:
                open(path, "wb").close()          # no tile: no surface water there
        data = open(path, "rb").read()
        water_tiles[key] = decode(data) if data else None
    rows = water_tiles[key]
    if rows is None: return False
    p = rows[int(py % 256)][int(px % 256)]
    # Transparent is dry. The palette runs from red (rarely wet) to blue (always wet).
    return len(p) == 4 and p[3] > 0 and p[2] > p[0]

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
values, wet, mask = [], 0, bytearray((N * N + 7) // 8)
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
        if use_surface_water and (h < -1 or surface_water(lat, lon)):
            k = j * N + i
            mask[k >> 3] |= 1 << (k & 7)
            wet += 1
        values.append(max(-32768, min(32767, round(h * 10))))
# Remove spikes: a sample far from all of its neighbours is bad source data, not terrain.
fixed = 0
for j in range(N):
    for i in range(N):
        v = values[j * N + i]
        around = sorted(values[y * N + x] for y in (j - 1, j, j + 1) for x in (i - 1, i, i + 1) if 0 <= x < N and 0 <= y < N and (x, y) != (i, j))
        median = around[len(around) // 2]
        if abs(v - median) > 2500 or v > 30000:
            values[j * N + i] = median if abs(median) < 30000 else 0
            fixed += 1
if fixed: print(f"replaced {fixed} spike samples")
with open(out, "wb") as f:
    f.write(struct.pack(f"<{N * N}h", *values))
if use_surface_water:
    with open(os.path.join(os.path.dirname(out), "water.bin"), "wb") as f:
        f.write(mask)
land = N * N - wet if use_surface_water else sum(1 for v in values if v > 5)
print(f"{out}: {len(tiles)} tiles, min {min(values) / 10} m, max {max(values) / 10} m, {100 * land // len(values)}% land, metres per degree {M_LAT:.1f} lat / {M_LON:.1f} lon")
