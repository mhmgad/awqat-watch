#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]


def draw_mark(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (7, 20, 15, 255))
    draw = ImageDraw.Draw(img)
    pad = size // 12
    draw.rounded_rectangle(
        (pad, pad, size - pad, size - pad),
        radius=size // 6,
        fill=(31, 111, 74, 255),
    )
    cx = cy = size // 2
    r = size // 3
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(242, 208, 137, 255), width=max(2, size // 24))
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(242, 208, 137, 255))
    hand = max(2, size // 32)
    draw.line((cx, cy, cx, cy - r * 0.7), fill=(242, 208, 137, 255), width=hand)
    draw.line((cx, cy, cx + r * 0.45, cy + r * 0.2), fill=(255, 255, 255, 255), width=hand)
    return img


def main() -> None:
    watch_icon = ROOT / "watch-lite/entry/src/main/resources/base/media/icon.png"
    watch_icon.parent.mkdir(parents=True, exist_ok=True)
    draw_mark(192).save(watch_icon)

    android_icon = ROOT / "android/app/src/main/res/drawable/ic_launcher.png"
    android_icon.parent.mkdir(parents=True, exist_ok=True)
    draw_mark(192).save(android_icon)
    print(f"wrote {watch_icon}")
    print(f"wrote {android_icon}")


if __name__ == "__main__":
    main()
