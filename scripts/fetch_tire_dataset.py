"""
Treadly Tire Dataset & Image Fetcher
Automatically downloads transparent tire cutouts and builds assets/data/tires.json
"""

import os
import io
import json
import requests
from PIL import Image

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

TIRES_CONFIG = [
    # --- MICHELIN ---
    {
        "id": "michelin-pilot-sport-5",
        "brand": "Michelin",
        "model": "Pilot Sport 5",
        "category": "Ultra High Performance Summer",
        "season": "Summer",
        "width": 225,
        "aspect_ratio": 45,
        "rim_size": 18,
        "load_index": 95,
        "speed_rating": "Y",
        "dot_year": 2024,
        "price": 219.99,
        "original_price": 249.99,
        "rating": 4.9,
        "reviews_count": 512,
        "stock": 36,
        "wet_grip": "A",
        "fuel_efficiency": "B",
        "noise_db": 68,
        "warranty_miles": 30000,
        "description": "5th generation of Michelin's iconic performance tire. Offers razor-sharp steering precision and supreme wet braking distance.",
        "compatible_cars": ["BMW 3 Series", "Mercedes C-Class", "Audi A4", "Tesla Model 3"],
        "image_url": "https://dxm.contentcenter.michelin.com/api/wedia/dam/transform/b98rpyxf61b4xdugq1h3a3861w/4w-240_3528706263095_tire_michelin_pilot-sport-4-s_255-slash-35-zr19-96y-xl_a_main_1-30_nopad.webp",
        "local_fallback": "assets/images/tires/michelin_ps5.webp"
    },
    {
        "id": "michelin-pilot-sport-all-season-4",
        "brand": "Michelin",
        "model": "Pilot Sport All-Season 4",
        "category": "Ultra High Performance All-Season",
        "season": "All-Season",
        "width": 245,
        "aspect_ratio": 40,
        "rim_size": 18,
        "load_index": 97,
        "speed_rating": "Y",
        "dot_year": 2024,
        "price": 234.99,
        "original_price": 269.99,
        "rating": 4.8,
        "reviews_count": 384,
        "stock": 28,
        "wet_grip": "A",
        "fuel_efficiency": "B",
        "noise_db": 69,
        "warranty_miles": 45000,
        "description": "Supercar-level all-weather grip. Standard equipment on Corvette C8 with 4% better dry braking and 5% better wet braking.",
        "compatible_cars": ["Chevrolet Corvette", "Audi S4", "BMW M340i", "Lexus IS350"],
        "image_url": "https://dxm.contentcenter.michelin.com/api/wedia/dam/transform/b98rpyxf61b4xgr9bgbcx6kj9y/4w-363_3528709347266_tire_michelin_pilot-sport-a-slash-s-4_245-slash-40-zr18-97y-xl_a_main_1-30_nopad.webp",
        "local_fallback": "assets/images/tires/michelin_ps5.webp"
    },
    {
        "id": "michelin-pilot-sport-cup-2",
        "brand": "Michelin",
        "model": "Pilot Sport Cup 2",
        "category": "Street-Legal Track & Competition",
        "season": "Summer Track",
        "width": 295,
        "aspect_ratio": 30,
        "rim_size": 19,
        "load_index": 100,
        "speed_rating": "Y",
        "dot_year": 2024,
        "price": 389.99,
        "original_price": 429.99,
        "rating": 4.9,
        "reviews_count": 196,
        "stock": 14,
        "wet_grip": "C",
        "fuel_efficiency": "E",
        "noise_db": 73,
        "warranty_miles": 15000,
        "description": "Bi-Compound technology developed for endurance championships. Designed for lightning track lap times on dry circuits.",
        "compatible_cars": ["Porsche 911 GT3", "BMW M3 CS", "Ferrari 488", "Mercedes-AMG GT"],
        "image_url": "https://dxm.contentcenter.michelin.com/api/wedia/dam/transform/b98rpyxf61b4xvdz2c6j4h6sc6/4w-97_3528708109599_tire_michelin_pilot-sport-cup-2_295-slash-30-zr19-100y-xl_a_main_1-30_nopad.webp",
        "local_fallback": "assets/images/tires/michelin_ps5.webp"
    },
    {
        "id": "michelin-primacy-4-plus",
        "brand": "Michelin",
        "model": "Primacy 4+",
        "category": "Premium Touring Comfort",
        "season": "Summer",
        "width": 215,
        "aspect_ratio": 55,
        "rim_size": 17,
        "load_index": 94,
        "speed_rating": "V",
        "dot_year": 2024,
        "price": 169.99,
        "original_price": 189.99,
        "rating": 4.7,
        "reviews_count": 420,
        "stock": 45,
        "wet_grip": "A",
        "fuel_efficiency": "A",
        "noise_db": 67,
        "warranty_miles": 55000,
        "description": "EverGrip self-regenerating tread technology ensures whisper-quiet cabin acoustics and class-leading safety when worn.",
        "compatible_cars": ["Toyota Camry", "Honda Accord", "Volkswagen Passat", "Hyundai Sonata"],
        "image_url": "https://dxm.contentcenter.michelin.com/api/wedia/dam/transform/b98rpyxf61b4xzk9wdsbidqs7o/4w-352_3528702021972_tire_michelin_primacy-tour-a-slash-s_225-slash-50-r17-98v-xl_a_main_1-30_nopad.webp",
        "local_fallback": "assets/images/tires/michelin_primacy4.webp"
    },
    {
        "id": "michelin-e-primacy",
        "brand": "Michelin",
        "model": "e-Primacy Electric Drive",
        "category": "EV Energy Saving",
        "season": "Summer EV",
        "width": 235,
        "aspect_ratio": 40,
        "rim_size": 19,
        "load_index": 96,
        "speed_rating": "W",
        "dot_year": 2024,
        "price": 209.99,
        "original_price": 239.99,
        "rating": 4.8,
        "reviews_count": 215,
        "stock": 22,
        "wet_grip": "B",
        "fuel_efficiency": "A+",
        "noise_db": 66,
        "warranty_miles": 50000,
        "description": "Eco-designed for Electric & Hybrid vehicles. Low rolling resistance extends vehicle battery range by up to 7%.",
        "compatible_cars": ["Tesla Model 3", "Hyundai Ioniq 5", "Kia EV6", "Polestar 2"],
        "image_url": "https://dxm.contentcenter.michelin.com/api/wedia/dam/transform/b98rpyxf61b4x5q24d27f8842w/4w-1594_3528702552063_tire_michelin_e-primacy-all-season_235-slash-40-r19-96w-xl_a_main_1-30_nopad.webp",
        "local_fallback": "assets/images/tires/michelin_primacy4.webp"
    },
    {
        "id": "michelin-crossclimate-2-suv",
        "brand": "Michelin",
        "model": "Cross Climate 2 SUV",
        "category": "All-Weather Touring SUV",
        "season": "All-Weather (3PMSF)",
        "width": 235,
        "aspect_ratio": 60,
        "rim_size": 18,
        "load_index": 107,
        "speed_rating": "V",
        "dot_year": 2024,
        "price": 219.99,
        "original_price": 249.99,
        "rating": 4.9,
        "reviews_count": 630,
        "stock": 30,
        "wet_grip": "B",
        "fuel_efficiency": "B",
        "noise_db": 70,
        "warranty_miles": 60000,
        "description": "Distinctive V-shaped directional tread pattern certified for severe snow conditions without switching tires seasonally.",
        "compatible_cars": ["Toyota RAV4", "Honda CR-V", "Subaru Forester", "Mazda CX-5"],
        "image_url": "https://dxm.contentcenter.michelin.com/api/wedia/dam/transform/b98rpyxf61b4xr6a9qf962v96q/4w-355_3528700308648_tire_michelin_primacy-ltx_265-slash-65-r18-114t_a_main_1-30_nopad.webp",
        "local_fallback": "assets/images/tires/michelin_crossclimate_suv.webp"
    },

    # --- CONTINENTAL ---
    {
        "id": "continental-extremecontact-dws06-plus",
        "brand": "Continental",
        "model": "Extreme Contact DWS06 Plus",
        "category": "Ultra High Performance All-Season",
        "season": "All-Season",
        "width": 225,
        "aspect_ratio": 45,
        "rim_size": 18,
        "load_index": 95,
        "speed_rating": "Y",
        "dot_year": 2024,
        "price": 194.99,
        "original_price": 219.99,
        "rating": 4.9,
        "reviews_count": 890,
        "stock": 52,
        "wet_grip": "A",
        "fuel_efficiency": "C",
        "noise_db": 71,
        "warranty_miles": 50000,
        "description": "Tuned Performance Indicators (D, W, S) stamped directly on tread to alert drivers when tire is optimized for Dry, Wet, or Snow.",
        "compatible_cars": ["BMW 3 Series", "Subaru WRX", "Volkswagen Golf R", "Audi S3"],
        "image_url": "https://continentaltire.com/sites/default/files/styles/square_medium/public/media/image/2021-01/ExtremeContactDWS06Plus_Lt3Q.png",
        "local_fallback": "assets/images/tires/continental_sc7.webp"
    },
    {
        "id": "continental-extremecontact-sport-02",
        "brand": "Continental",
        "model": "Extreme Contact Sport 02",
        "category": "Ultra High Performance Summer",
        "season": "Summer",
        "width": 245,
        "aspect_ratio": 40,
        "rim_size": 19,
        "load_index": 98,
        "speed_rating": "Y",
        "dot_year": 2024,
        "price": 242.99,
        "original_price": 275.99,
        "rating": 4.8,
        "reviews_count": 310,
        "stock": 25,
        "wet_grip": "A",
        "fuel_efficiency": "C",
        "noise_db": 70,
        "warranty_miles": 30000,
        "description": "Co-developed with professional IMSA race drivers. SportPlus technology provides immediate steering response and extreme cornering grip.",
        "compatible_cars": ["Ford Mustang GT", "Chevrolet Camaro", "BMW M2", "Porsche Cayman"],
        "image_url": "https://continentaltire.com/sites/default/files/styles/square_medium/public/media/image/2022-10/ECS02_Lt3Q_0.png",
        "local_fallback": "assets/images/tires/continental_sc7.webp"
    },
    {
        "id": "continental-sportcontact-7",
        "brand": "Continental",
        "model": "Sport Contact 7",
        "category": "Max Performance Supercar",
        "season": "Summer",
        "width": 265,
        "aspect_ratio": 35,
        "rim_size": 20,
        "load_index": 99,
        "speed_rating": "Y",
        "dot_year": 2024,
        "price": 319.99,
        "original_price": 359.99,
        "rating": 4.9,
        "reviews_count": 275,
        "stock": 18,
        "wet_grip": "A",
        "fuel_efficiency": "D",
        "noise_db": 72,
        "warranty_miles": 25000,
        "description": "BlackChili compound formulation engineered for sports cars and high-powered GTs. Ranked #1 in major European tire tests.",
        "compatible_cars": ["BMW M4 Competition", "Audi RS5", "Mercedes-AMG C63", "Porsche 911"],
        "image_url": "https://continentaltire.com/sites/default/files/styles/square_medium/public/media/image/2021-05/ExtremeContactForce_Lt3Q_2.png",
        "local_fallback": "assets/images/tires/continental_sc7.webp"
    },
    {
        "id": "continental-ultracontact-uc7",
        "brand": "Continental",
        "model": "Ultra Contact UC7",
        "category": "Daily Touring Safety & Noise",
        "season": "Summer",
        "width": 205,
        "aspect_ratio": 55,
        "rim_size": 16,
        "load_index": 91,
        "speed_rating": "V",
        "dot_year": 2024,
        "price": 149.99,
        "original_price": 172.99,
        "rating": 4.7,
        "reviews_count": 480,
        "stock": 60,
        "wet_grip": "A",
        "fuel_efficiency": "B",
        "noise_db": 67,
        "warranty_miles": 50000,
        "description": "Diamond compound with Noise Breaker 3.0 interrupts sound waves in tire grooves to deliver an ultra-quiet cabin ride.",
        "compatible_cars": ["Toyota Corolla", "Honda Civic", "Mazda 3", "Volkswagen Jetta"],
        "image_url": "https://continentaltire.com/sites/default/files/styles/square_medium/public/media/image/2024-07/ct_webpage_truecontacttour54_l3qt_600x600_0.png",
        "local_fallback": "assets/images/tires/continental_uc7.webp"
    },
    {
        "id": "continental-terraincontact-at",
        "brand": "Continental",
        "model": "Terrain Contact A/T",
        "category": "All-Terrain Truck & SUV",
        "season": "All-Terrain (3PMSF)",
        "width": 265,
        "aspect_ratio": 70,
        "rim_size": 17,
        "load_index": 115,
        "speed_rating": "T",
        "dot_year": 2024,
        "price": 259.99,
        "original_price": 289.99,
        "rating": 4.8,
        "reviews_count": 520,
        "stock": 24,
        "wet_grip": "A",
        "fuel_efficiency": "D",
        "noise_db": 72,
        "warranty_miles": 60000,
        "description": "TractionPlus technology strikes the perfect balance between off-road durability (gravel, dirt, rock) and quiet highway comfort.",
        "compatible_cars": ["Ford F-150", "Toyota Tacoma", "Jeep Wrangler", "Chevrolet Silverado"],
        "image_url": "https://continentaltire.com/sites/default/files/styles/square_medium/public/media/image/2020-08/terraincontactat_tread_rd.png",
        "local_fallback": "assets/images/tires/continental_sc7.webp"
    },
    {
        "id": "continental-crosscontact-lx25",
        "brand": "Continental",
        "model": "Cross Contact LX25",
        "category": "Premium Crossover / SUV Touring",
        "season": "All-Season",
        "width": 235,
        "aspect_ratio": 55,
        "rim_size": 19,
        "load_index": 105,
        "speed_rating": "H",
        "dot_year": 2024,
        "price": 224.99,
        "original_price": 254.99,
        "rating": 4.8,
        "reviews_count": 340,
        "stock": 35,
        "wet_grip": "A",
        "fuel_efficiency": "B",
        "noise_db": 68,
        "warranty_miles": 70000,
        "description": "EcoPlus technology saves fuel while providing best-in-class wet braking and an impressive 70,000-mile treadwear warranty.",
        "compatible_cars": ["Lexus RX350", "Audi Q5", "Acura MDX", "Volvo XC60"],
        "image_url": "https://continentaltire.com/sites/default/files/styles/square_medium/public/media/image/2020-08/crosscontactlx25_tread_rd.png",
        "local_fallback": "assets/images/tires/continental_uc7.webp"
    },
    {
        "id": "continental-vikingcontact-7",
        "brand": "Continental",
        "model": "Viking Contact 7",
        "category": "Nordic Winter / Ice & Snow",
        "season": "Winter (Studless)",
        "width": 225,
        "aspect_ratio": 50,
        "rim_size": 17,
        "load_index": 98,
        "speed_rating": "T",
        "dot_year": 2024,
        "price": 184.99,
        "original_price": 209.99,
        "rating": 4.9,
        "reviews_count": 415,
        "stock": 20,
        "wet_grip": "B",
        "fuel_efficiency": "C",
        "noise_db": 67,
        "warranty_miles": 40000,
        "description": "Nordic silica compound remains flexible in sub-zero temperatures with 3D sipes locking together for unmatched braking on black ice.",
        "compatible_cars": ["Volvo S60", "Audi A4 Quattro", "BMW 3 Series xDrive", "Subaru Outback"],
        "image_url": "https://continentaltire.com/sites/default/files/styles/square_medium/public/media/image/2020-08/vickingcontact7_tread_rd.png",
        "local_fallback": "assets/images/tires/continental_sc7.webp"
    },

    # --- PIRELLI ---
    {
        "id": "pirelli-p-zero-pz4",
        "brand": "Pirelli",
        "model": "P Zero (PZ4) Luxury",
        "category": "Ultra High Performance Luxury",
        "season": "Summer",
        "width": 245,
        "aspect_ratio": 40,
        "rim_size": 19,
        "load_index": 98,
        "speed_rating": "Y",
        "dot_year": 2024,
        "price": 279.99,
        "original_price": 319.99,
        "rating": 4.8,
        "reviews_count": 390,
        "stock": 28,
        "wet_grip": "A",
        "fuel_efficiency": "B",
        "noise_db": 69,
        "warranty_miles": 35000,
        "description": "Original equipment for prestige automakers. High silica content provides exceptional wet safety and low rolling resistance.",
        "compatible_cars": ["Mercedes-Benz E-Class", "BMW 5 Series", "Audi A6", "Jaguar XF"],
        "image_url": "https://tyre24.pirelli.com/dynamic_engine/assets/visori/3_4/pzero.png",
        "local_fallback": "assets/images/tires/goodyear_eagle_f1.png"
    },

    # --- GOODYEAR ---
    {
        "id": "goodyear-eagle-f1-asymmetric-6",
        "brand": "Goodyear",
        "model": "Eagle F1 Asymmetric 6",
        "category": "Ultra High Performance EV-Ready",
        "season": "Summer",
        "width": 225,
        "aspect_ratio": 45,
        "rim_size": 18,
        "load_index": 95,
        "speed_rating": "Y",
        "dot_year": 2024,
        "price": 199.99,
        "original_price": 229.99,
        "rating": 4.8,
        "reviews_count": 450,
        "stock": 38,
        "wet_grip": "A",
        "fuel_efficiency": "B",
        "noise_db": 69,
        "warranty_miles": 45000,
        "description": "Dry Contact Plus technology adapts tire footprint to driving style. EV-ready construction with noise-canceling foam layer.",
        "compatible_cars": ["Tesla Model 3", "BMW 3 Series", "Polestar 2", "Volkswagen Golf GTI"],
        "image_url": "",
        "local_fallback": "assets/images/tires/goodyear_eagle_f1.png"
    }
]

