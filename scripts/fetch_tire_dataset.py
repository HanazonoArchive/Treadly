"""Validates local verified tire imagery, builds assets/data/tires.json, and checks the live USD/PHP rate."""

import hashlib
import json
import sys
import urllib.request
from pathlib import Path

from generate_100_tires import IMAGES_DIR, TARGET_JSON, build_catalog, validate_catalog

FX_URLS = (
    "https://open.er-api.com/v6/latest/USD",
    "https://api.frankfurter.dev/v1/latest?base=USD&symbols=PHP",
)


def fetch_live_usd_to_php():
    for url in FX_URLS:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Treadly-Catalog/1.0"})
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            rates = data.get("rates") or {}
            php = rates.get("PHP")
            if isinstance(php, (int, float)) and 40 <= php <= 95:
                return float(php), url
        except Exception as exc:
            print(f"[WARN] FX lookup failed for {url}: {exc}")
    return None, None


def verify_images(catalog):
    hashes = {}
    for tire in catalog:
        rel = tire["image_asset"]
        path = Path(__file__).resolve().parent.parent / rel
        if not path.exists() or path.stat().st_size < 4096:
            raise FileNotFoundError(f"Missing or invalid image file: {path}")
        digest = hashlib.md5(path.read_bytes()).hexdigest()
        bm = (tire["brand"], tire["model"])
        if digest in hashes and hashes[digest] != bm:
            raise ValueError(f"Duplicate image content ({digest}) between {hashes[digest]} and {bm}")
        hashes[digest] = bm
    print(f"[OK] Verified {len(hashes)} unique model images in {IMAGES_DIR}")


def main():
    catalog = build_catalog()
    validate_catalog(catalog)
    verify_images(catalog)

    TARGET_JSON.write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"[OK] Wrote {len(catalog)} curated SKUs to {TARGET_JSON}")

    rate, source = fetch_live_usd_to_php()
    if rate is not None:
        print(f"[OK] Live USD->PHP FX rate ({source}): {rate:.4f} PHP/USD")
        sample = catalog[0]
        print(
            f"[OK] Sample conversion: {sample['brand']} {sample['model']} "
            f"(${sample['price']:.2f} USD -> ₱{round(sample['price'] * rate):,})"
        )
    else:
        print("[WARN] Offline: skipping live USD->PHP preview")


if __name__ == "__main__":
    try:
        main()
    except Exception as err:
        print(f"[ERROR] {err}", file=sys.stderr)
        sys.exit(1)
