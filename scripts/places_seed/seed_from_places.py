#!/usr/bin/env python3
"""
One-time Google Places → HeyEcho pilot_seed.json generator.

Production rules for this project:
  - Run offline as a backend/ops script (NOT from the iOS app).
  - Use Places API (New) Text Search with a Pro-tier field mask only
    (~5,000 free Text Search Pro calls / month as of 2026 pricing).
  - Do NOT request Enterprise fields (rating, priceLevel, openingHours,
    editorialSummary) — those burn a smaller free quota and cost more.
  - Billing must be enabled on the Google Cloud project to use free quota.
  - Set a budget alert before running.

Usage:
  set GOOGLE_PLACES_API_KEY=your_key
  python scripts/places_seed/seed_from_places.py
  python scripts/places_seed/seed_from_places.py --target 150 --dry-run
"""

from __future__ import annotations

import argparse
import json
import os
import random
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
SEED_PATH = ROOT / "HeyEcho" / "Data" / "Seed" / "pilot_seed.json"
RAW_CACHE_PATH = Path(__file__).resolve().parent / "places_raw_cache.json"
ENV_PATH = Path(__file__).resolve().parent / ".env"

TEXT_SEARCH_URL = "https://places.googleapis.com/v1/places:searchText"

# Pro-tier fields only — keeps billing on Text Search Pro (5k free / month).
# Do not add: priceLevel, rating, regularOpeningHours, editorialSummary.
FIELD_MASK = ",".join(
    [
        "places.id",
        "places.name",
        "places.displayName",
        "places.formattedAddress",
        "places.shortFormattedAddress",
        "places.location",
        "places.types",
        "places.primaryType",
        "places.primaryTypeDisplayName",
        "places.businessStatus",
        "places.addressComponents",
        "places.googleMapsUri",
        "nextPageToken",
    ]
)

# Neighborhood / area queries across Bengaluru (restaurants + hotels).
# Each query may paginate; keep pageSize=20. Dedup by place id.
QUERIES: list[dict[str, Any]] = [
    # Restaurants by area
    {"textQuery": "best restaurants in Indiranagar Bengaluru", "kind": "restaurant", "neighborhood": "Indiranagar"},
    {"textQuery": "cafes in Indiranagar Bengaluru", "kind": "restaurant", "neighborhood": "Indiranagar"},
    {"textQuery": "biryani restaurants in Indiranagar Bengaluru", "kind": "restaurant", "neighborhood": "Indiranagar"},
    {"textQuery": "restaurants in Koramangala Bengaluru", "kind": "restaurant", "neighborhood": "Koramangala"},
    {"textQuery": "cafes in Koramangala Bengaluru", "kind": "restaurant", "neighborhood": "Koramangala"},
    {"textQuery": "restaurants in HSR Layout Bengaluru", "kind": "restaurant", "neighborhood": "HSR Layout"},
    {"textQuery": "restaurants in Jayanagar Bengaluru", "kind": "restaurant", "neighborhood": "Jayanagar"},
    {"textQuery": "restaurants in JP Nagar Bengaluru", "kind": "restaurant", "neighborhood": "JP Nagar"},
    {"textQuery": "restaurants in Malleshwaram Bengaluru", "kind": "restaurant", "neighborhood": "Malleshwaram"},
    {"textQuery": "restaurants in Whitefield Bengaluru", "kind": "restaurant", "neighborhood": "Whitefield"},
    {"textQuery": "restaurants near MG Road Bengaluru", "kind": "restaurant", "neighborhood": "MG Road"},
    {"textQuery": "restaurants in Basavanagudi Bengaluru", "kind": "restaurant", "neighborhood": "Basavanagudi"},
    {"textQuery": "street food in Indiranagar Bengaluru", "kind": "restaurant", "neighborhood": "Indiranagar"},
    {"textQuery": "south indian restaurants in Bengaluru", "kind": "restaurant", "neighborhood": "Bengaluru"},
    {"textQuery": "fine dining restaurants in Bengaluru", "kind": "restaurant", "neighborhood": "Bengaluru"},
    # Hotels
    {"textQuery": "hotels in Indiranagar Bengaluru", "kind": "hotel", "neighborhood": "Indiranagar"},
    {"textQuery": "hotels near MG Road Bengaluru", "kind": "hotel", "neighborhood": "MG Road"},
    {"textQuery": "luxury hotels in Bengaluru", "kind": "hotel", "neighborhood": "Bengaluru"},
    {"textQuery": "hotels in Whitefield Bengaluru", "kind": "hotel", "neighborhood": "Whitefield"},
    {"textQuery": "hotels in Koramangala Bengaluru", "kind": "hotel", "neighborhood": "Koramangala"},
]

