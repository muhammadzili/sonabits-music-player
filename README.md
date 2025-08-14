# Sonabits 🎵

Sonabits adalah aplikasi pemutar musik open-source yang dibuat dengan Flutter dan Supabase, terinspirasi dari antarmuka Spotify dengan gaya Material 3.

![Sonabits Screenshot](https://i.ibb.co.com/j9CCwPYC/Screenshot-2025-08-14-192322.png) 

## Fitur Utama
- 🎵 Streaming musik dari Supabase Storage.
- 🎨 Antarmuka modern dengan Material 3.
- 🔍 Pencarian lagu dan artis.
- 📂 Sistem playlist yang disimpan secara lokal.
- ⚙️ Pengaturan aplikasi (Data Saver, Crossfade).
- 🔐 Otentikasi pengguna (Login & Register).

## Teknologi yang Digunakan
- **Framework:** Flutter
- **Backend:** Supabase (Database, Auth, Storage)
- **State Management:** Provider
- **Audio Player:** audioplayers
- **Penyimpanan Lokal:** shared_preferences

## Cara Menjalankan Proyek

1.  **Clone repositori ini:**
    ```bash
    git clone https://github.com/muhammadzili/sonabits-music-player.git
    cd sonabits
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Konfigurasi Supabase:**
    * Buka file `lib/main.dart`.
    * Ganti placeholder `YOUR_SUPABASE_URL` dan `YOUR_SUPABASE_ANON_KEY` dengan kunci dari proyek Supabase Anda.
    
4.  **Jalankan aplikasi:**
    ```bash
    flutter run
    ```

## Kontribusi
Kontribusi sangat diterima! Silakan buat *fork* dari repositori ini dan ajukan *pull request* untuk menambahkan fitur atau perbaikan.

## Lisensi
Proyek ini dilisensikan di bawah [Lisensi MIT](LICENSE).
