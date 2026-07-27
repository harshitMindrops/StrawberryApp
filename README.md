<div align="center">

<img src="strawberry/assets/images/logo.png" alt="Strawberry App Logo" width="120"/>

# 🍓 Strawberry — Preschool & Daycare App

**A cross-platform mobile app built for Strawberry Preschool & Daycare, connecting parents and school administrators in one simple, friendly app.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Messaging-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)]()

</div>

---

## 📖 About the Project

**Strawberry** is a full-featured mobile application I built end-to-end for a real client — **Strawberry Preschool & Daycare**. It replaces the school's manual, paper-based processes (attendance registers, notice boards, WhatsApp groups for updates) with one clean, easy-to-use app for both **parents/students** and **school admins**.

The app has two experiences in a single codebase:
- 👨‍👩‍👧 **Parent/Student side** — track attendance, view photo galleries from school events, read notices, and chat directly with the school admin.
- 🧑‍💼 **Admin side** — a complete management dashboard to approve new admissions, mark daily attendance, post notices, manage the photo gallery, view analytics, and chat with parents.

It's built with **Flutter**, so the same codebase runs on Android and iOS, and can also be extended to web and desktop.

---

## ✨ Features

### For Parents / Students 👨‍👩‍👧‍👦
- 🔐 **Simple Google Sign-In** — no passwords, just one tap to log in.
- ⏳ **Admission approval flow** — new sign-ups wait for admin approval before getting access.
- 📅 **Attendance tracking** — view daily and monthly attendance records.
- 🖼️ **Photo gallery** — browse photos from school events and activities.
- 📢 **Notice board** — get the latest announcements from the school.
- 💬 **Chat with admin** — direct in-app messaging with the school administration.
- 🔔 **Push notifications** — real-time alerts for new notices, chat messages, and updates.

### For Admins 🧑‍💼
- 📊 **Admin dashboard** — a complete overview of students, pending requests, and chats in one place.
- ✅ **Manage admission requests** — approve or reject new student sign-ups, and assign admission type & fees.
- 🗓️ **Mark attendance** — quick, daily attendance marking for every student.
- 📈 **Review & Analytics** — see total students, new admissions, category-wise breakdown, and day-wise/monthly attendance trends, with a GitHub-style attendance heatmap per student.
- 📤 **Export to Excel** — download or share monthly attendance reports as `.xlsx` files (via WhatsApp, email, drive, etc.).
- 🖼️ **Gallery management** — upload and organize event photos for parents to view.
- 📢 **Notice management** — create and publish notices to all parents instantly.
- 🏷️ **Category management** — organize students into custom categories/classes.
- 👥 **Manage other admins** — add or remove pre-authorized admin accounts.
- 💬 **Chat support** — respond to parent messages directly from the dashboard.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (Dart) |
| **Authentication** | Firebase Auth + Google Sign-In |
| **Database & Backend** | [Supabase](https://supabase.com) (Postgres) |
| **Push Notifications** | Firebase Cloud Messaging + `flutter_local_notifications` |
| **File Handling** | `image_picker`, `flutter_image_compress`, `path_provider` |
| **Reports** | `excel` package for generating `.xlsx` attendance reports |
| **Sharing** | `share_plus` for sharing exported reports |
| **State/Local Storage** | `shared_preferences` |

---

## 📂 Project Structure

```
strawberry/
├── lib/
│   ├── core/                  # Firebase & Supabase configuration
│   ├── features/
│   │   ├── auth/              # Login, Google Sign-In, push notification setup
│   │   ├── chat/              # In-app chat between parents and admin
│   │   ├── splash/            # Splash screen & routing logic
│   │   └── dashboard/
│   │       ├── admin/         # Admin dashboard, attendance, gallery, notices,
│   │       │                  # analytics, categories, manage-admins
│   │       └── student/       # Parent/student home, attendance, gallery, notices
│   └── main.dart
├── assets/images/              # App logo & icons
├── android/ · ios/ · web/ · windows/ · macos/ · linux/   # Platform-specific projects
└── pubspec.yaml                # Project dependencies
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- A [Firebase](https://console.firebase.google.com) project (Auth + Cloud Messaging enabled)
- A [Supabase](https://supabase.com) project (database + tables set up)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/harshitMindrops/StrawberryApp.git
   cd StrawberryApp/strawberry
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Add your own backend keys**
   - Add your Firebase config in `lib/core/firebase_config.dart`
   - Add your Supabase URL & anon key in `lib/core/supabase_config.dart`
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from the Firebase console.

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 👨‍💻 My Role

I designed and developed this app **end-to-end** for the Strawberry Preschool & Daycare client — including the UI/UX, the admin dashboard, the parent-facing app, attendance & analytics system, chat feature, and backend integration with Firebase and Supabase.

---

## 📄 License

This project was built as freelance client work. Feel free to explore the code for learning purposes.

</div>
