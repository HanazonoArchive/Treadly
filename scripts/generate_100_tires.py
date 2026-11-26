"""Builds and validates assets/data/tires.json with verified per-model assets, specs, and retail prices."""

import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IMAGES_DIR = ROOT / "assets" / "images" / "tires"
TARGET_JSON = ROOT / "assets" / "data" / "tires.json"

# Every distinct (brand, model) maps 1-to-1 to its own verified product image on disk.
IMAGE_BY_MODEL = {
    ("Michelin", "Pilot Sport 5"): "michelin_pilot_sport_5.webp",
    ("Michelin", "Pilot Sport All-Season 4"): "michelin_pilot_sport_all_season_4.webp",
    ("Michelin", "e.Primacy"): "michelin_e_primacy.webp",
    ("Michelin", "Pilot Sport 4S"): "michelin_pilot_sport_4s.webp",
    ("Michelin", "Pilot Sport Cup 2"): "michelin_pilot_sport_cup_2.webp",
    ("Michelin", "Pilot Sport Cup 2 R"): "michelin_pilot_sport_cup_2_r.webp",
    ("Michelin", "Defender 2"): "michelin_defender_2.webp",
    ("Michelin", "CrossClimate 2"): "michelin_crossclimate_2.webp",
    ("Michelin", "Primacy 4+"): "michelin_primacy_4_plus.webp",
    ("Michelin", "Agilis 3"): "michelin_agilis_3.jpg",
    ("Michelin", "CrossClimate 2 SUV"): "michelin_crossclimate_2_suv.webp",
    ("Michelin", "LTX Trail"): "michelin_ltx_trail.png",
    ("Michelin", "Primacy Tour A/S"): "michelin_primacy_tour_a_s.webp",
    ("Michelin", "Primacy SUV+"): "michelin_primacy_suv_plus.webp",
    ("Michelin", "Energy XM2+"): "michelin_energy_xm2_plus.webp",
    ("Continental", "UltraContact UC7"): "continental_ultracontact_uc7.webp",
    ("Continental", "ExtremeContact DWS06 Plus"): "continental_extremecontact_dws06_plus.webp",
    ("Continental", "ExtremeContact Sport 02"): "continental_extremecontact_sport_02.webp",
    ("Continental", "SportContact 7"): "continental_sportcontact_7.webp",
    ("Continental", "TerrainContact A/T"): "continental_terraincontact_a_t.webp",
    ("Continental", "CrossContact LX25"): "continental_crosscontact_lx25.webp",
    ("Continental", "VikingContact 7"): "continental_vikingcontact_7.webp",
    ("Continental", "PremiumContact 7"): "continental_premiumcontact_7.webp",
    ("Continental", "VanContact Ultra"): "continental_vancontact_ultra.webp",
    ("Continental", "ExtremeContact Force"): "continental_extremecontact_force.webp",
    ("Continental", "ComfortContact CC7"): "continental_comfortcontact_cc7.webp",
    ("Continental", "AllSeasonContact 2"): "continental_allseasoncontact_2.webp",
    ("Continental", "CrossContact AX6"): "continental_crosscontact_ax6.webp",
    ("Continental", "TrueContact Tour 54"): "continental_truecontact_tour_54.webp",
    ("Continental", "EcoContact 6"): "continental_ecocontact_6.webp",
    ("Bridgestone", "Potenza Sport"): "bridgestone_potenza_sport.webp",
    ("Bridgestone", "Alenza 001"): "bridgestone_alenza_001.webp",
    ("Bridgestone", "Turanza T005A"): "bridgestone_turanza_t005a.webp",
    ("Bridgestone", "Potenza RE-71RS"): "bridgestone_potenza_re_71rs.webp",
    ("Bridgestone", "Dueler All-Terrain A/T002"): "bridgestone_dueler_all_terrain_a_t002.jpg",
    ("Bridgestone", "Potenza Adrenalin RE004"): "bridgestone_potenza_adrenalin_re004.png",
    ("Bridgestone", "Ecopia EP300"): "bridgestone_ecopia_ep300.jpg",
    ("Bridgestone", "Turanza 6"): "bridgestone_turanza_6.webp",
    ("Bridgestone", "Dueler M/T 674"): "bridgestone_dueler_m_t_674.png",
    ("Bridgestone", "Dueler H/T 684II"): "bridgestone_dueler_h_t_684ii.webp",
    ("Bridgestone", "Alenza Sport A/S"): "bridgestone_alenza_sport_a_s.webp",
    ("Bridgestone", "WeatherPeak"): "bridgestone_weatherpeak.webp",
    ("Bridgestone", "Blizzak WS90"): "bridgestone_blizzak_ws90.webp",
    ("Pirelli", "Cinturato P7 C2"): "pirelli_cinturato_p7_c2.webp",
    ("Pirelli", "P Zero PZ4"): "pirelli_p_zero_pz4.webp",
    ("Pirelli", "Scorpion Verde All Season"): "pirelli_scorpion_verde_all_season.webp",
    ("Pirelli", "Scorpion All Terrain Plus"): "pirelli_scorpion_all_terrain_plus.webp",
    ("Pirelli", "P Zero Elect"): "pirelli_p_zero_elect.jpg",
    ("Pirelli", "Carrier"): "pirelli_carrier.jpg",
    ("Pirelli", "Cinturato All Season SF2"): "pirelli_cinturato_all_season_sf2.jpg",
    ("Pirelli", "Scorpion Zero All Season"): "pirelli_scorpion_zero_all_season.webp",
    ("Pirelli", "P Zero Corsa"): "pirelli_p_zero_corsa.webp",
    ("Pirelli", "Scorpion MS"): "pirelli_scorpion_ms.webp",
    ("Pirelli", "P Zero Nero GT"): "pirelli_p_zero_nero_gt.webp",
    ("Pirelli", "P Zero AS Plus 3"): "pirelli_p_zero_as_plus_3.webp",
    ("Pirelli", "Cinturato P1 Verde"): "pirelli_cinturato_p1_verde.webp",
    ("Pirelli", "Scorpion WeatherActive"): "pirelli_scorpion_weatheractive.webp",
    ("Goodyear", "Eagle F1 Asymmetric 6"): "goodyear_eagle_f1_asymmetric_6.webp",
    ("Goodyear", "Assurance MaxGuard"): "goodyear_assurance_maxguard.png",
    ("Goodyear", "Eagle F1 SuperSport"): "goodyear_eagle_f1_supersport.webp",
    ("Goodyear", "Assurance ComfortTred"): "goodyear_assurance_comforttred.webp",
    ("Goodyear", "Wrangler DuraTrac"): "goodyear_wrangler_duratrac.webp",
    ("Goodyear", "EfficientGrip 2 SUV"): "goodyear_efficientgrip_2_suv.jpg",
    ("Goodyear", "Wrangler AT SilentTrac"): "goodyear_wrangler_at_silenttrac.webp",
    ("Goodyear", "Vector 4Seasons Gen-3"): "goodyear_vector_4seasons_gen_3.jpg",
    ("Goodyear", "Cargo Marathon 2"): "goodyear_cargo_marathon_2.png",
    ("Goodyear", "Assurance WeatherReady 2"): "goodyear_assurance_weatherready_2.webp",
    ("Goodyear", "Eagle F1 Asymmetric 3 SUV"): "goodyear_eagle_f1_asymmetric_3_suv.webp",
    ("Goodyear", "Assurance MaxLife"): "goodyear_assurance_maxlife.webp",
    ("Yokohama", "Advan Neova AD09"): "yokohama_advan_neova_ad09.webp",
    ("Yokohama", "BluEarth-GT AE51"): "yokohama_bluearth_gt_ae51.png",
    ("Yokohama", "Advan Sport V107"): "yokohama_advan_sport_v107.webp",
    ("Yokohama", "Geolandar A/T G015"): "yokohama_geolandar_a_t_g015.webp",
    ("Yokohama", "Geolandar M/T G003"): "yokohama_geolandar_m_t_g003.webp",
    ("Yokohama", "BluEarth-Es ES32"): "yokohama_bluearth_es_es32.jpg",
    ("Yokohama", "Geolandar X-AT G016"): "yokohama_geolandar_x_at_g016.webp",
    ("Yokohama", "Geolandar CV G058"): "yokohama_geolandar_cv_g058.webp",
    ("Yokohama", "Advan Apex V601"): "yokohama_advan_apex_v601.webp",
    ("Yokohama", "Advan Fleva V701"): "yokohama_advan_fleva_v701.webp",
    ("Yokohama", "Geolandar H/T G056"): "yokohama_geolandar_h_t_g056.webp",
    ("Yokohama", "Avid Ascend GT"): "yokohama_avid_ascend_gt.webp",
    ("Dunlop", "Direzza ZIII"): "dunlop_direzza_ziii.jpg",
    ("Dunlop", "Enasave EC300+"): "dunlop_enasave_ec300_plus.webp",
    ("Dunlop", "Veuro VE304"): "dunlop_veuro_ve304.jpg",
    ("Dunlop", "Grandtrek AT5"): "dunlop_grandtrek_at5.png",
    ("Dunlop", "SP Sport Maxx 060+"): "dunlop_sp_sport_maxx_060_plus.webp",
    ("Dunlop", "Grandtrek PT3"): "dunlop_grandtrek_pt3.png",
    ("Dunlop", "SP Sport Maxx RT2"): "dunlop_sp_sport_maxx_rt2.webp",
    ("Toyo Tires", "Proxes Sport 2"): "toyo_tires_proxes_sport_2.webp",
    ("Toyo Tires", "Proxes TR1"): "toyo_tires_proxes_tr1.png",
    ("Toyo Tires", "Open Country M/T"): "toyo_tires_open_country_m_t.webp",
    ("Toyo Tires", "Open Country A/T III"): "toyo_tires_open_country_a_t_iii.webp",
    ("Toyo Tires", "Celsius II"): "toyo_tires_celsius_ii.webp",
    ("Toyo Tires", "Proxes R888R"): "toyo_tires_proxes_r888r.webp",
    ("Toyo Tires", "Open Country R/T"): "toyo_tires_open_country_r_t.webp",
    ("Hankook", "Ventus S1 evo3"): "hankook_ventus_s1_evo3.webp",
    ("Hankook", "iON evo SUV"): "hankook_ion_evo_suv.webp",
    ("Hankook", "Dynapro AT2 Xtreme"): "hankook_dynapro_at2_xtreme.webp",
    ("Hankook", "Kinergy 4S2"): "hankook_kinergy_4s2.webp",
    ("Kumho", "Ecsta PS71"): "kumho_ecsta_ps71.webp",
    ("Kumho", "Solus TA51a"): "kumho_solus_ta51a.webp",
    ("Kumho", "Crugen HP71"): "kumho_crugen_hp71.webp",
    ("Kumho", "Road Venture AT52"): "kumho_road_venture_at52.webp",
    ("Falken", "Azenis FK520"): "falken_azenis_fk520.jpg",
    ("Falken", "Ziex ZE310 Ecorun"): "falken_ziex_ze310_ecorun.png",
    ("Falken", "Wildpeak A/T3W"): "falken_wildpeak_a_t3w.webp",
    ("Falken", "Wildpeak A/T4W"): "falken_wildpeak_a_t4w.webp",
    ("BFGoodrich", "All-Terrain T/A KO2"): "bfgoodrich_all_terrain_t_a_ko2.webp",
    ("BFGoodrich", "All-Terrain T/A KO3"): "bfgoodrich_all_terrain_t_a_ko3.webp",
    ("BFGoodrich", "Trail-Terrain T/A"): "bfgoodrich_trail_terrain_t_a.webp",
    ("Maxxis", "Razr AT-811"): "maxxis_razr_at_811.webp",
    ("Maxxis", "Premitra HP5"): "maxxis_premitra_hp5.png",
    ("Maxxis", "Bravo HP-M3"): "maxxis_bravo_hp_m3.webp",
    ("Maxxis", "Victra Sport 5"): "maxxis_victra_sport_5.jpg",
    ("Maxxis", "Razr MT-772"): "maxxis_razr_mt_772.webp",
    ("Nitto", "Ridge Grappler"): "nitto_ridge_grappler.webp",
    ("Nitto", "Recon Grappler A/T"): "nitto_recon_grappler_a_t.webp",
    ("Nitto", "NT555 G2"): "nitto_nt555_g2.webp",
    ("Nitto", "Motivo 365"): "nitto_motivo_365.webp",
    ("Nitto", "Terra Grappler G2"): "nitto_terra_grappler_g2.webp",
    ("Cooper", "Discoverer Road+Trail AT"): "cooper_discoverer_road_plus_trail_at.webp",
    ("Cooper", "Discoverer AT3 4S"): "cooper_discoverer_at3_4s.webp",
    ("Cooper", "Evolution Tour"): "cooper_evolution_tour.webp",
    ("Cooper", "Zeon RS3-G1"): "cooper_zeon_rs3_g1.webp",
    ("Nexen", "N'Fera SU1"): "nexen_n_fera_su1.webp",
    ("Nexen", "N'Priz AH8"): "nexen_n_priz_ah8.webp",
    ("Nexen", "Roadian ATX"): "nexen_roadian_atx.webp",
    ("Nexen", "N'Fera Sport"): "nexen_n_fera_sport.webp",
    ("GT Radial", "Adventuro AT3"): "gt_radial_adventuro_at3.webp",
    ("GT Radial", "Champiro SX2"): "gt_radial_champiro_sx2.webp",
    ("GT Radial", "Maxtour LX"): "gt_radial_maxtour_lx.webp",
    ("GT Radial", "Savero HT2"): "gt_radial_savero_ht2.webp",
    ("Sailun", "Atrezzo ZSR"): "sailun_atrezzo_zsr.webp",
    ("Sailun", "Erange EV"): "sailun_erange_ev.webp",
    ("Sailun", "Atrezzo Touring LS"): "sailun_atrezzo_touring_ls.webp",
    ("Sailun", "Terramax A/T"): "sailun_terramax_a_t.webp",
}

