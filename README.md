# Treadly

Treadly is a Flutter app for a tire shop. Customers browse the tire catalog, find tires by size or vehicle, order and pay in the app, and chat with the shop about their order. Shop staff manage orders, stock and prices from the Treadly Desk.

Built for CCE106/L (Applications Development and Emerging Technologies).

## Features

**Customers**
- Tire catalog with search by size, brand, model or vehicle
- Category filters (Set of 4, Performance, All-Season, SUV & 4x4) and sorting
- Tire Sizing Studio: pick width, profile and rim on drawn diagrams
- Product page with specs and compatible vehicles
- Ordering with a Set of 4 discount (10%) and a ₱150 platform fee
- Payment by GCash, Maya, card or at the counter
- Order tracking: Unpaid, Placed, Confirmed, Installed (or Cancelled)
- A chat thread for every order
- Profile photo upload (cropped to a 512x512 square on the phone, stored on Cloudinary)

**Staff (Treadly Desk, for accounts with an `@treadly.com` email)**
- Live orders: confirm, decline, chat, mark as installed
- Inventory: change stock and edit prices and specs
- Analytics by period, with CSV export

## Tech stack

- Flutter / Dart
- GetX for state management and routing
- Firebase Authentication (email and password)
- Cloud Firestore for tires, orders, chats and profiles
- SharedPreferences for the cached session
- Cloudinary for profile photos (unsigned upload preset)
- DevicePreview for testing phone layouts on web

## Getting started

```bash
flutter pub get
flutter run -d chrome
```

Firebase setup:
1. Enable **Email/Password** under Authentication > Sign-in method.
2. Create staff accounts (`name@treadly.com`) under Authentication > Users. Staff can't sign up from the app.

The catalog loads from Firestore. If Firestore is empty or offline, the app uses `assets/data/tires.json` and uploads it to Firestore in the background.

## Tests

```bash
flutter test
```

- `test/pricing_test.dart` covers order pricing
- `test/app_logic_test.dart` covers order statuses, staff detection, search and the category filters
- `test/catalog_search_test.dart` checks the catalog data
- `test/image_compressor_test.dart` checks that profile photos come out as 512x512 squares

## Project layout

```
lib/
  controllers/   GetX controllers (auth, orders/chat, search, settings, home)
  core/          theme, Firebase options, pricing, shop name
  models/        tire, order (inquiry)
  services/      Firestore access, tire catalog, navigation
  views/         screens (home, search, product, orders, chat, profile, settings, staff desk)
  widgets/       shared UI pieces
assets/data/     bundled tire catalog
scripts/         Python scripts used to build tires.json
test/            unit tests
```
