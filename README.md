# 🐾 PawStay

**PawStay** is a comprehensive, pet-friendly boarding and stay management platform built with [Flutter](https://flutter.dev) and [Supabase](https://supabase.com). It bridges the gap between pet owners seeking reliable care and hosts passionate about providing a safe and comfortable home for furry friends.

Whether you're looking for a short-term stay or seeking to become a verified pet host, PawStay offers a seamless, secure, and modern experience.

---

## 🌟 Key Features

### For Pet Owners
- **🔍 Smart Search & Discovery:** Easily find local pet hosts based on location, amenities, and host ratings.
- **🐕 Pet Management:** Create detailed profiles for your pets, including their preferences, health needs, and photos.
- **📅 Real-Time Booking:** Hassle-free booking flow with integrated availability checks.
- **💳 Secure Payments:** Integrated with [Razorpay](https://razorpay.com) for safe and fast transactions.
- **💬 Direct Messaging:** In-app chat system to communicate directly with pet hosts.
- **💾 Wishlist & History:** Save your favorite hosts and keep track of all past and upcoming stays.

### For Pet Hosts
- **🏠 Become a Host:** Simple onboarding process to list your home as a pet haven.
- **📊 Host Dashboard:** Manage bookings, view earnings, and communicate with pet owners from a single view.
- **⭐ Profile Customization:** Showcase your space with photos and detailed hosting info.

---

## 🛠️ Technology Stack

- **Frontend:** [Flutter](https://flutter.dev) (Fast, Smooth, Multi-platform UI)
- **Backend:** [Supabase](https://supabase.com) (Real-time Database & Authentication)
- **AI Integration:** [Google Gemini Pro](https://deepmind.google/technologies/gemini/) (Intelligent Matching & Assistance)
- **Payments:** [Razorpay](https://razorpay.com) (Secure checkout)
- **Maps & Location:** [Geolocator](https://pub.dev/packages/geolocator) & [Geocoding](https://pub.dev/packages/geocoding)
- **Animations:** [Animations Package](https://pub.dev/packages/animations) & [Shimmer](https://pub.dev/packages/shimmer) for a premium UI feel.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
- [Dart SDK](https://dart.dev/get-started)
- A [Supabase](https://supabase.com/) project set up and its credentials.
- A [Google AI API Key](https://aistudio.google.com/) for Gemini features.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/harshshirke66/PawStay.git
   cd PawStay
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup:**
   Create a `.env` file in the root directory (the app is configured to read from it via `flutter_dotenv`) and add the following:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GEMINI_API_KEY=your_google_gemini_api_key
   RAZORPAY_KEY=your_razorpay_api_key
   ```
   *Make sure you don't commit your actual `.env` file to version control.*

4. **Run the application:**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure (Key Folders)

```text
lib/
├── models/         # Data models and business logic classes
├── screens/        # Main UI screens (Auth, Host, Owner modules)
├── services/       # External service integrations (Supabase, Razorpay, AI)
├── utils/          # Constants, formatting, and helper themes
└── widgets/        # Reusable UI components and responsive layouts
```

---

## 🤝 Contributing

Contributions are welcome! If you'd like to help improve PawStay, please follow these steps:
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/NewFeature`)
3. Commit your Changes (`git commit -m 'Add some NewFeature'`)
4. Push to the Branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

🐾 *PawStay: Taking the stress out of pet stays.*
