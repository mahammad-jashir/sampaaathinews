# 🚀 Sampathi News - Enterprise Kannada Digital News Portal

Sampathi News is a modern, enterprise-scale digital newsroom designed to deliver a high-performance Kannada-first reading experience. The solution utilizes a **headless WordPress CMS** as the content, reporter, and advertisement dashboard, coupled with a responsive, premium **Flutter Web** frontend.

---

## 📂 Project Architecture

```
sampaathi/
 ├── backend/plugins/sampathi-news-core/  # Custom Headless WordPress Plugin
 │    ├── sampathi-news-core.php          # Custom CPTs and REST API endpoints
 │    ├── admin/ads-dashboard.php         # WP Admin Ad reports & analytics
 │    └── includes/
 │         ├── acf-fields-bootstrap.php   # Advanced Custom Fields setup
 │         ├── wp-cron-scheduler.php      # Auto ad activation/expiration (WP Cron)
 │         └── ads-analytics-db.php       # DB Table schema & click/impression logs
 ├── web/                                 # Web resources (index.html, PWA manifest)
 ├── lib/                                 # Flutter codebase
 │    ├── main.dart                       # Entry point
 │    ├── config/                         # Routes, constants, configurations
 │    ├── themes/                         # AppTheme with Kannada typography
 │    ├── services/                       # API clients (Dio + JWT)
 │    ├── models/                         # News & Ad serialization models
 │    ├── repositories/                   # News/Ad API repositories & mock backups
 │    ├── providers/                      # State Management (Riverpod)
 │    ├── widgets/                        # Reusable banners, weather trackers
 │    └── features/                       # Modular pages (Home, Article, Search, etc.)
 └── pubspec.yaml                         # Package definitions
```

---

## ⚡ Frontend Setup (Flutter Web)

### Prerequisites
* Install Flutter SDK (Stable Channel): `https://docs.flutter.dev/get-started/install`
* Chrome / Edge for local web testing.

### Installation & Run
1. Navigate to the project root directory:
   ```bash
   cd d:\sampaathi
   ```
2. Get packages and dependencies:
   ```bash
   flutter pub get
   ```
3. Run locally in development mode:
   ```bash
   flutter run -d chrome
   ```
4. Build release bundle for web:
   ```bash
   flutter build web --release
   ```
   The compiled web output will be generated inside the `build/web/` directory.

### Deploying Frontend
* **Firebase Hosting:**
  Initialize Firebase in the project directory, select Hosting, specify `build/web` as the public folder, and deploy:
  ```bash
  firebase init hosting
  firebase deploy --only hosting
  ```
* **Vercel / Netlify:**
  Connect your repository containing the Flutter web project, set the Build Command to `flutter/bin/flutter build web --release` (or configure a custom pipeline), and the output directory to `build/web`.

---

## 🔌 Headless WordPress Backend Setup

### Prerequisites
* An active WordPress installation (Hosted on AWS, VPS, DigitalOcean, or Hostinger).
* Standard **Advanced Custom Fields (ACF)** plugin installed (for easy UI fields editing).
* JWT Authentication for WP REST API plugin (optional: if using secure subscriber login features).

### Installation
1. Zip the plugin directory located at `backend/plugins/sampathi-news-core/`.
2. Log in to your WordPress dashboard.
3. Navigate to **Plugins > Add New** and upload the zip file.
4. Activate **Sampathi News Core Integrator**.
5. Once activated, a new sidebar menu **Ad Dashboard** will appear.

### Automated Advertisement Scheduler
* The plugin registers a cron task running hourly: `sampathi_news_hourly_ads_check`.
* When an advertisement reaches its start date/time, its status changes from `scheduled` to `active`.
* When it reaches the end date/time, it changes to `expired`. Records are **never deleted**, so past booking logs are preserved for accounting.
* Ensure WP-Cron is enabled in your `wp-config.php`:
  ```php
  define('DISABLE_WP_CRON', false);
  ```
  *(For high-traffic portals, it is recommended to disable standard WP-Cron and trigger it via system crontab on your VPS/Server)*:
  ```bash
  * * * * * wget -q -O - http://yourdomain.com/wp-cron.php?doing_wp_cron >/dev/null 2>&1
  ```

---

## 📱 Scaling to Mobile (Android & iOS)

Because this project is written in **Flutter**, you can compile this exact same codebase to native Android and iOS applications with minimal configuration changes.

1. **Remove Web specific imports:**
   The `SeoHelper` utilizes `universal_html` to modify browser elements. This package is multi-platform compatible, but platform checking is handled using `kIsWeb` to prevent runtime crashes.
2. **Add Mobile dependencies:**
   Configure Firebase Cloud Messaging (FCM) in `pubspec.yaml` to support rich breaking news push notifications for mobile platforms:
   ```yaml
   firebase_messaging: ^14.7.10
   flutter_local_notifications: ^16.1.0
   ```
3. **Compile Commands:**
   * **Android APK/App Bundle:**
     ```bash
     flutter build apk --release
     flutter build appbundle --release
     ```
   * **iOS IPA:**
     ```bash
     flutter build ipa --release
     ```
