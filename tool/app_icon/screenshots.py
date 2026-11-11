"""Frames the app screens for store listings: caption, phone, letter tiles.

Take the screens first on a clean emulator:
    flutter drive --profile --driver test_driver/integration_test.dart \
        --target integration_test/store_screenshots_test.dart

Then run from the project root:
    python tool/app_icon/screenshots.py
"""

import base64

from generate import (
    INK, MINT, ORANGE, OUT_SRC, ROOT, SKY, UNBOUNDED, VIOLET, WHITE, YELLOW,
    Identity, advance, render, scattered, svg, text,
)

SHOTS = ROOT / 'build/screenshots'
OUT = OUT_SRC / 'screenshots'

WIDTH = 1080
HEIGHT = 1920

SCREEN_HEIGHT = 1460
SCREEN_RADIUS = 56
BORDER = 10
SHADOW = 16

CAPTION_SIZE = 60
CAPTION_LINE = 76
CAPTION_TOP = 170

# Screen file, caption lines, tiles behind the phone: letter, left, top, size, fill, turn
FRAMES = [
    ('01_home', ['Играй с компьютером,', 'вдвоём и онлайн'],
     [('К', 40, 520, 150, YELLOW, -12), ('Р', 900, 1240, 140, MINT, 10)]),
    ('02_game', ['Называй город', 'на последнюю букву'],
     [('А', 880, 500, 150, ORANGE, 12), ('Н', 50, 1300, 140, SKY, -8)]),
    ('03_results', ['Комбо за быстрые', 'и длинные ответы'],
     [('Т', 50, 560, 140, MINT, -10), ('М', 890, 1260, 150, YELLOW, 8)]),
    ('04_cities', ['Города всего мира', 'в одном словаре'],
     [('Л', 900, 540, 140, SKY, 10), ('Е', 40, 1250, 150, ORANGE, -12)]),
    ('05_profile', ['Собирай страны', 'в паспорт'],
     [('П', 40, 520, 150, ORANGE, -10), ('С', 890, 1280, 140, YELLOW, 12)]),
]


def caption(lines):
    layers = []

    for index, line in enumerate(lines):
        width = advance(UNBOUNDED, line, CAPTION_SIZE)
        baseline = CAPTION_TOP + index * CAPTION_LINE
        layers.append((text(Identity, UNBOUNDED, line, (WIDTH - width) / 2, baseline, CAPTION_SIZE), WHITE, None, 0))

    return layers


def phone(name):
    """The screen in a rounded frame with a hard shadow, as markup"""
    data = base64.b64encode((SHOTS / f'{name}.png').read_bytes()).decode()
    height = SCREEN_HEIGHT
    width = round(height * 1080 / 2280)
    x = (WIDTH - width) / 2
    y = HEIGHT - height - 80
    radius = SCREEN_RADIUS
    outer = radius + BORDER

    return f'''<rect x="{x - BORDER}" y="{y - BORDER + SHADOW}" width="{width + 2 * BORDER}" height="{height + 2 * BORDER}" rx="{outer}" fill="{INK}"/>
<rect x="{x - BORDER}" y="{y - BORDER}" width="{width + 2 * BORDER}" height="{height + 2 * BORDER}" rx="{outer}" fill="{INK}"/>
<clipPath id="screen"><rect x="{x}" y="{y}" width="{width}" height="{height}" rx="{radius}"/></clipPath>
<image href="data:image/png;base64,{data}" x="{x}" y="{y}" width="{width}" height="{height}" clip-path="url(#screen)"/>'''


def frame(name, lines, tiles):
    layers = [layer for spec in tiles for layer in scattered(*spec)] + caption(lines)
    background = f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{VIOLET}"/>'
    source = svg(background, layers, WIDTH, HEIGHT)

    # The phone goes over the tiles and the caption
    return source.replace('</svg>', phone(name) + '</svg>')


def main():
    for index, (name, lines, tiles) in enumerate(FRAMES, start=1):
        render(frame(name, lines, tiles), WIDTH, OUT / f'screenshot_{index}.png', opaque=True, height=HEIGHT)


if __name__ == '__main__':
    main()
