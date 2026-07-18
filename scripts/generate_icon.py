#!/usr/bin/env python3
"""Generates the 1024x1024 app icon: a friendly diagonal gradient with faint
"text line" bars and a monospaced "y:" glyph, nodding to YAML."""

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
TOP = (33, 82, 166)
BOTTOM = (26, 140, 140)

image = Image.new("RGB", (SIZE, SIZE))
draw = ImageDraw.Draw(image, "RGBA")

for y in range(SIZE):
    t = y / (SIZE - 1)
    row = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
    draw.line([(0, y), (SIZE, y)], fill=row)

line_widths = [560, 420, 640, 380, 520, 460, 600]
for i, width in enumerate(line_widths):
    y = 150 + i * 106
    draw.rounded_rectangle(
        [140, y, 140 + width, y + 36], radius=18, fill=(255, 255, 255, 20)
    )

font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 460, index=1)  # Menlo Bold
text = "y:"
box = draw.textbbox((0, 0), text, font=font)
text_width = box[2] - box[0]
text_height = box[3] - box[1]
draw.text(
    ((SIZE - text_width) / 2 - box[0], (SIZE - text_height) / 2 - box[1] - 20),
    text,
    font=font,
    fill=(255, 255, 255),
)

output = "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
image.save(output, "PNG")
print(f"Wrote {output}")
