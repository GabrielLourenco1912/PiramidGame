#!/usr/bin/env python3
"""Reproduz IfprMark nos recursos Android. Requer Pillow (python3 -m pip install Pillow)."""

from pathlib import Path
import re

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
COLORS = (ROOT / "lib/app/theme/app_colors.dart").read_text(encoding="utf-8")
DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# Mesma grade de IfprMark: círculo em (0, 0) e nove módulos verdes.
MODULES = [(0, 1), (0, 2), (1, 0), (1, 1), (2, 0), (2, 1), (2, 2), (3, 0), (3, 1)]
UNIT = 14
PADDING = UNIT * 0.08
SIDE = UNIT * 0.84
RADIUS = 2


def color(name):
    match = re.search(rf"\b{name}\s*=\s*Color\(0xFF([0-9A-Fa-f]{{6}})\)", COLORS)
    if match is None:
        raise ValueError(f"Cor institucional não encontrada: {name}")
    return f"#{match[1]}"


def bounds(row, column):
    # Grade 42 × 56 centralizada no viewport adaptativo de 108 × 108.
    x = 33 + column * UNIT + PADDING
    y = 26 + row * UNIT + PADDING
    return x, y, x + SIDE, y + SIDE


def rounded_path(row, column):
    x, y, right, bottom = bounds(row, column)
    r = RADIUS
    return (
        f"M{x+r:.2f},{y:.2f} H{right-r:.2f} "
        f"A{r},{r} 0,0 1,{right:.2f},{y+r:.2f} V{bottom-r:.2f} "
        f"A{r},{r} 0,0 1,{right-r:.2f},{bottom:.2f} H{x+r:.2f} "
        f"A{r},{r} 0,0 1,{x:.2f},{bottom-r:.2f} V{y+r:.2f} "
        f"A{r},{r} 0,0 1,{x+r:.2f},{y:.2f} Z"
    )


def main():
    green = color("institutionalGreen")
    red = color("institutionalRed")
    paths = [
        f'    <path android:fillColor="{red}" '
        'android:pathData="M45.88,33 A5.88,5.88 0,1 1,34.12,33 '
        'A5.88,5.88 0,1 1,45.88,33 Z" />'
    ]
    for row, column in MODULES:
        paths.append(
            f'    <path android:fillColor="{green}" '
            f'android:pathData="{rounded_path(row, column)}" />'
        )
    foreground = RES / "drawable/ic_launcher_foreground.xml"
    foreground.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Gerado por scripts/gerar_icones_android.py a partir da marca IfprMark. -->\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="108dp"\n'
        '    android:height="108dp"\n'
        '    android:viewportWidth="108"\n'
        '    android:viewportHeight="108">\n'
        + "\n".join(paths)
        + "\n</vector>\n",
        encoding="utf-8",
    )

    # A área visível do ícone adaptativo mede 72 × 72, com origem em (18, 18).
    # Desenha em resolução maior e reduz com antialiasing para cada densidade.
    scale = 16
    image = Image.new("RGB", (72 * scale, 72 * scale), "white")
    draw = ImageDraw.Draw(image)

    def pixels(row, column):
        return tuple((value - 18) * scale for value in bounds(row, column))

    draw.ellipse(pixels(0, 0), fill=red)
    for row, column in MODULES:
        draw.rounded_rectangle(pixels(row, column), radius=RADIUS * scale, fill=green)
    for density, size in DENSITIES.items():
        destination = RES / f"mipmap-{density}/ic_launcher.png"
        image.resize((size, size), Image.Resampling.LANCZOS).save(destination)
        print(f"Gerado: {destination.relative_to(ROOT)} ({size} × {size})")
    print(f"Gerado: {foreground.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
