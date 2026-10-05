"""
Generate exactly 100 rich, distinct, real-world tire products for Treadly.
Saves to assets/data/tires.json with full schema and expanded vehicle compatibility.
"""

import json
import os

FITMENT_EXPANSION = {
    (175, 65, 14): ["Toyota Wigo", "Mitsubishi Mirage", "Suzuki Celerio", "Honda Brio", "Hyundai Grand i10", "Kia Picanto", "Suzuki Alto", "Daihatsu Ayla"],
    (185, 65, 14): ["Toyota Wigo", "Mitsubishi Mirage", "Suzuki Celerio", "Honda Brio", "Hyundai i10", "Kia Picanto"],
    (185, 60, 15): ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift", "Hyundai Accent", "Toyota Yaris", "Suzuki Dzire", "Kia Soluto"],
    (185, 65, 15): ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift", "Suzuki Ciaz", "Hyundai Accent", "Toyota Avanza", "Suzuki Ertiga"],
    (195, 50, 16): ["Mazda MX-5 Miata", "Toyota Vios", "Honda City", "Suzuki Swift Sport", "Ford Fiesta", "Toyota Yaris", "Mini Cooper"],
    (195, 70, 15): ["Toyota HiAce", "Nissan Urvan", "Ford Transit Custom", "Hyundai Staria Cargo", "Renault Master", "Mitsubishi L300", "Kia K2500"],
    (195, 80, 15): ["Toyota HiAce", "Nissan NV350 Urvan", "Hyundai Staria Cargo", "Mitsubishi L300", "Kia K2500", "Isuzu Traviz", "Hyundai H100"],
    (205, 45, 17): ["Honda Civic", "Toyota Corolla Altis", "Mazda 3", "Suzuki Swift Sport", "Toyota Vios GR-S", "Mazda 2", "Hyundai Veloster", "Kia Forte GT", "Mini Cooper S"],
    (205, 50, 16): ["Mazda MX-5 Miata", "Toyota GR86", "Honda Civic Si", "Suzuki Swift Sport", "Toyota Corolla AE86", "Mini Cooper S", "Subaru BRZ"],
    (205, 55, 16): ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Hyundai Elantra", "Kia Forte", "Nissan Sylphy", "Nissan Sentra", "Volkswagen Golf", "Ford Focus", "Subaru Impreza", "Audi A3", "BMW 1 Series"],
    (215, 45, 17): ["Honda Civic", "Toyota Corolla Altis", "Mazda 3", "Subaru BRZ", "Mini Cooper S", "Toyota GR86", "Volkswagen Golf GTI"],
    (215, 50, 17): ["Toyota Corolla Altis GR-S", "Honda Civic RS", "Mazda 3 Fastback", "Subaru Impreza", "Hyundai Elantra N-Line", "Toyota Camry", "Honda Accord", "Nissan Altima", "Kia Forte GT"],
    (215, 55, 17): ["Toyota Camry", "Honda Accord", "Volkswagen Passat", "Nissan Teana", "Mazda 6", "Subaru Legacy", "Lexus ES300h", "Toyota Alphard", "Hyundai Sonata", "Kia K5"],
    (215, 60, 17): ["Toyota Corolla Cross", "Honda HR-V", "Subaru Crosstrek", "Subaru XV", "Mazda CX-30", "Hyundai Kona", "Nissan Kicks e-Power", "Kia Seltos", "Mitsubishi Xpander Cross"],
    (215, 70, 16): ["Toyota HiAce Commuter", "Nissan NV350 Urvan", "Ford Transit", "Hyundai Staria", "Mercedes-Benz Sprinter", "Mitsubishi Delica"],
    (225, 40, 18): ["Volkswagen Golf GTI", "Volkswagen Golf R", "Honda Civic Type R", "Honda Civic", "Toyota Corolla GR", "Subaru WRX", "Hyundai i30 N", "Mini Cooper JCW", "BMW 1 Series", "Audi S3", "Mercedes-Benz A250"],
    (225, 45, 17): ["Subaru WRX", "Volkswagen Golf GTI", "Honda Civic Si", "BMW 2 Series", "Mazda 3 Turbo", "Audi A3", "BMW 1 Series", "Mercedes-Benz A-Class", "Toyota Prius", "Nissan Leaf"],
    (225, 45, 18): ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Honda Civic Type R", "Subaru WRX", "Hyundai Sonata", "Kia K5", "Toyota Camry", "Mazda 6", "Lexus IS300"],
    (225, 50, 17): ["Volvo V60", "Audi A4 Allroad", "BMW 3 Series xDrive", "Subaru Forester", "Mercedes-Benz C-Class 4MATIC", "Tesla Model 3", "Mercedes-Benz E-Class", "Audi A6", "Lexus ES300h", "Volvo S60", "Volkswagen Arteon"],
    (225, 55, 17): ["Toyota Camry", "Honda Accord", "Lexus ES300h", "Mazda 6", "Nissan Teana", "Toyota Alphard", "Subaru Outback", "Hyundai Sonata"],
    (225, 60, 18): ["Subaru Forester", "Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Hyundai Tucson", "Kia Sportage", "Mitsubishi Outlander"],
    (225, 65, 17): ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Subaru Forester", "Hyundai Tucson", "Kia Sportage", "Mitsubishi Outlander", "Ford Territory"],
    (235, 35, 19): ["BMW M240i", "Audi S3", "Volkswagen Golf R", "Mercedes-AMG A35", "Honda Civic Type R", "Subaru WRX STI", "Mercedes-AMG A45", "BMW M2", "Toyota GR Supra", "Audi S4", "Mercedes-Benz C300", "Lexus IS350"],
    (235, 40, 18): ["Audi S3", "Honda Civic Type R", "Volkswagen Golf R", "Mercedes-Benz CLA250", "BMW 3 Series", "Subaru WRX", "Toyota GR Yaris", "Subaru WRX STI", "Mitsubishi Lancer Evolution", "Mazda RX-7", "Nissan Silvia S15"],
    (235, 40, 19): ["Audi S3", "BMW 3 Series", "Mercedes-Benz CLA", "Volkswagen Golf R", "Subaru WRX", "Hyundai i30 N", "Porsche Taycan", "Audi S4", "Mercedes-Benz C-Class", "Genesis G70", "Kia Stinger"],
    (235, 45, 18): ["Tesla Model 3", "Hyundai Ioniq 5", "Kia EV6", "BYD Seal", "Polestar 2", "BMW i4", "Honda Accord", "Toyota Camry Hybrid"],
    (235, 50, 19): ["Mazda CX-5", "Mazda CX-60", "Toyota Harrier", "Audi Q3", "BMW X1", "Mercedes-Benz GLA", "Lexus NX300"],
    (235, 55, 18): ["Honda CR-V", "Toyota RAV4", "Lexus NX300", "Subaru Outback", "Hyundai Santa Fe", "Kia Sorento", "Ford Territory", "Mazda CX-5"],
    (235, 55, 19): ["BMW X3", "Audi Q5", "Lexus RX350", "Toyota Harrier", "Mercedes-Benz GLC", "Volvo XC60", "Genesis GV70", "Porsche Macan"],
    (235, 60, 18): ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Subaru Forester", "Hyundai Tucson", "Kia Sportage", "Audi Q5", "Porsche Macan", "Volvo XC60", "BMW X3", "Land Rover Discovery Sport", "Mercedes-Benz GLC"],
    (245, 35, 20): ["Porsche 911", "Audi R8", "Ferrari F8", "Mercedes-AMG GT", "BMW M5", "Lamborghini Huracan", "Chevrolet Corvette C8", "Nissan GT-R"],
    (245, 40, 18): ["Chevrolet Corvette", "Audi S4", "BMW M340i", "Lexus IS350", "Ford Mustang", "Genesis G70", "Toyota GR86", "Subaru BRZ", "Mazda MX-5 Miata", "Honda S2000", "BMW M2"],
    (245, 40, 19): ["BMW 4 Series Gran Coupe", "Audi A5 Sportback", "Mercedes-Benz E-Class Coupe", "Genesis G70", "Lexus IS350 F Sport", "Toyota GR Supra", "Mercedes-AMG A45 S", "Audi RS3", "BMW M340i", "Alfa Romeo Giulia QV", "Porsche 911", "Honda Civic Type R", "BMW M3", "BMW M4", "Mercedes-AMG C43", "Audi S4"],
    (245, 45, 18): ["Lexus IS300", "BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Subaru WRX", "Infiniti Q50", "BMW 5 Series", "Mercedes-Benz E-Class"],
    (245, 45, 19): ["Porsche Taycan", "Tesla Model S", "BMW i4 M50", "Audi e-tron GT", "Mercedes-Benz EQE", "Lucid Air", "Genesis G80 EV", "BMW 5 Series"],
    (255, 35, 19): ["Audi S5", "BMW M3", "Mercedes-AMG C43", "Ford Mustang GT", "Nissan Z", "Lexus RC F", "Toyota GR Supra", "BMW M2", "Porsche 718 Cayman", "Chevrolet Camaro SS", "BMW M4", "Mercedes-AMG C63", "Audi RS5", "Genesis G70", "BMW M340i"],
    (255, 40, 18): ["Toyota GR Yaris", "Honda Civic Type R", "Porsche Cayman", "BMW M3", "Subaru BRZ", "Mazda MX-5 Miata", "Ford Mustang GT", "Nissan 370Z"],
    (255, 45, 19): ["Tesla Model Y", "Tesla Model 3", "Hyundai Ioniq 5", "Kia EV6", "BYD Seal", "BMW i4", "Audi Q4 e-tron", "Genesis GV60"],
    (255, 50, 20): ["Lexus RX350", "BMW X5", "Mercedes-Benz GLE", "Audi Q7", "Acura MDX", "Infiniti QX60", "Porsche Macan", "Range Rover Velar", "Volvo XC90"],
    (255, 55, 19): ["Mercedes-Benz GLE", "BMW X5", "Volvo XC90", "Audi Q7", "Lexus RX350", "Genesis GV80", "Porsche Cayenne", "Land Rover Discovery"],
    (265, 60, 18): ["Toyota Fortuner GR-S", "Mitsubishi Montero Sport GT", "Ford Everest Titanium", "Nissan Terra VL", "Isuzu mu-X LS-E", "Toyota Hilux Conquest", "Ford Ranger Wildtrak", "Nissan Navara Pro-4X", "Mitsubishi Strada Athlete", "Isuzu D-Max LS-E", "Toyota Prado"],
    (265, 65, 17): ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Isuzu mu-X", "Toyota Hilux", "Ford Ranger", "Nissan Navara", "Isuzu D-Max", "Mitsubishi Strada", "Jeep Gladiator"],
    (265, 70, 17): ["Ford Ranger", "Toyota Hilux", "Toyota Fortuner", "Nissan Navara", "Mitsubishi Montero Sport", "Isuzu D-Max", "Ford Ranger Raptor", "Jeep Wrangler", "Toyota Hilux Conquest", "Nissan Navara Pro-4X", "Isuzu D-Max V-Cross", "Toyota Fortuner GR-S"],
    (265, 75, 16): ["Toyota Land Cruiser 70", "Toyota Hilux", "Jeep Wrangler", "Ford Ranger Raptor", "Nissan Patrol Safari", "Isuzu D-Max", "Mitsubishi Pajero"],
    (275, 35, 19): ["BMW M2 CS", "BMW M4 Competition", "Toyota GR Supra 3.0", "Porsche 911 Carrera S", "Chevrolet Corvette C8", "Nissan Z Performance", "Lexus RC F"],
    (275, 35, 20): ["BMW M5", "Mercedes-AMG E63 S", "Audi RS6 Avant", "Porsche Panamera Turbo", "Nissan GT-R", "Lexus LC500", "Aston Martin DB11"],
    (275, 45, 20): ["Land Rover Defender", "BMW X5 M", "Porsche Cayenne", "Audi Q8", "Mercedes-Benz GLE 53 AMG", "Range Rover Sport", "Genesis GV80"],
    (275, 65, 18): ["Ford Ranger Raptor", "Toyota Land Cruiser 300", "Nissan Patrol Nismo", "Toyota Hilux GR-S", "Mitsubishi Montero Sport", "Jeep Gladiator", "Ford Everest Titanium+"],
    (285, 30, 20): ["McLaren 720S", "Ferrari 296 GTB", "Lamborghini Huracan STO", "Porsche 911 GT3 RS", "Aston Martin Vantage", "Ferrari F8 Tributo"],
    (285, 65, 18): ["Ford Ranger Raptor", "Toyota Land Cruiser", "Nissan Patrol", "Jeep Gladiator", "Ford F-150", "Toyota Hilux GR-S", "Toyota Land Cruiser 300"],
    (285, 70, 17): ["Jeep Wrangler Rubicon", "Toyota Land Cruiser", "Ford Ranger Raptor", "Nissan Patrol Safari", "Toyota Hilux Arctic", "Isuzu D-Max Arctic Trucks"],
    (285, 75, 16): ["Toyota Land Cruiser", "Jeep Wrangler Rubicon", "Ford Ranger Raptor", "Nissan Patrol Safari", "Isuzu D-Max", "Toyota Land Cruiser 70"],
    (295, 30, 19): ["Porsche 911 GT3", "BMW M3 CS", "Mercedes-AMG GT", "Ferrari 488", "Audi R8", "Chevrolet Corvette Z06", "Porsche 911 Carrera GTS"],
    (325, 30, 21): ["Porsche 911 GT2 RS", "Porsche 911 GT3 RS", "Ferrari SF90 Stradale", "Mercedes-AMG GT Black Series", "McLaren 765LT", "Lamborghini Aventador SVJ"],
}