# Vehicle-class-accurate fitments keyed by (width, aspect_ratio, rim_size).
FITMENT_EXPANSION = {
    (175, 65, 14): ["Toyota Wigo", "Mitsubishi Mirage", "Suzuki Celerio", "Honda Brio", "Hyundai Grand i10", "Kia Picanto", "Suzuki Alto", "Daihatsu Ayla"],
    (185, 65, 14): ["Toyota Wigo", "Mitsubishi Mirage", "Suzuki Celerio", "Honda Brio", "Hyundai i10", "Kia Picanto", "Suzuki Alto"],
    (185, 60, 15): ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift", "Hyundai Accent", "Toyota Yaris", "Suzuki Dzire", "Kia Soluto"],
    (185, 65, 15): ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift", "Suzuki Ciaz", "Hyundai Accent", "Toyota Avanza", "Suzuki Ertiga"],
    (195, 50, 16): ["Mazda MX-5 Miata", "Toyota Vios GR-S", "Honda City", "Suzuki Swift Sport", "Ford Fiesta", "Toyota Yaris", "Mini Cooper"],
    (195, 65, 15): ["Toyota Corolla Altis", "Honda Civic", "Toyota Prius", "Volkswagen Golf", "Hyundai Elantra", "Kia Forte", "Nissan Sentra"],
    (195, 70, 15): ["Toyota HiAce", "Nissan Urvan", "Ford Transit Custom", "Hyundai Staria Cargo", "Renault Master", "Mitsubishi L300", "Kia K2500"],
    (195, 80, 15): ["Toyota HiAce", "Nissan NV350 Urvan", "Hyundai Staria Cargo", "Mitsubishi L300", "Kia K2500", "Isuzu Traviz", "Hyundai H100"],
    (205, 45, 17): ["Honda Civic", "Toyota Corolla Altis", "Mazda 3", "Suzuki Swift Sport", "Toyota Vios GR-S", "Mazda 2", "Hyundai Veloster", "Kia Forte GT", "Mini Cooper S"],
    (205, 50, 16): ["Mazda MX-5 Miata", "Toyota GR86", "Honda Civic Si", "Suzuki Swift Sport", "Mini Cooper S", "Subaru BRZ", "Ford Fiesta ST"],
    (205, 55, 16): ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Hyundai Elantra", "Kia Forte", "Nissan Sylphy", "Nissan Sentra", "Volkswagen Golf", "Ford Focus", "Subaru Impreza"],
    (205, 60, 16): ["Honda Civic", "Toyota Camry", "Hyundai Sonata", "Kia K5", "Nissan Sentra", "Mazda 3", "Kia Carens", "Toyota Innova"],
    (215, 45, 17): ["Honda Civic Si", "Toyota Corolla Altis", "Mazda 3", "Subaru BRZ", "Toyota GR86", "Mini Cooper S", "Volkswagen Golf GTI", "Mazda MX-5 Miata"],
    (215, 50, 17): ["Honda Civic RS", "Toyota Corolla Altis GR-S", "Mazda 3 Fastback", "Subaru Impreza", "Hyundai Elantra N-Line", "Honda Accord", "Nissan Altima", "Kia Forte GT"],
    (215, 55, 17): ["Toyota Camry", "Honda Accord", "Volkswagen Passat", "Nissan Teana", "Mazda 6", "Subaru Legacy", "Lexus ES300h", "Hyundai Sonata", "Kia K5"],
    (215, 60, 17): ["Toyota Corolla Cross", "Honda HR-V", "Subaru Crosstrek", "Mazda CX-30", "Hyundai Kona", "Nissan Kicks e-Power", "Kia Seltos", "Mitsubishi Xpander Cross"],
    (215, 70, 16): ["Toyota HiAce Commuter", "Nissan NV350 Urvan", "Ford Transit", "Hyundai Staria", "Mercedes-Benz Sprinter", "Mitsubishi Delica"],
    (225, 40, 18): ["Volkswagen Golf GTI", "Volkswagen Golf R", "Honda Civic Type R", "Toyota GR Corolla", "Subaru WRX", "Hyundai i30 N", "Mini Cooper JCW", "Audi S3", "Mercedes-AMG A35"],
    (225, 45, 17): ["Subaru WRX", "Volkswagen Golf GTI", "Honda Civic Si", "BMW 2 Series", "Mazda 3 Turbo", "Audi A3", "BMW 1 Series", "Mercedes-Benz A-Class", "Volkswagen Jetta GLI"],
    (225, 45, 18): ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Subaru WRX", "Hyundai Sonata", "Kia K5", "Toyota Camry", "Mazda 6", "Lexus IS300"],
    (225, 50, 17): ["Volvo V60", "Audi A4 Allroad", "BMW 3 Series xDrive", "Mercedes-Benz C-Class 4MATIC", "Mercedes-Benz E-Class", "Audi A6", "Lexus ES300h", "Volvo S60", "Volkswagen Arteon"],
    (225, 55, 17): ["Toyota Camry", "Honda Accord", "Lexus ES300h", "Mazda 6", "Nissan Teana", "Toyota Alphard", "Subaru Legacy", "Hyundai Sonata"],
    (225, 60, 17): ["Subaru Outback", "Subaru Forester", "Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Hyundai Tucson", "Kia Sportage"],
    (225, 60, 18): ["Subaru Forester", "Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Hyundai Tucson", "Kia Sportage", "Mitsubishi Outlander"],
    (225, 65, 17): ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Subaru Forester", "Hyundai Tucson", "Kia Sportage", "Mitsubishi Outlander", "Ford Territory"],
    (235, 35, 19): ["BMW M240i", "Audi S3", "Volkswagen Golf R", "Mercedes-AMG A35", "Honda Civic Type R", "Subaru WRX STI", "Mercedes-AMG A45", "BMW M2", "Audi S4"],
    (235, 40, 18): ["Audi S3", "Honda Civic", "Volkswagen Golf R", "Mercedes-Benz CLA250", "BMW 3 Series", "Subaru WRX", "Subaru WRX STI", "Mitsubishi Lancer Evolution X", "Hyundai Elantra N"],
    (235, 40, 19): ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi S4", "Lexus IS350 F Sport", "Genesis G70", "Kia Stinger", "Volkswagen Arteon", "Audi A5"],
    (235, 45, 18): ["Tesla Model 3", "Honda Accord", "Toyota Camry Hybrid", "BYD Seal", "Polestar 2", "BMW i4", "Lexus ES300h", "Hyundai Ioniq 6"],
    (235, 50, 19): ["Mazda CX-5", "Mazda CX-60", "Toyota Harrier", "Audi Q3", "BMW X1", "Mercedes-Benz GLA", "Lexus NX300"],
    (235, 55, 18): ["Honda CR-V", "Toyota RAV4", "Lexus NX300", "Subaru Outback", "Hyundai Santa Fe", "Kia Sorento", "Ford Territory", "Mazda CX-5"],
    (235, 55, 19): ["BMW X3", "Audi Q5", "Lexus RX350", "Toyota Harrier", "Mercedes-Benz GLC", "Volvo XC60", "Genesis GV70", "Porsche Macan"],
    (235, 60, 18): ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Subaru Forester", "Hyundai Tucson", "Kia Sportage", "Audi Q5", "Volvo XC60", "BMW X3", "Mercedes-Benz GLC"],
    (245, 35, 20): ["Porsche 911", "Audi R8", "Ferrari F8 Tributo", "Mercedes-AMG GT", "BMW M5", "Lamborghini Huracan", "Chevrolet Corvette C8", "Nissan GT-R"],
    (245, 40, 18): ["Chevrolet Corvette", "Audi S4", "BMW M240i", "BMW M340i", "Lexus IS350 F Sport", "Ford Mustang EcoBoost", "Genesis G70", "Subaru WRX STI", "Mitsubishi Lancer Evolution X", "Kia Stinger"],
    (245, 40, 19): ["BMW 4 Series Gran Coupe", "Audi A5 Sportback", "Mercedes-Benz E-Class Coupe", "Genesis G70", "Lexus IS350 F Sport", "Toyota GR Supra", "Mercedes-AMG A45 S", "Audi RS3", "BMW M340i", "Alfa Romeo Giulia QV"],
    (245, 45, 18): ["BMW 5 Series", "Mercedes-Benz E-Class", "Audi A6", "Lexus GS350", "Infiniti Q50", "Genesis G80", "Audi A4", "BMW 3 Series"],
    (245, 45, 19): ["Porsche Taycan", "Tesla Model S", "BMW i4 M50", "Audi e-tron GT", "Mercedes-Benz EQE", "Genesis G80 EV", "BMW i5", "Polestar 2"],
    (255, 35, 19): ["BMW M3", "BMW M4", "Mercedes-AMG C43", "Mercedes-AMG C63", "Audi S5", "Audi RS5", "Ford Mustang GT", "Nissan Z", "Lexus RC F", "Toyota GR Supra"],
    (255, 40, 18): ["Toyota GR Yaris", "Porsche 718 Cayman", "BMW M3", "Ford Mustang GT", "Nissan 370Z", "Chevrolet Camaro SS", "Subaru WRX STI", "Honda Civic Type R"],
    (255, 45, 19): ["Tesla Model Y", "Hyundai Ioniq 5", "Kia EV6", "Audi Q4 e-tron", "Genesis GV60", "BYD Sealion 7", "BMW iX3", "Volkswagen ID.4"],
    (255, 50, 20): ["Lexus RX350", "BMW X5", "Mercedes-Benz GLE", "Audi Q7", "Acura MDX", "Infiniti QX60", "Porsche Macan", "Range Rover Velar", "Volvo XC90"],
    (255, 55, 19): ["Mercedes-Benz GLE", "BMW X5", "Volvo XC90", "Audi Q7", "Lexus RX350", "Genesis GV80", "Porsche Cayenne", "Land Rover Discovery"],
    (265, 60, 18): ["Toyota Fortuner GR-S", "Mitsubishi Montero Sport GT", "Ford Everest Titanium", "Nissan Terra VL", "Isuzu mu-X LS-E", "Toyota Hilux Conquest", "Ford Ranger Wildtrak", "Nissan Navara Pro-4X", "Mitsubishi Strada Athlete", "Isuzu D-Max LS-E"],
    (265, 65, 17): ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Isuzu mu-X", "Toyota Hilux", "Ford Ranger", "Nissan Navara", "Isuzu D-Max", "Mitsubishi Strada"],
    (265, 70, 17): ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Isuzu D-Max V-Cross", "Jeep Wrangler", "Ford Everest", "Mitsubishi Strada", "Isuzu mu-X"],
    (265, 75, 16): ["Toyota Land Cruiser 70", "Toyota Hilux", "Jeep Wrangler", "Nissan Patrol Safari", "Isuzu D-Max", "Mitsubishi Pajero", "Ford Ranger"],
    (275, 35, 19): ["BMW M2 CS", "BMW M4 Competition", "Toyota GR Supra 3.0", "Porsche 911 Carrera S", "Chevrolet Corvette C8", "Nissan Z Performance", "Lexus RC F"],
    (275, 35, 20): ["BMW M5", "Mercedes-AMG E63 S", "Audi RS6 Avant", "Porsche Panamera Turbo", "Nissan GT-R", "Lexus LC500", "Aston Martin DB11"],
    (275, 45, 20): ["Land Rover Defender", "BMW X5 M", "Porsche Cayenne", "Audi Q8", "Mercedes-Benz GLE 53 AMG", "Range Rover Sport", "Genesis GV80"],
    (275, 55, 20): ["Ford F-150", "Chevrolet Silverado 1500", "Ram 1500", "Toyota Tundra", "GMC Sierra 1500", "Nissan Titan", "Ford Expedition"],
    (275, 65, 18): ["Ford F-150", "Toyota Land Cruiser 300", "Nissan Patrol Nismo", "Toyota Hilux GR-S", "Ford Ranger Raptor", "Jeep Gladiator", "Ford Everest Titanium+"],
    (285, 30, 20): ["McLaren 720S", "Ferrari 296 GTB", "Lamborghini Huracan STO", "Porsche 911 GT3 RS", "Aston Martin Vantage", "Ferrari F8 Tributo"],
    (285, 65, 18): ["Ford Ranger Raptor", "Toyota Land Cruiser 300", "Nissan Patrol", "Jeep Gladiator", "Ford F-150", "Toyota Hilux GR-S", "Ram 1500 Rebel"],
    (285, 70, 17): ["Ford Ranger Raptor", "Jeep Wrangler Rubicon", "Toyota Land Cruiser", "Nissan Patrol Safari", "Toyota Hilux Arctic Trucks", "Isuzu D-Max Arctic Trucks"],
    (285, 75, 16): ["Toyota Land Cruiser 70", "Jeep Wrangler Rubicon", "Ford Ranger Raptor", "Nissan Patrol Safari", "Isuzu D-Max", "Toyota Hilux"],
    (295, 30, 19): ["Porsche 911 GT3", "BMW M3 CS", "Mercedes-AMG GT", "Ferrari 488 GTB", "Audi R8 V10", "Chevrolet Corvette Z06", "Porsche 911 Carrera GTS"],
    (325, 30, 21): ["Porsche 911 GT2 RS", "Porsche 911 GT3 RS", "Ferrari SF90 Stradale", "Mercedes-AMG GT Black Series", "McLaren 765LT", "Lamborghini Aventador SVJ"],
}


def make_tire(
    id_slug,
    brand,
    model,
    category,
    season,
    width,
    aspect_ratio,
    rim_size,
    load_index,
    speed_rating,
    dot_year,
    price,
    original_price,
    rating,
    reviews_count,
    stock,
    wet_grip,
    fuel_efficiency,
    noise_db,
    warranty_miles,
    description,
    compatible_cars,
):
    if (brand, model) not in IMAGE_BY_MODEL:
        raise ValueError(f"No verified image configured for {(brand, model)}")
    if fuel_efficiency not in ("A", "B", "C", "D", "E"):
        raise ValueError(f"Invalid EU fuel_efficiency {fuel_efficiency} for {id_slug}")
    if wet_grip not in ("A", "B", "C", "D", "E"):
        raise ValueError(f"Invalid EU wet_grip {wet_grip} for {id_slug}")
    if original_price is None or original_price <= price:
        raise ValueError(f"original_price ({original_price}) must exceed price ({price}) for {id_slug}")

    img_filename = IMAGE_BY_MODEL[(brand, model)]
    img_path = IMAGES_DIR / img_filename
    if not img_path.exists():
        raise FileNotFoundError(f"Verified image missing on disk: {img_path}")

    generic = FITMENT_EXPANSION.get((width, aspect_ratio, rim_size), [])
    merged_cars = []
    seen = set()
    for car in (compatible_cars or []) + generic:
        c_clean = car.strip()
        if c_clean.lower() not in seen:
            seen.add(c_clean.lower())
            merged_cars.append(c_clean)
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
        "price": round(float(price), 2),
        "original_price": round(float(original_price), 2),
        "rating": round(float(rating), 1),
        "reviews_count": int(reviews_count),
        "stock": int(stock),
        "wet_grip": wet_grip,
        "fuel_efficiency": fuel_efficiency,
        "noise_db": int(noise_db),
        "warranty_miles": int(warranty_miles),
        "description": description.strip(),
        "compatible_cars": merged_cars,
        "image_asset": f"assets/images/tires/{img_filename}",
    }


