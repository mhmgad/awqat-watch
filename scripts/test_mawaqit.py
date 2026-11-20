#!/usr/bin/env python3
"""Fetch a public MAWAQIT page and print today's prayer clocks."""
from __future__ import annotations

import json
import sys
import urllib.request
from datetime import date


def extract_conf_data(html: str) -> dict:
    idx = html.find("confData")
    if idx < 0:
        return {}
    start = html.find("{", idx)
    if start < 0:
        return {}
    depth = 0
    in_string = False
    escape = False
    quote = ""
    for i, ch in enumerate(html[start:], start):
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                in_string = False
            continue
        if ch in "\"'":
            in_string = True
            quote = ch
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return json.loads(html[start : i + 1])
    return {}


def slug_from(query: str) -> str:
    text = query.strip()
    marker = "mawaqit.net/"
    if marker in text:
        rest = text.split(marker, 1)[1].split("?", 1)[0]
        parts = [p for p in rest.split("/") if p]
        if len(parts) >= 3 and parts[1] == "m":
            return parts[2]
        if len(parts) >= 2:
            return parts[1]
        if parts:
            return parts[0]
    return text.strip("/").lower()


def today_clocks(conf: dict) -> dict[str, str]:
    today = date.today()
    clocks = {
        "fajr": "--:--",
        "dhuhr": "--:--",
        "asr": "--:--",
        "maghrib": "--:--",
        "isha": "--:--",
        "jumua": "--:--",
    }
    calendar = conf.get("calendar") or []
    row = []
    if isinstance(calendar, list) and len(calendar) >= 12:
        month = calendar[today.month - 1] or {}
        row = month.get(str(today.day)) or []
    if isinstance(row, list) and len(row) >= 6:
        offset = 1 if len(row) == 7 else 0
        clocks["fajr"] = row[offset]
        clocks["dhuhr"] = row[offset + 2]
        clocks["asr"] = row[offset + 3]
        clocks["maghrib"] = row[offset + 4]
        clocks["isha"] = row[offset + 5]
    times = conf.get("times") or []
    if clocks["fajr"] == "--:--" and isinstance(times, list) and len(times) >= 5:
        clocks["fajr"], clocks["dhuhr"], clocks["asr"], clocks["maghrib"], clocks["isha"] = times[:5]
    if conf.get("jumuaAsDuhr"):
        clocks["jumua"] = clocks["dhuhr"]
    else:
        clocks["jumua"] = str(conf.get("jumua") or clocks["dhuhr"])
    return clocks


def main() -> int:
    query = sys.argv[1] if len(sys.argv) > 1 else "lille"
    slug = slug_from(query)
    url = f"https://mawaqit.net/en/{slug}"
    req = urllib.request.Request(url, headers={"User-Agent": "AwqatWatch/1.0"})
    html = urllib.request.urlopen(req, timeout=20).read().decode("utf-8", "replace")
    conf = extract_conf_data(html)
    if not conf:
        print(f"No confData in {url}", file=sys.stderr)
        return 1
    clocks = today_clocks(conf)
    name = conf.get("label") or conf.get("name") or slug
    print(name)
    print(date.today().isoformat())
    for key in ("fajr", "dhuhr", "jumua", "asr", "maghrib", "isha"):
        print(f"{key:8} {clocks[key]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