# Helper to build consistent tire dict
def make_tire(
    id_slug, brand, model, category, season,
    width, aspect_ratio, rim_size, load_index, speed_rating, dot_year,
    price, original_price, rating, reviews_count, stock,
    wet_grip, fuel_efficiency, noise_db, warranty_miles,
    description, compatible_cars, image_asset
):
    generic = FITMENT_EXPANSION.get((width, aspect_ratio, rim_size), [])
    merged_cars = []
    seen = set()
    for car in (compatible_cars or []) + generic:
        c_clean = car.strip()
        if c_clean.lower() not in seen:
            seen.add(c_clean.lower())
            merged_cars.append(c_clean)
            
    # Keep up to 10 top compatible vehicles
    merged_cars = merged_cars[:10]

    return {
        "id": id_slug,
        "brand": brand,
        "model": model,
        "category": category,
        "season": season,
        "width": width,
        "aspect_ratio": aspect_ratio,
        "rim_size": rim_size,
        "load_index": load_index,
        "speed_rating": speed_rating,
        "dot_year": dot_year,
        "price": price,
        "original_price": original_price,
        "rating": rating,
        "reviews_count": reviews_count,
        "stock": stock,
        "wet_grip": wet_grip,
        "fuel_efficiency": fuel_efficiency,
        "noise_db": noise_db,
        "warranty_miles": warranty_miles,
        "description": description,
        "compatible_cars": merged_cars,
        "image_asset": image_asset
    }

TIRES = []

