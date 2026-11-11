"""Renders the D2 app icon («Плитки Г→А») for Android, iOS, VK and OK.

Run from the project root:
    python tool/app_icon/generate.py

Needs fonttools, skia-pathops, resvg-py and pillow.
"""

import io
import json
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


def rect(transform, x, y, inset=0):
    markup = (
        f'<svg xmlns="http://www.w3.org/2000/svg"><rect x="{x - inset}" y="{y - inset}"'
        f' width="{TILE + 2 * inset}" height="{TILE + 2 * inset}" rx="{RADIUS + inset}"/></svg>'
    )
    path = pathops.Path()
    SVGPath.fromstring(markup.encode(), transform=transform).draw(path.getPen())

    return path


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
    glyphs, cmap, upem = UNBOUNDED
    width = glyphs[cmap[ord(char)]].width * FONT_SIZE / upem

    return text(transform, UNBOUNDED, char, x + TILE / 2 - width / 2, y + BASELINE, FONT_SIZE)


def colored(transform):
    """Both tiles as in D2-Brand: (path, fill, stroke, stroke width)"""
    layers = []

    for char, x, y, fill in TILES:
        layers += [
            (rect(transform, x, y + SHADOW), INK, None, 0),
            (rect(transform, x, y), fill, INK, BORDER * transform[0]),
            (letter(transform, char, x, y), INK, None, 0),
        ]

    return layers


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


def lockup(transform):
    """Main logo lockup of D2-Brand: tiles, «сыграем в» and «Города», 278.82×84"""
    return colored(transform.translate(0, 4).scale(.76)) + [
        (text(transform, RUBIK, 'сыграем в', 89, 24, 15), INK_SOFT, None, 0),
        (text(transform, UNBOUNDED, 'Города', 88, 64, 37, length=176.82), INK, None, 0),
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


def banner(width, height, lockup_width):
    """Logo lockup centred on the app background"""
    k = lockup_width / LOCKUP_WIDTH
    transform = Identity.translate((width - lockup_width) / 2, (height - LOCKUP_HEIGHT * k) / 2).scale(k)

    return svg(f'<rect width="{width}" height="{height}" fill="{BG}"/>', lockup(transform), width, height)


OK_BANNER = banner(1280, 720, 760)


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
