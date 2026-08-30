# 📱 MahalFlow Flutter Mobile Application

Cross-platform mobile client for **Community Members** and **Mahal Administrators** built with Flutter and Dart.

---

## 🎨 UI/UX Features & Design System

- **Emerald Fintech Theme**: Primary `#0D5C3A`, Gold `#D97706`, Background `#F8FAF9`, Typography `GoogleFonts.inter`.
- **Modal Bottom Sheets (`AppBottomSheet`)**: Replaced all centered popups with slide-up modal bottom sheets featuring top drag handles, keyboard safe-area insets, and choice chips.
- **Shared Components**:
  - `ShimmerLoading`: Smooth shimmer placeholder skeletons for loading states.
  - `AppSearchBar`: Live filter search bar with clear button.
  - `AppFilterChipBar`: Rounded pill filter bar with interactive count badges.
  - `EmptyStateView`: Clean illustrations with actionable buttons for empty lists.
  - `AppMetricCard`: Glassmorphic gradient metric cards for financial aggregates.

---

## 📂 Project Structure

```
mobile-flutter/lib/
├── core/
│   ├── constants/       # AppColors, ApiEndpoints, Asset paths
│   ├── network/         # Dio ApiService with multi-host fallback engine
│   ├── utils/           # PDF receipt generator, date formatters
│   └── widgets/         # AppBottomSheet, Shimmer, SearchBar, FilterChips
├── features/
│   ├── admin/           # Dashboard, Member Directory, Gateway config, Audit Logs
│   ├── alerts/          # Notifications & Broadcast messages
│   ├── autopay/         # AutoPay mandate setups
│   ├── contribution/    # Designated fund donations
│   ├── dashboard/       # Member dues portal & summary
│   ├── dues_payment/    # Month selector & UPI payment engine
│   ├── profile/         # Member & Admin profile settings
│   └── receipts/        # Cryptographic receipt details & PDF sharing
└── main.dart            # Multi-host initialization & entrypoint
```

---

## 🚀 Running the App

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static code analyzer
flutter analyze

# 3. Launch on connected Android device / Emulator
flutter run
```
