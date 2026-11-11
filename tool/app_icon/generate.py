"""Renders the D2 app icon («Плитки Г→А») for Android, iOS, VK and OK.

Run from the project root:
    python tool/app_icon/generate.py

Needs fonttools, skia-pathops, resvg-py and pillow.
"""

import io
import json
import math
from pathlib import Path

import pathops
from fontTools.misc.transform import Identity, Transform
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib import SVGPath
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from PIL import Image
from resvg_py import svg_to_bytes

ROOT = Path(__file__).resolve().parents[2]
OUT_SRC = ROOT / 'tool/app_icon'
RES = ROOT / 'android/app/src/main/res'
IOS = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
VK = OUT_SRC / 'vk'
OK = OUT_SRC / 'ok'

VIOLET = '#5B3DF5'
INK = '#1B1340'
WHITE = '#FFFFFF'
ORANGE = '#FF7A1A'
BLACK = '#000000'
BG = '#F1EEFF'
INK_SOFT = '#5B5480'
EDGE = '#D6CEFA'
YELLOW = '#FFC93C'
MINT = '#52D6A4'
SKY = '#8EC9FF'

# Highlighted last letter of a city
LETTER = '#B84E00'

# Adaptive icons show the middle 72 of the 108 dp canvas
ADAPTIVE_VISIBLE = 72 / 108

# Tile layout of D2-Brand in a 100-unit box: top-left corners of the two tiles
TILES = [('Г', 6, 4, WHITE), ('А', 40, 38, ORANGE)]
TILE = 52
RADIUS = 12
BORDER = 3
SHADOW = 5
FONT_SIZE = 26
BASELINE = 35.75

# Gap that separates the tiles in the themed icon
GAP = 4



def load_font(name, weight):
    font = instantiateVariableFont(TTFont(ROOT / f'assets/fonts/{name}[wght].ttf'), {'wght': weight})

    return font.getGlyphSet(), font.getBestCmap(), font['head'].unitsPerEm


UNBOUNDED = load_font('Unbounded', 700)
RUBIK = load_font('Rubik', 500)


def canvas(scale):
    """Maps the 100-unit tile box to the centre of the 108 canvas"""
    return Transform(scale, 0, 0, scale, 54 - 50 * scale, 54 - 50 * scale)


def shape(transform, markup):
    """Outline of SVG shape markup such as a rect or a path"""
    path = pathops.Path()
    source = f'<svg xmlns="http://www.w3.org/2000/svg">{markup}</svg>'
    SVGPath.fromstring(source.encode(), transform=transform).draw(path.getPen())

    return path


def rect(transform, x, y, inset=0, width=TILE, height=TILE, radius=RADIUS):
    return shape(
        transform,
        f'<rect x="{x - inset}" y="{y - inset}" width="{width + 2 * inset}"'
        f' height="{height + 2 * inset}" rx="{radius + inset}"/>',
    )


def advance(font, string, size):
    glyphs, cmap, upem = font

    return sum(glyphs[cmap[ord(char)]].width for char in string) * size / upem


def text(transform, font, string, x, baseline, size, length=None):
    """Outline of a line of text, overlapping contours merged.

    With ``length`` the letter spacing is stretched to that width, as SVG textLength does.
    """
    glyphs, cmap, upem = font
    k = size / upem
    names = [cmap[ord(char)] for char in string]
    natural = sum(glyphs[name].width for name in names) * k
    spacing = (length - natural) / (len(names) - 1) if length else 0
    path = pathops.Path()

    # Cyrillic letters may be components of Latin ones, the glyph set resolves them
    pen = TransformPen(path.getPen(glyphSet=glyphs), transform)

    for name in names:
        glyphs[name].draw(TransformPen(pen, (k, 0, 0, -k, x, baseline)))
        x += glyphs[name].width * k + spacing

    return pathops.simplify(path)


def letter(transform, char, x, y):
    """Glyph centred on its tile"""
    width = advance(UNBOUNDED, char, FONT_SIZE)

    return text(transform, UNBOUNDED, char, x + TILE / 2 - width / 2, y + BASELINE, FONT_SIZE)


