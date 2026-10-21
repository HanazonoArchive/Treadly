# 🚗 Treadly

> **Premium Tire Fitting, Live Technician Inquiries & Shop Operations Management**

Treadly is a modern, high-performance Flutter application designed to bridge car enthusiasts and daily drivers directly with certified tire technicians and local shop bays. Instead of conventional e-commerce cart checkouts, Treadly delivers a streamlined **Drive-In Bay & Inquiry Platform** with real-time technician consultations, live inventory tracking, and full shop desk management.

---

## 🌟 Key Features

### 1. Driver Portal & Dynamic Catalog
- **100+ Tire Catalog**: Explore ultra-high performance (UHP), touring, all-terrain, and winter tires from top manufacturers (Michelin, Continental, Pirelli, Bridgestone, Goodyear, Yokohama).
- **Multi-Factor Search**: Instant filtering by tire dimensions (Width, Aspect Ratio, Rim Diameter), Brand, Seasonality, and exact Vehicle Model compatibility (e.g., Civic Type R, GR Yaris, WRX STI).
- **Direct Drive-In Inquiries**: Submit inquiries for specific tire models and fitment sets without tedious checkout friction.

### 2. Live Inquiry & Real-Time Technician Chat
- **Inquiry Lifecycle**: Track inquiry status in real time across 3 streamlined phases:
  - 🟡 **Submitted**: Customer request sent; awaiting technician review.
  - 🔵 **Responded**: Technician reviewed stock and initiated active consultation.
  - 🟢 **Completed**: In-bay installation finished and inquiry archived.
- **Bi-directional Live Chat**: Real-time messaging between car owners and shop technicians with auto-scrolling to the latest updates, message bubbles, and unread badge clearing upon completion.
- **Workflow Integrity**: Built-in safeguards prevent cancellation of completed jobs while enabling customer cancellation of pending inquiries.

### 3. Treadly Desk (Staff Operations Portal)
- **Role-Aware Portal**: Access the official shop technician desk using verified credentials (`@treadly.com`).
- **Inquiry Management & Filters**: Segment and respond to driver inquiries with dedicated tab filters (**All**, **Inquiries**, **Responded**, and **Completed**).
- **Inventory & Specification Adjustments**:
  - Live stock adjustment: Quick tap to increment, decrement, or restock tire inventory directly.
  - Specification editing: Modify pricing, dimensions, load index, and speed ratings in real time.
- **Shop Location Management (CRUD)**:
  - Add, edit, and switch active shop desk locations (e.g., Makati Flagship Bay, Quezon City Hub, BGC Express Bay).
  - Manage bay capabilities, operating hours, and active technician assignments.

### 4. Account & Driver Profile
- **Session Modes**: Seamless support for both Authenticated Drivers and Guest browsing.
- **Help Center & Fitment Guide**: Integrated tire sizing guides, wheel care advice, and instant emergency hotline access.
- **Secure Account Control**: Profile updating and self-service account termination with automated cleanup.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev/) (Channel Stable 3.x, Dart 3.x) |
| **State Management** | [GetX](https://pub.dev/packages/get) (Reactive `.obs`, `GetxController`, Micro-dependency Injection) |
| **Cloud Database** | [Google Firebase Cloud Firestore](https://firebase.google.com/) (Real-time synchronization for tires, inquiries, chat messages, profiles, and shop desks) |
| **Local Persistence** | `SharedPreferences` (Local user sessions and desk selections) |
| **Design System** | Custom Dark Theme (`AppTheme.dark`), Glassmorphism, [Lucide Icons](https://pub.dev/packages/lucide_icons_flutter) |
| **Multi-Device Testing**| [DevicePreview](https://pub.dev/packages/device_preview) for cross-platform viewport validation |

---

## 📁 Project Structure

```text
lib/
├── controllers/              # GetX state controllers
│   ├── auth_controller.dart          # Driver & staff authentication session
│   ├── inquiry/
│   │   └── inquiry_controller.dart   # Inquiry pipeline, chat messaging, and badge counts
│   ├── navigation_controller.dart    # Bottom navigation bar state
│   ├── profile/
│   │   └── top_nav_bar_controller.dart
│   ├── search/
│   │   └── search_controller.dart    # Catalog filtering and car compatibility matching
│   ├── settings_controller.dart      # User preferences and danger zone actions
│   ├── sync_controller.dart          # Firebase session coordination
│   └── treadly_desk/
│       └── treadly_desk_controller.dart # Staff inventory CRUD, branch locations, desk filters
├── core/                     # App-wide constants & configuration
│   ├── app_theme.dart                # Curated dark color palette and typography
│   └── firebase_options.dart         # Generated Firebase platform options
├── models/                   # Data transfer objects
│   ├── branch.dart                   # Shop desk / bay location model
│   ├── inquiry.dart                  # Customer inquiry & chat message models
│   └── tire.dart                     # Rich tire model with specifications & vehicle compatibility
├── services/                 # Remote and local data services
│   ├── firebase_sync_service.dart    # Firestore catalog and user sync service
│   └── tire_repository.dart          # Tire catalog repository with Firestore & local fallback
├── views/                    # Primary application screens
│   ├── auth/                         # Sign In & Sign Up views
│   ├── home_view.dart                # Root scaffold with bottom navigation
│   ├── inquiries_view.dart           # Driver inquiry tracking and conversation modal
│   ├── product_view.dart             # Tire details, vehicle compatibility, and inquiry trigger
│   ├── profile_view.dart             # Driver profile and account services
│   ├── search_input_view.dart        # Search overlay with quick filters
│   ├── settings_view.dart            # Settings and preferences view
│   └── treadly_desk/
│       └── treadly_desk_view.dart    # Staff Operations Desk (Inquiries, Inventory, Branches)
└── widgets/                  # Modular, reusable UI components
    ├── common/                       # Navigation bars, search chips, and badges
    ├── inquiries/                    # Conversation chat sheet and inquiry status cards
    ├── product/                      # Image carousels, specification rows, compatibility list
    ├── profile/                      # Support modals and account cards
    └── treadly_desk/                 # Stock modifier dialogs, branch CRUD modals, inquiry filters
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.13 or newer)
- [Dart SDK](https://dart.dev/get-dart) (3.x)
- Chrome (for Web development) or Android SDK / Device (for mobile development)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/Treadly.git
   cd Treadly
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify analyzer diagnostics**:
   ```bash
   dart analyze lib
   ```

4. **Run the development server**:
   - **Web (with DevicePreview)**:
     ```bash
     flutter run -d chrome
     # Or run headless web-server:
     flutter run -d web-server --web-port 8080
     ```
   - **Android / Windows**:
     ```bash
     flutter run -d windows
     # or
     flutter run -d android
     ```

---

## 🧪 Testing

Run automated tests covering catalog loading, specifications, and widget rendering:
```bash
flutter test
```

---

## 🔒 Security & Data Rules
- Live inquiries and conversations are keyed to authenticated user IDs and staff roles.
- Customer inquiries automatically isolate customer records upon sign-out.
- Completed inquiries are locked to preserve audit history and prevent erroneous status regressions.

---

## 📄 License
This project is licensed under the MIT License — see the LICENSE file for details.
