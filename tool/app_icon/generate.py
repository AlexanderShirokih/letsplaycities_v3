"""Renders the D2 app icon («Плитки Г→А») for Android, iOS and VK.

Run from the project root:
    python tool/app_icon/generate.py

Needs fonttools, resvg-py and pillow.
"""

import io
import json
from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from PIL import Image
from resvg_py import svg_to_bytes

ROOT = Path(__file__).resolve().parents[2]
OUT_SRC = ROOT / 'tool/app_icon'
RES = ROOT / 'android/app/src/main/res'
IOS = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
VK = OUT_SRC / 'vk'

VIOLET = '#5B3DF5'
INK = '#1B1340'
WHITE = '#FFFFFF'
ORANGE = '#FF7A1A'

# Adaptive icons show the middle 72 of the 108 dp canvas
ADAPTIVE_VISIBLE = 72 / 108


def letter_paths():
    font = TTFont(ROOT / 'assets/fonts/Unbounded[wght].ttf')
    font = instantiateVariableFont(font, {'wght': 700})
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    upem = font['head'].unitsPerEm

    def path(char, center_x, baseline_y, size=26):
        name = cmap[ord(char)]
        scale = size / upem
        advance = glyphs[name].width * scale
        pen = SVGPathPen(glyphs)
        transform = (scale, 0, 0, -scale, center_x - advance / 2, baseline_y)
        glyphs[name].draw(TransformPen(pen, transform))

        return pen.getCommands()

    return path('Г', 32, 39.75), path('А', 66, 73.75)


G_PATH, A_PATH = letter_paths()


def tiles(scale):
    """Both tiles in the 108 canvas, as in D2-Brand"""
    return f'''<g transform="translate(54 54) scale({scale}) translate(-50 -50)">
<rect x="6" y="9" width="52" height="52" rx="12" fill="{INK}"/>
<rect x="6" y="4" width="52" height="52" rx="12" fill="{WHITE}" stroke="{INK}" stroke-width="3"/>
<path d="{G_PATH}" fill="{INK}"/>
<rect x="40" y="43" width="52" height="52" rx="12" fill="{INK}"/>
<rect x="40" y="38" width="52" height="52" rx="12" fill="{ORANGE}" stroke="{INK}" stroke-width="3"/>
<path d="{A_PATH}" fill="{INK}"/>
</g>'''


def mono_tiles(scale):
    """Silhouette for themed icons: tiles with cut-out letters, a gap between tiles"""
    return f'''<defs>
<mask id="g" maskUnits="userSpaceOnUse" x="0" y="0" width="100" height="100">
<rect width="100" height="100" fill="#fff"/>
<path d="{G_PATH}" fill="#000"/>
<rect x="40" y="38" width="52" height="52" rx="12" fill="#000" stroke="#000" stroke-width="8"/>
</mask>
<mask id="a" maskUnits="userSpaceOnUse" x="0" y="0" width="100" height="100">
<rect width="100" height="100" fill="#fff"/>
<path d="{A_PATH}" fill="#000"/>
</mask>
</defs>
<g transform="translate(54 54) scale({scale}) translate(-50 -50)">
<rect x="6" y="4" width="52" height="52" rx="12" mask="url(#g)"/>
<rect x="40" y="38" width="52" height="52" rx="12" mask="url(#a)"/>
</g>'''


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">{body}</svg>'


FULL = svg(f'<rect width="108" height="108" fill="{VIOLET}"/>{tiles(.64)}')
ROUNDED = svg(f'<rect width="108" height="108" rx="26" fill="{VIOLET}"/>{tiles(.64)}')
# At 32 px the tiles need more room to stay readable
SMALL = svg(f'<rect width="108" height="108" fill="{VIOLET}"/>{tiles(.84)}')
ROUND = svg(f'<circle cx="54" cy="54" r="54" fill="{VIOLET}"/>{tiles(.6)}')
FOREGROUND = svg(tiles(.64 * ADAPTIVE_VISIBLE))
MONOCHROME = svg(mono_tiles(.64 * ADAPTIVE_VISIBLE))


def render(source, size, path, opaque=False):
    png = bytes(svg_to_bytes(svg_string=source, width=size, height=size))
    image = Image.open(io.BytesIO(png))

    if opaque:
        image = image.convert('RGB')

    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def main():
    for name, source in [
        ('app_icon', FULL),
        ('foreground', FOREGROUND),
        ('monochrome', MONOCHROME),
    ]:
        (OUT_SRC / f'{name}.svg').write_text(source)

    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

    for density, factor in densities.items():
        folder = RES / f'mipmap-{density}'
        render(ROUNDED, round(48 * factor), folder / 'ic_launcher.png')
        render(ROUND, round(48 * factor), folder / 'ic_launcher_round.png')
        render(FOREGROUND, round(108 * factor), folder / 'ic_launcher_foreground.png')
        render(MONOCHROME, round(108 * factor), folder / 'ic_launcher_monochrome.png')

    render(FULL, 512, ROOT / 'android/app/src/main/ic_launcher-playstore.png', opaque=True)

    contents = json.loads((IOS / 'Contents.json').read_text())

    for image in contents['images']:
        points = float(image['size'].split('x')[0])
        factor = int(image['scale'].rstrip('x'))
        render(FULL, round(points * factor), IOS / image['filename'], opaque=True)

    render(SMALL, 32, VK / 'vk_32.png', opaque=True)

    for size in (150, 278):
        render(FULL, size, VK / f'vk_{size}.png', opaque=True)


if __name__ == '__main__':
    main()