TYPE_TO_CATEGORY = {
    "restaurant": "North Indian",
    "indian_restaurant": "North Indian",
    "meal_takeaway": "Cheap Eats",
    "meal_delivery": "Cloud Kitchens",
    "cafe": "Cafe & Coffee",
    "coffee_shop": "Cafe & Coffee",
    "bakery": "Desserts",
    "ice_cream_shop": "Desserts",
    "dessert_shop": "Desserts",
    "pizza_restaurant": "Pizza & Pasta",
    "italian_restaurant": "Pizza & Pasta",
    "chinese_restaurant": "Chinese",
    "seafood_restaurant": "Seafood",
    "vegetarian_restaurant": "Healthy / Bowls",
    "vegan_restaurant": "Healthy / Bowls",
    "fast_food_restaurant": "Cheap Eats",
    "hamburger_restaurant": "Cheap Eats",
    "sushi_restaurant": "Fine Dining",
    "steak_house": "Fine Dining",
    "fine_dining_restaurant": "Fine Dining",
    "bar": "Late-Night Food",
    "bar_and_grill": "Late-Night Food",
    "lodging": "Hotels",
    "hotel": "Hotels",
    "extended_stay_hotel": "Hotels",
    "resort_hotel": "Hotels",
}

KEYWORD_CATEGORIES = [
    ("biryani", "Biryani"),
    ("dosa", "South Indian"),
    ("idli", "South Indian"),
    ("filter coffee", "Filter Coffee"),
    ("chaat", "Chaat"),
    ("kebab", "Kebabs & Rolls"),
    ("shawarma", "Kebabs & Rolls"),
    ("roll", "Kebabs & Rolls"),
    ("pizza", "Pizza & Pasta"),
    ("pasta", "Pizza & Pasta"),
    ("chinese", "Chinese"),
    ("seafood", "Seafood"),
    ("cafe", "Cafe & Coffee"),
    ("coffee", "Cafe & Coffee"),
    ("dessert", "Desserts"),
    ("ice cream", "Desserts"),
    ("hotel", "Hotels"),
    ("resort", "Hotels"),
]

CATEGORY_SYMBOL = {
    "Biryani": "flame.fill",
    "South Indian": "leaf.fill",
    "Street Food": "takeoutbag.and.cup.and.straw.fill",
    "Cafe & Coffee": "cup.and.saucer.fill",
    "North Indian": "fork.knife",
    "Desserts": "birthday.cake.fill",
    "Hotels": "building.2.fill",
    "Cloud Kitchens": "bicycle",
    "Kebabs & Rolls": "flame",
    "Late-Night Food": "moon.stars.fill",
    "Fine Dining": "wineglass.fill",
    "Seafood": "fish.fill",
    "Chinese": "fork.knife",
    "Pizza & Pasta": "fork.knife",
    "Healthy / Bowls": "leaf",
    "Cheap Eats": "takeoutbag.and.cup.and.straw.fill",
    "Filter Coffee": "cup.and.saucer.fill",
    "Chaat": "takeoutbag.and.cup.and.straw.fill",
}

CATEGORY_PERFECT_FOR = {
    "Hotels": ["Business stay", "Special occasion"],
    "Cafe & Coffee": ["Work", "Catch-up"],
    "Biryani": ["Dinner", "Group orders"],
    "Street Food": ["Quick bite", "Late night"],
    "Fine Dining": ["Date night", "Celebration"],
    "Desserts": ["After dinner", "Sweet craving"],
}

