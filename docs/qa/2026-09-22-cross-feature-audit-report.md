# Laporan Audit Lintas Fitur

Tanggal: 22 September 2026  
Branch: `dev1-riyadh`  
Status: berjalan; baseline otomatis selesai, smoke test emulator dimulai, pengujian perangkat fisik masih menunggu

## Ringkasan

Baseline Flutter dan backend berada dalam kondisi bersih. Audit emulator menemukan satu bug UX pada interaksi filter dan notifikasi; bug tersebut sudah direproduksi melalui widget test dan diperbaiki. Tidak ada perubahan yang menyimpan frame kamera ke Neon atau penyimpanan permanen.

## Bukti baseline otomatis

| Area | Perintah | Hasil |
|---|---|---|
| Flutter static analysis | `flutter analyze` | Lulus, `No issues found!` |
| Flutter full suite sebelum perbaikan filter | `flutter test --reporter compact` | Lulus, 286 test |
| Flutter full suite setelah perbaikan filter | `flutter test --reporter compact` | Lulus, 287 test |
| Backend tests | `npm test` | Lulus, 89/89 test |
| Backend TypeScript build | `npm run build` | Lulus |
| Notifikasi dan filter | focused Flutter tests | Lulus, 7 test |
| Design detector | Impeccable detector pada komponen notice dan call site utama | Tidak ada temuan (`[]`) |

Catatan lingkungan: percobaan awal backend test di sandbox Windows menghasilkan `spawn EPERM` pada seluruh worker. Pengujian yang sama dijalankan ulang dengan izin proses turunan dan lulus 89/89; kegagalan pertama berasal dari pembatasan sandbox, bukan kode backend.

## Lingkungan emulator

- Emulator: `Medium Phone API 36.1`
- Device ID: `emulator-5554`
- Model virtual: `sdk_gphone64_x86_64`
- Resolusi tangkapan: 1080 x 2400
- Flutter: 3.44.4 stable
- Android SDK: 36.1
- APK debug berhasil dibangun dan dipasang.
- Izin lokasi yang dipakai saat smoke test: hanya saat aplikasi digunakan.
- Peningkatan Google Location Accuracy ditolak untuk menjaga skenario dasar tetap terkontrol.

## Temuan

### QA-001 — Notifikasi filter tampil di belakang drawer

- Severity: Medium
- Status: diperbaiki dan diverifikasi
- Area: Beranda → Filter Kawasan → pilihan kawasan yang belum tersedia
- Langkah reproduksi:
  1. Buka panel Filter Kawasan.
  2. Pilih `Jakarta Pusat` atau kawasan lain yang masih berstatus coming soon.
  3. Perhatikan posisi feedback.
- Hasil sebelumnya: drawer tetap terbuka; notifikasi berada pada Scaffold utama sehingga tertutup dan terpotong oleh drawer.
- Hasil yang diharapkan: drawer menutup lebih dahulu, lalu notifikasi tampil penuh di atas navigation bar.
- Akar masalah: callback menampilkan `AppNotice` melalui Scaffold utama tanpa menutup drawer.
- Perbaikan: `_showAreaComingSoon` menangkap pesan terlokalisasi, menutup drawer, lalu menampilkan notice pada frame berikutnya dari context halaman.
- Bukti otomatis: `coming-soon feedback closes the filter before appearing` lulus.

### QA-002 — Gradle mendekati batas dukungan Flutter

- Severity: Low (maintenance risk)
- Status: terbuka, tidak memblokir demo
- Bukti: build memberi peringatan bahwa Gradle 8.13.0 akan segera tidak didukung dan menyarankan minimal 8.14.0.
- Dampak saat ini: APK debug tetap berhasil dibangun.
- Tindak lanjut: upgrade Gradle wrapper dalam pekerjaan tersendiri dan verifikasi plugin Android sebelum upgrade Flutter berikutnya.

### QA-003 — Plugin masih menerapkan Kotlin Gradle Plugin lama

- Severity: Low (maintenance risk)
- Status: terbuka, tidak memblokir demo
- Plugin yang disebut build: `camera_android_camerax`, `flutter_tts`, `google_mlkit_commons`, `google_mlkit_object_detection`, `shared_preferences_android`, dan `url_launcher_android`.
- Dampak saat ini: APK debug tetap berhasil dibangun.
- Tindak lanjut: audit versi plugin dan migrasi Built-in Kotlin setelah dukungan plugin tersedia. Jangan memaksakan migrasi parsial sebelum kompatibilitas semua plugin terkonfirmasi.

### QA-004 — Frame terlewat saat cold start debug

- Severity: belum diklasifikasikan sebagai bug; observasi performa
- Status: perlu profiling
- Bukti: log emulator mencatat satu kejadian 48 frame dan satu kejadian 444 frame terlewat saat cold start, inisialisasi plugin, serta migrasi secure storage.
- Batas interpretasi: debug build dan emulator tidak mewakili performa APK release pada HP nyata.
- Tindak lanjut: ukur startup dan pipeline kamera pada profile/release build di perangkat kelas bawah serta perangkat modern. Catat median, p95, frame drop, dan memori.

## Pemeriksaan UI emulator yang sudah dilakukan

- Halaman utama tampil setelah dialog izin sistem selesai.
- Search, schematic map, kontrol zoom/lokasi, legend, dan bottom navigation terlihat tanpa overflow pada 1080 x 2400.
- Filter drawer menghormati navigation inset dan dapat discroll.
- Notifikasi informasi memakai surface terang, ikon kategori, dan posisi di atas inset bawah.
- Dialog izin Android sempat menghasilkan screenshot hitam karena permission controller menjadi activity teratas; proses aplikasi tetap hidup dan tidak mengalami crash.

## Masih harus diuji di emulator

- Navigasi lima tab dan back stack.
- Pencarian asal–tujuan, transit, jalan kaki, dan preview highlight antarnode.
- Jadwal untuk sampel rute tiap line.
- Assistant text flow untuk empat bahasa dan fallback backend offline.
- STT/TTS dasar pada emulator, dengan catatan kualitas audio emulator bukan bukti perangkat nyata.
- Tiket demo, riwayat, dan alarm perjalanan.
- Permission kamera: allow, deny, deny permanently, background/resume.

## Wajib perangkat fisik

Item berikut tidak boleh ditandai lulus hanya dari emulator:

- Rasio preview kamera pada sensor nyata; objek lingkaran harus tetap lingkaran.
- Rotasi portrait/landscape dan alignment bounding box.
- Fokus, low light, blur, glare, serta kamera tertutup.
- Latensi deteksi median/p95 dan stabilitas endless loop.
- Penggunaan memori, thermal throttling, dan frame drop.
- Perangkat Android lama/kelas bawah dan perangkat modern.
- TTS/STT dengan mikrofon dan speaker nyata.
- GPS di sekitar stasiun nyata untuk marker `Kamu di sini`.
- Verifikasi bahwa kegagalan deteksi tidak pernah menghasilkan klaim jalur aman.

## Kriteria penutupan audit

Audit dapat ditutup setelah seluruh alur emulator selesai, setiap temuan Critical/High diselesaikan, temuan Medium memiliki keputusan, dan checklist perangkat fisik mempunyai bukti pengukuran. Temuan yang belum diuji harus tetap berstatus pending, bukan diasumsikan lulus.
