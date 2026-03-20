#!/usr/bin/env python3
"""Download PNG flags for European sovereign states into Textures/Flags.

Source: https://flagcdn.com (flags from Wikimedia Commons, public domain).
"""
from __future__ import annotations

import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

# ISO 3166-1 alpha-2: UN geoscheme Europe + transcontinental states often used
# in European geopolitical games (KZ, TR, AM, AZ, GE). Kosovo uses de-facto XK.
EUROPE_ISO2 = [
    "ad",  # Andorra
    "al",  # Albania
    "am",  # Armenia
    "at",  # Austria
    "az",  # Azerbaijan
    "ba",  # Bosnia and Herzegovina
    "be",  # Belgium
    "bg",  # Bulgaria
    "by",  # Belarus
    "ch",  # Switzerland
    "cy",  # Cyprus
    "cz",  # Czechia
    "de",  # Germany
    "dk",  # Denmark
    "ee",  # Estonia
    "es",  # Spain
    "fi",  # Finland
    "fr",  # France
    "gb",  # United Kingdom
    "ge",  # Georgia
    "gr",  # Greece
    "hr",  # Croatia
    "hu",  # Hungary
    "ie",  # Ireland
    "is",  # Iceland
    "it",  # Italy
    "kz",  # Kazakhstan (partly European)
    "li",  # Liechtenstein
    "lt",  # Lithuania
    "lu",  # Luxembourg
    "lv",  # Latvia
    "mc",  # Monaco
    "md",  # Moldova
    "me",  # Montenegro
    "mk",  # North Macedonia
    "mt",  # Malta
    "nl",  # Netherlands
    "no",  # Norway
    "pl",  # Poland
    "pt",  # Portugal
    "ro",  # Romania
    "rs",  # Serbia
    "ru",  # Russia
    "se",  # Sweden
    "si",  # Slovenia
    "sk",  # Slovakia
    "sm",  # San Marino
    "tr",  # Turkey (partly European)
    "ua",  # Ukraine
    "va",  # Vatican City
    "xk",  # Kosovo
]

WIDTH = 640
BASE = f"https://flagcdn.com/w{WIDTH}"
UA = "EconomyGrandStrategy/1.0 (flag asset prefetch; +local game project)"


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    out = root / "Textures" / "Flags"
    out.mkdir(parents=True, exist_ok=True)

    opener = urllib.request.build_opener()
    opener.addheaders = [("User-Agent", UA)]

    failed: list[str] = []
    for i, code in enumerate(EUROPE_ISO2):
        url = f"{BASE}/{code}.png"
        dest = out / f"{code}.png"
        try:
            with opener.open(url, timeout=60) as resp:
                data = resp.read()
            if not data or len(data) < 100:
                failed.append(code)
                continue
            dest.write_bytes(data)
        except (urllib.error.URLError, OSError):
            failed.append(code)
        if i and i % 5 == 0:
            time.sleep(0.15)

    if failed:
        print("Failed:", ", ".join(failed), file=sys.stderr)
        return 1
    print(f"OK: {len(EUROPE_ISO2)} flags -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