CATEGORY_GOTO_AFFINITY = {
    "South Indian": ["u1", "u11", "cgoto3"],
    "Filter Coffee": ["u1", "cgoto3"],
    "Biryani": ["u2", "u10", "cgoto1"],
    "North Indian": ["u2"],
    "Cafe & Coffee": ["u3", "u5", "u9", "cgoto2"],
    "Healthy / Bowls": ["u3", "cgoto2"],
    "Street Food": ["u4", "u10", "cgoto1"],
    "Chaat": ["u4"],
    "Desserts": ["u5", "cgoto2"],
    "Seafood": ["u6"],
    "Chinese": ["u6"],
    "Pizza & Pasta": ["u9"],
    "Cheap Eats": ["u11", "cgoto3"],
    "Kebabs & Rolls": ["u12", "cgoto1"],
    "Late-Night Food": ["u12", "cgoto1"],
    "Hotels": ["u3", "u6"],
    "Fine Dining": ["u3", "u6"],
    "Cloud Kitchens": ["u9"],
}


def load_dotenv() -> None:
    if not ENV_PATH.exists():
        return
    for line in ENV_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def api_key() -> str:
    key = os.environ.get("GOOGLE_PLACES_API_KEY", "").strip()
    if not key:
        print(
            "Missing GOOGLE_PLACES_API_KEY.\n"
            "  1. Enable Places API (New) in Google Cloud Console\n"
            "  2. Enable billing + set a budget alert\n"
            "  3. Create an API key restricted to Places API\n"
            "  4. Copy scripts/places_seed/.env.example → .env and set the key\n",
            file=sys.stderr,
        )
        sys.exit(1)
    return key


def post_text_search(key: str, body: dict[str, Any]) -> dict[str, Any]:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        TEXT_SEARCH_URL,
        data=data,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-Goog-Api-Key": key,
            "X-Goog-FieldMask": FIELD_MASK,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Places HTTP {exc.code}: {detail}") from exc


def neighborhood_from_components(components: list[dict[str, Any]], fallback: str) -> str:
    preferred = ("sublocality_level_1", "sublocality", "neighborhood", "locality")
    by_type: dict[str, str] = {}
    for comp in components:
        types = comp.get("types") or []
        name = comp.get("longText") or comp.get("shortText") or ""
        for t in types:
            by_type[t] = name
    for t in preferred:
        if t in by_type and by_type[t]:
            return by_type[t]
    return fallback


def categories_for(place: dict[str, Any], kind: str) -> list[str]:
    if kind == "hotel":
        return ["Hotels"]

    name = ((place.get("displayName") or {}).get("text") or "").lower()
    primary = place.get("primaryType") or ""
    types = place.get("types") or []

    cats: list[str] = []
    for needle, cat in KEYWORD_CATEGORIES:
        if needle in name and cat not in cats:
            cats.append(cat)

    mapped = TYPE_TO_CATEGORY.get(primary)
    if mapped and mapped not in cats:
        cats.append(mapped)

    for t in types:
        mapped = TYPE_TO_CATEGORY.get(t)
        if mapped and mapped not in cats:
            cats.append(mapped)

    if not cats:
        cats = ["North Indian"]
    # Cap to 3 for UI
    return cats[:3]


def price_for(categories: list[str]) -> int:
    if "Hotels" in categories or "Fine Dining" in categories:
        return 4
    if "Cheap Eats" in categories or "Street Food" in categories or "Chaat" in categories:
        return 1
    if "Cafe & Coffee" in categories or "Cloud Kitchens" in categories:
        return 2
    return 2


def hours_for(categories: list[str]) -> str:
    if "Hotels" in categories:
        return "Open 24 hours (hotel)"
    if "Late-Night Food" in categories:
        return "12:00 PM – 1:00 AM"
    if "Cafe & Coffee" in categories:
        return "8:00 AM – 10:00 PM"
    return "11:00 AM – 11:00 PM"


