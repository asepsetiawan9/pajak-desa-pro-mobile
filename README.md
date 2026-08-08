# 📱 LENTERA (Layanan Elektronik Terpadu Pajak Daerah) Mobile (Flutter)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2B%20Provider-059669?style=for-the-badge)](https://flutter.dev)
[![Theme](https://img.shields.io/badge/Theme-Light%20Emerald%20%26%20Glassmorphism-10B981?style=for-the-badge)](#)

Aplikasi Mobile Resmi **LENTERA (Layanan Elektronik Terpadu Pajak Daerah)** — Solusi Digitalisasikan Tata Kelola & Penagihan Pajak Bumi dan Bangunan Perdesaan dan Perkotaan (PBB-P2) berbasis Mobile Android.

---

## ✨ Fitur Utama

- **🛡️ Mobile Role Guard & Authentications**:
  - Proteksi Hak Akses khusus untuk Role **Kolektor** dan **Kepala Desa (Kades)**.
  - Multi-Dusun Auto-Filter berdasarkan wilayah penugasan kolektor.
- **📱 Floating Glass Navigation Dock**:
  - Navigasi bawah melayang *(Floating Dock)* dengan efek *Backdrop Filter Glassmorphism* dan animasi pill expanding gradient.
- **⚡ Fitur Kolektor (Kasir & Penagihan PBB-P2)**:
  - Pencarian & Filter DHKP SPPT real-time dengan *Infinite Scroll Pagination*.
  - Penyaringan berbasis status pembayaran (Terbayar/Belum Bayar), Dusun, dan Buku Pajak (Buku I-V).
  - Modal Bayar Cepat & pencatatan STTS instan.
- **📊 Fitur Kepala Desa (Executive Dashboard & Laporan 21 Kolom)**:
  - Ringkasan KPI Realisasi Pajak Desa secara real-time.
  - Laporan Rekapitulasi 21 Kolom lengkap dengan filter Buku I s/d Buku V.
- **🌐 Dynamic Server Switcher**:
  - Peralihan otomatis/manual server host dari `Android Emulator (10.0.2.2)`, `Local Desktop (127.0.0.1)`, hingga `VPS Production (backend.barudua.initd.web.id)`.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: Flutter 3.x / Dart 3.x
- **State Management**: `provider: ^6.1.2`
- **Networking**: `http: ^1.2.2`
- **Local Storage**: `shared_preferences: ^2.3.2`
- **UI & Animations**: Material 3, HSL Palette, BackdropFilter Glassmorphism, Google Fonts (`Inter`).

---

## 📁 Struktur Proyek (Clean Architecture)

```
lib/
├── core/
│   ├── constants/         # App Colors, API Endpoints, Local & VPS Host Presets
│   ├── network/           # ApiService (HTTP Client, Bearer & Platform Headers)
│   ├── storage/           # SessionManager (Token, User & Base URL Storage)
│   └── theme/             # Material 3 Light Emerald Theme
├── models/                # User, Dhkp, Transaction, Summary Metrics Models
├── providers/             # AuthProvider, DhkpProvider, PaymentProvider, SummaryProvider
└── views/
    ├── auth/              # LoginScreen & Server Host Config Selector
    ├── kolektor/          # KolektorDashboard, DhkpListScreen, Quick Payment Modal
    ├── kepaladesa/        # KadesDashboard Executive Overview & 21-Column Laporan Screen
    └── shared/            # SplashScreen & Profile Screen
```

---

## 🚀 Cara Menjalankan Project

### 1. Prasyarat
- Flutter SDK (v3.22.x atau lebih baru)
- Android Studio / VS Code + Flutter Extension
- Android Emulator / Perangkat Native Android (Developer Mode ON)

### 2. Instalasi & Setup

```bash
# Clone Repository
git clone https://github.com/asepsetiawan9/pajak-desa-pro-mobile.git

# Masuk ke direktori
cd pajak-desa-pro-mobile

# Download dependencies
flutter pub get

# Jalankan aplikasi di Emulator / Device
flutter run
```

---

## 📜 Lisensi & Pengembang

Dikembangkan dengan presisi oleh **Jarvis** untuk **Mr Zeps (Asep Setiawan)** — LENTERA Team.