def build_catalog():
    tires = []
    add = tires.append

    # =========================================================================
    # 1. MICHELIN
    # =========================================================================
    add(make_tire(
        "michelin-pilot-sport-5", "Michelin", "Pilot Sport 5",
        "Ultra High Performance Summer", "Summer",
        225, 45, 18, 95, "Y", 2026, 224.99, 254.99, 4.9, 540, 36, "A", "C", 72, 30000,
        "5th-generation Michelin UHP summer tire with Dual Sport Tread Design and MaxTouch Construction for crisp cornering response and wet braking.",
        ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Subaru WRX", "Lexus IS300"],
    ))
    add(make_tire(
        "michelin-pilot-sport-5-19", "Michelin", "Pilot Sport 5",
        "Ultra High Performance Summer", "Summer",
        245, 40, 19, 98, "Y", 2026, 269.99, 304.99, 4.9, 320, 24, "A", "C", 72, 30000,
        "Larger 19-inch UHP summer fitment for executive sport sedans and coupes, engineered for even pressure distribution under hard cornering.",
        ["BMW 4 Series Gran Coupe", "Audi A5 Sportback", "Mercedes-Benz E-Class Coupe", "Genesis G70", "Lexus IS350 F Sport", "BMW M340i"],
    ))
    add(make_tire(
        "michelin-pilot-sport-all-season-4", "Michelin", "Pilot Sport All-Season 4",
        "Ultra High Performance All-Season", "All-Season",
        245, 40, 18, 97, "Y", 2025, 234.99, 269.99, 4.8, 392, 28, "A", "C", 71, 30000,
        "High-performance all-season tire engineered with Helio Compound and Dynamic Response Technology for confident year-round dry, wet, and light-snow grip.",
        ["Chevrolet Corvette", "Audi S4", "BMW M340i", "Lexus IS350 F Sport", "Ford Mustang EcoBoost", "Genesis G70"],
    ))
    add(make_tire(
        "michelin-pilot-sport-all-season-4-19", "Michelin", "Pilot Sport All-Season 4",
        "Ultra High Performance All-Season", "All-Season",
        255, 35, 19, 96, "Y", 2025, 279.99, 319.99, 4.8, 245, 20, "A", "C", 71, 30000,
        "Staggered 19-inch UHP all-season fitment featuring 360-degree Variable Thickness Sipes that lock together for stable dry turn-in.",
        ["Audi S5", "BMW M3", "Mercedes-AMG C43", "Ford Mustang GT", "Nissan Z", "Lexus RC F"],
    ))
    add(make_tire(
        "michelin-pilot-sport-cup-2", "Michelin", "Pilot Sport Cup 2",
        "Street-Legal Track & Competition", "Summer Track",
        295, 30, 19, 100, "Y", 2025, 419.99, 469.99, 4.9, 196, 14, "C", "E", 73, 0,
        "Motorsport-derived Bi-Compound tread combines an outside elastomer for dry circuit grip with rigid wet-weather inner ribs for consistent track laps.",
        ["Porsche 911 GT3", "BMW M3 CS", "Mercedes-AMG GT", "Ferrari 488 GTB", "Audi R8 V10", "Chevrolet Corvette Z06", "Porsche 911 Carrera GTS"],
    ))
    add(make_tire(
        "michelin-pilot-sport-cup-2-r", "Michelin", "Pilot Sport Cup 2 R",
        "Extreme Track & Record Breaker", "Summer Track",
        325, 30, 21, 108, "Y", 2025, 565.00, 635.00, 4.9, 140, 8, "D", "E", 75, 0,
        "Special semi-slick track competition compound delivering peak dry lateral G-force and minimal block squirm for timed circuit sessions.",
        ["Porsche 911 GT2 RS", "Porsche 911 GT3 RS", "Ferrari SF90 Stradale", "Mercedes-AMG GT Black Series", "McLaren 765LT", "Lamborghini Aventador SVJ"],
    ))
    add(make_tire(
        "michelin-primacy-4-plus", "Michelin", "Primacy 4+",
        "Premium Touring Comfort", "Summer",
        215, 55, 17, 94, "W", 2025, 159.99, 182.99, 4.8, 420, 45, "A", "B", 69, 50000,
        "EverGrip multi-layer rubber compound exposes fresh tread biting channels as the tire wears for reliable wet braking throughout its service life.",
        ["Toyota Camry", "Honda Accord", "Volkswagen Passat", "Mazda 6", "Lexus ES300h", "Hyundai Sonata", "Kia K5"],
    ))
    add(make_tire(
        "michelin-primacy-4-plus-16", "Michelin", "Primacy 4+",
        "Premium Touring Comfort", "Summer",
        205, 55, 16, 91, "V", 2025, 134.99, 154.99, 4.8, 310, 50, "A", "B", 68, 50000,
        "Balanced touring tire for compact and midsize sedans combining absorbed road harshness with low internal rolling resistance.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Hyundai Elantra", "Kia Forte", "Nissan Sentra", "Volkswagen Golf"],
    ))
    add(make_tire(
        "michelin-crossclimate-2", "Michelin", "CrossClimate 2",
        "All-Weather Grand Touring", "All-Weather",
        215, 55, 17, 94, "V", 2026, 209.99, 239.99, 4.9, 418, 32, "B", "B", 69, 60000,
        "Directional V-Ramp tread and 3PMSF-certified Thermal Adaptive Compound deliver confident wet, dry, and all-weather stopping power mile after mile.",
        ["Toyota Camry", "Honda Accord", "Subaru Outback", "Volkswagen Passat", "Hyundai Sonata", "Lexus ES300h"],
    ))
    add(make_tire(
        "michelin-crossclimate-2-suv", "Michelin", "CrossClimate 2 SUV",
        "All-Weather Grand Touring", "All-Weather",
        235, 60, 18, 103, "V", 2026, 229.99, 262.99, 4.9, 278, 30, "B", "C", 70, 60000,
        "Crossover-reinforced V-formation tread evacuate standing water rapidly while supporting higher SUV center-of-gravity cornering loads.",
        ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Subaru Forester", "Hyundai Tucson", "Volvo XC60", "Audi Q5"],
    ))
    add(make_tire(
        "michelin-e-primacy", "Michelin", "e.Primacy",
        "Electric Vehicle Dedicated", "Summer EV",
        235, 45, 18, 98, "W", 2025, 204.99, 234.99, 4.8, 165, 26, "B", "A", 69, 45000,
        "EnergyAirShield belt and ultra-low rolling resistance compound minimize energy dissipation to extend EV range and reduce highway fuel burn.",
        ["Tesla Model 3", "BYD Seal", "Polestar 2", "BMW i4", "Hyundai Ioniq 6", "Toyota Camry Hybrid"],
    ))
    add(make_tire(
        "michelin-pilot-sport-4s", "Michelin", "Pilot Sport 4S",
        "Max Performance Summer", "Summer",
        255, 35, 19, 96, "(Y)", 2025, 289.99, 329.99, 4.9, 624, 22, "A", "C", 71, 30000,
        "Benchmark ultra-high performance street tire blending Dynamic Response hybrid belts and Bi-Compound rubber for track-ready precision.",
        ["BMW M3", "BMW M4", "Mercedes-AMG C63", "Audi RS5", "Porsche 718 Cayman", "Lexus RC F", "Ford Mustang GT"],
    ))
    add(make_tire(
        "michelin-primacy-suv-plus", "Michelin", "Primacy SUV+",
        "Highway Terrain Luxury SUV", "All-Season",
        265, 65, 17, 112, "H", 2025, 198.50, 226.00, 4.8, 210, 32, "A", "B", 69, 55000,
        "Dedicated luxury SUV highway tire featuring U-Shape grooves and StabiliGrip sipes for composed braking in sudden monsoon downpours.",
        ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Isuzu mu-X", "Toyota Land Cruiser Prado"],
    ))
    add(make_tire(
        "michelin-primacy-suv-plus-18", "Michelin", "Primacy SUV+",
        "Highway Terrain Luxury SUV", "All-Season",
        265, 60, 18, 110, "H", 2025, 228.00, 259.00, 4.8, 175, 28, "A", "B", 69, 55000,
        "18-inch executive SUV highway specification engineered for quiet cabin refinement and confident wet braking.",
        ["Toyota Fortuner GR-S", "Mitsubishi Montero Sport GT", "Ford Everest Titanium", "Nissan Terra VL", "Isuzu mu-X LS-E", "Toyota Land Cruiser Prado"],
    ))
    add(make_tire(
        "michelin-primacy-tour-a-s", "Michelin", "Primacy Tour A/S",
        "Grand Touring All-Season", "All-Season",
        235, 55, 19, 101, "V", 2025, 249.99, 284.99, 4.8, 194, 24, "A", "C", 68, 55000,
        "Flagship North American grand touring all-season tire tuned with Piano Acoustic Tuning to suppress harsh highway cavity resonance.",
        ["Lexus RX350", "BMW X3", "Audi Q5", "Volvo XC60", "Mercedes-Benz GLC", "Porsche Macan"],
    ))
    add(make_tire(
        "michelin-energy-xm2-plus", "Michelin", "Energy XM2+",
        "High Mileage Eco Touring", "All-Season",
        185, 60, 15, 84, "H", 2025, 89.99, 104.99, 4.7, 340, 60, "B", "A", 68, 60000,
        "Alternating bridging silica compound resists tearing on rough provincial roads while delivering long city commuter mileage.",
        ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift", "Hyundai Accent", "Toyota Yaris"],
    ))
    add(make_tire(
        "michelin-energy-xm2-plus-14", "Michelin", "Energy XM2+",
        "High Mileage Eco Touring", "All-Season",
        175, 65, 14, 82, "T", 2025, 74.99, 86.99, 4.7, 290, 55, "B", "A", 68, 60000,
        "Fuel-efficient 14-inch touring tire engineered for subcompact hatchbacks and everyday urban stop-and-go durability.",
        ["Toyota Wigo", "Mitsubishi Mirage", "Suzuki Celerio", "Honda Brio", "Hyundai Grand i10", "Kia Picanto"],
    ))
    add(make_tire(
        "michelin-defender-2", "Michelin", "Defender 2",
        "Standard Touring All-Season", "All-Season",
        205, 55, 16, 91, "H", 2025, 159.99, 184.99, 4.9, 480, 42, "B", "B", 69, 80000,
        "Engineered for maximum tread longevity with Locking 3D Sipes and an 80,000-mile limited treadwear warranty.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Hyundai Elantra", "Kia Forte", "Nissan Sentra", "Volkswagen Golf"],
    ))
    add(make_tire(
        "michelin-ltx-trail", "Michelin", "LTX Trail",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 60, 18, 110, "T", 2025, 219.99, 249.99, 4.8, 195, 25, "A", "C", 71, 45000,
        "RallyForce tread compound resists chips and cuts on gravel trails while Biting Shoulder Edges add off-road traction without highway drone.",
        ["Toyota Hilux Conquest", "Ford Ranger Wildtrak", "Nissan Navara Pro-4X", "Mitsubishi Strada Athlete", "Isuzu D-Max LS-E", "Ford Everest Titanium", "Toyota Fortuner GR-S"],
    ))
    add(make_tire(
        "michelin-agilis-3", "Michelin", "Agilis 3",
        "Commercial Van & Utility", "Summer Commercial",
        195, 80, 15, 106, "R", 2025, 119.99, 136.99, 4.7, 150, 38, "A", "B", 71, 50000,
        "Commercial van workhorse built with kerbstone sidewall protectors, stone ejectors, and a reinforced casing for heavy payload efficiency.",
        ["Toyota HiAce", "Nissan NV350 Urvan", "Hyundai Staria Cargo", "Mitsubishi L300", "Kia K2500", "Isuzu Traviz", "Hyundai H100"],
    ))

    # =========================================================================
    # 2. CONTINENTAL
    # =========================================================================
    add(make_tire(
        "continental-extreme-contact-dws06-plus", "Continental", "ExtremeContact DWS06 Plus",
        "Ultra High Performance All-Season", "All-Season",
        225, 45, 17, 94, "W", 2025, 169.99, 194.99, 4.8, 412, 34, "A", "C", 70, 50000,
        "SPORTPLUS Technology delivers crisp handling and wet-road confidence alongside Tuned Performance Indicators molded into the tread.",
        ["Subaru WRX", "Volkswagen Golf GTI", "Honda Civic Si", "BMW 2 Series", "Audi A3", "Mazda 3 Turbo", "Volkswagen Jetta GLI"],
    ))
    add(make_tire(
        "continental-extreme-contact-dws06-plus-18", "Continental", "ExtremeContact DWS06 Plus",
        "Ultra High Performance All-Season", "All-Season",
        235, 40, 18, 95, "Y", 2025, 194.99, 222.99, 4.8, 290, 26, "A", "C", 71, 50000,
        "18-inch UHP all-season tire pairing fast steering turn-in with reliable wet evacuation and light winter versatility.",
        ["Audi S3", "Honda Civic", "Volkswagen Golf R", "Mercedes-Benz CLA250", "BMW 3 Series", "Subaru WRX", "Hyundai Elantra N"],
    ))
    add(make_tire(
        "continental-extreme-contact-sport-02", "Continental", "ExtremeContact Sport 02",
        "Ultra High Performance Summer", "Summer",
        255, 35, 19, 96, "Y", 2025, 254.99, 289.99, 4.9, 285, 22, "A", "C", 71, 30000,
        "Max-performance summer tire developed with racing drivers for strong dry braking, progressive breakaway at the limit, and wet security.",
        ["Toyota GR Supra", "BMW M2", "Ford Mustang GT", "Nissan Z", "Porsche 718 Cayman", "Audi S5", "BMW M3"],
    ))
    add(make_tire(
        "continental-sport-contact-7", "Continental", "SportContact 7",
        "Max Performance Summer", "Summer",
        245, 40, 19, 98, "(Y)", 2026, 289.99, 329.99, 4.9, 340, 20, "A", "C", 72, 25000,
        "BlackChili compound and an Adaptive Pattern automatically maximize contact patch on dry corners and drain grooves in heavy rain.",
        ["Mercedes-AMG A45 S", "Audi RS3", "BMW M340i", "Alfa Romeo Giulia QV", "Porsche 911", "BMW 4 Series Gran Coupe", "Genesis G70"],
    ))
    add(make_tire(
        "continental-sport-contact-7-20", "Continental", "SportContact 7",
        "Max Performance Summer", "Summer",
        275, 35, 20, 102, "(Y)", 2026, 339.99, 389.99, 4.9, 180, 14, "A", "C", 73, 25000,
        "Wide 20-inch rear/staggered flagship fitment tailored to transfer high twin-turbo torque cleanly onto wet and dry pavement.",
        ["BMW M5", "Mercedes-AMG E63 S", "Audi RS6 Avant", "Porsche Panamera Turbo", "Nissan GT-R", "Lexus LC500"],
    ))
    add(make_tire(
        "continental-premium-contact-7", "Continental", "PremiumContact 7",
        "Premium Touring Comfort", "Summer",
        225, 50, 17, 98, "Y", 2026, 175.99, 202.99, 4.9, 265, 34, "A", "B", 69, 45000,
        "RedChili compound achieves peak wet grip from cold start without warm-up time, paired with a size-tuned comfort-sport carcass.",
        ["BMW 3 Series", "Mercedes-Benz E-Class", "Audi A6", "Lexus ES300h", "Volvo S60", "Volkswagen Arteon", "Volvo V60"],
    ))
    add(make_tire(
        "continental-ultra-contact-uc7", "Continental", "UltraContact UC7",
        "Premium Touring Comfort", "Summer",
        205, 55, 16, 91, "V", 2025, 114.99, 132.99, 4.8, 310, 42, "A", "B", 68, 50000,
        "Diamond Compound and Aqua Channel drainage combined with Noise Breaker 3.0 acoustic baffles for calm, assured tropical highway touring.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sentra", "Hyundai Elantra", "Kia Forte", "Volkswagen Golf"],
    ))
    add(make_tire(
        "continental-ultra-contact-uc7-17", "Continental", "UltraContact UC7",
        "Premium Touring Comfort", "Summer",
        215, 50, 17, 95, "W", 2025, 144.99, 165.99, 4.8, 220, 35, "A", "B", 68, 50000,
        "17-inch comfort-touring upgrade featuring Aqua Channel grooves to disperse water film rapidly at highway speeds.",
        ["Honda Civic RS", "Toyota Corolla Altis GR-S", "Mazda 3 Fastback", "Hyundai Elantra N-Line", "Honda Accord", "Kia Forte GT"],
    ))
    add(make_tire(
        "continental-comfort-contact-cc7", "Continental", "ComfortContact CC7",
        "Ultra Quiet Passenger Touring", "All-Season",
        185, 65, 15, 88, "H", 2025, 82.99, 94.99, 4.7, 290, 50, "B", "A", 66, 55000,
        "Comfort+ Technology with Resonator Chambers and Noise Breaker 3.0 noticeably softens concrete road expansion joints in urban commutes.",
        ["Toyota Vios", "Honda City", "Suzuki Swift", "Nissan Almera", "Mitsubishi Mirage G4", "Hyundai Accent", "Toyota Avanza"],
    ))
    add(make_tire(
        "continental-comfort-contact-cc7-14", "Continental", "ComfortContact CC7",
        "Ultra Quiet Passenger Touring", "All-Season",
        175, 65, 14, 82, "T", 2025, 68.99, 78.99, 4.7, 210, 45, "B", "A", 66, 55000,
        "14-inch city hatchback tire calibrated to dampen cabin vibration and improve commuter ride composure.",
        ["Toyota Wigo", "Suzuki Celerio", "Mitsubishi Mirage", "Honda Brio", "Hyundai Grand i10", "Kia Picanto"],
    ))
    add(make_tire(
        "continental-allseasoncontact-2", "Continental", "AllSeasonContact 2",
        "All-Weather Grand Touring", "All-Weather",
        225, 45, 17, 94, "W", 2026, 152.99, 175.99, 4.8, 176, 30, "B", "B", 70, 50000,
        "C-Block architecture and Chili Blend resin compound reduce rolling resistance for EVs and hybrids while excelling in cold and wet grip.",
        ["Volkswagen Golf GTI", "Audi A3", "BMW 1 Series", "Mercedes-Benz A-Class", "Subaru WRX", "BMW 2 Series"],
    ))
    add(make_tire(
        "continental-truecontact-tour-54", "Continental", "TrueContact Tour 54",
        "Standard Touring All-Season", "All-Season",
        205, 55, 16, 91, "H", 2025, 154.99, 177.99, 4.8, 224, 34, "A", "B", 68, 80000,
        "EcoPlus Technology and QuickView indicators combine an 80,000-mile H-rated tread life warranty with confident wet stopping power.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sentra", "Hyundai Elantra", "Subaru Impreza"],
    ))
    add(make_tire(
        "continental-ecocontact-6", "Continental", "EcoContact 6",
        "High Mileage Eco Touring", "Summer",
        205, 60, 16, 92, "V", 2025, 149.99, 172.99, 4.7, 189, 36, "B", "A", 69, 45000,
        "Green Chili 2.0 silica polymer adapts cleanly to road texture, reducing rolling energy loss and CO2 emissions for everyday sedans.",
        ["Honda Civic", "Toyota Camry", "Hyundai Sonata", "Nissan Sentra", "Mazda 3", "Toyota Innova"],
    ))
    add(make_tire(
        "continental-cross-contact-lx25", "Continental", "CrossContact LX25",
        "Highway Terrain Luxury SUV", "All-Season",
        235, 55, 18, 100, "V", 2025, 189.99, 219.99, 4.8, 240, 28, "B", "B", 69, 70000,
        "EcoPlus+ silane additives promote low rolling resistance, responsive wet braking, and quiet expressway poise for crossovers.",
        ["Honda CR-V", "Toyota RAV4", "Lexus NX300", "Subaru Outback", "Hyundai Santa Fe", "Kia Sorento", "Ford Territory"],
    ))
    add(make_tire(
        "continental-cross-contact-lx25-19", "Continental", "CrossContact LX25",
        "Highway Terrain Luxury SUV", "All-Season",
        235, 50, 19, 99, "V", 2025, 219.00, 249.00, 4.8, 165, 20, "B", "B", 69, 70000,
        "Low-profile 19-inch luxury crossover specification reducing lateral body roll and suppressing road resonance.",
        ["Mazda CX-5", "Mazda CX-60", "Toyota Harrier", "Audi Q3", "BMW X1", "Mercedes-Benz GLA", "Lexus NX300"],
    ))
    add(make_tire(
        "continental-terrain-contact-at", "Continental", "TerrainContact A/T",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 224.99, 256.99, 4.8, 355, 30, "B", "C", 71, 60000,
        "TractionPlus Technology delivers confident dirt, gravel, and wet-grass bite alongside disciplined highway quietness.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Isuzu D-Max V-Cross", "Jeep Wrangler"],
    ))
    add(make_tire(
        "continental-terrain-contact-at-18", "Continental", "TerrainContact A/T",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 60, 18, 110, "T", 2025, 239.00, 272.00, 4.8, 225, 24, "B", "C", 71, 60000,
        "18-inch pickup and 4x4 fitment balancing rugged trail durability with comfortable daily pavement manners.",
        ["Toyota Hilux Conquest", "Ford Ranger Wildtrak", "Nissan Navara Pro-4X", "Mitsubishi Strada Athlete", "Isuzu D-Max LS-E", "Toyota Fortuner GR-S"],
    ))
    add(make_tire(
        "continental-cross-contact-ax6", "Continental", "CrossContact AX6",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 60, 18, 110, "T", 2025, 214.99, 244.99, 4.7, 145, 22, "C", "D", 72, 50000,
        "APAC-engineered SUV all-terrain tire featuring rugged shoulder blocks, stone ejectors, and Noise-Blocker pattern geometry.",
        ["Toyota Fortuner", "Ford Everest Titanium", "Mitsubishi Montero Sport GT", "Nissan Terra VL", "Toyota Hilux Conquest", "Ford Ranger Wildtrak"],
    ))
    add(make_tire(
        "continental-viking-contact-7", "Continental", "VikingContact 7",
        "Nordic Winter & Ice", "Winter",
        225, 50, 17, 98, "T", 2025, 199.99, 229.99, 4.9, 270, 22, "B", "C", 69, 35000,
        "Active Grip Silica and rapeseed oil formulation stays supple in sub-zero cold for confident traction on packed snow and black ice.",
        ["Volvo V60", "Audi A4 Allroad", "BMW 3 Series xDrive", "Mercedes-Benz C-Class 4MATIC", "Audi A6", "Lexus ES300h", "Volvo S60"],
    ))
    add(make_tire(
        "continental-van-contact-ultra", "Continental", "VanContact Ultra",
        "Commercial Van & Utility", "Summer Commercial",
        215, 70, 16, 108, "T", 2025, 164.99, 189.99, 4.8, 130, 30, "A", "B", 71, 60000,
        "Thick sidewall scuff ribs and closed robust tread blocks resist urban curb scraping and gravel stone drilling on delivery fleets.",
        ["Toyota HiAce Commuter", "Nissan NV350 Urvan", "Ford Transit", "Hyundai Staria", "Mercedes-Benz Sprinter", "Mitsubishi Delica"],
    ))
    add(make_tire(
        "continental-extreme-contact-force", "Continental", "ExtremeContact Force",
        "Street-Legal Track & Competition", "Summer Track",
        245, 40, 18, 97, "W", 2025, 279.99, 318.99, 4.9, 118, 15, "B", "E", 74, 0,
        "200-treadwear endurance circuit tire co-developed with Hoosier for heat resistance, wear consistency, and sustained stint lap speed.",
        ["Audi S4", "BMW M240i", "BMW M340i", "Lexus IS350 F Sport", "Subaru WRX STI", "Mitsubishi Lancer Evolution X", "Ford Mustang EcoBoost"],
    ))

    # =========================================================================
    # 3. BRIDGESTONE
    # =========================================================================
    add(make_tire(
        "bridgestone-potenza-sport", "Bridgestone", "Potenza Sport",
        "Ultra High Performance Summer", "Summer",
        235, 35, 19, 91, "(Y)", 2025, 245.99, 279.99, 4.8, 360, 26, "A", "D", 72, 25000,
        "3D sipe architecture and sport carcass reinforcement deliver fast steering reaction, high wet braking performance, and cornering bite.",
        ["BMW M240i", "Audi S3", "Volkswagen Golf R", "Mercedes-AMG A35", "Honda Civic Type R", "Subaru WRX STI"],
    ))
    add(make_tire(
        "bridgestone-potenza-sport-18", "Bridgestone", "Potenza Sport",
        "Ultra High Performance Summer", "Summer",
        225, 40, 18, 92, "Y", 2025, 209.99, 239.99, 4.8, 280, 32, "A", "D", 71, 25000,
        "High-performance 18-inch fitment balancing wet-road stopping precision with flat high-speed stability on sport compacts.",
        ["Volkswagen Golf GTI", "Volkswagen Golf R", "Honda Civic Type R", "Toyota GR Corolla", "Subaru WRX", "Hyundai i30 N"],
    ))
    add(make_tire(
        "bridgestone-potenza-re-71rs", "Bridgestone", "Potenza RE-71RS",
        "Street-Legal Track & Competition", "Summer Track",
        255, 40, 18, 99, "W", 2025, 289.99, 329.99, 4.9, 215, 16, "B", "E", 75, 0,
        "200-treadwear autocross and time-attack benchmark utilizing high-grip polymer chemistry and rigid outside slick shoulder ribs.",
        ["Toyota GR Yaris", "Honda Civic Type R", "Porsche 718 Cayman", "BMW M3", "Ford Mustang GT", "Nissan 370Z"],
    ))
    add(make_tire(
        "bridgestone-potenza-re-71rs-19", "Bridgestone", "Potenza RE-71RS",
        "Street-Legal Track & Competition", "Summer Track",
        275, 35, 19, 100, "W", 2025, 335.00, 382.00, 4.9, 140, 12, "B", "E", 75, 0,
        "Wide 19-inch track fitment built for heavy braking zone bite and progressive trail-braking feel.",
        ["BMW M2 CS", "BMW M4 Competition", "Toyota GR Supra 3.0", "Porsche 911 Carrera S", "Chevrolet Corvette C8", "Lexus RC F"],
    ))
    add(make_tire(
        "bridgestone-potenza-adrenalin-re004", "Bridgestone", "Potenza Adrenalin RE004",
        "Street Performance Sport", "Summer",
        205, 45, 17, 88, "W", 2025, 134.99, 154.99, 4.8, 290, 40, "A", "C", 71, 35000,
        "Triple center ribs and rigid A-shaped tread blocks give compact street machines direct steering response and wet cornering control.",
        ["Honda Civic", "Toyota Corolla Altis", "Mazda 3", "Suzuki Swift Sport", "Hyundai Veloster", "Kia Forte GT", "Mini Cooper S"],
    ))
    add(make_tire(
        "bridgestone-potenza-adrenalin-re004-18", "Bridgestone", "Potenza Adrenalin RE004",
        "Street Performance Sport", "Summer",
        225, 45, 18, 95, "W", 2025, 169.99, 194.99, 4.8, 215, 30, "A", "C", 71, 35000,
        "18-inch sporty street tire designed for responsive lane changes and confident grip across warm tarmac.",
        ["Subaru WRX", "BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Mazda 6"],
    ))
    add(make_tire(
        "bridgestone-turanza-t005a", "Bridgestone", "Turanza T005A",
        "Premium Touring Comfort", "All-Season",
        215, 50, 17, 95, "V", 2025, 149.99, 172.99, 4.7, 380, 48, "A", "B", 67, 50000,
        "High-angle sipes and optimized sidewall plies soften sharp bumps and lower cabin drone for serene highway travel.",
        ["Honda Civic RS", "Toyota Corolla Altis GR-S", "Mazda 3 Fastback", "Hyundai Elantra N-Line", "Honda Accord", "Nissan Altima"],
    ))
    add(make_tire(
        "bridgestone-turanza-t005a-16", "Bridgestone", "Turanza T005A",
        "Premium Touring Comfort", "All-Season",
        205, 55, 16, 91, "V", 2025, 124.99, 142.99, 4.7, 295, 52, "A", "B", 67, 50000,
        "16-inch touring fitment crafted with NanoPro-Tech silica polymers for balanced wet braking and plush daily driving comfort.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Hyundai Elantra", "Kia Forte", "Nissan Sylphy"],
    ))
    add(make_tire(
        "bridgestone-turanza-6", "Bridgestone", "Turanza 6",
        "Premium Touring Comfort", "Summer",
        225, 45, 17, 94, "Y", 2026, 174.99, 199.99, 4.9, 160, 32, "A", "A", 68, 50000,
        "ENLITEN lightweight architecture reduces tire mass and rolling resistance for EVs and hybrids while earning Grade-A wet grip.",
        ["Volkswagen Golf GTI", "Audi A3", "BMW 1 Series", "Mercedes-Benz A-Class", "Subaru WRX", "BMW 2 Series"],
    ))
    add(make_tire(
        "bridgestone-weatherpeak", "Bridgestone", "WeatherPeak",
        "All-Weather Grand Touring", "All-Weather",
        215, 55, 17, 94, "V", 2025, 179.99, 204.99, 4.8, 240, 30, "B", "B", 69, 70000,
        "3PMSF all-weather touring tire featuring Evolving Sipes and open shoulder slots for dependable grip through wet, dry, and wintry conditions.",
        ["Toyota Camry", "Honda Accord", "Volkswagen Passat", "Hyundai Sonata", "Kia K5", "Lexus ES300h"],
    ))
    add(make_tire(
        "bridgestone-blizzak-ws90", "Bridgestone", "Blizzak WS90",
        "Studless Winter & Ice", "Winter",
        205, 55, 16, 91, "H", 2025, 148.99, 169.99, 4.9, 390, 26, "B", "D", 71, 35000,
        "Multicell rubber compound wicks surface water off ice for confident winter stopping control and crisp steering bite.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Subaru Impreza", "Volkswagen Golf", "Hyundai Elantra"],
    ))
    add(make_tire(
        "bridgestone-ecopia-ep300", "Bridgestone", "Ecopia EP300",
        "High Mileage Eco Touring", "All-Season",
        185, 60, 15, 84, "H", 2025, 76.99, 89.99, 4.7, 360, 58, "B", "A", 68, 60000,
        "NanoPro-Tech tread compound minimizes heat buildup and rolling resistance to lower fuel consumption without sacrificing wet grip.",
        ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Suzuki Dzire", "Nissan Almera", "Toyota Yaris", "Hyundai Accent"],
    ))
    add(make_tire(
        "bridgestone-alenza-001", "Bridgestone", "Alenza 001",
        "Highway Terrain Luxury SUV", "Summer",
        235, 55, 19, 101, "V", 2025, 274.99, 312.99, 4.8, 245, 24, "A", "C", 69, 45000,
        "Tailored for prestige SUVs using NanoPro-Tech polymer and rounded Multi-Round Block profiles to sharpen steering and suppress edge wear.",
        ["BMW X3", "Audi Q5", "Lexus RX350", "Toyota Harrier", "Mercedes-Benz GLC", "Volvo XC60", "Porsche Macan"],
    ))
    add(make_tire(
        "bridgestone-alenza-sport-a-s", "Bridgestone", "Alenza Sport A/S",
        "High Performance Luxury SUV", "All-Season",
        255, 50, 20, 109, "V", 2025, 254.99, 289.99, 4.8, 175, 20, "A", "C", 69, 55000,
        "All-season grand touring SUV tire tuned for high-speed stability, low treadwear noise, and heavy luxury crossover payloads.",
        ["Lexus RX350", "BMW X5", "Mercedes-Benz GLE", "Audi Q7", "Acura MDX", "Range Rover Velar", "Volvo XC90"],
    ))
    add(make_tire(
        "bridgestone-dueler-ht-684ii", "Bridgestone", "Dueler H/T 684II",
        "Highway Terrain Luxury SUV", "All-Season",
        265, 60, 18, 110, "H", 2025, 229.99, 262.99, 4.7, 290, 35, "B", "C", 70, 60000,
        "Original equipment highway-terrain SUV tire with spiral wrap nylon belts for smooth tracking and dependable wet traction.",
        ["Toyota Fortuner GR-S", "Mitsubishi Montero Sport GT", "Ford Everest Titanium", "Nissan Terra VL", "Isuzu mu-X LS-E", "Toyota Land Cruiser Prado"],
    ))
    add(make_tire(
        "bridgestone-dueler-all-terrain-at002", "Bridgestone", "Dueler All-Terrain A/T002",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 65, 17, 112, "T", 2025, 194.99, 222.99, 4.9, 210, 30, "A", "C", 71, 55000,
        "Hexagonal tread block geometry and high-silica compound deliver strong off-road grip in mud and gravel alongside quiet highway manners.",
        ["Toyota Hilux", "Toyota Fortuner", "Ford Ranger", "Mitsubishi Montero Sport", "Nissan Navara", "Isuzu D-Max", "Ford Everest"],
    ))
    add(make_tire(
        "bridgestone-dueler-all-terrain-at002-18", "Bridgestone", "Dueler All-Terrain A/T002",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 60, 18, 110, "T", 2025, 214.99, 245.99, 4.9, 165, 26, "A", "C", 71, 55000,
        "18-inch all-terrain 4x4 specification featuring reinforced sidewall lugs and self-cleaning shoulder channels.",
        ["Toyota Fortuner GR-S", "Ford Everest Titanium", "Mitsubishi Montero Sport GT", "Nissan Terra VL", "Toyota Hilux Conquest", "Ford Ranger Wildtrak"],
    ))
    add(make_tire(
        "bridgestone-dueler-mt-674", "Bridgestone", "Dueler M/T 674",
        "Mud Terrain Maximum Traction", "Mud-Terrain",
        265, 75, 16, 119, "Q", 2025, 239.99, 274.99, 4.8, 180, 18, "C", "E", 76, 0,
        "3D groove mud-terrain lugs eject packed clay automatically while armored 3-ply sidewalls protect against sharp rock trails.",
        ["Toyota Land Cruiser 70", "Toyota Hilux", "Jeep Wrangler", "Nissan Patrol Safari", "Isuzu D-Max", "Mitsubishi Pajero"],
    ))

    # =========================================================================
    # 4. PIRELLI
    # =========================================================================
    add(make_tire(
        "pirelli-p-zero-pz4", "Pirelli", "P Zero PZ4",
        "Max Performance Summer", "Summer",
        245, 35, 20, 95, "(Y)", 2025, 349.99, 399.99, 4.9, 390, 20, "A", "C", 72, 20000,
        "High-silica customized outer tread developed alongside exotic OEMs for rapid steering precision and planted braking.",
        ["Porsche 911", "Audi R8", "Ferrari F8 Tributo", "Mercedes-AMG GT", "BMW M5", "Chevrolet Corvette C8"],
    ))
    add(make_tire(
        "pirelli-p-zero-pz4-19", "Pirelli", "P Zero PZ4",
        "Max Performance Summer", "Summer",
        235, 35, 19, 91, "Y", 2025, 289.99, 329.99, 4.9, 270, 24, "A", "C", 71, 20000,
        "19-inch ultra-high performance summer specification delivering short wet stopping distances and sharp turn-in feel.",
        ["Volkswagen Golf R", "Audi S3", "Mercedes-AMG A45", "BMW M2", "BMW M240i", "Honda Civic Type R", "Audi S4"],
    ))
    add(make_tire(
        "pirelli-p-zero-as-plus-3", "Pirelli", "P Zero AS Plus 3",
        "Ultra High Performance All-Season", "All-Season",
        235, 45, 18, 98, "W", 2026, 214.99, 245.99, 4.9, 198, 28, "A", "C", 69, 50000,
        "All-new 3D sipe UHP all-season design providing confident four-season agility, refined acoustics, and a 50,000-mile warranty.",
        ["Tesla Model 3", "Honda Accord", "Toyota Camry Hybrid", "BYD Seal", "Polestar 2", "BMW i4"],
    ))
    add(make_tire(
        "pirelli-p-zero-elect", "Pirelli", "P Zero Elect",
        "Electric Vehicle Dedicated", "Summer EV",
        245, 45, 19, 102, "Y", 2025, 329.99, 374.99, 4.9, 170, 20, "A", "A", 68, 30000,
        "ELECT-marked structure tuned to carry battery pack weight, harness instant EV torque, and damp motor-cabin frequency hum.",
        ["Porsche Taycan", "Tesla Model S", "BMW i4 M50", "Audi e-tron GT", "Mercedes-Benz EQE", "Genesis G80 EV"],
    ))
    add(make_tire(
        "pirelli-p-zero-corsa", "Pirelli", "P Zero Corsa",
        "Street-Legal Track & Competition", "Summer Track",
        285, 30, 20, 99, "(Y)", 2025, 419.99, 479.99, 4.9, 130, 10, "B", "E", 74, 0,
        "Motorsport dual-compound track tire co-engineered with supercar manufacturers for maximum cornering stability at circuit temperatures.",
        ["McLaren 720S", "Ferrari 296 GTB", "Lamborghini Huracan STO", "Porsche 911 GT3 RS", "Aston Martin Vantage", "Ferrari F8 Tributo"],
    ))
    add(make_tire(
        "pirelli-p-zero-nero-gt", "Pirelli", "P Zero Nero GT",
        "Max Performance Summer", "Summer",
        215, 45, 17, 91, "Y", 2025, 138.99, 159.99, 4.7, 225, 32, "B", "C", 71, 30000,
        "Wide continuous central ribs increase lateral stiffness for immediate steering response on lightweight sports coupes and hot hatches.",
        ["Honda Civic Si", "Toyota GR86", "Subaru BRZ", "Volkswagen Golf GTI", "Mini Cooper S", "Mazda 3"],
    ))
    add(make_tire(
        "pirelli-cinturato-p7-c2", "Pirelli", "Cinturato P7 C2",
        "Premium Grand Touring", "Summer",
        225, 50, 17, 98, "Y", 2025, 179.99, 204.99, 4.8, 310, 42, "A", "B", 69, 45000,
        "Green Performance touring tire utilizing smart mechanical polymers that balance low fuel burn, wet security, and calm cabin refinement.",
        ["BMW 3 Series", "Mercedes-Benz C-Class 4MATIC", "Audi A4 Allroad", "Volvo S60", "Volvo V60", "Lexus ES300h"],
    ))
    add(make_tire(
        "pirelli-cinturato-p7-c2-18", "Pirelli", "Cinturato P7 C2",
        "Premium Grand Touring", "Summer",
        225, 45, 18, 95, "Y", 2025, 194.99, 224.99, 4.8, 205, 34, "A", "B", 69, 45000,
        "18-inch executive touring specification designed for responsive handling with reduced treadwear vibration.",
        ["Mercedes-Benz C-Class", "BMW 3 Series", "Audi A4", "Toyota Camry", "Tesla Model 3", "Mazda 6"],
    ))
    add(make_tire(
        "pirelli-cinturato-all-season-sf2", "Pirelli", "Cinturato All Season SF2",
        "All-Weather Grand Touring", "All-Weather",
        205, 55, 16, 94, "V", 2025, 144.99, 166.99, 4.8, 195, 36, "B", "B", 69, 50000,
        "3D Adaptive Sipe pattern interlocks on warm tarmac for stable braking and expands automatically to channel heavy rain.",
        ["Toyota Corolla Altis", "Honda Civic", "Volkswagen Golf", "Audi A3", "Mazda 3", "Hyundai Elantra", "Kia Forte"],
    ))
    add(make_tire(
        "pirelli-cinturato-p1-verde", "Pirelli", "Cinturato P1 Verde",
        "High Mileage Eco Touring", "All-Season",
        185, 65, 15, 88, "H", 2025, 84.99, 97.99, 4.6, 250, 44, "B", "A", 68, 55000,
        "Hybrid urban mobility rubber cuts rolling resistance and aerodynamic drag for nimble subcompact sedans.",
        ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift", "Hyundai Accent", "Toyota Avanza"],
    ))
    add(make_tire(
        "pirelli-scorpion-verde-all-season", "Pirelli", "Scorpion Verde All Season",
        "Highway Terrain Luxury SUV", "All-Season",
        235, 60, 18, 107, "V", 2025, 209.99, 239.99, 4.8, 340, 32, "B", "B", 71, 50000,
        "Dedicated luxury crossover highway tire lowering rolling energy consumption and external noise across premium SUVs.",
        ["Audi Q5", "Porsche Macan", "Volvo XC60", "BMW X3", "Mercedes-Benz GLC", "Toyota RAV4", "Honda CR-V"],
    ))
    add(make_tire(
        "pirelli-scorpion-ms", "Pirelli", "Scorpion MS",
        "Highway Terrain Luxury SUV", "All-Season",
        255, 55, 19, 111, "V", 2026, 279.99, 319.99, 4.9, 185, 24, "A", "B", 68, 50000,
        "Next-generation OEM SUV touring tire crafted for acoustic silence, balanced all-season traction, and electric SUV torque.",
        ["Mercedes-Benz GLE", "BMW X5", "Volvo XC90", "Audi Q7", "Lexus RX350", "Porsche Cayenne"],
    ))
    add(make_tire(
        "pirelli-scorpion-zero-all-season", "Pirelli", "Scorpion Zero All Season",
        "High Performance Luxury SUV", "All-Season",
        275, 45, 20, 110, "W", 2025, 289.99, 329.99, 4.9, 210, 18, "A", "B", 71, 45000,
        "Asymmetric UHP SUV tire engineered with prestige European automakers for crisp cornering grip across shifting weather.",
        ["Land Rover Defender", "BMW X5 M", "Porsche Cayenne", "Audi Q8", "Mercedes-Benz GLE 53 AMG", "Range Rover Sport"],
    ))
    add(make_tire(
        "pirelli-scorpion-weatheractive", "Pirelli", "Scorpion WeatherActive",
        "All-Weather SUV Touring", "All-Weather",
        235, 60, 18, 107, "V", 2026, 224.99, 256.99, 4.9, 212, 26, "B", "B", 69, 60000,
        "Directional zig-zag grooves and trumpet-shaped sipes give 3PMSF-rated all-weather confidence and quiet comfort for crossovers.",
        ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Subaru Forester", "Hyundai Tucson", "Volvo XC60", "Audi Q5"],
    ))
    add(make_tire(
        "pirelli-scorpion-all-terrain-plus", "Pirelli", "Scorpion All Terrain Plus",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 65, 17, 112, "T", 2025, 209.99, 239.99, 4.8, 280, 26, "B", "D", 72, 50000,
        "Conical stone ejectors and rugged shoulder lugs clear mud, loose gravel, and sharp rocks with disciplined highway poise.",
        ["Ford Ranger", "Toyota Hilux", "Jeep Gladiator", "Nissan Navara", "Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest"],
    ))
    add(make_tire(
        "pirelli-carrier", "Pirelli", "Carrier",
        "Commercial Van & Utility", "Summer Commercial",
        195, 70, 15, 104, "R", 2025, 114.99, 131.99, 4.7, 160, 34, "A", "C", 71, 55000,
        "Reinforced commercial van tire built to resist sidewall abrasion, carry heavy loads reliably, and prevent wet aquaplaning.",
        ["Toyota HiAce", "Nissan Urvan", "Ford Transit Custom", "Hyundai Staria Cargo", "Renault Master", "Mitsubishi L300"],
    ))

    # =========================================================================
    # 5. GOODYEAR
    # =========================================================================
    add(make_tire(
        "goodyear-eagle-f1-asymmetric-6", "Goodyear", "Eagle F1 Asymmetric 6",
        "Ultra High Performance Summer", "Summer",
        225, 40, 18, 92, "Y", 2026, 194.99, 224.99, 4.9, 420, 38, "A", "C", 70, 35000,
        "Dry Contact Plus technology adapts the contact patch under hard braking while wet micro-resin optimizes storm-road traction.",
        ["Volkswagen Golf R", "Volkswagen Golf GTI", "Honda Civic Type R", "Toyota GR Corolla", "Audi S3", "Subaru WRX", "Hyundai i30 N"],
    ))
    add(make_tire(
        "goodyear-eagle-f1-asymmetric-6-19", "Goodyear", "Eagle F1 Asymmetric 6",
        "Ultra High Performance Summer", "Summer",
        235, 35, 19, 91, "Y", 2026, 224.99, 256.99, 4.9, 285, 26, "A", "C", 70, 35000,
        "19-inch UHP summer spec engineered with sound-cancelling center rib chamfers to cut cabin noise in fast sport sedans.",
        ["BMW M240i", "Audi S3", "Volkswagen Golf R", "Mercedes-AMG A35", "Honda Civic Type R", "Subaru WRX STI"],
    ))
    add(make_tire(
        "goodyear-eagle-f1-supersport", "Goodyear", "Eagle F1 SuperSport",
        "Max Performance Summer", "Summer",
        255, 35, 19, 96, "(Y)", 2025, 279.00, 319.00, 4.9, 175, 16, "A", "D", 73, 25000,
        "Massive closed outboard shoulder ribs brace against extreme cornering loads for direct steering response on road or circuit.",
        ["BMW M3", "BMW M4", "Mercedes-AMG C63", "Audi RS5", "Ford Mustang GT", "Nissan Z", "Toyota GR Supra"],
    ))
    add(make_tire(
        "goodyear-eagle-f1-asymmetric-3-suv", "Goodyear", "Eagle F1 Asymmetric 3 SUV",
        "High Performance Luxury SUV", "Summer",
        255, 50, 20, 109, "Y", 2025, 284.99, 324.99, 4.8, 195, 20, "A", "C", 71, 35000,
        "Active Braking technology and Grip Booster resin expand road contact under deceleration for sharp performance SUV handling.",
        ["Porsche Macan", "BMW X5", "Audi Q7", "Mercedes-Benz GLE", "Range Rover Velar", "Volvo XC90", "Lexus RX350"],
    ))
    add(make_tire(
        "goodyear-assurance-weatherready-2", "Goodyear", "Assurance WeatherReady 2",
        "All-Weather Grand Touring", "All-Weather",
        225, 65, 17, 102, "H", 2026, 194.99, 222.99, 4.9, 205, 30, "B", "B", 69, 60000,
        "AquaTred Sweep grooves and 3PMSF Evolving Traction sipes earn strong wet-road stopping power across shifting seasonal weather.",
        ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Subaru Forester", "Nissan X-Trail", "Hyundai Tucson", "Kia Sportage"],
    ))
    add(make_tire(
        "goodyear-assurance-comforttred", "Goodyear", "Assurance ComfortTred",
        "Premium Touring Comfort", "All-Season",
        215, 55, 17, 94, "V", 2025, 145.00, 166.00, 4.8, 260, 40, "A", "B", 67, 55000,
        "ANX noise-insulation cushioning layer surrounds the inner tread to mute coarse asphalt buzz inside executive sedans.",
        ["Toyota Camry", "Honda Accord", "Nissan Teana", "Mazda 6", "Lexus ES300h", "Hyundai Sonata", "Kia K5"],
    ))
    add(make_tire(
        "goodyear-assurance-comforttred-16", "Goodyear", "Assurance ComfortTred",
        "Premium Touring Comfort", "All-Season",
        205, 55, 16, 91, "V", 2025, 119.00, 136.00, 4.8, 200, 44, "A", "B", 67, 55000,
        "Closed shoulder grooves and soft impact-absorbing construction minimize harsh vibration over city road joints.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sentra", "Hyundai Elantra", "Kia Forte"],
    ))
    add(make_tire(
        "goodyear-assurance-maxlife", "Goodyear", "Assurance MaxLife",
        "Standard Touring All-Season", "All-Season",
        205, 60, 16, 92, "V", 2025, 159.99, 182.99, 4.8, 342, 42, "B", "B", 69, 85000,
        "TredLife compound paired with built-in wear gauges delivers Goodyear's longest-lasting all-season commuter tread warranty.",
        ["Honda Civic", "Toyota Camry", "Hyundai Sonata", "Nissan Sentra", "Mazda 3", "Toyota Innova"],
    ))
    add(make_tire(
        "goodyear-assurance-maxguard", "Goodyear", "Assurance MaxGuard",
        "Passenger Safety Touring", "All-Season",
        185, 65, 15, 88, "H", 2025, 84.99, 97.99, 4.7, 320, 56, "A", "B", 68, 60000,
        "ActiveGrip sipes and dual-layer DuraGuard steel belts reinforce pothole resilience while shortening wet stopping distance.",
        ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Suzuki Swift", "Hyundai Accent", "Toyota Avanza"],
    ))
    add(make_tire(
        "goodyear-vector-4seasons-gen-3", "Goodyear", "Vector 4Seasons Gen-3",
        "All-Weather Grand Touring", "All-Weather",
        205, 55, 16, 94, "V", 2025, 134.99, 154.99, 4.8, 290, 40, "B", "B", 70, 50000,
        "Aqua Control deep directional channels evacuate water aggressively for year-round confident braking across rain and temperate roads.",
        ["Toyota Corolla Altis", "Honda Civic", "Volkswagen Golf", "Ford Focus", "Mazda 3", "Hyundai Elantra"],
    ))
    add(make_tire(
        "goodyear-efficientgrip-2-suv", "Goodyear", "EfficientGrip 2 SUV",
        "Highway Terrain Luxury SUV", "Summer",
        225, 65, 17, 102, "H", 2025, 172.00, 196.00, 4.8, 235, 36, "A", "B", 69, 55000,
        "Mileage Plus tread elasticity resists micro-cracking across hot highways while shorter wet braking channels improve rain safety.",
        ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Subaru Forester", "Hyundai Tucson", "Ford Territory"],
    ))
    add(make_tire(
        "goodyear-wrangler-at-silenttrac", "Goodyear", "Wrangler AT SilentTrac",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 60, 18, 110, "T", 2025, 189.99, 217.99, 4.8, 250, 34, "B", "C", 70, 55000,
        "DuraWall reinforced rubber sidewalls defend against sharp stone slashes while sound-dampening shoulder blocks keep cabin acoustics calm.",
        ["Toyota Fortuner GR-S", "Mitsubishi Montero Sport GT", "Ford Everest Titanium", "Nissan Terra VL", "Toyota Hilux Conquest", "Ford Ranger Wildtrak"],
    ))
    add(make_tire(
        "goodyear-wrangler-duratrac", "Goodyear", "Wrangler DuraTrac",
        "Rugged All-Terrain & 4x4", "All-Terrain",
        265, 70, 17, 115, "S", 2025, 249.99, 284.99, 4.8, 410, 26, "B", "E", 74, 50000,
        "TractiveGroove stepped lugs dig deep in mud and loose shale while self-cleaning shoulders shrug off sticky clay.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Jeep Wrangler", "Nissan Navara Pro-4X", "Isuzu D-Max V-Cross", "Toyota Fortuner"],
    ))
    add(make_tire(
        "goodyear-cargo-marathon-2", "Goodyear", "Cargo Marathon 2",
        "Commercial Van & Utility", "Summer Commercial",
        195, 80, 15, 106, "R", 2025, 108.99, 124.99, 4.6, 175, 42, "B", "C", 71, 55000,
        "Heavy-duty dual-steel belt carcass supports full commercial payloads over uneven city pavement and long intercity hauls.",
        ["Toyota HiAce", "Nissan NV350 Urvan", "Mitsubishi L300", "Hyundai H100", "Kia K2500", "Isuzu Traviz"],
    ))

    # =========================================================================
    # 6. YOKOHAMA
    # =========================================================================
    add(make_tire(
        "yokohama-advan-sport-v107", "Yokohama", "Advan Sport V107",
        "Ultra High Performance Summer", "Summer",
        245, 40, 19, 98, "(Y)", 2025, 259.99, 296.99, 4.8, 220, 24, "A", "C", 71, 30000,
        "Mound-profile contact footprint co-developed with prestige German automakers delivers sharp steering and uniform high-load stability.",
        ["BMW 4 Series Gran Coupe", "Audi A5 Sportback", "Mercedes-Benz E-Class Coupe", "Genesis G70", "Lexus IS350 F Sport", "BMW M340i"],
    ))
    add(make_tire(
        "yokohama-advan-apex-v601", "Yokohama", "Advan Apex V601",
        "Ultra High Performance Summer", "Summer",
        255, 35, 19, 96, "Y", 2025, 219.99, 251.99, 4.8, 240, 22, "A", "C", 71, 25000,
        "Strong center solid rib and micro-silica tread compound yield instant dry turn-in and predictable wet road evacuation.",
        ["BMW M3", "Mercedes-AMG C43", "Audi S5", "Ford Mustang GT", "Lexus RC F", "Nissan Z", "Toyota GR Supra"],
    ))
    add(make_tire(
        "yokohama-advan-neova-ad09", "Yokohama", "Advan Neova AD09",
        "Street-Legal Track & Competition", "Summer Track",
        235, 40, 18, 95, "W", 2025, 244.99, 279.99, 4.9, 280, 20, "A", "E", 74, 0,
        "Ultra-stiff casing construction and continuous asymmetric tread blocks maximize lap consistency for club track drivers.",
        ["Honda Civic", "Toyota GR86", "Subaru WRX STI", "Mitsubishi Lancer Evolution X", "Audi S3", "Volkswagen Golf R", "Hyundai Elantra N"],
    ))
    add(make_tire(
        "yokohama-advan-neova-ad09-17", "Yokohama", "Advan Neova AD09",
        "Street-Legal Track & Competition", "Summer Track",
        215, 45, 17, 91, "W", 2025, 214.99, 244.99, 4.9, 190, 22, "A", "E", 73, 0,
        "Lightweight track-ready 17-inch fitment eliminating sidewall flex under heavy trail braking on nimble sports cars.",
        ["Toyota GR86", "Subaru BRZ", "Mazda MX-5 Miata", "Honda Civic Si", "Mini Cooper S", "Volkswagen Golf GTI"],
    ))
    add(make_tire(
        "yokohama-advan-fleva-v701", "Yokohama", "Advan Fleva V701",
        "Street Performance Sport", "Summer",
        205, 45, 17, 88, "W", 2025, 131.99, 151.99, 4.7, 290, 38, "A", "C", 69, 40000,
        "Drop-groove claw pattern clears standing rain effortlessly while nano-blend polymers deliver nimble street handling.",
        ["Honda Civic", "Toyota Vios GR-S", "Mazda 2", "Suzuki Swift Sport", "Mini Cooper S", "Toyota Corolla Altis", "Kia Forte GT"],
    ))
    add(make_tire(
        "yokohama-bluearth-gt-ae51", "Yokohama", "BluEarth-GT AE51",
        "Grand Touring Comfort", "All-Season",
        215, 55, 17, 94, "V", 2025, 139.99, 159.99, 4.8, 310, 44, "A", "B", 68, 50000,
        "High-rigidity asymmetrical pattern with blade-cut lightning sipes keeps sedans planted straight and calm at expressway speeds.",
        ["Toyota Camry", "Honda Accord", "Mazda 6", "Nissan Teana", "Subaru Legacy", "Lexus ES300h"],
    ))
    add(make_tire(
        "yokohama-bluearth-es-es32", "Yokohama", "BluEarth-Es ES32",
        "High Mileage Eco Touring", "All-Season",
        185, 65, 14, 86, "H", 2025, 69.99, 81.99, 4.6, 260, 50, "B", "A", 68, 60000,
        "Nano-blend orange oil compound keeps rubber supple over hot pavement while improving mileage and wet grip.",
        ["Toyota Wigo", "Mitsubishi Mirage", "Suzuki Celerio", "Honda Brio", "Hyundai i10", "Kia Picanto"],
    ))
    add(make_tire(
        "yokohama-avid-ascend-gt", "Yokohama", "Avid Ascend GT",
        "Grand Touring All-Season", "All-Season",
        215, 55, 17, 94, "V", 2025, 144.99, 165.99, 4.8, 275, 38, "B", "B", 68, 65000,
        "TriBlend compound and asymmetric multi-pitch blocks yield long 65,000-mile tread life and hushed passenger sedan refinement.",
        ["Toyota Camry", "Honda Accord", "Nissan Teana", "Hyundai Sonata", "Kia K5", "Volkswagen Passat"],
    ))
    add(make_tire(
        "yokohama-geolandar-cv-g058", "Yokohama", "Geolandar CV G058",
        "Highway Terrain Luxury SUV", "All-Season",
        225, 60, 18, 100, "H", 2025, 178.99, 204.99, 4.8, 220, 32, "B", "B", 69, 65000,
        "CV-2 micro-silica compound and serrated center sipes provide 65,000-mile durability and wet confidence on modern crossovers.",
        ["Subaru Forester", "Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Hyundai Tucson", "Kia Sportage"],
    ))
    add(make_tire(
        "yokohama-geolandar-h-t-g056", "Yokohama", "Geolandar H/T G056",
        "Highway Terrain SUV & Truck", "All-Season",
        265, 65, 17, 112, "H", 2025, 164.99, 188.99, 4.8, 295, 30, "B", "C", 69, 70000,
        "Triple 3D sipes and Orange Oil infused blocks deliver long 70,000-mile highway tread life and low road hum on trucks and SUVs.",
        ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Toyota Hilux", "Ford Ranger"],
    ))
    add(make_tire(
        "yokohama-geolandar-at-g015", "Yokohama", "Geolandar A/T G015",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 65, 17, 112, "H", 2025, 198.99, 227.99, 4.9, 540, 38, "B", "C", 71, 60000,
        "Triple 3D sipes adapt shape as tread wears down while EdgeTec grooves maintain crisp biting edges on gravel roads.",
        ["Toyota Fortuner", "Toyota Hilux", "Ford Ranger", "Mitsubishi Montero Sport", "Nissan Navara", "Isuzu D-Max", "Ford Everest"],
    ))
    add(make_tire(
        "yokohama-geolandar-at-g015-18", "Yokohama", "Geolandar A/T G015",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 60, 18, 110, "H", 2025, 224.99, 256.99, 4.9, 310, 28, "B", "C", 71, 60000,
        "18-inch highway-friendly all-terrain fitment featuring armor-plated sidewall protectors for dual-sport pickups and SUVs.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Nissan Navara Pro-4X", "Toyota Fortuner GR-S", "Ford Everest Titanium", "Mitsubishi Montero Sport GT"],
    ))
    add(make_tire(
        "yokohama-geolandar-x-at-g016", "Yokohama", "Geolandar X-AT G016",
        "Rugged All-Terrain & 4x4", "All-Terrain",
        275, 65, 18, 116, "Q", 2025, 258.99, 294.99, 4.8, 185, 20, "B", "D", 73, 45000,
        "Extreme all-terrain hybrid offering GEO-SHIELD multi-ply strength, dual sidewall styling, and tenacious boulder bite.",
        ["Ford F-150", "Toyota Land Cruiser 300", "Nissan Patrol Nismo", "Toyota Hilux GR-S", "Ford Ranger Raptor", "Jeep Gladiator"],
    ))
    add(make_tire(
        "yokohama-geolandar-mt-g003", "Yokohama", "Geolandar M/T G003",
        "Mud Terrain Maximum Traction", "Mud-Terrain",
        285, 70, 17, 121, "Q", 2025, 274.99, 312.99, 4.9, 380, 20, "C", "E", 75, 0,
        "High-density GEO-SHIELD 3-ply casing and rock-ejector tread voids deliver ferocious mud and boulder traction.",
        ["Jeep Wrangler Rubicon", "Ford Ranger Raptor", "Toyota Land Cruiser", "Nissan Patrol Safari", "Toyota Hilux Arctic Trucks"],
    ))

    # =========================================================================
    # 7. DUNLOP
    # =========================================================================
    add(make_tire(
        "dunlop-direzza-ziii", "Dunlop", "Direzza ZIII",
        "Street-Legal Track & Competition", "Summer Track",
        205, 50, 16, 87, "V", 2025, 162.99, 185.99, 4.9, 240, 22, "B", "E", 73, 0,
        "200-treadwear competition rubber tuned with high-rigidity outer blocks for rapid steering build-up and consistent circuit heat resilience.",
        ["Mazda MX-5 Miata", "Toyota GR86", "Honda Civic Si", "Suzuki Swift Sport", "Mini Cooper S", "Subaru BRZ"],
    ))
    add(make_tire(
        "dunlop-sp-sport-maxx-060-plus", "Dunlop", "SP Sport Maxx 060+",
        "Ultra High Performance Summer", "Summer",
        245, 45, 18, 100, "Y", 2025, 195.00, 224.00, 4.8, 210, 26, "A", "C", 70, 35000,
        "High-dispersion silica tread pattern evens out footprint load across fast highway corners in premium sedans.",
        ["BMW 5 Series", "Mercedes-Benz E-Class", "Audi A6", "Lexus GS350", "Infiniti Q50", "Genesis G80", "BMW 3 Series"],
    ))
    add(make_tire(
        "dunlop-sp-sport-maxx-rt2", "Dunlop", "SP Sport Maxx RT2",
        "Ultra High Performance Summer", "Summer",
        225, 45, 17, 94, "Y", 2025, 159.99, 184.99, 4.8, 190, 28, "A", "C", 70, 30000,
        "Traction resin compound and large outer shoulder blocks tighten wet-road braking distances and cornering stability.",
        ["Subaru WRX", "Volkswagen Golf GTI", "Honda Civic Si", "BMW 2 Series", "Audi A3", "Mazda 3 Turbo"],
    ))
    add(make_tire(
        "dunlop-veuro-ve304", "Dunlop", "Veuro VE304",
        "Premium Touring Comfort", "All-Season",
        225, 55, 17, 97, "W", 2025, 164.99, 188.99, 4.9, 175, 28, "A", "B", 66, 50000,
        "Built with internal Silent Core polyurethane acoustic sponge and high-silica ribs for tranquil luxury sedan cruising.",
        ["Toyota Camry", "Honda Accord", "Lexus ES300h", "Mazda 6", "Nissan Teana", "Toyota Alphard", "Hyundai Sonata"],
    ))
    add(make_tire(
        "dunlop-enasave-ec300-plus", "Dunlop", "Enasave EC300+",
        "High Mileage Eco Touring", "All-Season",
        185, 65, 15, 88, "H", 2025, 74.99, 86.99, 4.7, 350, 52, "B", "A", 68, 60000,
        "OEM-proven low-rolling-resistance formulation cuts heat waste and boosts everyday commuter fuel economy.",
        ["Toyota Vios", "Honda City", "Mitsubishi Mirage G4", "Nissan Almera", "Toyota Avanza", "Suzuki Ertiga", "Hyundai Accent"],
    ))
    add(make_tire(
        "dunlop-grandtrek-pt3", "Dunlop", "Grandtrek PT3",
        "Highway Terrain Luxury SUV", "All-Season",
        235, 60, 18, 100, "V", 2025, 169.99, 195.99, 4.8, 225, 34, "A", "B", 69, 55000,
        "Equalized footprint pressure prevents uneven shoulder wear while full-silica ribs cut wet stopping distance for urban SUVs.",
        ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Subaru Forester", "Hyundai Tucson", "Volvo XC60"],
    ))
    add(make_tire(
        "dunlop-grandtrek-at5", "Dunlop", "Grandtrek AT5",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 65, 17, 112, "S", 2025, 184.99, 211.99, 4.8, 265, 32, "B", "C", 71, 50000,
        "Stone ejector ribs and a ruggedized cut-resistant compound tackle unpaved trails while preserving calm highway tracking.",
        ["Toyota Hilux", "Toyota Fortuner", "Mitsubishi Montero Sport", "Nissan Navara", "Ford Ranger", "Isuzu D-Max", "Ford Everest"],
    ))

    # =========================================================================
    # 8. TOYO TIRES
    # =========================================================================
    add(make_tire(
        "toyo-proxes-sport-2", "Toyo Tires", "Proxes Sport 2",
        "Ultra High Performance Summer", "Summer",
        245, 40, 19, 98, "Y", 2025, 209.99, 239.99, 4.8, 220, 26, "A", "C", 71, 30000,
        "Asymmetric Dynamic Taper ribs equalize contact load under high lateral Gs for balanced wet and dry sports performance.",
        ["BMW 4 Series Gran Coupe", "Audi A5 Sportback", "Mercedes-Benz E-Class Coupe", "Genesis G70", "Lexus IS350 F Sport", "Toyota GR Supra"],
    ))
    add(make_tire(
        "toyo-proxes-tr1", "Toyo Tires", "Proxes TR1",
        "Street Performance Sport", "Summer",
        195, 50, 16, 84, "V", 2025, 109.99, 125.99, 4.7, 290, 36, "B", "C", 70, 35000,
        "Distinctive directional V-channels clear water effectively while delivering lively steering feedback on hot hatches and roadsters.",
        ["Mazda MX-5 Miata", "Toyota Vios GR-S", "Honda City", "Suzuki Swift Sport", "Ford Fiesta", "Mini Cooper"],
    ))
    add(make_tire(
        "toyo-proxes-r888r", "Toyo Tires", "Proxes R888R",
        "Street-Legal Track & Competition", "Summer Track",
        255, 40, 18, 99, "Y", 2025, 249.99, 286.99, 4.9, 310, 16, "C", "E", 75, 0,
        "100-treadwear R-compound motorsport tire with wide center contact patch delivering fierce dry cornering grip on circuit days.",
        ["Porsche 718 Cayman", "BMW M3", "Ford Mustang GT", "Nissan 370Z", "Chevrolet Camaro SS", "Honda Civic Type R"],
    ))
    add(make_tire(
        "toyo-celsius-2", "Toyo Tires", "Celsius II",
        "All-Weather Grand Touring", "All-Weather",
        215, 60, 17, 96, "H", 2025, 139.99, 159.99, 4.7, 190, 36, "B", "B", 69, 60000,
        "Variable inner/outer sipe density delivers dependable wet and cold-weather bite alongside composed dry cornering.",
        ["Toyota Corolla Cross", "Honda HR-V", "Subaru Crosstrek", "Mazda CX-30", "Hyundai Kona", "Nissan Kicks e-Power", "Kia Seltos"],
    ))
    add(make_tire(
        "toyo-open-country-at3", "Toyo Tires", "Open Country A/T III",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 214.99, 246.99, 4.9, 610, 34, "A", "D", 71, 65000,
        "3D multi-wave sipes resist irregular treadwear while aggressive staggered shoulder lugs climb loose rock trails confidently.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Jeep Wrangler", "Isuzu D-Max V-Cross"],
    ))
    add(make_tire(
        "toyo-open-country-rt", "Toyo Tires", "Open Country R/T",
        "Rugged All-Terrain & 4x4", "All-Terrain",
        285, 65, 18, 121, "Q", 2025, 349.99, 399.99, 4.9, 320, 20, "B", "E", 73, 45000,
        "Hybrid Rugged-Terrain architecture bridges open mud-terrain shoulders with all-terrain road comfort and a 45,000-mile warranty.",
        ["Ford Ranger Raptor", "Toyota Land Cruiser 300", "Nissan Patrol", "Jeep Gladiator", "Ford F-150", "Toyota Hilux GR-S"],
    ))
    add(make_tire(
        "toyo-open-country-mt", "Toyo Tires", "Open Country M/T",
        "Mud Terrain Maximum Traction", "Mud-Terrain",
        285, 75, 16, 122, "P", 2025, 319.99, 364.99, 4.9, 480, 18, "C", "E", 76, 0,
        "Deep hook-shaped tread blocks and aggressive over-the-shoulder lugs claw through deep mud, ruts, and sharp trail obstacles.",
        ["Toyota Land Cruiser 70", "Jeep Wrangler Rubicon", "Ford Ranger Raptor", "Nissan Patrol Safari", "Isuzu D-Max", "Toyota Hilux"],
    ))

    # =========================================================================
    # 9. HANKOOK
    # =========================================================================
    add(make_tire(
        "hankook-ventus-s1-evo3", "Hankook", "Ventus S1 evo3",
        "Ultra High Performance Summer", "Summer",
        235, 40, 19, 96, "Y", 2025, 234.99, 268.99, 4.8, 290, 28, "A", "C", 70, 30000,
        "Interlocking outside grooves and high-rigidity aramid cap belt eliminate distortion at speed for keen executive sedan steering.",
        ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi S4", "Genesis G70", "Kia Stinger", "Lexus IS350 F Sport"],
    ))
    add(make_tire(
        "hankook-ion-evo-suv", "Hankook", "iON evo SUV",
        "Electric Vehicle Dedicated", "Summer EV",
        255, 45, 19, 104, "Y", 2026, 269.99, 309.99, 4.9, 230, 28, "A", "A", 66, 45000,
        "EV-dedicated structure featuring Sound Absorber acoustic foam and Evolution Compound to extend electric crossover battery range quietly.",
        ["Tesla Model Y", "Hyundai Ioniq 5", "Kia EV6", "Audi Q4 e-tron", "Genesis GV60", "BYD Sealion 7"],
    ))
    add(make_tire(
        "hankook-kinergy-4s2", "Hankook", "Kinergy 4S2",
        "All-Weather Grand Touring", "All-Weather",
        205, 55, 16, 94, "V", 2025, 129.99, 148.99, 4.8, 210, 38, "B", "C", 69, 60000,
        "High-density natural silica compound and serrated V-pattern grooves deliver fast rain drainage and 3PMSF all-weather grip.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Volkswagen Golf", "Hyundai Elantra", "Kia Forte"],
    ))
    add(make_tire(
        "hankook-dynapro-at2-xtreme", "Hankook", "Dynapro AT2 Xtreme",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 194.99, 222.99, 4.8, 340, 34, "B", "C", 71, 60000,
        "Biting multi-directional shoulder edges and noise-reducing tie-bars yield steady dirt-road bite without highway drone.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Isuzu D-Max V-Cross"],
    ))

    # =========================================================================
    # 10. KUMHO
    # =========================================================================
    add(make_tire(
        "kumho-ecsta-ps71", "Kumho", "Ecsta PS71",
        "Ultra High Performance Summer", "Summer",
        225, 45, 18, 95, "Y", 2025, 124.99, 144.99, 4.7, 250, 36, "A", "C", 71, 30000,
        "High-dispersion micro-silica compound and wide four-channel drainage grooves promote agile dry cornering and crisp wet braking.",
        ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Subaru WRX", "Hyundai Sonata", "Kia K5"],
    ))
    add(make_tire(
        "kumho-solus-ta51a", "Kumho", "Solus TA51a",
        "Grand Touring All-Season", "All-Season",
        215, 55, 17, 94, "V", 2025, 108.99, 124.99, 4.7, 215, 42, "B", "B", 68, 65000,
        "Chamfered shoulder blocks and multi-angle 3D sipes pair quiet daily road manners with a generous 65,000-mile tread life warranty.",
        ["Toyota Camry", "Honda Accord", "Hyundai Sonata", "Kia K5", "Mazda 6", "Nissan Teana"],
    ))
    add(make_tire(
        "kumho-crugen-hp71", "Kumho", "Crugen HP71",
        "Highway Terrain Luxury SUV", "All-Season",
        235, 60, 18, 103, "V", 2025, 154.99, 178.99, 4.8, 285, 34, "B", "B", 68, 65000,
        "Variable pitch block sequence breaks road noise harmonics for an ultra-quiet ride across urban and family crossovers.",
        ["Toyota RAV4", "Honda CR-V", "Hyundai Tucson", "Kia Sportage", "Mazda CX-5", "Subaru Forester", "Audi Q5"],
    ))
    add(make_tire(
        "kumho-road-venture-at52", "Kumho", "Road Venture AT52",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 179.99, 206.99, 4.8, 240, 32, "B", "D", 72, 55000,
        "Cut-and-chip resistant tread rubber with saw-tooth shoulder edges offers dependable grip over jagged trails and rainy pavement.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Isuzu D-Max V-Cross"],
    ))

    # =========================================================================
    # 11. FALKEN
    # =========================================================================
    add(make_tire(
        "falken-azenis-fk520", "Falken", "Azenis FK520",
        "Ultra High Performance Summer", "Summer",
        235, 40, 19, 96, "Y", 2025, 189.99, 218.99, 4.8, 275, 26, "A", "C", 70, 35000,
        "Motorsport-inspired aramid reinforcement stiffens belt structure for immediate steering turn-in and strong high-speed braking.",
        ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi S4", "Lexus IS350 F Sport", "Genesis G70", "Kia Stinger"],
    ))
    add(make_tire(
        "falken-ziex-ze310-ecorun", "Falken", "Ziex ZE310 Ecorun",
        "Premium Touring Comfort", "Summer",
        205, 55, 16, 91, "V", 2025, 109.99, 126.99, 4.7, 340, 42, "A", "B", 69, 50000,
        "Adaptive Constant Pressure contact shape levels footprint stress, improving wet-weather stopping grip and mileage.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sentra", "Hyundai Elantra", "Kia Forte"],
    ))
    add(make_tire(
        "falken-wildpeak-at3w", "Falken", "Wildpeak A/T3W",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 219.99, 249.99, 4.9, 520, 32, "A", "D", 72, 55000,
        "Heat Diffuser sidewall cooling technology shields internal plies while aggressive staggered upper shoulder blocks climb rough terrain.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Jeep Wrangler"],
    ))
    add(make_tire(
        "falken-wildpeak-at4w", "Falken", "Wildpeak A/T4W",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 65, 17, 112, "T", 2026, 204.99, 234.99, 4.9, 315, 30, "A", "C", 71, 65000,
        "Next-gen all-terrain flagship adding deeper tread, DURASPEC 3-ply sidewall strength, and a 65,000-mile warranty.",
        ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Isuzu mu-X", "Toyota Hilux", "Ford Ranger"],
    ))

    # =========================================================================
    # 12. BFGOODRICH
    # =========================================================================
    add(make_tire(
        "bfgoodrich-all-terrain-ta-ko2", "BFGoodrich", "All-Terrain T/A KO2",
        "Rugged All-Terrain & 4x4", "All-Terrain",
        265, 70, 17, 116, "S", 2025, 259.99, 299.99, 4.9, 780, 26, "B", "D", 73, 50000,
        "CoreGard Baja race-derived sidewall compound resists sharp rock splits while interlocking tread elements promote steady highway wear.",
        ["Toyota Hilux Conquest", "Toyota Fortuner", "Ford Ranger Wildtrak", "Jeep Wrangler", "Nissan Navara Pro-4X", "Isuzu D-Max V-Cross"],
    ))
    add(make_tire(
        "bfgoodrich-all-terrain-ta-ko3", "BFGoodrich", "All-Terrain T/A KO3",
        "Rugged All-Terrain & 4x4", "All-Terrain",
        285, 70, 17, 116, "T", 2026, 279.99, 319.99, 4.9, 360, 22, "A", "C", 71, 50000,
        "OE on the Ford Ranger Raptor with upgraded full-depth locking sipes, enhanced wet braking, and tougher gravel-road compound durability.",
        ["Ford Ranger Raptor", "Jeep Wrangler Rubicon", "Toyota Land Cruiser", "Nissan Patrol Safari", "Toyota Hilux Arctic Trucks"],
    ))
    add(make_tire(
        "bfgoodrich-trail-terrain-ta", "BFGoodrich", "Trail-Terrain T/A",
        "On-Road All-Terrain SUV & Crossover", "All-Terrain",
        225, 65, 17, 102, "H", 2025, 189.99, 217.99, 4.8, 280, 32, "B", "C", 69, 60000,
        "Serrated shoulder design handles light dirt tracks and weekend trails while maintaining quiet crossover refinement on Monday commutes.",
        ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Subaru Forester", "Nissan X-Trail", "Hyundai Tucson", "Ford Territory"],
    ))

    # =========================================================================
    # 13. MAXXIS (NEW BRAND)
    # =========================================================================
    add(make_tire(
        "maxxis-victra-sport-5", "Maxxis", "Victra Sport 5",
        "Ultra High Performance Summer", "Summer",
        225, 45, 18, 95, "Y", 2025, 118.99, 136.99, 4.7, 210, 34, "A", "C", 71, 30000,
        "Aramid-nylon cap plies and chamfered diagonal sipes offer agile dry turn-in and strong tropical downpour grip at accessible UHP value.",
        ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Subaru WRX", "Hyundai Sonata", "Kia K5"],
    ))
    add(make_tire(
        "maxxis-premitra-hp5", "Maxxis", "Premitra HP5",
        "Premium Touring Comfort", "Summer",
        205, 55, 16, 91, "V", 2025, 84.99, 97.99, 4.7, 245, 44, "A", "C", 69, 45000,
        "Full-silica touring formulation with curved shoulder noise-blocking grooves delivers crisp wet braking and low road drone.",
        ["Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Hyundai Elantra", "Kia Forte", "Nissan Sentra"],
    ))
    add(make_tire(
        "maxxis-bravo-hp-m3", "Maxxis", "Bravo HP-M3",
        "Highway Terrain Luxury SUV", "All-Season",
        225, 65, 17, 102, "H", 2025, 109.99, 126.99, 4.7, 230, 38, "B", "B", 69, 50000,
        "Cross-linked silica compound and variable-pitch blocks support stable crossover highway travel with confident rain evacuation.",
        ["Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Subaru Forester", "Nissan X-Trail", "Hyundai Tucson", "Kia Sportage"],
    ))
    add(make_tire(
        "maxxis-razr-at-811", "Maxxis", "Razr AT-811",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 65, 17, 112, "T", 2025, 194.99, 224.99, 4.8, 320, 28, "B", "D", 72, 50000,
        "Armored 3D tread blocks and dual-cord body construction fend off sidewall punctures while remaining civilized on paved highways.",
        ["Toyota Fortuner", "Toyota Hilux", "Ford Ranger", "Mitsubishi Montero Sport", "Nissan Navara", "Isuzu D-Max", "Ford Everest"],
    ))
    add(make_tire(
        "maxxis-razr-at-811-18", "Maxxis", "Razr AT-811",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 60, 18, 110, "T", 2025, 209.99, 239.99, 4.8, 195, 24, "B", "D", 72, 50000,
        "18-inch pickup and 4x4 fitment featuring armored shoulder armor lugs and stone-ejecting voids.",
        ["Toyota Fortuner GR-S", "Ford Everest Titanium", "Mitsubishi Montero Sport GT", "Nissan Terra VL", "Toyota Hilux Conquest", "Ford Ranger Wildtrak"],
    ))
    add(make_tire(
        "maxxis-razr-mt-772", "Maxxis", "Razr MT-772",
        "Mud Terrain Maximum Traction", "Mud-Terrain",
        285, 70, 17, 121, "Q", 2025, 274.99, 314.99, 4.8, 265, 18, "C", "E", 75, 0,
        "Deeply sculpted center blocks and dual-sidewall armor lugs provide fierce traction across deep ruts, loose shale, and rocky climbs.",
        ["Ford Ranger Raptor", "Jeep Wrangler Rubicon", "Toyota Land Cruiser", "Nissan Patrol Safari", "Toyota Hilux Arctic Trucks"],
    ))

    # =========================================================================
    # 14. NITTO (NEW BRAND)
    # =========================================================================
    add(make_tire(
        "nitto-nt555-g2", "Nitto", "NT555 G2",
        "Ultra High Performance Summer", "Summer",
        255, 35, 19, 96, "W", 2025, 189.99, 218.99, 4.8, 360, 26, "B", "C", 72, 0,
        "Twin center ribs and tapered outer tread blocks stabilize acceleration traction and wet cornering for muscle coupes and sport sedans.",
        ["Ford Mustang GT", "Chevrolet Camaro SS", "BMW M3", "Audi S5", "Nissan Z", "Lexus RC F", "Toyota GR Supra"],
    ))
    add(make_tire(
        "nitto-motivo-365", "Nitto", "Motivo 365",
        "All-Weather Grand Touring", "All-Weather",
        225, 45, 18, 95, "W", 2026, 159.99, 183.99, 4.8, 180, 32, "B", "C", 70, 60000,
        "Asymmetric all-weather touring tread pairs solid outer shoulder control with deep inside evacuation grooves for year-round dependability.",
        ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Subaru WRX", "Toyota Camry"],
    ))
    add(make_tire(
        "nitto-terra-grappler-g2", "Nitto", "Terra Grappler G2",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 204.99, 234.99, 4.8, 490, 30, "B", "C", 71, 65000,
        "Full-depth sipes and dual sidewall designs balance rugged weekend off-road capability with quiet 65,000-mile paved touring.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Isuzu D-Max V-Cross"],
    ))
    add(make_tire(
        "nitto-recon-grappler-at", "Nitto", "Recon Grappler A/T",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        275, 65, 18, 116, "T", 2025, 279.99, 319.99, 4.8, 275, 24, "B", "D", 72, 65000,
        "Wide zig-zag center grooves and staggered shoulder lugs blend aggressive trail capability with refined cabin acoustics.",
        ["Ford F-150", "Toyota Land Cruiser 300", "Ford Ranger Raptor", "Nissan Patrol Nismo", "Toyota Hilux GR-S", "Jeep Gladiator"],
    ))
    add(make_tire(
        "nitto-ridge-grappler", "Nitto", "Ridge Grappler",
        "Hybrid Rugged-Terrain & 4x4", "All-Terrain",
        285, 65, 18, 121, "Q", 2025, 289.99, 329.99, 4.9, 640, 22, "B", "D", 73, 0,
        "Hybrid terrain construction fuses quiet variable-pitch highway center blocks with deep mud-clearing side-biter lugs.",
        ["Ford Ranger Raptor", "Toyota Land Cruiser 300", "Jeep Gladiator", "Ford F-150", "Nissan Patrol", "Toyota Hilux GR-S"],
    ))

    # =========================================================================
    # 15. COOPER (NEW BRAND)
    # =========================================================================
    add(make_tire(
        "cooper-zeon-rs3-g1", "Cooper", "Zeon RS3-G1",
        "Ultra High Performance All-Season", "All-Season",
        245, 40, 18, 97, "W", 2025, 149.99, 172.99, 4.7, 290, 28, "B", "C", 71, 45000,
        "High-silica compound and 3D Micro-Gauge sipes hold crisp lateral grip and confident year-round highway traction.",
        ["Audi S4", "BMW M240i", "BMW M340i", "Lexus IS350 F Sport", "Ford Mustang EcoBoost", "Genesis G70", "Subaru WRX STI"],
    ))
    add(make_tire(
        "cooper-evolution-tour", "Cooper", "Evolution Tour",
        "Standard Touring All-Season", "All-Season",
        215, 60, 17, 96, "H", 2025, 129.99, 149.99, 4.7, 310, 42, "B", "B", 69, 60000,
        "Stabiledge tread stiffness maintains stable steering control while deep grooves sweep standing rainwater cleanly.",
        ["Toyota Corolla Cross", "Honda HR-V", "Subaru Crosstrek", "Mazda CX-30", "Hyundai Kona", "Kia Seltos"],
    ))
    add(make_tire(
        "cooper-discoverer-at3-4s", "Cooper", "Discoverer AT3 4S",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 209.99, 239.99, 4.8, 430, 30, "B", "C", 71, 65000,
        "Adaptive-Traction Technology pairs five-rib all-season wet braking with tough off-road durability and 65,000-mile longevity.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Isuzu D-Max V-Cross"],
    ))
    add(make_tire(
        "cooper-discoverer-road-plus-trail-at", "Cooper", "Discoverer Road+Trail AT",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        275, 55, 20, 117, "T", 2026, 204.99, 234.99, 4.8, 220, 28, "B", "C", 70, 65000,
        "Durable on- and off-road construction features jagged edge blocks and extended sidewall armor backed by a 65,000-mile warranty.",
        ["Ford F-150", "Chevrolet Silverado 1500", "Ram 1500", "Toyota Tundra", "GMC Sierra 1500", "Ford Expedition"],
    ))

    # =========================================================================
    # 16. NEXEN (NEW BRAND)
    # =========================================================================
    add(make_tire(
        "nexen-n-fera-su1", "Nexen", "N'Fera SU1",
        "Ultra High Performance Summer", "Summer",
        225, 45, 18, 95, "Y", 2025, 108.99, 124.99, 4.6, 260, 40, "A", "C", 71, 25000,
        "Asymmetric three-plus-one wide drainage channels expel water rapidly, balancing sporty highway responsiveness and affordability.",
        ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Hyundai Sonata", "Kia K5", "Mazda 6"],
    ))
    add(make_tire(
        "nexen-n-fera-sport", "Nexen", "N'Fera Sport",
        "Max Performance Summer", "Summer",
        245, 40, 19, 98, "Y", 2026, 184.99, 212.99, 4.8, 190, 26, "A", "C", 71, 25000,
        "European UHP test contender using stiff outside pattern blocks for razor-sharp high-speed lane precision and wet control.",
        ["BMW 4 Series Gran Coupe", "Audi A5 Sportback", "Genesis G70", "Lexus IS350 F Sport", "BMW M340i", "Toyota GR Supra"],
    ))
    add(make_tire(
        "nexen-n-priz-ah8", "Nexen", "N'Priz AH8",
        "Standard Touring All-Season", "All-Season",
        205, 55, 16, 91, "H", 2025, 89.99, 104.99, 4.6, 330, 50, "B", "B", 68, 70000,
        "Original equipment Hyundai and Kia all-season touring tire offering quiet highway comfort and 70,000-mile commuter durability.",
        ["Hyundai Elantra", "Kia Forte", "Toyota Corolla Altis", "Honda Civic", "Mazda 3", "Nissan Sentra"],
    ))
    add(make_tire(
        "nexen-roadian-atx", "Nexen", "Roadian ATX",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 159.99, 184.99, 4.8, 255, 34, "B", "C", 71, 70000,
        "Deep sidewall lugs, 3D self-opening sipes, and a 70,000-mile warranty provide capable dirt-road traction and smooth tarmac comfort.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Isuzu D-Max V-Cross"],
    ))

    # =========================================================================
    # 17. GT RADIAL (NEW BRAND)
    # =========================================================================
    add(make_tire(
        "gt-radial-champiro-sx2", "GT Radial", "Champiro SX2",
        "Street-Legal Track & Competition", "Summer Track",
        215, 45, 17, 87, "W", 2025, 144.99, 166.99, 4.8, 210, 24, "B", "E", 73, 0,
        "High-grip motorsports compound with Gradient Stepping shoulder geometry trusted in drifting, autocross, and club track events.",
        ["Toyota GR86", "Subaru BRZ", "Mazda MX-5 Miata", "Honda Civic Si", "Mini Cooper S", "Volkswagen Golf GTI"],
    ))
    add(make_tire(
        "gt-radial-maxtour-lx", "GT Radial", "Maxtour LX",
        "Standard Touring All-Season", "All-Season",
        215, 55, 17, 94, "V", 2025, 109.99, 126.99, 4.7, 295, 44, "B", "B", 68, 70000,
        "Harmonically tuned tread pattern dampens road cavity resonance while delivering dependable 70,000-mile grand touring longevity.",
        ["Toyota Camry", "Honda Accord", "Mazda 6", "Hyundai Sonata", "Kia K5", "Nissan Teana"],
    ))
    add(make_tire(
        "gt-radial-savero-ht2", "GT Radial", "Savero HT2",
        "Highway Terrain Luxury SUV", "All-Season",
        265, 65, 17, 112, "H", 2025, 114.99, 132.99, 4.6, 240, 38, "B", "C", 69, 50000,
        "Double steel-belt construction and four broad circumferential grooves balance heavy SUV load control and quiet highway cruising.",
        ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Isuzu mu-X", "Toyota Hilux"],
    ))
    add(make_tire(
        "gt-radial-adventuro-at3", "GT Radial", "Adventuro AT3",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 70, 17, 115, "T", 2025, 145.99, 168.99, 4.7, 325, 36, "B", "D", 72, 50000,
        "Interlocking chamfers and dual-purpose S-shaped central ribs evacuate muddy water cleanly while guarding against gravel stone retention.",
        ["Ford Ranger Wildtrak", "Toyota Hilux Conquest", "Toyota Fortuner", "Nissan Navara Pro-4X", "Mitsubishi Montero Sport", "Isuzu D-Max V-Cross"],
    ))

    # =========================================================================
    # 18. SAILUN (NEW BRAND)
    # =========================================================================
    add(make_tire(
        "sailun-atrezzo-zsr", "Sailun", "Atrezzo ZSR",
        "Ultra High Performance Summer", "Summer",
        225, 45, 18, 95, "W", 2025, 98.99, 114.99, 4.6, 215, 40, "B", "C", 71, 30000,
        "Variable-pitch asymmetric pattern lowers cabin drone while solid center ribs sharpen dry turn-in for sporty everyday sedans.",
        ["BMW 3 Series", "Mercedes-Benz C-Class", "Audi A4", "Tesla Model 3", "Hyundai Sonata", "Kia K5", "Mazda 6"],
    ))
    add(make_tire(
        "sailun-erange-ev", "Sailun", "Erange EV",
        "Electric Vehicle Dedicated", "All-Season EV",
        235, 45, 18, 98, "W", 2026, 147.99, 169.99, 4.8, 195, 34, "A", "A", 67, 45000,
        "EcoPoint3 liquid-phase mixing rubber handles high EV torque, extends battery range, and trims road noise inside electric cabins.",
        ["Tesla Model 3", "BYD Seal", "Polestar 2", "BMW i4", "Hyundai Ioniq 6", "Toyota Camry Hybrid"],
    ))
    add(make_tire(
        "sailun-atrezzo-touring-ls", "Sailun", "Atrezzo Touring LS",
        "Standard Touring All-Season", "All-Season",
        195, 65, 15, 91, "T", 2025, 80.99, 93.99, 4.6, 240, 48, "B", "B", 68, 55000,
        "Four wide evacuation channels and progressive sipe biting edges promote comfortable, reliable value for compact family cars.",
        ["Toyota Corolla Altis", "Honda Civic", "Toyota Prius", "Hyundai Elantra", "Kia Forte", "Volkswagen Golf"],
    ))
    add(make_tire(
        "sailun-terramax-a-t", "Sailun", "Terramax A/T",
        "All-Terrain Off-Road & SUV", "All-Terrain",
        265, 65, 17, 112, "T", 2025, 134.99, 155.99, 4.7, 270, 36, "B", "D", 72, 50000,
        "Three-rib solid center tracks steadily on expressways while open staggered shoulders conquer dirt roads and job-site terrain.",
        ["Toyota Fortuner", "Mitsubishi Montero Sport", "Ford Everest", "Nissan Terra", "Toyota Hilux", "Ford Ranger", "Isuzu D-Max"],
    ))

    # Extra high-demand sizes on flagship new models so new brands cover 162 SKUs total
    add(make_tire(
        "michelin-pilot-sport-all-season-4-18", "Michelin", "Pilot Sport All-Season 4",
        "Ultra High Performance All-Season", "All-Season",
        235, 45, 18, 98, "Y", 2025, 229.99, 262.99, 4.8, 260, 28, "A", "C", 71, 30000,
        "EV and executive sedan 18-inch UHP all-season fitment balancing immediate torque launch traction with 30,000-mile W/Y coverage.",
        ["Tesla Model 3", "Honda Accord", "Toyota Camry Hybrid", "BYD Seal", "BMW i4", "Polestar 2"],
    ))
    add(make_tire(
        "bridgestone-weatherpeak-18", "Bridgestone", "WeatherPeak",
        "All-Weather Grand Touring", "All-Weather",
        225, 60, 18, 100, "H", 2025, 199.99, 229.99, 4.8, 180, 28, "B", "B", 69, 70000,
        "18-inch crossover all-weather fitment certified for wet, cold, and mild wintry highways with 70,000-mile warranty protection.",
        ["Subaru Forester", "Toyota RAV4", "Honda CR-V", "Mazda CX-5", "Nissan X-Trail", "Hyundai Tucson"],
    ))
    add(make_tire(
        "nitto-ridge-grappler-17", "Nitto", "Ridge Grappler",
        "Hybrid Rugged-Terrain & 4x4", "All-Terrain",
        285, 70, 17, 116, "Q", 2025, 279.99, 319.99, 4.9, 410, 20, "B", "D", 73, 0,
        "33-inch Raptor/Rubicon hybrid terrain size combining deep shoulder lugs with quiet variable-pitch road tracking.",
        ["Ford Ranger Raptor", "Jeep Wrangler Rubicon", "Toyota Land Cruiser", "Nissan Patrol Safari", "Toyota Hilux Arctic Trucks"],
    ))
    add(make_tire(
        "sailun-erange-ev-19", "Sailun", "Erange EV",
        "Electric Vehicle Dedicated", "All-Season EV",
        255, 45, 19, 104, "W", 2026, 159.99, 184.99, 4.8, 165, 28, "A", "A", 67, 45000,
        "19-inch reinforced EV crossover specification carrying high battery weights cleanly with low rolling resistance.",
        ["Tesla Model Y", "Hyundai Ioniq 5", "Kia EV6", "Audi Q4 e-tron", "Genesis GV60", "BYD Sealion 7"],
    ))

    return tires