def tile(transform, char, x, y, fill):
    """One letter tile with its hard shadow"""
    return [
        (rect(transform, x, y + SHADOW), INK, None, 0),
        (rect(transform, x, y), fill, INK, BORDER * transform[0]),
        (letter(transform, char, x, y), INK, None, 0),
    ]


def colored(transform):
    """Both tiles as in D2-Brand: (path, fill, stroke, stroke width)"""
    return [layer for char, x, y, fill in TILES for layer in tile(transform, char, x, y, fill)]


def silhouette(transform):
    """Themed icon: tiles with cut-out letters, each tile clears a gap in the one below"""
    layers = []

    for index, (char, x, y, _) in enumerate(TILES):
        tile = pathops.op(rect(transform, x, y), letter(transform, char, x, y), pathops.PathOp.DIFFERENCE)

        for _, above_x, above_y, _ in TILES[index + 1:]:
            gap = rect(transform, above_x, above_y, inset=GAP)
            tile = pathops.op(tile, gap, pathops.PathOp.DIFFERENCE)

        layers.append((tile, BLACK, None, 0))

    return layers


def lockup(transform, caption=INK_SOFT, title=INK):
    """Main logo lockup of D2-Brand: tiles, «сыграем в» and «Города», 278.82×84"""
    return colored(transform.translate(0, 4).scale(.76)) + [
        (text(transform, RUBIK, 'сыграем в', 89, 24, 15), caption, None, 0),
        (text(transform, UNBOUNDED, 'Города', 88, 64, 37, length=176.82), title, None, 0),
    ]


LOCKUP_WIDTH = 278.82
LOCKUP_HEIGHT = 84


def number(value):
    text = f'{value:.3f}'.rstrip('0').rstrip('.')

    return '0' if text == '-0' else text


def path_data(path):
    pen = SVGPathPen(None, ntos=number)
    path.draw(pen)

    return pen.getCommands()


def svg(background, layers, width=108, height=108):
    body = ''.join(
        f'<path d="{path_data(path)}" fill="{fill}"'
        + (f' stroke="{stroke}" stroke-width="{number(width)}"' if stroke else '')
        + '/>'
        for path, fill, stroke, width in layers
    )

    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {number(width)} {number(height)}">{background}{body}</svg>'


def vector(layers):
    paths = ''.join(
        f'\n    <path\n        android:fillColor="{fill}"'
        + (f'\n        android:strokeColor="{stroke}"\n        android:strokeWidth="{number(width)}"' if stroke else '')
        + f'\n        android:pathData="{path_data(path)}" />'
        for path, fill, stroke, width in layers
    )

    return f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by tool/app_icon/generate.py -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">{paths}
