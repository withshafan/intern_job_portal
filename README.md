<div align="center">
  <img src="assets/icon/app_icon.jpg" width="150" height="150" alt="Intern Job Logo"/>
  <h1>Intern Job (formerly InternHub)</h1>
  <p>A modern, premium, and scalable Flutter application for streamlined intern task management, progress tracking, and seamless collaboration.</p>

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
</div>

<br/>

## 📖 Overview

**Intern Job** is a role-based task management system designed to bridge the gap between administrators/mentors and interns. Built with a focus on **UI/UX excellence**, it features a beautiful custom-designed theme, smooth micro-interactions, real-time data sync, and interactive analytics.

## ✨ Key Features

### 🛡️ Role-Based Access Control
- **Admin Dashboard:** Get a bird's-eye view of all interns, task distribution (pending, in-progress, completed), and individual progress metrics.
- **Intern Workspace:** A personalized workspace to view assigned tasks, update task statuses, and track personal completion rates.

### ⚡ Real-Time Task Management
- Create, assign, and track tasks instantly using **Firebase Cloud Firestore**.
- Assign deadlines and visually highlight overdue tasks.
- Integrated **Real-Time Comments** on task details for seamless mentor-intern collaboration.

### 🎨 Premium UI/UX & Animations
- **Modern Aesthetic:** Deep Indigo and Teal color palette with subtle gradients, soft shadows, and rounded glassmorphism-inspired cards.
- **Micro-Interactions:** Staggered list animations, Hero transitions for task details, and beautifully crafted Shimmer loading effects.
- **Typography:** Sleek and readable typography using Google Fonts (Poppins/Inter).

### 📊 Interactive Analytics & Progress
- Dynamic **Pie Charts** and **Progress Bars** (powered by `fl_chart`) to visualize task completion rates and statuses instantly.
- Detailed statistical breakdowns per intern for admins.

### 👤 Profile & Account Management
- Secure authentication via **Firebase Auth**.
- Profile picture uploads via **Firebase Storage** & `image_picker`.

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Backend & Database:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **UI Components:** 
  - `fl_chart` (Analytics & Charts)
  - `google_fonts` (Typography)
  - `flutter_staggered_animations` & `shimmer` (Visual Effects)
- **Tooling:** `flutter_launcher_icons`

## 📁 Project Structure

```text
lib/
├── main.dart                 # App entry point & Provider setup
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models (AppUser, Task, TaskComment)
├── providers/                # State management (AuthProvider, TaskProvider)
├── screens/                  # UI Screens
│   ├── splash_screen.dart    # Animated loading & auth routing
│   ├── login_screen.dart     # User login
│   ├── signup_screen.dart    # User registration (Role selection)
│   ├── home_screen.dart      # Main dashboard with bottom navigation
│   ├── tasks_screen.dart     # Task list with filtering
│   ├── create_task_screen.dart # Form to assign/create tasks
│   ├── task_detail_screen.dart # Detailed view & comment stream
│   └── progress_screen.dart  # Charts and analytics view
├── services/                 # API & Firebase logic
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── task_service.dart
│   └── notification_service.dart
├── theme/                    # Design System
│   └── app_theme.dart        # Custom light/dark themes & design tokens
└── widgets/                  # Reusable UI components
    ├── app_drawer.dart       # Custom navigation drawer
    └── task_card.dart        # Premium task list item
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.10.0 or higher)
- Dart SDK
- Android Studio / VS Code
- A Firebase project configured for Android and iOS

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/withshafan/intern_job_portal.git
   cd intern_job_portal
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Make sure you have your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in their respective directories if you are setting up a new Firebase backend, or rely on the generated `firebase_options.dart` if using FlutterFire CLI.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Screenshots

*(Add your beautiful app screenshots here)*
<div align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Login" width="200"/>
  <img src="https://via.placeholder.com/250x500.png?text=Dashboard" width="200"/>
  <img src="https://via.placeholder.com/250x500.png?text=Task+Details" width="200"/>
</div>

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/withshafan/intern_job_portal/issues).

## 📄 License
This project is licensed under the MIT License.