def validate_catalog(tires):
    ids = [t["id"] for t in tires]
    assert len(ids) == len(set(ids)), "Duplicate tire IDs found!"

    # Ensure every distinct (brand, model) maps to a unique image_asset (zero cross-model reuse!)
    asset_to_models = {}
    for t in tires:
        bm = (t["brand"], t["model"])
        asset = t["image_asset"]
        asset_to_models.setdefault(asset, set()).add(bm)
    reused = {a: sorted(m) for a, m in asset_to_models.items() if len(m) > 1}
    assert not reused, f"Images shared across distinct models: {reused}"

    # Ensure every single model image on disk is used in the catalog
    used_files = {Path(t["image_asset"]).name for t in tires}
    expected_files = set(IMAGE_BY_MODEL.values())
    assert used_files == expected_files, f"Unused or mismatched images: {expected_files ^ used_files}"


def main():
    catalog = build_catalog()
    validate_catalog(catalog)
    TARGET_JSON.write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    distinct_models = len({(t["brand"], t["model"]) for t in catalog})
    distinct_cars = len({c for t in catalog for c in t["compatible_cars"]})
    print(f"Generated {len(catalog)} SKUs across {distinct_models} unique models and {distinct_cars} unique vehicles -> {TARGET_JSON}")


if __name__ == "__main__":
    main()