# =============================================================================
# 1. MICHELIN (18 Tires)
# =============================================================================
TIRES.append(make_tire(
    "michelin-pilot-sport-5", "Michelin", "Pilot Sport 5",
    "Ultra High Performance Summer", "Summer",
    225, 45, 18, 95, "Y", 2024,
    219.99, 249.99, 4.9, 512, 36,
    "A", "B", 68, 30000,
    "5th generation of Michelin's iconic performance tire. Offers razor-sharp steering precision and supreme wet braking distance.",
    ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Honda Civic Type R", "Subaru WRX"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "michelin-pilot-sport-5-19", "Michelin", "Pilot Sport 5",
    "Ultra High Performance Summer", "Summer",
    245, 40, 19, 98, "Y", 2024,
    264.99, 299.99, 4.9, 320, 24,
    "A", "B", 69, 30000,
    "Larger diameter fitment for modern executive sedans and sports coupes, with Dual Sport tread technology.",
    ["BMW 4 Series Gran Coupe", "Audi A5 Sportback", "Mercedes-Benz E-Class Coupe", "Genesis G70", "Lexus IS350 F Sport", "Toyota GR Supra"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "michelin-pilot-sport-all-season-4", "Michelin", "Pilot Sport All-Season 4",
    "Ultra High Performance All-Season", "All-Season",
    245, 40, 18, 97, "Y", 2024,
    234.99, 269.99, 4.8, 384, 28,
    "A", "B", 69, 45000,
    "Supercar-level all-weather grip. Standard equipment on Corvette C8 with 4% better dry braking and 5% better wet braking.",
    ["Chevrolet Corvette", "Audi S4", "BMW M340i", "Lexus IS350", "Ford Mustang", "Genesis G70"],
    "assets/images/tires/michelin_pilot_sport_all_season_4.webp"
))

TIRES.append(make_tire(
    "michelin-pilot-sport-all-season-4-19", "Michelin", "Pilot Sport All-Season 4",
    "Ultra High Performance All-Season", "All-Season",
    255, 35, 19, 96, "Y", 2024,
    279.99, 319.99, 4.8, 245, 20,
    "A", "B", 70, 45000,
    "Staggered rear fitment with 360-degree variable sipes that lock under cornering load.",
    ["Audi S5", "BMW M3", "Mercedes-AMG C43", "Ford Mustang GT", "Nissan Z", "Lexus RC F"],
    "assets/images/tires/michelin_pilot_sport_all_season_4.webp"
))

TIRES.append(make_tire(
    "michelin-pilot-sport-cup-2", "Michelin", "Pilot Sport Cup 2",
    "Street-Legal Track & Competition", "Summer Track",
    295, 30, 19, 100, "Y", 2024,
    389.99, 429.99, 4.9, 196, 14,
    "C", "E", 73, 15000,
    "Bi-Compound technology developed for endurance championships. Designed for lightning track lap times on dry circuits.",
    ["Porsche 911 GT3", "BMW M3 CS", "Mercedes-AMG GT", "Ferrari 488", "Audi R8", "Chevrolet Corvette Z06"],
    "assets/images/tires/michelin_pilot_sport_cup_2.webp"
))

TIRES.append(make_tire(
    "michelin-pilot-sport-cup-2-r", "Michelin", "Pilot Sport Cup 2 R",
    "Extreme Track & Record Breaker", "Summer Track",
    325, 30, 21, 108, "Y", 2024,
    525.00, 595.00, 5.0, 88, 6,
    "E", "E", 75, 8000,
    "Nürburgring lap record setter. Ultimate motorsport-grade rubber compound engineered for maximum instantaneous lateral grip.",
    ["Porsche 911 GT2 RS", "Porsche 911 GT3 RS", "Ferrari SF90 Stradale", "Mercedes-AMG GT Black Series", "McLaren 765LT"],
    "assets/images/tires/michelin_pilot_sport_cup_2.webp"
))

TIRES.append(make_tire(
    "michelin-primacy-4-plus", "Michelin", "Primacy 4+",
    "Premium Touring Comfort", "Summer",
    215, 55, 17, 94, "W", 2024,
    179.99, 199.99, 4.7, 428, 42,
    "A", "B", 68, 50000,
    "Class-leading wet braking from the first mile to the legal limit. Ultra-quiet compound engineered for whisper-quiet highway cruising.",
    ["Toyota Camry", "Honda Accord", "Volkswagen Passat", "Nissan Teana", "Mazda 6", "Subaru Legacy"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "michelin-primacy-4-plus-16", "Michelin", "Primacy 4+",
    "Premium Touring Comfort", "Summer",
    205, 55, 16, 91, "V", 2024,
    139.99, 159.99, 4.8, 380, 48,
    "A", "B", 68, 50000,
    "Perfect balance of plush ride quality, extended tread life, and reassuring wet weather safety for compact family sedans.",
    ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Hyundai Elantra", "Kia Forte", "Nissan Sylphy"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "michelin-cross-climate-2-suv", "Michelin", "Cross Climate 2 SUV",
    "All-Weather Grand Touring", "All-Weather",
    235, 60, 18, 103, "V", 2024,
    224.99, 254.99, 4.8, 310, 25,
    "B", "C", 70, 60000,
    "V-formation tread channels water efficiently while reinforced sidewalls withstand the extra torque and load of modern SUVs.",
    ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Subaru Forester", "Hyundai Tucson", "Kia Sportage"],
    "assets/images/tires/michelin_crossclimate_2_suv.webp"
))

TIRES.append(make_tire(
    "michelin-e-primacy-electric-drive", "Michelin", "e-Primacy Electric Drive",
    "Electric Vehicle Dedicated", "Summer EV",
    235, 45, 18, 98, "W", 2024,
    209.99, None, 4.7, 188, 22,
    "B", "A", 67, 40000,
    "Lowest rolling resistance in its category, extending EV battery range by up to 7%. Acoustic foam dampens road vibration.",
    ["Tesla Model 3", "Hyundai Ioniq 5", "Kia EV6", "BYD Seal", "Polestar 2", "BMW i4"],
    "assets/images/tires/michelin_e_primacy.webp"
))

TIRES.append(make_tire(
    "michelin-pilot-sport-4s", "Michelin", "Pilot Sport 4S",
    "Max Performance Summer", "Summer",
    255, 35, 19, 96, "(Y)", 2024,
    279.99, 319.99, 4.9, 680, 30,
    "A", "C", 71, 30000,
    "Benchmark ultra-high performance tire. Multi-compound construction delivers phenomenal road contact and cornering precision.",
    ["BMW M3", "BMW M4", "Mercedes-AMG C63", "Audi RS5", "Porsche Cayman", "Lexus RC F"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "michelin-primacy-suv-plus", "Michelin", "Primacy SUV+",
    "Highway Terrain Luxury SUV", "All-Season",
    265, 65, 17, 112, "H", 2024,
    198.50, 225.00, 4.8, 294, 35,
    "A", "B", 69, 55000,
    "Engineered for medium to full-size SUVs. Features StabiliGrip sipe technology for enhanced braking on both wet and dry asphalt.",
    ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Isuzu mu-X", "Toyota Hilux"],
    "assets/images/tires/michelin_crossclimate_suv.webp"
))

TIRES.append(make_tire(
    "michelin-primacy-suv-plus-18", "Michelin", "Primacy SUV+",
    "Highway Terrain Luxury SUV", "All-Season",
    265, 60, 18, 110, "H", 2024,
    228.00, 258.00, 4.8, 315, 28,
    "A", "B", 69, 55000,
    "Premium 18-inch fitment delivering executive SUV ride smoothness with short stopping distances in sudden highway cloudbursts.",
    ["Toyota Fortuner GR-S", "Mitsubishi Montero Sport GT", "Ford Everest Titanium", "Nissan Terra VL", "Isuzu mu-X LS-E"],
    "assets/images/tires/michelin_crossclimate_suv.webp"
))

TIRES.append(make_tire(
    "michelin-energy-xm2-plus", "Michelin", "Energy XM2+",
    "High Mileage Eco Touring", "All-Season",
    185, 60, 15, 84, "H", 2024,
    89.99, 105.00, 4.7, 540, 50,
    "B", "A", 68, 65000,
    "Full-silica formulation lasts 25% longer than competitor tires. Robust casing resists potholes and curb scuffs.",
    ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift", "Hyundai Accent"],
    "assets/images/tires/michelin_primacy4.webp"
))

TIRES.append(make_tire(
    "michelin-energy-xm2-plus-14", "Michelin", "Energy XM2+",
    "High Mileage Eco Touring", "All-Season",
    175, 65, 14, 82, "T", 2024,
    69.99, 82.00, 4.6, 420, 60,
    "B", "A", 68, 65000,
    "Long-lasting economy tire designed for entry-level hatchbacks. Incredible tread durability on tough provincial asphalt.",
    ["Toyota Wigo", "Mitsubishi Mirage", "Suzuki Celerio", "Honda Brio", "Hyundai Grand i10", "Kia Picanto"],
    "assets/images/tires/michelin_primacy4.webp"
))

TIRES.append(make_tire(
    "michelin-defender-2", "Michelin", "Defender 2",
    "Standard Touring All-Season", "All-Season",
    205, 55, 16, 91, "H", 2024,
    139.99, 159.99, 4.8, 312, 38,
    "B", "B", 69, 80000,
    "Unrivaled tread longevity backed by Michelin's 80,000-mile warranty. Locking 3D sipes maintain crisp handling throughout tire life.",
    ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Hyundai Elantra", "Kia Forte", "Nissan Sylphy"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "michelin-ltx-trail", "Michelin", "LTX Trail",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 60, 18, 110, "T", 2024,
    235.00, 265.00, 4.8, 210, 26,
    "A", "C", 71, 45000,
    "RallyForce rubber compound resists jagged rock tears on trails while maintaining smooth passenger car noise levels on pavement.",
    ["Ford Ranger", "Toyota Hilux Conquest", "Nissan Navara Pro-4X", "Mitsubishi Strada Athlete", "Isuzu D-Max", "Ford Everest"],
    "assets/images/tires/michelin_crossclimate_2_suv.webp"
))

TIRES.append(make_tire(
    "michelin-agilis-3", "Michelin", "Agilis 3",
    "Commercial Van & Utility", "Summer Commercial",
    195, 80, 15, 106, "R", 2024,
    118.00, 135.00, 4.7, 340, 48,
    "A", "B", 71, 50000,
    "Reinforced sidewall shield protects against curb strikes in dense city traffic. Low rolling resistance minimizes fleet operating costs.",
    ["Toyota HiAce", "Nissan Urvan", "Hyundai Staria Cargo", "Mitsubishi L300", "Kia K2500", "Isuzu Traviz"],
    "assets/images/tires/michelin_primacy4.webp"
))


# =============================================================================
# 2. CONTINENTAL (18 Tires)
# =============================================================================
TIRES.append(make_tire(
    "continental-extreme-contact-dws06-plus", "Continental", "Extreme Contact DWS06 Plus",
    "Ultra High Performance All-Season", "All-Season",
    225, 45, 17, 94, "W", 2024,
    164.99, 189.99, 4.8, 445, 32,
    "A", "C", 71, 50000,
    "SPORTPLUS Technology delivers responsive handling and superior wet traction. Features quickview indicators for Dry, Wet, and Snow readiness.",
    ["Subaru WRX", "Volkswagen Golf GTI", "Honda Civic Si", "BMW 2 Series", "Mazda 3 Turbo", "Audi A3"],
    "assets/images/tires/continental_extremecontact_dws06_plus.webp"
))

TIRES.append(make_tire(
    "continental-extreme-contact-dws06-plus-18", "Continental", "Extreme Contact DWS06 Plus",
    "Ultra High Performance All-Season", "All-Season",
    235, 40, 18, 95, "Y", 2024,
    194.99, 219.99, 4.8, 390, 28,
    "A", "C", 71, 50000,
    "Wide-contact 18-inch profile delivering razor-sharp all-season sports responsiveness in rain or shine.",
    ["Audi S3", "Honda Civic Type R", "Volkswagen Golf R", "Mercedes-Benz CLA250", "BMW 3 Series", "Subaru WRX"],
    "assets/images/tires/continental_extremecontact_dws06_plus.webp"
))

TIRES.append(make_tire(
    "continental-extreme-contact-sport-02", "Continental", "Extreme Contact Sport 02",
    "Ultra High Performance Summer", "Summer",
    255, 35, 19, 96, "Y", 2024,
    249.99, 289.99, 4.9, 278, 20,
    "A", "C", 71, 30000,
    "Dynamic dry braking and track-tested cornering stability engineered with professional championship sports car drivers.",
    ["Toyota GR Supra", "BMW M2", "Ford Mustang GT", "Nissan Z", "Porsche 718 Cayman", "Chevrolet Camaro SS"],
    "assets/images/tires/continental_extremecontact_sport_02.webp"
))

TIRES.append(make_tire(
    "continental-sport-contact-7", "Continental", "Sport Contact 7",
    "Max Performance Summer", "Summer",
    245, 40, 19, 98, "(Y)", 2024,
    269.99, 309.99, 4.9, 312, 24,
    "A", "C", 72, 25000,
    "Adaptive pattern design adapts to dry and wet roads, delivering unwavering high-speed stability and razor-sharp feedback.",
    ["Mercedes-AMG A45 S", "Audi RS3", "BMW M340i", "Alfa Romeo Giulia QV", "Porsche 911", "Honda Civic Type R"],
    "assets/images/tires/continental_sportcontact_7.webp"
))

TIRES.append(make_tire(
    "continental-sport-contact-7-20", "Continental", "Sport Contact 7",
    "Max Performance Summer", "Summer",
    275, 35, 20, 102, "(Y)", 2024,
    339.99, 389.99, 5.0, 185, 16,
    "A", "C", 73, 25000,
    "Ultra-wide 20-inch supercar fitment capable of absorbing huge torque output on high-speed track outings.",
    ["BMW M5", "Mercedes-AMG E63 S", "Audi RS6 Avant", "Porsche Panamera Turbo", "Nissan GT-R"],
    "assets/images/tires/continental_sportcontact_7.webp"
))

TIRES.append(make_tire(
    "continental-ultra-contact-uc7", "Continental", "Ultra Contact UC7",
    "Premium Touring Comfort", "All-Season",
    205, 55, 16, 91, "V", 2024,
    129.99, None, 4.7, 366, 40,
    "A", "B", 68, 50000,
    "Diamond Compound with Noise Breaker 3.0 technology provides ultra-quiet rides and shorter wet stopping distances.",
    ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sentra", "Hyundai Elantra", "Kia Forte"],
    "assets/images/tires/continental_ultracontact_uc7.webp"
))

TIRES.append(make_tire(
    "continental-ultra-contact-uc7-17", "Continental", "Ultra Contact UC7",
    "Premium Touring Comfort", "All-Season",
    215, 50, 17, 95, "W", 2024,
    155.00, 175.00, 4.8, 290, 36,
    "A", "B", 68, 50000,
    "Upgraded 17-inch specification combining velvety highway bump absorption with rapid wet rain braking.",
    ["Honda Civic RS", "Toyota Corolla Altis GR-S", "Mazda 3 Fastback", "Subaru Impreza", "Hyundai Elantra N-Line"],
    "assets/images/tires/continental_ultracontact_uc7.webp"
))

TIRES.append(make_tire(
    "continental-cross-contact-lx25", "Continental", "Cross Contact LX25",
    "Highway Terrain Luxury SUV", "All-Season",
    235, 55, 18, 100, "V", 2024,
    189.99, 219.99, 4.8, 256, 26,
    "B", "B", 69, 70000,
    "EcoPlus Technology provides fuel efficiency and extended tread life. Smooth, composed highway ride tailored for crossovers.",
    ["Honda CR-V", "Toyota RAV4", "Lexus NX300", "Subaru Outback", "Hyundai Santa Fe", "Kia Sorento"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "continental-cross-contact-lx25-19", "Continental", "Cross Contact LX25",
    "Highway Terrain Luxury SUV", "All-Season",
    235, 50, 19, 99, "V", 2024,
    219.00, 249.00, 4.8, 190, 22,
    "B", "B", 69, 70000,
    "Low profile luxury crossover tire that prevents excessive body roll and provides whisper-quiet expressway cruising.",
    ["Mazda CX-5", "Mazda CX-60", "Toyota Harrier", "Audi Q3", "BMW X1", "Mercedes-Benz GLA"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "continental-terrain-contact-at", "Continental", "Terrain Contact A/T",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 70, 17, 115, "T", 2024,
    214.99, 244.99, 4.8, 389, 18,
    "B", "C", 71, 60000,
    "TractionPlus Technology provides off-road grip on gravel, dirt, and wet grass while preserving whisper-quiet road manners.",
    ["Ford Ranger", "Toyota Hilux", "Toyota Fortuner", "Nissan Navara", "Mitsubishi Montero Sport", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "continental-terrain-contact-at-18", "Continental", "Terrain Contact A/T",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 60, 18, 110, "T", 2024,
    239.00, 269.00, 4.8, 280, 25,
    "B", "C", 71, 60000,
    "18-inch pickup and 4x4 fitment balancing rugged rocky trail traction with smooth metropolitan ride compliance.",
    ["Toyota Hilux Conquest", "Ford Ranger Wildtrak", "Nissan Navara Pro-4X", "Mitsubishi Strada Athlete", "Isuzu D-Max LS-E"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "continental-viking-contact-7", "Continental", "Viking Contact 7",
    "Nordic Winter & Ice", "Winter",
    225, 50, 17, 98, "T", 2023,
    174.99, None, 4.7, 198, 15,
    "A", "C", 69, 35000,
    "Advanced rapeseed oil compound stays flexible in extreme sub-zero conditions. Diamond grip edges bite securely into packed snow and black ice.",
    ["Volvo V60", "Audi A4 Allroad", "BMW 3 Series xDrive", "Subaru Forester", "Mercedes-Benz C-Class 4MATIC", "Tesla Model 3"],
    "assets/images/tires/continental_vikingcontact_7.webp"
))

TIRES.append(make_tire(
    "continental-premium-contact-7", "Continental", "Premium Contact 7",
    "Premium Touring Comfort", "Summer",
    225, 50, 17, 98, "Y", 2024,
    184.00, 209.00, 4.9, 320, 35,
    "A", "B", 69, 45000,
    "RedChili compound requires zero warm-up time to achieve optimal grip. Outstanding safety and stopping performance in tropical rain.",
    ["BMW 3 Series", "Mercedes-Benz E-Class", "Audi A6", "Lexus ES300h", "Volvo S60", "Volkswagen Arteon"],
    "assets/images/tires/continental_sportcontact_7.webp"
))

TIRES.append(make_tire(
    "continental-comfort-contact-cc7", "Continental", "Comfort Contact CC7",
    "Ultra Quiet Passenger Touring", "All-Season",
    185, 65, 15, 88, "H", 2024,
    79.99, 92.00, 4.8, 480, 55,
    "B", "A", 66, 55000,
    "Engineered with Comfort+ Technology and Zero Doubt Noise Muffling. The smoothest, quietest tire for compact urban runabouts.",
    ["Toyota Vios", "Honda City", "Suzuki Swift", "Mitsubishi Mirage", "Nissan Almera", "Toyota Wigo"],
    "assets/images/tires/continental_ultracontact_uc7.webp"
))

TIRES.append(make_tire(
    "continental-comfort-contact-cc7-14", "Continental", "Comfort Contact CC7",
    "Ultra Quiet Passenger Touring", "All-Season",
    175, 65, 14, 82, "T", 2024,
    64.99, 75.00, 4.7, 360, 60,
    "B", "A", 66, 55000,
    "Ultra-low noise level tire for small city hatchbacks. Eliminates harsh suspension vibration over concrete road expansion joints.",
    ["Toyota Wigo", "Suzuki Celerio", "Mitsubishi Mirage", "Honda Brio", "Hyundai i10"],
    "assets/images/tires/continental_ultracontact_uc7.webp"
))

TIRES.append(make_tire(
    "continental-cross-contact-ax6", "Continental", "Cross Contact AX6",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 60, 18, 110, "T", 2024,
    228.00, 259.00, 4.8, 215, 22,
    "B", "C", 70, 50000,
    "Double-shield stone ejectors prevent carcass punctures while curved tread blocks optimize highway acoustics.",
    ["Toyota Fortuner", "Ford Everest", "Mitsubishi Montero Sport", "Nissan Terra", "Toyota Hilux", "Ford Ranger"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "continental-van-contact-ultra", "Continental", "Van Contact Ultra",
    "Commercial Van & Utility", "Summer Commercial",
    215, 70, 16, 108, "T", 2024,
    135.00, 155.00, 4.7, 190, 30,
    "A", "B", 71, 60000,
    "Solid scuff ribs along sidewall prevent stone drilling. Built to handle heavy commercial cargo without overheating.",
    ["Toyota HiAce Commuter", "Nissan NV350 Urvan", "Ford Transit", "Hyundai Staria", "Mercedes-Benz Sprinter"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "continental-extreme-contact-force", "Continental", "Extreme Contact Force",
    "Street-Legal Track & Competition", "Summer Track",
    245, 40, 18, 97, "W", 2024,
    275.00, 315.00, 4.9, 130, 12,
    "B", "E", 74, 15000,
    "200-treadwear endurance race tire engineered for track day enthusiasts wanting long stint consistency and heat resistance.",
    ["Toyota GR86", "Subaru BRZ", "Mazda MX-5 Miata", "Honda S2000", "BMW M2", "Ford Mustang"],
    "assets/images/tires/continental_extremecontact_sport_02.webp"
))


# =============================================================================
# 3. BRIDGESTONE (16 Tires)
# =============================================================================
TIRES.append(make_tire(
    "bridgestone-potenza-sport", "Bridgestone", "Potenza Sport",
    "Ultra High Performance Summer", "Summer",
    235, 35, 19, 91, "(Y)", 2024,
    245.99, 279.99, 4.9, 348, 25,
    "A", "D", 72, 25000,
    "Master the wet and own the curves. Innovative 3D sipes improve pattern stiffness for lightning-fast lane changes.",
    ["BMW M240i", "Audi S3", "Volkswagen Golf R", "Mercedes-AMG A35", "Honda Civic Type R", "Subaru WRX STI"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "bridgestone-potenza-sport-18", "Bridgestone", "Potenza Sport",
    "Ultra High Performance Summer", "Summer",
    225, 40, 18, 92, "Y", 2024,
    209.00, 239.00, 4.8, 290, 30,
    "A", "D", 71, 25000,
    "High-tensile steel belts keep the contact patch flat across aggressive high-speed directional changes.",
    ["Volkswagen Golf GTI", "Honda Civic", "Toyota Corolla GR", "Subaru WRX", "Hyundai i30 N", "Mini Cooper JCW"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "bridgestone-potenza-re-71rs", "Bridgestone", "Potenza RE-71RS",
    "Street-Legal Track & Competition", "Summer Track",
    255, 40, 18, 99, "W", 2024,
    289.99, 329.99, 4.9, 185, 10,
    "B", "E", 75, 15000,
    "King of the autocross circuit. Asymmetric tread profile creates maximum contact footprint under extreme lateral cornering loads.",
    ["Toyota GR Yaris", "Honda Civic Type R", "Porsche Cayman", "BMW M3", "Subaru BRZ", "Mazda MX-5 Miata"],
    "assets/images/tires/continental_extremecontact_sport_02.webp"
))

TIRES.append(make_tire(
    "bridgestone-potenza-re-71rs-19", "Bridgestone", "Potenza RE-71RS",
    "Street-Legal Track & Competition", "Summer Track",
    275, 35, 19, 100, "W", 2024,
    335.00, 380.00, 5.0, 120, 8,
    "B", "E", 75, 15000,
    "Wide-section track weapon engineered for brutal braking zone stability and instant trail-braking rotation.",
    ["BMW M2 CS", "BMW M4 Competition", "Toyota GR Supra 3.0", "Porsche 911 Carrera S", "Chevrolet Corvette C8"],
    "assets/images/tires/continental_extremecontact_sport_02.webp"
))

TIRES.append(make_tire(
    "bridgestone-turanza-t005a", "Bridgestone", "Turanza T005A",
    "Premium Touring Comfort", "All-Season",
    215, 50, 17, 95, "V", 2024,
    149.99, 169.99, 4.7, 420, 38,
    "A", "B", 67, 50000,
    "Quiet luxury touring tire with high-angle sipes that soften road impact and eliminate high-frequency highway drone.",
    ["Toyota Camry", "Honda Accord", "Lexus ES350", "Nissan Altima", "Mazda 6", "Hyundai Sonata"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "bridgestone-turanza-t005a-16", "Bridgestone", "Turanza T005A",
    "Premium Touring Comfort", "All-Season",
    205, 55, 16, 91, "V", 2024,
    124.99, 142.00, 4.7, 360, 45,
    "A", "B", 67, 50000,
    "Exceptional smoothness for midsize family cruisers. Variable pitch shoulder blocks absorb road seams with zero vibration.",
    ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sylphy", "Hyundai Elantra", "Kia Forte"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "bridgestone-alenza-001", "Bridgestone", "Alenza 001",
    "Highway Terrain Luxury SUV", "Summer",
    235, 55, 19, 101, "V", 2024,
    225.00, 255.00, 4.8, 270, 28,
    "A", "C", 69, 45000,
    "Designed exclusively for premium SUVs. Enhances high-speed dynamic braking and suppresses uneven edge wear.",
    ["BMW X3", "Audi Q5", "Lexus RX350", "Toyota Harrier", "Mercedes-Benz GLC", "Volvo XC60"],
    "assets/images/tires/michelin_crossclimate_2_suv.webp"
))

TIRES.append(make_tire(
    "bridgestone-dueler-all-terrain-at002", "Bridgestone", "Dueler All-Terrain A/T002",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 65, 17, 112, "T", 2024,
    218.00, 249.00, 4.8, 310, 30,
    "A", "C", 71, 55000,
    "Aggressive shoulder blocks grip deep mud and gravel trails while advanced compound delivers class-A wet grip.",
    ["Toyota Hilux", "Toyota Fortuner", "Ford Ranger", "Mitsubishi Montero Sport", "Nissan Navara", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "bridgestone-dueler-all-terrain-at002-18", "Bridgestone", "Dueler All-Terrain A/T002",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 60, 18, 110, "T", 2024,
    242.00, 275.00, 4.8, 260, 24,
    "A", "C", 71, 55000,
    "Modern 18-inch all-terrain tire with reinforced bead structure designed to resist unseating when aired down off-road.",
    ["Toyota Fortuner GR-S", "Ford Everest Titanium+", "Mitsubishi Montero Sport GT", "Nissan Terra VL", "Toyota Hilux Conquest"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "bridgestone-ecopia-ep300", "Bridgestone", "Ecopia EP300",
    "High Mileage Eco Touring", "All-Season",
    185, 60, 15, 84, "H", 2024,
    84.99, 99.00, 4.6, 490, 60,
    "B", "A", 68, 65000,
    "NanoPro-Tech silica polymers lower rolling resistance, saving fuel every trip. Deep tread depth ensures long mileage.",
    ["Toyota Vios", "Honda City", "Mitsubishi Mirage", "Suzuki Dzire", "Nissan Almera", "Toyota Yaris"],
    "assets/images/tires/michelin_primacy4.webp"
))

TIRES.append(make_tire(
    "bridgestone-potenza-adrenalin-re004", "Bridgestone", "Potenza Adrenalin RE004",
    "Street Performance Sport", "Summer",
    205, 45, 17, 88, "W", 2024,
    138.00, 158.00, 4.8, 415, 35,
    "A", "C", 71, 35000,
    "Connecting block design stabilizes tread ribs for agile steering turn-in and high-speed highway stability.",
    ["Honda Civic", "Toyota Corolla Altis", "Mazda 3", "Suzuki Swift Sport", "Hyundai Veloster", "Kia Forte GT"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "bridgestone-potenza-adrenalin-re004-18", "Bridgestone", "Potenza Adrenalin RE004",
    "Street Performance Sport", "Summer",
    225, 45, 18, 95, "W", 2024,
    168.00, 192.00, 4.8, 320, 30,
    "A", "C", 71, 35000,
    "Enthusiast street tire with wide triple center ribs that keep the car pinned securely in high-speed sweeping corners.",
    ["Subaru WRX", "Honda Civic RS", "Toyota Corolla GR-S", "Mazda 3 Turbo", "Volkswagen Jetta GLI"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "bridgestone-dueler-ht-684ii", "Bridgestone", "Dueler H/T 684II",
    "Highway Terrain Luxury SUV", "All-Season",
    265, 60, 18, 110, "H", 2024,
    195.00, 225.00, 4.7, 350, 32,
    "B", "C", 70, 60000,
    "Original equipment standard on Toyota Fortuner and Prado. Spiral wrap nylon overlay maintains smooth high-speed balance.",
    ["Toyota Fortuner", "Toyota Prado", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Isuzu mu-X"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "bridgestone-turanza-6", "Bridgestone", "Turanza 6",
    "Premium Touring Comfort", "Summer",
    225, 45, 17, 94, "Y", 2024,
    175.00, 199.00, 4.8, 280, 26,
    "A", "A", 68, 50000,
    "ENLITEN technology cuts tire weight while improving EV range and delivering class-leading EU label grade A wet grip.",
    ["Volkswagen Golf", "Audi A3", "BMW 1 Series", "Mercedes-Benz A-Class", "Toyota Prius", "Nissan Leaf"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "bridgestone-dueler-mt-674", "Bridgestone", "Dueler M/T 674",
    "Mud Terrain Maximum Traction", "Mud-Terrain",
    265, 75, 16, 119, "Q", 2024,
    255.00, 289.00, 4.8, 160, 14,
    "C", "F", 76, 30000,
    "3D groove technology self-cleans thick clay and mud. Extra heavy-duty 3-ply sidewalls endure punishment from boulders and tree roots.",
    ["Toyota Land Cruiser 70", "Toyota Hilux", "Jeep Wrangler", "Ford Ranger Raptor", "Nissan Patrol Safari", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "bridgestone-alenza-sport-as", "Bridgestone", "Alenza Sport A/S",
    "High Performance Luxury SUV", "All-Season",
    255, 50, 20, 109, "V", 2024,
    265.00, 299.00, 4.8, 180, 20,
    "A", "C", 69, 55000,
    "Premium grand touring all-season tire tuned for quiet high-speed expressway travel in luxury German and Japanese SUVs.",
    ["Lexus RX350", "BMW X5", "Mercedes-Benz GLE", "Audi Q7", "Acura MDX", "Infiniti QX60"],
    "assets/images/tires/michelin_crossclimate_2_suv.webp"
))


# =============================================================================
# 4. PIRELLI (14 Tires)
# =============================================================================
TIRES.append(make_tire(
    "pirelli-p-zero-pz4", "Pirelli", "P Zero PZ4",
    "Max Performance Summer", "Summer",
    245, 35, 20, 95, "(Y)", 2024,
    299.99, 349.99, 4.9, 390, 18,
    "A", "C", 72, 20000,
    "Born on Formula 1 circuits. Customized outer tread pattern enhances steering response and rapid lateral acceleration.",
    ["Porsche 911", "Audi R8", "Ferrari F8", "Mercedes-AMG GT", "BMW M5", "Lamborghini Huracan"],
    "assets/images/tires/pirelli_p_zero_pz4.webp"
))

TIRES.append(make_tire(
    "pirelli-p-zero-pz4-19", "Pirelli", "P Zero PZ4",
    "Max Performance Summer", "Summer",
    235, 35, 19, 91, "Y", 2024,
    255.00, 289.00, 4.8, 295, 22,
    "A", "C", 71, 20000,
    "Superb dry handling precision and short wet braking distance developed in partnership with top prestige car manufacturers.",
    ["Volkswagen Golf R", "Audi S3", "Mercedes-AMG A45", "BMW M2", "Toyota GR Supra"],
    "assets/images/tires/pirelli_p_zero_pz4.webp"
))

TIRES.append(make_tire(
    "pirelli-cinturato-p7-c2", "Pirelli", "Cinturato P7 C2",
    "Premium Grand Touring", "Summer",
    225, 50, 17, 98, "Y", 2024,
    168.00, 195.00, 4.7, 310, 34,
    "A", "B", 69, 45000,
    "Green Performance philosophy combines safety in wet conditions, long mileage, and decreased fuel consumption.",
    ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Alfa Romeo Giulia", "Lexus IS300", "Volvo S60"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "pirelli-cinturato-p7-c2-18", "Pirelli", "Cinturato P7 C2",
    "Premium Grand Touring", "Summer",
    225, 45, 18, 95, "Y", 2024,
    188.00, 215.00, 4.8, 260, 30,
    "A", "B", 69, 45000,
    "18-inch executive touring fitment delivering quiet cabin ambiance with low rolling resistance.",
    ["Mercedes-Benz C-Class", "BMW 3 Series", "Audi A4", "Toyota Camry", "Lexus ES300h"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "pirelli-scorpion-verde-all-season", "Pirelli", "Scorpion Verde All Season",
    "Highway Terrain Luxury SUV", "All-Season",
    235, 60, 18, 107, "V", 2024,
    205.00, 235.00, 4.7, 285, 25,
    "B", "B", 71, 50000,
    "Optimized profile and innovative materials ensure lower fuel consumption and whisper-quiet operation in premium crossover SUVs.",
    ["Audi Q5", "Porsche Macan", "Volvo XC60", "BMW X3", "Land Rover Discovery Sport", "Mercedes-Benz GLC"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "pirelli-scorpion-all-terrain-plus", "Pirelli", "Scorpion All Terrain Plus",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 65, 17, 112, "T", 2024,
    229.00, 260.00, 4.8, 240, 20,
    "B", "D", 72, 50000,
    "Conical stone ejectors prevent punctures while high-density sipes offer confidence across mud, loose gravel, and tarmac.",
    ["Ford Ranger", "Toyota Hilux", "Jeep Gladiator", "Nissan Navara", "Mitsubishi Strada", "Toyota Fortuner"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "pirelli-p-zero-elect", "Pirelli", "P Zero Elect",
    "Electric Vehicle Dedicated", "Summer EV",
    245, 45, 19, 102, "Y", 2024,
    275.00, 315.00, 4.8, 160, 16,
    "A", "A", 67, 35000,
    "Specifically engineered for high-performance electric vehicles. Reinforced belt package controls battery weight and eliminates EV hum.",
    ["Porsche Taycan", "Tesla Model S", "BMW i4 M50", "Audi e-tron GT", "Mercedes-Benz EQE", "Lucid Air"],
    "assets/images/tires/michelin_e_primacy.webp"
))

TIRES.append(make_tire(
    "pirelli-p-zero-corsa", "Pirelli", "P Zero Corsa",
    "Street-Legal Track & Competition", "Summer Track",
    285, 30, 20, 99, "(Y)", 2024,
    395.00, 445.00, 4.9, 125, 8,
    "B", "E", 74, 12000,
    "Track day supercar weapon developed with Ferrari and McLaren. Custom dual-compound tread delivers brutal lateral Gs.",
    ["McLaren 720S", "Ferrari 296 GTB", "Lamborghini Huracan STO", "Porsche 911 GT3 RS", "Aston Martin Vantage"],
    "assets/images/tires/pirelli_p_zero_pz4.webp"
))

TIRES.append(make_tire(
    "pirelli-cinturato-all-season-sf2", "Pirelli", "Cinturato All Season SF2",
    "All-Weather Grand Touring", "All-Weather",
    205, 55, 16, 94, "V", 2024,
    142.00, 165.00, 4.7, 210, 30,
    "B", "B", 69, 50000,
    "3D interlocking sipes adapt to dry pavement for crisp handling and open up to channel torrential rain safely.",
    ["Toyota Corolla", "Honda Civic", "Volkswagen Golf", "Audi A3", "Mazda 3", "Hyundai i30"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "pirelli-carrier", "Pirelli", "Carrier",
    "Commercial Van & Utility", "Summer Commercial",
    195, 70, 15, 104, "R", 2024,
    115.00, 130.00, 4.7, 240, 40,
    "A", "C", 71, 55000,
    "Heavy load carrying capacity with 30% extended mileage over predecessor. Excellent aquaplaning resistance for commercial vans.",
    ["Toyota HiAce", "Nissan Urvan", "Ford Transit Custom", "Hyundai Staria Cargo", "Renault Master"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "pirelli-scorpion-ms", "Pirelli", "Scorpion MS",
    "Highway Terrain Luxury SUV", "All-Season",
    255, 55, 19, 111, "V", 2024,
    240.00, 275.00, 4.8, 175, 22,
    "A", "B", 68, 50000,
    "Latest evolution in Pirelli SUV technology. Exceptional acoustic comfort and low rolling resistance for luxury crossovers.",
    ["Mercedes-Benz GLE", "BMW X5", "Volvo XC90", "Audi Q7", "Lexus RX350", "Genesis GV80"],
    "assets/images/tires/michelin_crossclimate_2_suv.webp"
))

TIRES.append(make_tire(
    "pirelli-p-zero-nero-gt", "Pirelli", "P Zero Nero GT",
    "Max Performance Summer", "Summer",
    215, 45, 17, 91, "Y", 2024,
    135.00, 155.00, 4.7, 340, 32,
    "B", "C", 71, 30000,
    "Wide continuous ribs improve tread rigidity, offering immediate cornering reaction for sport compacts.",
    ["Honda Civic", "Toyota Corolla Altis", "Mazda 3", "Subaru BRZ", "Mini Cooper S"],
    "assets/images/tires/pirelli_p_zero_pz4.webp"
))

TIRES.append(make_tire(
    "pirelli-scorpion-zero-all-season", "Pirelli", "Scorpion Zero All Season",
    "High Performance Luxury SUV", "All-Season",
    275, 45, 20, 110, "W", 2024,
    310.00, 350.00, 4.8, 190, 16,
    "A", "B", 71, 45000,
    "Asymmetric tread with curved sipes delivers all-season grip for high-horsepower luxury performance SUVs.",
    ["Land Rover Defender", "BMW X5 M", "Porsche Cayenne", "Audi Q8", "Mercedes-Benz GLE 53 AMG"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "pirelli-cinturato-p1-verde", "Pirelli", "Cinturato P1 Verde",
    "High Mileage Eco Touring", "All-Season",
    185, 65, 15, 88, "H", 2024,
    79.99, 92.00, 4.6, 380, 45,
    "B", "A", 68, 60000,
    "Urban mobility tire with optimized tread profile that reduces aerodynamic drag and fuel consumption.",
    ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift"],
    "assets/images/tires/michelin_primacy4.webp"
))


# =============================================================================
# 5. GOODYEAR (12 Tires)
# =============================================================================
TIRES.append(make_tire(
    "goodyear-eagle-f1-asymmetric-6", "Goodyear", "Eagle F1 Asymmetric 6",
    "Ultra High Performance Summer", "Summer",
    225, 40, 18, 92, "Y", 2024,
    194.99, 224.99, 4.8, 315, 25,
    "A", "C", 70, 35000,
    "Dry Contact Plus technology and wet resin compound adapt to road surface irregularities for superior braking.",
    ["Volkswagen Golf R", "BMW 1 Series", "Audi S3", "Mercedes-Benz A250", "Toyota GR Yaris", "Mini Cooper S"],
    "assets/images/tires/goodyear_eagle_f1_asymmetric_6.webp"
))

TIRES.append(make_tire(
    "goodyear-eagle-f1-asymmetric-6-19", "Goodyear", "Eagle F1 Asymmetric 6",
    "Ultra High Performance Summer", "Summer",
    235, 35, 19, 91, "Y", 2024,
    229.00, 259.00, 4.8, 240, 22,
    "A", "C", 70, 35000,
    "Prestige 19-inch sports fitment with quiet-running pattern bars that eliminate unwanted cabin drone.",
    ["BMW 3 Series", "Audi S4", "Mercedes-Benz C300", "Lexus IS350", "Toyota GR Supra"],
    "assets/images/tires/goodyear_eagle_f1_asymmetric_6.webp"
))

TIRES.append(make_tire(
    "goodyear-eagle-f1-supersport", "Goodyear", "Eagle F1 SuperSport",
    "Max Performance Summer", "Summer",
    265, 35, 19, 98, "(Y)", 2024,
    279.00, 315.00, 4.9, 210, 16,
    "A", "D", 73, 25000,
    "Massive closed outboard shoulder blocks resist heavy track day lateral forces for surgical turn-in precision.",
    ["Porsche 911", "BMW M4", "Audi RS4", "Mercedes-AMG C63", "Toyota GR Supra", "Ford Mustang Dark Horse"],
    "assets/images/tires/goodyear_eagle_f1.png"
))

TIRES.append(make_tire(
    "goodyear-assurance-comforttred", "Goodyear", "Assurance ComfortTred",
    "Premium Touring Comfort", "All-Season",
    215, 55, 17, 94, "V", 2024,
    145.00, 165.00, 4.8, 390, 45,
    "A", "B", 67, 55000,
    "ANX Technology integrates an internal sound dampening layer that absorbs tire cavity vibrations by up to 2.5 dB.",
    ["Toyota Camry", "Honda Accord", "Nissan Altima", "Mazda 6", "Subaru Legacy", "Toyota Corolla Altis"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "goodyear-assurance-comforttred-16", "Goodyear", "Assurance ComfortTred",
    "Premium Touring Comfort", "All-Season",
    205, 55, 16, 91, "V", 2024,
    119.00, 135.00, 4.7, 320, 50,
    "A", "B", 67, 55000,
    "Extra cushioned cap ply absorbs sharp road jolts from potholes and rough concrete highway sections.",
    ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sentra", "Hyundai Elantra"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "goodyear-wrangler-duratrac", "Goodyear", "Wrangler DuraTrac",
    "Rugged All-Terrain & 4x4", "All-Terrain",
    265, 70, 17, 115, "S", 2024,
    245.00, 280.00, 4.8, 420, 24,
    "B", "E", 74, 50000,
    "TractiveGroove Technology offers enhanced traction in deep mud. Self-cleaning shoulder blocks push gravel away.",
    ["Ford Ranger Raptor", "Toyota Hilux Conquest", "Jeep Wrangler", "Nissan Navara Pro-4X", "Isuzu D-Max V-Cross", "Toyota Fortuner GR-S"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "goodyear-assurance-maxguard", "Goodyear", "Assurance MaxGuard",
    "Passenger Safety Touring", "All-Season",
    185, 65, 15, 88, "H", 2024,
    82.00, 95.00, 4.7, 510, 50,
    "A", "B", 68, 60000,
    "ActiveGrip Technology provides 2x more biting edges for instant panic stop braking on slick tropical city roads.",
    ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Ciaz", "Hyundai Accent"],
    "assets/images/tires/michelin_primacy4.webp"
))

TIRES.append(make_tire(
    "goodyear-efficientgrip-2-suv", "Goodyear", "EfficientGrip 2 SUV",
    "Highway Terrain Luxury SUV", "Summer",
    225, 65, 17, 102, "H", 2024,
    172.00, 195.00, 4.8, 280, 35,
    "A", "B", 69, 55000,
    "Mileage Plus Technology provides 25% higher mileage than predecessor. Highly flexible tread compound resists cracking.",
    ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Subaru Forester", "Hyundai Tucson"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "goodyear-wrangler-at-silenttrac", "Goodyear", "Wrangler AT SilentTrac",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 60, 18, 110, "T", 2024,
    215.00, 245.00, 4.8, 310, 26,
    "B", "C", 70, 55000,
    "DuraWall Technology features reinforced thick rubber layer on sidewalls for cut resistance while minimizing cabin road noise.",
    ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Isuzu mu-X", "Toyota Hilux"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "goodyear-vector-4seasons-gen-3", "Goodyear", "Vector 4Seasons Gen-3",
    "All-Weather Grand Touring", "All-Weather",
    205, 55, 16, 94, "V", 2024,
    135.00, 155.00, 4.7, 290, 32,
    "B", "B", 70, 50000,
    "AquaControl Technology uses deep directional grooves to disperse rain rapidly throughout the entire lifespan of the tire.",
    ["Toyota Corolla", "Honda Civic", "Volkswagen Golf", "Ford Focus", "Mazda 3", "Audi A3"],
    "assets/images/tires/goodyear_eagle_f1_asymmetric_6.webp"
))

TIRES.append(make_tire(
    "goodyear-cargo-marathon-2", "Goodyear", "Cargo Marathon 2",
    "Commercial Van & Utility", "Summer Commercial",
    195, 80, 15, 106, "R", 2024,
    112.00, 128.00, 4.6, 310, 42,
    "B", "C", 71, 55000,
    "Reinforced carcass construction withstands overloading and rough provincial roads, minimizing fleet maintenance downtime.",
    ["Toyota HiAce", "Nissan Urvan", "Mitsubishi L300", "Hyundai H100", "Kia K2500", "Isuzu Traviz"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "goodyear-eagle-f1-asymmetric-5-suv", "Goodyear", "Eagle F1 Asymmetric 5 SUV",
    "High Performance Luxury SUV", "Summer",
    255, 50, 20, 109, "Y", 2024,
    270.00, 310.00, 4.8, 185, 18,
    "A", "C", 71, 35000,
    "Impulse Control Compound achieves short braking distances on wet and dry roads while handling high SUV ride heights.",
    ["Porsche Macan", "BMW X5", "Audi Q7", "Mercedes-Benz GLE", "Range Rover Velar", "Volvo XC90"],
    "assets/images/tires/goodyear_eagle_f1_asymmetric_6.webp"
))


# =============================================================================
# 6. YOKOHAMA (12 Tires)
# =============================================================================
TIRES.append(make_tire(
    "yokohama-advan-sport-v107", "Yokohama", "Advan Sport V107",
    "Ultra High Performance Summer", "Summer",
    245, 40, 19, 98, "(Y)", 2024,
    240.00, 275.00, 4.9, 295, 22,
    "A", "C", 71, 30000,
    "Co-developed with BMW M and Mercedes-AMG. Ultra-micro silica compound delivers phenomenal dry cornering grip.",
    ["BMW M3", "BMW M4", "Mercedes-AMG C43", "Audi S4", "Toyota GR Supra", "Lexus IS350"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "yokohama-advan-neova-ad09", "Yokohama", "Advan Neova AD09",
    "Street-Legal Track & Competition", "Summer Track",
    235, 40, 18, 95, "W", 2024,
    265.00, 299.00, 4.9, 210, 14,
    "A", "E", 74, 15000,
    "The legend of street tuner tires continues. Features an ultra-stiff casing structure and track-ready heat management.",
    ["Honda Civic Type R", "Toyota GR Yaris", "Subaru WRX STI", "Mitsubishi Lancer Evolution", "Mazda RX-7", "Nissan Silvia S15"],
    "assets/images/tires/continental_extremecontact_sport_02.webp"
))

TIRES.append(make_tire(
    "yokohama-advan-neova-ad09-17", "Yokohama", "Advan Neova AD09",
    "Street-Legal Track & Competition", "Summer Track",
    215, 45, 17, 91, "W", 2024,
    225.00, 255.00, 4.9, 180, 16,
    "A", "E", 73, 15000,
    "Track day weapon for lightweight sports cars. Eliminates sidewall squirm under heavy braking and cornering.",
    ["Toyota GR86", "Subaru BRZ", "Mazda MX-5 Miata", "Honda S2000", "Lotus Elise"],
    "assets/images/tires/continental_extremecontact_sport_02.webp"
))

TIRES.append(make_tire(
    "yokohama-geolandar-at-g015", "Yokohama", "Geolandar A/T G015",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 65, 17, 112, "H", 2024,
    208.00, 238.00, 4.8, 380, 30,
    "B", "C", 71, 60000,
    "Triple 3D sipes change shape as the tread wears to maintain biting edges throughout tire life. EdgeTec grooves grip gravel.",
    ["Toyota Fortuner", "Toyota Hilux", "Ford Ranger", "Mitsubishi Montero Sport", "Nissan Navara", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "yokohama-geolandar-at-g015-18", "Yokohama", "Geolandar A/T G015",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 60, 18, 110, "H", 2024,
    235.00, 268.00, 4.8, 290, 25,
    "B", "C", 71, 60000,
    "Premium 18-inch all-terrain tire with reinforced bead protection for adventurous lifestyle pick-ups and SUVs.",
    ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Nissan Navara Pro-4X", "Toyota Fortuner", "Mitsubishi Strada"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "yokohama-bluearth-gt-ae51", "Yokohama", "BluEarth-GT AE51",
    "Grand Touring Comfort", "All-Season",
    215, 55, 17, 94, "V", 2024,
    142.00, 162.00, 4.7, 340, 36,
    "A", "B", 68, 50000,
    "Asymmetrical pattern with lightning sipes ensures rapid water dispersion and effortless high-speed straight-line stability.",
    ["Toyota Camry", "Honda Accord", "Mazda 6", "Nissan Altima", "Subaru Legacy", "Toyota Corolla Altis"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "yokohama-geolandar-mt-g003", "Yokohama", "Geolandar M/T G003",
    "Mud Terrain Maximum Traction", "Mud-Terrain",
    285, 70, 17, 121, "Q", 2024,
    275.00, 310.00, 4.9, 170, 12,
    "C", "F", 76, 35000,
    "GEO-SHIELD armor construction withstands severe rock impacts. Crushed stone ejectors protect against puncture damage.",
    ["Jeep Wrangler", "Toyota Land Cruiser", "Ford Ranger Raptor", "Nissan Patrol", "Toyota Hilux", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "yokohama-bluearth-es-es32", "Yokohama", "BluEarth-Es ES32",
    "High Mileage Eco Touring", "All-Season",
    185, 65, 14, 86, "H", 2024,
    68.00, 79.00, 4.6, 450, 50,
    "B", "A", 68, 60000,
    "Orange Oil technology enhances rubber flexibility, ensuring a wide contact patch on hot city tarmac while lowering fuel burn.",
    ["Toyota Wigo", "Mitsubishi Mirage", "Suzuki Celerio", "Honda Brio", "Hyundai Grand i10", "Kia Picanto"],
    "assets/images/tires/michelin_primacy4.webp"
))

TIRES.append(make_tire(
    "yokohama-geolandar-cv-g058", "Yokohama", "Geolandar CV G058",
    "Highway Terrain Luxury SUV", "All-Season",
    225, 60, 18, 100, "H", 2024,
    178.00, 205.00, 4.8, 260, 32,
    "B", "B", 69, 65000,
    "Specially formulated for modern midsize urban crossovers. Si-micro silica compound resists wear across long highway trips.",
    ["Subaru Forester", "Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Hyundai Tucson"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "yokohama-advan-fleva-v701", "Yokohama", "Advan Fleva V701",
    "Street Performance Sport", "Summer",
    205, 45, 17, 88, "W", 2024,
    128.00, 148.00, 4.7, 395, 38,
    "A", "C", 69, 40000,
    "Emotional sporty handling with drop-groove design that repels surface standing water during heavy monsoon rainfall.",
    ["Honda Civic", "Toyota Vios GR-S", "Mazda 2", "Suzuki Swift Sport", "Ford Fiesta ST", "Mini Cooper"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "yokohama-geolandar-x-at-g016", "Yokohama", "Geolandar X-AT G016",
    "Rugged All-Terrain & 4x4", "All-Terrain",
    275, 65, 18, 116, "Q", 2024,
    258.00, 295.00, 4.9, 185, 20,
    "B", "D", 73, 45000,
    "Bridging the gap between All-Terrain and Mud-Terrain. Dual sidewall design lets owners choose aggressive tread aesthetics.",
    ["Ford Ranger Raptor", "Toyota Land Cruiser 300", "Nissan Patrol Nismo", "Toyota Hilux", "Mitsubishi Montero Sport"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "yokohama-advan-apex-v601", "Yokohama", "Advan Apex V601",
    "Ultra High Performance Summer", "Summer",
    255, 35, 19, 96, "Y", 2024,
    235.00, 269.00, 4.8, 230, 24,
    "A", "C", 71, 25000,
    "High-grade micro-silica compound delivers confident dry road feedback and immediate high-speed steering precision.",
    ["BMW M340i", "Mercedes-AMG C43", "Audi S5", "Genesis G70", "Lexus IS350", "Ford Mustang GT"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))


# =============================================================================
# 7. DUNLOP & TOYO (12 Tires)
# =============================================================================
TIRES.append(make_tire(
    "dunlop-direzza-ziii", "Dunlop", "Direzza ZIII",
    "Street-Legal Track & Competition", "Summer Track",
    205, 50, 16, 87, "V", 2024,
    165.00, 188.00, 4.8, 270, 18,
    "B", "E", 73, 20000,
    "High-rigidity shoulder blocks and carbon-infused polymers offer instantaneous steering response and track endurance.",
    ["Mazda MX-5 Miata", "Toyota GR86", "Honda Civic Si", "Suzuki Swift Sport", "Toyota Corolla AE86", "Mini Cooper S"],
    "assets/images/tires/continental_extremecontact_sport_02.webp"
))

TIRES.append(make_tire(
    "dunlop-sp-sport-maxx-060-plus", "Dunlop", "SP Sport Maxx 060+",
    "Ultra High Performance Summer", "Summer",
    245, 45, 18, 100, "Y", 2024,
    195.00, 225.00, 4.8, 220, 25,
    "A", "C", 70, 35000,
    "Asymmetric tread design optimizes contact pressure during high-speed cornering on luxury performance sedans and coupes.",
    ["Lexus IS300", "BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Subaru WRX", "Infiniti Q50"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "dunlop-grandtrek-at5", "Dunlop", "Grandtrek AT5",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 65, 17, 112, "S", 2024,
    185.00, 210.00, 4.7, 390, 35,
    "B", "C", 71, 50000,
    "Block ejection stone technology and cut-resistant compound for pick-ups and SUVs tackling mixed on- and off-road driving.",
    ["Toyota Hilux", "Toyota Fortuner", "Mitsubishi Montero Sport", "Nissan Navara", "Ford Ranger", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "dunlop-enasave-ec300-plus", "Dunlop", "Enasave EC300+",
    "High Mileage Eco Touring", "All-Season",
    185, 65, 15, 88, "H", 2024,
    75.00, 88.00, 4.6, 480, 55,
    "B", "A", 68, 60000,
    "Low rolling resistance compound cuts greenhouse emissions and maximizes mileage. Standard factory fitment on Japanese compacts.",
    ["Toyota Vios", "Honda City", "Mitsubishi Mirage", "Nissan Almera", "Toyota Avanza", "Suzuki Ertiga"],
    "assets/images/tires/michelin_primacy4.webp"
))

TIRES.append(make_tire(
    "dunlop-veuro-ve304", "Dunlop", "Veuro VE304",
    "Premium Touring Comfort", "All-Season",
    225, 55, 17, 97, "W", 2024,
    165.00, 190.00, 4.8, 210, 28,
    "A", "B", 66, 50000,
    "Silent Core acoustic foam sponge inside tire absorbs resonance, delivering library-level quietness inside executive vehicles.",
    ["Toyota Camry", "Honda Accord", "Lexus ES300h", "Mazda 6", "Nissan Teana", "Toyota Alphard"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "dunlop-grandtrek-pt3", "Dunlop", "Grandtrek PT3",
    "Highway Terrain Luxury SUV", "All-Season",
    235, 60, 18, 100, "V", 2024,
    170.00, 198.00, 4.7, 290, 30,
    "A", "B", 69, 55000,
    "Silica modified compound and equalized footprint pressure prevent shoulder wear on heavy urban crossovers.",
    ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Subaru Forester", "Hyundai Tucson"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "toyo-proxes-sport-2", "Toyo Tires", "Proxes Sport 2",
    "Ultra High Performance Summer", "Summer",
    245, 40, 19, 98, "Y", 2024,
    210.00, 240.00, 4.8, 260, 24,
    "A", "C", 71, 30000,
    "Dynamic Taper design stabilizes ribs during high lateral cornering Gs, keeping handling predictable and playful.",
    ["Toyota GR Supra", "BMW 3 Series", "Audi A5", "Mercedes-Benz C-Class", "Lexus IS350", "Nissan Z"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "toyo-open-country-at3", "Toyo Tires", "Open Country A/T III",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 70, 17, 115, "T", 2024,
    225.00, 255.00, 4.9, 480, 30,
    "A", "D", 71, 65000,
    "3D multi-wave sipes resist irregular wear while aggressive staggered shoulder blocks climb loose mountain boulders with ease.",
    ["Ford Ranger", "Toyota Hilux", "Toyota Fortuner", "Nissan Navara", "Mitsubishi Montero Sport", "Jeep Wrangler"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "toyo-proxes-tr1", "Toyo Tires", "Proxes TR1",
    "Street Performance Sport", "Summer",
    195, 50, 16, 84, "V", 2024,
    105.00, 120.00, 4.7, 390, 35,
    "B", "C", 70, 35000,
    "Iconic asymmetric directional tread blends track-inspired style with exceptional water evacuation and responsive steering.",
    ["Mazda MX-5 Miata", "Toyota Vios", "Honda City", "Suzuki Swift Sport", "Ford Fiesta", "Toyota Yaris"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "toyo-open-country-rt", "Toyo Tires", "Open Country R/T",
    "Rugged All-Terrain & 4x4", "All-Terrain",
    285, 65, 18, 121, "Q", 2024,
    285.00, 325.00, 4.9, 240, 15,
    "B", "E", 73, 45000,
    "Rugged Terrain hybrid delivers mud-terrain off-road grip with all-terrain highway comfort and 45,000-mile treadwear warranty.",
    ["Ford Ranger Raptor", "Toyota Land Cruiser", "Nissan Patrol", "Jeep Gladiator", "Ford F-150", "Toyota Hilux GR-S"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "toyo-celsius-2", "Toyo Tires", "Celsius II",
    "All-Weather Grand Touring", "All-Weather",
    215, 60, 17, 96, "H", 2024,
    148.00, 170.00, 4.7, 180, 25,
    "B", "B", 69, 60000,
    "Variable sipe density provides confident year-round traction. Inside tread grips ice while outside pattern carves dry curves.",
    ["Toyota Corolla Cross", "Honda HR-V", "Subaru Crosstrek", "Mazda CX-30", "Hyundai Kona", "Nissan Kicks"],
    "assets/images/tires/michelin_crossclimate_2_suv.webp"
))

TIRES.append(make_tire(
    "toyo-open-country-mt", "Toyo Tires", "Open Country M/T",
    "Mud Terrain Maximum Traction", "Mud-Terrain",
    285, 75, 16, 122, "P", 2024,
    289.00, 330.00, 4.9, 350, 14,
    "C", "F", 76, 35000,
    "Legendary off-road champion tire. Hook-shaped tread blocks bite into slippery red clay, rocks, and mud.",
    ["Toyota Land Cruiser", "Jeep Wrangler Rubicon", "Ford Ranger Raptor", "Nissan Patrol Safari", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))


# =============================================================================
# 8. HANKOOK, KUMHO, FALKEN, BFGOODRICH (10 Tires)
# =============================================================================
TIRES.append(make_tire(
    "hankook-ventus-s1-evo3", "Hankook", "Ventus S1 evo3",
    "Ultra High Performance Summer", "Summer",
    235, 40, 19, 96, "Y", 2024,
    198.00, 225.00, 4.8, 320, 28,
    "A", "C", 70, 30000,
    "Interlocking outside groove design maximizes wet grip and prevents hydroplaning. Original equipment on Porsche Taycan.",
    ["Porsche Taycan", "BMW 3 Series", "Audi S4", "Mercedes-Benz C-Class", "Genesis G70", "Kia Stinger"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "hankook-ion-evo-electric", "Hankook", "iON evo Electric",
    "Electric Vehicle Dedicated", "Summer EV",
    255, 45, 19, 104, "Y", 2024,
    245.00, 280.00, 4.9, 190, 20,
    "A", "A", 66, 45000,
    "Formula E official technical partner tire. Sound Absorber foam cuts cabin noise by 18% while optimizing battery range.",
    ["Tesla Model Y", "Tesla Model 3", "Hyundai Ioniq 5", "Kia EV6", "BYD Seal", "BMW i4"],
    "assets/images/tires/michelin_e_primacy.webp"
))

TIRES.append(make_tire(
    "hankook-dynapro-at2-xtreme", "Hankook", "Dynapro AT2 Xtreme",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 70, 17, 115, "T", 2024,
    210.00, 239.00, 4.8, 340, 30,
    "B", "C", 71, 60000,
    "High-depth multidirectional sipes and tie-bars provide exceptional stability on gravel and smooth asphalt alike.",
    ["Ford Ranger", "Toyota Hilux", "Toyota Fortuner", "Nissan Navara", "Mitsubishi Montero Sport", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "kumho-ecsta-ps71", "Kumho", "Ecsta PS71",
    "Ultra High Performance Summer", "Summer",
    225, 45, 18, 95, "Y", 2024,
    148.00, 172.00, 4.7, 290, 32,
    "A", "C", 71, 30000,
    "High-dispersion micro-silica compound delivers confident dry stability and short braking distance in wet downpours.",
    ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Hyundai Sonata", "Kia K5", "Toyota Camry"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "kumho-crugen-hp71", "Kumho", "Crugen HP71",
    "Highway Terrain Luxury SUV", "All-Season",
    235, 60, 18, 103, "V", 2024,
    162.00, 188.00, 4.7, 310, 26,
    "B", "B", 68, 65000,
    "Variable pitch tread sequence breaks acoustic resonance, offering an exceptionally quiet cabin ride in modern crossovers.",
    ["Toyota RAV4", "Honda CR-V", "Hyundai Tucson", "Kia Sportage", "Mazda CX-5", "Nissan X-Trail"],
    "assets/images/tires/continental_crosscontact_lx25.webp"
))

TIRES.append(make_tire(
    "falken-azenis-fk520", "Falken", "Azenis FK520",
    "Ultra High Performance Summer", "Summer",
    235, 40, 19, 96, "Y", 2024,
    192.00, 220.00, 4.8, 275, 26,
    "A", "C", 70, 35000,
    "Aramid reinforcement derived from motorsport racing stiffens sidewalls, delivering laser-accurate steering turn-in response.",
    ["Audi S3", "BMW 3 Series", "Mercedes-Benz CLA", "Volkswagen Golf R", "Subaru WRX", "Hyundai i30 N"],
    "assets/images/tires/michelin_pilot_sport_5.webp"
))

TIRES.append(make_tire(
    "falken-wildpeak-at3w", "Falken", "Wildpeak A/T3W",
    "All-Terrain Off-Road & SUV", "All-Terrain",
    265, 70, 17, 115, "T", 2024,
    228.00, 258.00, 4.9, 520, 32,
    "A", "D", 72, 55000,
    "Heat Diffuser Technology in lower sidewall shields internal tire components. Outstanding off-road traction without highway howl.",
    ["Ford Ranger", "Toyota Hilux", "Toyota Fortuner", "Nissan Navara", "Mitsubishi Montero Sport", "Jeep Wrangler"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "falken-ziex-ze310-ecorun", "Falken", "Ziex ZE310 Ecorun",
    "Premium Touring Comfort", "Summer",
    205, 55, 16, 91, "V", 2024,
    105.00, 122.00, 4.7, 340, 38,
    "A", "B", 69, 50000,
    "Adaptive Constant Pressure tread profile improves contact pressure distribution, reducing braking distances on wet tarmac.",
    ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sentra", "Hyundai Elantra", "Kia Forte"],
    "assets/images/tires/michelin_primacy_4_plus.webp"
))

TIRES.append(make_tire(
    "bfgoodrich-all-terrain-ta-ko2", "BFGoodrich", "All-Terrain T/A KO2",
    "Rugged All-Terrain & 4x4", "All-Terrain",
    265, 70, 17, 116, "S", 2024,
    259.99, 299.99, 4.9, 780, 25,
    "B", "D", 73, 50000,
    "Tougher than rock. CoreGard Technology uses split and bruise-resistant sidewall rubber derived from Baja champion racing tires.",
    ["Toyota Hilux", "Ford Ranger Raptor", "Toyota Fortuner", "Jeep Wrangler", "Nissan Navara Pro-4X", "Isuzu D-Max"],
    "assets/images/tires/continental_terraincontact_at.webp"
))

TIRES.append(make_tire(
    "bfgoodrich-all-terrain-ta-ko3", "BFGoodrich", "All-Terrain T/A KO3",
    "Rugged All-Terrain & 4x4", "All-Terrain",
    275, 65, 18, 116, "T", 2024,
    289.00, 329.00, 4.9, 310, 18,
    "A", "C", 71, 50000,
    "Next generation legend. Upgraded tread compound delivers enhanced wet braking, longer gravel life, and legendary Baja toughness.",
    ["Ford Ranger Raptor", "Toyota Land Cruiser 300", "Jeep Gladiator", "Ford Everest Titanium+", "Toyota Hilux GR-S"],
    "assets/images/tires/continental_terraincontact_at.webp"
))


def main():
    print(f"Total curated tire models prepared: {len(TIRES)}")

    # Target path
    target_path = os.path.join(os.path.dirname(__file__), "..", "assets", "data", "tires.json")
    target_path = os.path.abspath(target_path)

    with open(target_path, "w", encoding="utf-8") as f:
        json.dump(TIRES, f, indent=2, ensure_ascii=False)

    print(f"Successfully saved {len(TIRES)} tires to {target_path}")

if __name__ == "__main__":
    main()