def perfect_for(categories: list[str]) -> list[str]:
    for cat in categories:
        if cat in CATEGORY_PERFECT_FOR:
            return CATEGORY_PERFECT_FOR[cat]
    return ["Dinner", "Friends"]


def image_symbol(categories: list[str]) -> str:
    for cat in categories:
        if cat in CATEGORY_SYMBOL:
            return CATEGORY_SYMBOL[cat]
    return "fork.knife"


def recommenders(categories: list[str], rng: random.Random) -> list[str]:
    pool: list[str] = []
    for cat in categories:
        pool.extend(CATEGORY_GOTO_AFFINITY.get(cat, []))
    pool = list(dict.fromkeys(pool)) or ["u1", "u2", "u3"]
    k = min(len(pool), rng.randint(1, 3))
    return rng.sample(pool, k=k)


def place_resource_id(place: dict[str, Any]) -> str | None:
    # places.name is "places/ChIJ..."
    name = place.get("name") or ""
    if name.startswith("places/"):
        return name.split("/", 1)[1]
    pid = place.get("id")
    if isinstance(pid, str) and pid:
        return pid.replace("places/", "")
    return None


def to_business(
    place: dict[str, Any],
    *,
    kind: str,
    query_neighborhood: str,
    index: int,
    rng: random.Random,
) -> dict[str, Any] | None:
    pid = place_resource_id(place)
    if not pid:
        return None
    if place.get("businessStatus") not in (None, "OPERATIONAL"):
        return None

    display = (place.get("displayName") or {}).get("text") or ""
    if not display:
        return None

    loc = place.get("location") or {}
    lat = loc.get("latitude")
    lng = loc.get("longitude")
    if lat is None or lng is None:
        return None

    address = place.get("formattedAddress") or place.get("shortFormattedAddress") or query_neighborhood
    neighborhood = neighborhood_from_components(
        place.get("addressComponents") or [],
        query_neighborhood if query_neighborhood != "Bengaluru" else "Bengaluru",
    )
    categories = categories_for(place, kind)
    prefix = "h" if "Hotels" in categories else "r"
    short = (
        f"{(place.get('primaryTypeDisplayName') or {}).get('text') or categories[0]} "
        f"in {neighborhood}."
    )

    return {
        "id": f"{prefix}{index:03d}",
        "googlePlaceId": pid,
        "name": display,
        "neighborhood": neighborhood,
        "city": "Bengaluru",
        "categories": categories,
        "shortDescription": short[:160],
        "priceLevel": price_for(categories),
        "perfectFor": perfect_for(categories),
        "recommendedByContactIds": recommenders(categories, rng),
        "imageSymbol": image_symbol(categories),
        "address": address,
        "hours": hours_for(categories),
        "latitude": round(float(lat), 6),
        "longitude": round(float(lng), 6),
    }


def collect_places(key: str, *, max_pages_per_query: int, sleep_s: float) -> tuple[list[dict[str, Any]], int]:
    """Returns (raw places with meta), api_call_count."""
    seen: set[str] = set()
    collected: list[dict[str, Any]] = []
    calls = 0

    for q in QUERIES:
        page_token: str | None = None
        for _ in range(max_pages_per_query):
            body: dict[str, Any] = {
                "textQuery": q["textQuery"],
                "pageSize": 20,
                "languageCode": "en",
                "regionCode": "IN",
            }
            if q["kind"] == "hotel":
                body["includedType"] = "lodging"
            else:
                body["includedType"] = "restaurant"
            if page_token:
                body["pageToken"] = page_token

            payload = post_text_search(key, body)
            calls += 1
            places = payload.get("places") or []
            for place in places:
                pid = place_resource_id(place)
                if not pid or pid in seen:
                    continue
                seen.add(pid)
                collected.append(
                    {
                        "place": place,
                        "kind": q["kind"],
                        "neighborhood": q["neighborhood"],
                        "query": q["textQuery"],
                    }
                )

            page_token = payload.get("nextPageToken")
            if not page_token:
                break
            time.sleep(sleep_s)
        time.sleep(sleep_s)

    return collected, calls


