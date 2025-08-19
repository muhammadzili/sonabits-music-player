# Sonabits Music Player

![Sonabits Logo](assets/icon/sona.png)

Sonabits adalah aplikasi pemutar musik streaming modern yang dibangun menggunakan Flutter. Aplikasi ini memungkinkan pengguna untuk mendengarkan musik secara online, mengunduhnya untuk didengarkan secara offline, membuat playlist pribadi, dan menikmati lirik lagu yang tersinkronisasi.

## ✨ Fitur Utama

- **🎵 Streaming Musik**: Putar lagu favoritmu secara langsung dari server.
- **🔐 Autentikasi Pengguna**: Sistem registrasi dan login yang aman menggunakan Supabase Auth.
- **🔍 Pencarian Lagu**: Cari lagu berdasarkan judul dengan mudah.
- **❤️ Playlist Pribadi**: Buat playlist tanpa batas dan tambahkan lagu favoritmu.
- **📥 Mode Offline**: Unduh lagu untuk didengarkan kapan saja tanpa koneksi internet.
- **🎤 Lirik Sinkron**: Tampilkan lirik yang berjalan sesuai dengan waktu lagu (format .lrc).
- **🎨 UI Modern & Responsif**: Tampilan yang bersih dan menarik dengan Material 3, serta animasi yang halus.
- **⚙️ Pengaturan Fleksibel**: Atur kualitas pemutaran (Data Saver) dan durasi crossfade antar lagu.
- **🗑️ Manajemen Penyimpanan**: Hapus lagu yang sudah diunduh untuk menghemat ruang.

## 🛠️ Teknologi & Library yang Digunakan

- **Framework**: Flutter 3
- **Bahasa**: Dart
- **Backend & Database**: Supabase (Auth, Realtime Database, Storage)
- **Manajemen State**: Provider
- **Pemutar Audio**: `audioplayers`
- **Networking**: `dio` (untuk mengunduh lagu)
- **Penyimpanan Lokal**: `shared_preferences` & `path_provider`
- **UI & Animasi**:
  - `google_fonts`
  - `marquee` (untuk teks berjalan)
  - `url_launcher` (untuk membuka link eksternal)

## 🚀 Cara Menjalankan Proyek

Untuk menjalankan proyek ini di komputermu, ikuti langkah-langkah berikut:

1.  **Clone Repositori**
    ```bash
    git clone [https://github.com/muhammadzili/sonabits-music-player.git](https://github.com/muhammadzili/sonabits-music-player.git)
    cd sonabits-music-player
    ```

2.  **Install Dependencies**
    Pastikan kamu sudah menginstal Flutter SDK. Jalankan perintah berikut di terminal:
    ```bash
    flutter pub get
    ```

3.  **Konfigurasi Supabase**
    - Buka file `lib/main.dart`.
    - Ganti placeholder `YOUR_SUPABASE_URL` dan `YOUR_SUPABASE_ANON_KEY` dengan kredensial dari proyek Supabase-mu.
    ```dart
    // lib/main.dart

    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
    ```

4.  **Jalankan Aplikasi**
    Hubungkan perangkat atau jalankan emulator, lalu gunakan perintah:
    ```bash
    flutter run
    ```

## 🎵 Mengunggah Musik (Opsional)

Proyek ini menyertakan file `upload-music.html` untuk mempermudah proses pengunggahan file musik, gambar sampul, dan lirik ke Supabase Storage serta menambahkan datanya ke tabel `songs`.

1.  Buka file `upload-music.html` di browser.
2.  Masukkan kredensial Supabase (URL & Anon Key).
3.  Isi detail lagu dan pilih file yang akan diunggah.
4.  Klik tombol "Upload" untuk memulai proses.

## 👤 Author

- **Muhammad Zili** - [muhammadzili](https://github.com/muhammadzili)

## 📄 Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT - lihat file [LICENSE](LICENSE) untuk detailnya.