</vector>
'''


SQUARE = f'<rect width="108" height="108" fill="{VIOLET}"/>'
ROUNDED = f'<rect width="108" height="108" rx="26" fill="{VIOLET}"/>'
CIRCLE = f'<circle cx="54" cy="54" r="54" fill="{VIOLET}"/>'

FULL = svg(SQUARE, colored(canvas(.64)))
LEGACY = svg(ROUNDED, colored(canvas(.64)))
LEGACY_ROUND = svg(CIRCLE, colored(canvas(.6)))

# At 32 px the tiles need more room to stay readable
SMALL = svg(SQUARE, colored(canvas(.84)))

FOREGROUND = colored(canvas(.64 * ADAPTIVE_VISIBLE))
MONOCHROME = silhouette(canvas(.64 * ADAPTIVE_VISIBLE))


# Letter tiles scattered around the banner: letter, left, top, size, fill, turn in degrees
BANNER_TILES = [
    ('К', 56, 64, 124, YELLOW, -12),
    ('Р', 1096, 44, 112, WHITE, 10),
    ('Т', 36, 492, 118, SKY, 8),
    ('Н', 1108, 506, 132, MINT, -8),
    ('Л', 252, 600, 78, ORANGE, 14),
    ('М', 940, 612, 78, YELLOW, -10),
]

# A round of the game: each city starts with the last letter of the one before
BANNER_CHAIN = ['Москва', 'Анапа', 'Астана']
CHAIN_SIZE = 34
CHAIN_PAD = 26
CHAIN_HEIGHT = 74
CHAIN_ARROW = 64


def scattered(char, x, y, size, fill, turn):
    k = size / TILE
    transform = (
        Identity.translate(x + size / 2, y + size / 2)
        .rotate(math.radians(turn))
        .translate(-size / 2, -size / 2)
        .scale(k)
    )

    return tile(transform, char, 0, 0, fill)


def city(x, y, name):
    """City pill with its last letter highlighted"""
    width = advance(UNBOUNDED, name, CHAIN_SIZE) + 2 * CHAIN_PAD
    baseline = y + CHAIN_HEIGHT / 2 + CHAIN_SIZE * .36
    head = name[:-1]
    left = x + CHAIN_PAD

    return width, [
        (rect(Identity, x, y + 6, width=width, height=CHAIN_HEIGHT, radius=20), INK, None, 0),
        (rect(Identity, x, y, width=width, height=CHAIN_HEIGHT, radius=20), WHITE, INK, 4),
        (text(Identity, UNBOUNDED, head, left, baseline, CHAIN_SIZE), INK, None, 0),
        (text(Identity, UNBOUNDED, name[-1], left + advance(UNBOUNDED, head, CHAIN_SIZE), baseline, CHAIN_SIZE), LETTER, None, 0),
    ]


def arrow(x, y):
    return shape(Identity.translate(x, y), '<path d="M14 -6H34V-15L50 0 34 15V6H14Z"/>')


def chain(width, y):
    pills = [advance(UNBOUNDED, name, CHAIN_SIZE) + 2 * CHAIN_PAD for name in BANNER_CHAIN]
    x = (width - sum(pills) - CHAIN_ARROW * (len(pills) - 1)) / 2
    layers = []

    for index, name in enumerate(BANNER_CHAIN):
        pill, parts = city(x, y, name)
        layers += parts
        x += pill

        if index < len(BANNER_CHAIN) - 1:
            layers.append((arrow(x, y + CHAIN_HEIGHT / 2), WHITE, None, 0))
            x += CHAIN_ARROW

    return layers


def banner(width, height):
    """Logo over a round of the game, with letter tiles around"""
    lockup_width = 640
    k = lockup_width / LOCKUP_WIDTH
    logo = Identity.translate((width - lockup_width) / 2, 128).scale(k)
    layers = [layer for spec in BANNER_TILES for layer in scattered(*spec)]
    layers += lockup(logo, caption=EDGE, title=WHITE)
    layers += chain(width, 436)

    return svg(f'<rect width="{width}" height="{height}" fill="{VIOLET}"/>', layers, width, height)


OK_BANNER = banner(1280, 720)


def render(source, size, path, opaque=False, height=None):
    png = bytes(svg_to_bytes(svg_string=source, width=size, height=height or size))
    image = Image.open(io.BytesIO(png))

    if opaque:
        image = image.convert('RGB')

    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def main():
    (OUT_SRC / 'app_icon.svg').write_text(FULL)
    (OUT_SRC / 'foreground.svg').write_text(svg('', FOREGROUND))
    (OUT_SRC / 'monochrome.svg').write_text(svg('', MONOCHROME))

    (RES / 'drawable/ic_launcher_foreground.xml').write_text(vector(FOREGROUND))
    (RES / 'drawable/ic_launcher_monochrome.xml').write_text(vector(MONOCHROME))

    # Launchers below API 26 have no adaptive icons and take these
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

    for density, factor in densities.items():
        folder = RES / f'mipmap-{density}'
        render(LEGACY, round(48 * factor), folder / 'ic_launcher.png')
        render(LEGACY_ROUND, round(48 * factor), folder / 'ic_launcher_round.png')

    render(FULL, 512, ROOT / 'android/app/src/main/ic_launcher-playstore.png', opaque=True)

    contents = json.loads((IOS / 'Contents.json').read_text())

    for image in contents['images']:
        points = float(image['size'].split('x')[0])
        factor = int(image['scale'].rstrip('x'))
        render(FULL, round(points * factor), IOS / image['filename'], opaque=True)

    render(SMALL, 32, VK / 'vk_32.png', opaque=True)

    for size in (150, 278):
        render(FULL, size, VK / f'vk_{size}.png', opaque=True)

    render(FULL, 512, OK / 'ok_512.png', opaque=True)
    render(OK_BANNER, 1280, OK / 'ok_1280x720.png', opaque=True, height=720)


if __name__ == '__main__':
    main()