def strip_google_place_id(businesses: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """App Codable model does not include googlePlaceId — keep it only in raw cache."""
    out = []
    for b in businesses:
        copy = dict(b)
        copy.pop("googlePlaceId", None)
        out.append(copy)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed HeyEcho pilot_seed.json from Google Places (one-time).")
    parser.add_argument("--target", type=int, default=150, help="Target unique listings (default 150).")
    parser.add_argument("--restaurants", type=int, default=120, help="Soft target for restaurants.")
    parser.add_argument("--hotels", type=int, default=30, help="Soft target for hotels.")
    parser.add_argument("--max-pages", type=int, default=2, help="Max Text Search pages per query (20 results each).")
    parser.add_argument("--sleep", type=float, default=0.35, help="Delay between API calls (seconds).")
    parser.add_argument("--dry-run", action="store_true", help="Fetch + print stats; do not write pilot_seed.json.")
    parser.add_argument("--seed", type=int, default=42, help="RNG seed for recommenders.")
    args = parser.parse_args()

    load_dotenv()
    key = api_key()

    if not SEED_PATH.exists():
        print(f"Missing existing seed at {SEED_PATH}", file=sys.stderr)
        sys.exit(1)

    existing = json.loads(SEED_PATH.read_text(encoding="utf-8"))
    contacts = existing.get("contacts") or []
    config = existing.get("config") or {}

    print("Fetching from Places API (New) Text Search — Pro field mask only…")
    collected, calls = collect_places(key, max_pages_per_query=args.max_pages, sleep_s=args.sleep)
    print(f"API calls used: {calls}")
    print(f"Unique places returned: {len(collected)}")

    rng = random.Random(args.seed)
    restaurants: list[dict[str, Any]] = []
    hotels: list[dict[str, Any]] = []
    r_i = 1
    h_i = 1

    for item in collected:
        kind = item["kind"]
        biz = to_business(
            item["place"],
            kind=kind,
            query_neighborhood=item["neighborhood"],
            index=h_i if kind == "hotel" else r_i,
            rng=rng,
        )
        if not biz:
            continue
        if "Hotels" in biz["categories"]:
            if len(hotels) >= args.hotels:
                continue
            biz["id"] = f"h{h_i:03d}"
            hotels.append(biz)
            h_i += 1
        else:
            if len(restaurants) >= args.restaurants:
                continue
            biz["id"] = f"r{r_i:03d}"
            restaurants.append(biz)
            r_i += 1

        if len(restaurants) + len(hotels) >= args.target:
            break

    businesses = restaurants + hotels
    print(f"Mapped restaurants: {len(restaurants)}, hotels: {len(hotels)}, total: {len(businesses)}")

    if len(businesses) < 100:
        print(
            "WARNING: fewer than 100 listings. Add more QUERIES or raise --max-pages, then re-run.",
            file=sys.stderr,
        )

    raw_payload = {
        "generatedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "apiCalls": calls,
        "fieldMask": FIELD_MASK,
        "businesses": businesses,
        "sourceQueries": [q["textQuery"] for q in QUERIES],
    }
    RAW_CACHE_PATH.write_text(json.dumps(raw_payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote audit cache: {RAW_CACHE_PATH}")

    if args.dry_run:
        print("Dry run — pilot_seed.json not modified.")
        for sample in businesses[:5]:
            print(f"  • {sample['name']} ({sample['neighborhood']}) — {', '.join(sample['categories'])}")
        return

    out = {
        "contacts": contacts,
        "businesses": strip_google_place_id(businesses),
        "config": config,
    }
    SEED_PATH.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Updated {SEED_PATH}")
    print("Next: commit pilot_seed.json, publish firestore.rules, relaunch app to upsert Firestore.")


if __name__ == "__main__":
    main()