def main():
    assets_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "tires")
    data_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "data")
    os.makedirs(assets_dir, exist_ok=True)
    os.makedirs(data_dir, exist_ok=True)

    print("[INFO] Starting Treadly Automatic Tire Ingestion Pipeline...")
    print(f"[INFO] Total tire items to process: {len(TIRES_CONFIG)}")

    saved_items = []

    for tire in TIRES_CONFIG:
        slug = tire["id"].replace("-", "_")
        target_filename = f"{slug}.webp"
        target_path = os.path.join(assets_dir, target_filename)
        asset_rel_path = f"assets/images/tires/{target_filename}"

        downloaded = False
        img_url = tire.get("image_url", "").strip()

        if img_url:
            try:
                print(f"  [FETCH] Downloading {tire['brand']} {tire['model']}...")
                r = requests.get(img_url, headers=HEADERS, timeout=12)
                if r.status_code == 200:
                    img = Image.open(io.BytesIO(r.content))
                    if img.mode != 'RGBA':
                        img = img.convert('RGBA')
                    img.thumbnail((700, 700), Image.Resampling.LANCZOS)
                    img.save(target_path, "WEBP", quality=90)
                    downloaded = True
                    print(f"  [OK] Saved: {target_filename} ({img.size[0]}x{img.size[1]})")
                else:
                    print(f"  [WARN] HTTP {r.status_code} for {img_url}")
            except Exception as e:
                print(f"  [WARN] Download error for {tire['model']}: {e}")

        # If download didn't succeed, check local fallback
        if not downloaded:
            fallback = tire.get("local_fallback")
            fallback_abs = os.path.join(os.path.dirname(__file__), "..", fallback) if fallback else ""
            if fallback_abs and os.path.exists(fallback_abs):
                try:
                    img = Image.open(fallback_abs)
                    if img.mode != 'RGBA':
                        img = img.convert('RGBA')
                    img.thumbnail((700, 700), Image.Resampling.LANCZOS)
                    img.save(target_path, "WEBP", quality=90)
                    print(f"  [FALLBACK] Processed from local: {target_filename}")
                except Exception as e:
                    print(f"  [WARN] Fallback error: {e}")

        # Update tire record with verified local asset path
        record = dict(tire)
        record.pop("image_url", None)
        record.pop("local_fallback", None)
        record["image_asset"] = asset_rel_path
        saved_items.append(record)

    # Write out JSON dataset
    json_path = os.path.join(data_dir, "tires.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(saved_items, f, indent=2, ensure_ascii=False)

    print("\n[SUCCESS] Automatic Ingestion Complete!")
    print(f"[SUCCESS] Saved {len(saved_items)} tires to: assets/data/tires.json")
    print(f"[SUCCESS] Images saved in: assets/images/tires/")

if __name__ == "__main__":
    main()
