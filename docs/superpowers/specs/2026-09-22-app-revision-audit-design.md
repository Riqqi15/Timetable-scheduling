# Dokumen Revisi Aplikasi Berdasarkan Audit dan Brainstorming

Tanggal: 22 September 2026  
Status: siap ditinjau sebelum penyusunan rencana implementasi  
Branch acuan: `dev1-riyadh`

## 1. Tujuan

Dokumen ini merangkum revisi yang disepakati untuk aplikasi Timetable Scheduling setelah audit kode, evaluasi UI, dan pembahasan kebutuhan dosen. Revisi berfokus pada empat area:

1. Konsistensi bahasa chatbot, voice input, dan voice output.
2. Preview kamera yang tidak stretch serta pemrosesan deteksi yang mengutamakan keselamatan.
3. Sistem notifikasi yang kontekstual dan tidak menutupi konten penting.
4. Audit menyeluruh terhadap fitur aplikasi sebelum demonstrasi dan distribusi APK.

Dokumen ini merupakan spesifikasi desain dan kriteria keberhasilan. Pelatihan model YOLO dan penyusunan dataset tetap dikelola sebagai pekerjaan terpisah di folder proyek AI Camera.

## 2. Temuan Audit Saat Ini

### 2.1 Bahasa asisten

- Halaman asisten sudah membaca locale aplikasi dan mengirimkan kode bahasa ke controller.
- Speech recognition sudah mencoba memilih locale perangkat berdasarkan bahasa aplikasi.
- Backend dan beberapa layanan TTS belum konsisten menangani semua bahasa yang didukung aplikasi.
- Aplikasi mendukung Bahasa Indonesia, Inggris, Mandarin Sederhana, dan Arab, tetapi terdapat layanan yang hanya membedakan Inggris dan Indonesia.
- Respons percakapan masih perlu mempertahankan konteks antarpesan agar pertanyaan lanjutan terdengar alami.

### 2.2 Kamera

- `CameraPreview` ditempatkan langsung di dalam `Stack(fit: StackFit.expand)`. Constraint penuh dari parent berpotensi memaksa preview mengikuti rasio layar dan menyebabkan gambar terlihat gepeng pada perangkat tertentu.
- Kamera menggunakan `ResolutionPreset.medium`, yang sesuai sebagai baseline untuk perangkat kelas bawah dan menengah.
- Pemrosesan lokal sudah membatasi satu frame aktif melalui flag `_busy`, sehingga frame tidak menumpuk.
- Rotasi input hanya memakai `sensorOrientation`. Koreksi akhir juga harus memperhitungkan orientasi perangkat.
- ML Kit saat ini mengaktifkan deteksi banyak objek dan klasifikasi sekaligus. Konfigurasi tersebut dapat menurunkan framerate pada perangkat lemah.
- Permintaan vision ke backend dilakukan berkala dan tidak boleh diperlakukan sebagai mekanisme keselamatan real-time.
- Belum ada pengukuran latensi per tahap, indikator kualitas frame, atau status eksplisit ketika hasil deteksi tidak dapat dipercaya.
- Tidak ada kebutuhan untuk menyimpan frame kamera atau gambar hasil deteksi di Neon. Frame hanya boleh hidup sementara di memori selama proses analisis.

### 2.3 Notifikasi

- Banyak fitur masih membuat `SnackBar` bawaan secara langsung.
- Tampilan, posisi, durasi, ikon, dan perilaku notifikasi belum dikelola oleh satu komponen bersama.
- Pesan lokasi pada peta pernah menutupi area visual yang penting.
- Notifikasi kamera keselamatan tidak boleh memakai snackbar singkat karena statusnya harus selalu terlihat dan terdengar.

### 2.4 Quality assurance

- Pengujian unit dan widget sudah tersedia untuk beberapa fitur, tetapi belum ada satu audit lintas fitur, lintas bahasa, lintas ukuran layar, dan lintas kondisi jaringan.
- Pengujian kamera harus dilakukan pada perangkat fisik. Emulator tidak cukup untuk menilai rasio sensor, performa, fokus, kondisi cahaya, atau dukungan depth.

## 3. Revisi Bahasa Chatbot dan Voice Assistant

### 3.1 Perilaku utama

- Bahasa percakapan mengikuti bahasa yang dipilih di pengaturan aplikasi, bukan semata-mata bahasa sistem perangkat.
- STT, teks permintaan backend, respons chatbot, TTS, pesan error, placeholder, dan tombol harus menggunakan locale yang sama.
- Locale yang didukung adalah:
  - `id-ID` untuk Bahasa Indonesia.
  - `en-US` untuk Bahasa Inggris.
  - `zh-CN` untuk Mandarin Sederhana.
  - `ar-SA` untuk Bahasa Arab.
- Jika suara TTS khusus locale tidak tersedia, aplikasi memilih suara lain dalam bahasa yang sama. Aplikasi tidak boleh diam-diam membacakan bahasa berbeda.
- Konteks percakapan aktif harus diteruskan secara ringkas agar pertanyaan lanjutan seperti “tujuannya Jakarta Kota” tetap mengacu pada asal yang disebutkan sebelumnya.
- Percakapan ringan tetap dijawab secara natural, tetapi konteks dibatasi pada perjalanan KRL, jadwal, stasiun, tiket, aksesibilitas, dan fitur aplikasi agar penggunaan Gemini tetap hemat.

### 3.2 Kegagalan dan fallback

- Jika STT tidak tersedia, input teks tetap dapat digunakan.
- Jika TTS gagal, jawaban teks tetap tampil dan tersedia tombol untuk mencoba membacakan kembali.
- Jika backend tidak dapat memproses locale tertentu, aplikasi menampilkan pesan yang sudah diterjemahkan dan tidak mengganti bahasa respons tanpa pemberitahuan.
- Riwayat yang dikirim ke backend dibatasi pada beberapa giliran relevan, bukan seluruh percakapan tanpa batas.

## 4. Revisi Preview dan Pemrosesan Kamera

### 4.1 Keputusan desain preview

Preview menggunakan bingkai vertikal menyerupai area pemindaian QRIS, tetapi tidak memakai rasio persegi tetap. Ukuran preview berasal dari `CameraController.value.previewSize` dan orientasi perangkat.

Aturan tampilan:

- Preview mempertahankan rasio asli sensor.
- Perilaku visual setara `FIT_CENTER`: seluruh frame terlihat dan letterboxing kecil diperbolehkan.
- `BoxFit.fill` dilarang karena mendistorsi gambar.
- `BoxFit.cover` tidak digunakan untuk mode keselamatan karena dapat memotong objek di tepi frame.
- Preview memiliki batas halus dan sudut membulat agar terpisah dari header dan panel status.
- Bingkai panduan area berjalan ditampilkan pada bagian tengah-bawah, tetapi seluruh frame tetap dianalisis.
- Bounding box dan label harus dipetakan dengan transformasi rotasi, skala, serta offset yang sama dengan preview.
- Preview ditujukan untuk pengguna awas, pendamping, pengujian, dan demonstrasi. Bagi pengguna tunanetra, keluaran utama tetap suara dan getaran.

### 4.2 Tata letak

Urutan halaman kamera:

1. Header berisi tombol kembali, judul, dan indikator status sistem.
2. Preview kamera berasio asli di tengah halaman.
3. Overlay area berjalan, bounding box, dan label objek di atas preview.
4. Panel status keselamatan di bawah preview.
5. Tombol hentikan atau mulai ulang panduan sebagai tindakan utama.

Panel status memakai tiga tingkat:

- Netral: sistem aktif dan sedang memindai.
- Peringatan: kualitas frame, performa, atau confidence menurun.
- Bahaya: hambatan dekat, perubahan ketinggian, lubang, atau jalur tertutup yang menuntut pengguna berhenti.

Status netral tidak menggunakan kata “aman”. Kalimat yang diperbolehkan adalah “tidak ada hambatan yang terdeteksi saat ini”.

### 4.3 Pipeline analisis

Alur data yang disepakati:

```text
CameraImage mentah
  -> normalisasi rotasi dan orientasi
  -> resize dengan letterbox tanpa stretching
  -> detektor lokal/YOLO
  -> pemetaan bounding box ke preview
  -> penilaian area berjalan dan tingkat bahaya
  -> UI + suara + getaran
  -> analisis backend opsional untuk deskripsi tambahan
```

Ketentuan teknis:

- Preview dan input model boleh memiliki resolusi berbeda.
- Input model diperkecil dengan mempertahankan rasio dan padding/letterbox.
- Hanya satu frame boleh dianalisis dalam satu waktu.
- Saat analyzer sibuk, frame lama dibuang dan frame terbaru yang dipilih.
- Resolusi awal tetap kelas medium. Sistem dapat menurunkan input analisis pada perangkat lambat tanpa menurunkan ukuran visual preview secara paksa.
- Target perangkat normal adalah 10–15 inferensi per detik.
- Batas minimum operasional adalah 5 inferensi per detik atau satu hasil maksimal setiap 200 ms.
- Latensi diukur dari penerimaan frame sampai peringatan tersedia, menggunakan metrik median dan p95.
- Jika p95 berulang kali melebihi 200 ms, sistem menurunkan beban analisis dan memberi tahu bahwa mode performa rendah sedang digunakan.
- Analisis backend tidak menjadi sumber peringatan utama karena jaringan tidak menjamin latensi dan ketersediaan.

### 4.4 Estimasi jarak

- Bounding box YOLO dari kamera monokular tidak cukup untuk menjamin jarak absolut 5 meter.
- Mode dasar menggunakan zona risiko seperti sangat dekat, dekat, dan terdeteksi di depan.
- Penyebutan jarak meter hanya diaktifkan jika depth tersedia dan confidence memenuhi ambang yang sudah diuji.
- ARCore Depth dapat digunakan sebagai peningkatan opsional pada perangkat yang mendukungnya.
- Perangkat tanpa dukungan depth tetap dapat memakai deteksi objek, tetapi tidak menampilkan jarak sebagai ukuran pasti.

### 4.5 Fail-safe

Sistem menghentikan panduan arah dan meminta pengguna berhenti ketika salah satu kondisi berikut terjadi:

- Kamera tertutup atau frame tidak berubah.
- Pencahayaan terlalu gelap atau terlalu terang.
- Blur berlebihan atau perangkat bergerak terlalu cepat.
- Detektor mengalami error atau tidak menghasilkan heartbeat.
- Latensi melampaui batas secara terus-menerus.
- Suhu atau memori menyebabkan pipeline tidak stabil.
- Confidence objek atau depth terlalu rendah untuk membuat keputusan.
- Orientasi kamera tidak mengarah ke area berjalan.

Peringatan fail-safe harus diberikan melalui teks, suara, dan pola getaran yang berbeda dari notifikasi biasa. Sistem tidak boleh menyatakan jalur aman berdasarkan ketiadaan deteksi. Fitur ini merupakan alat bantu dan bukan pengganti tongkat, jalur pemandu, atau pendamping manusia.

Objek transparan, reflektif, kabel tipis, permukaan minim tekstur, dan kondisi pencahayaan ekstrem harus disebut sebagai keterbatasan. Tidak ada klaim bahwa kamera biasa dapat selalu mendeteksi kondisi tersebut.

## 5. Revisi Sistem Notifikasi

Semua feedback non-kamera menggunakan satu layanan dan komponen notifikasi bersama agar tampil konsisten.

### 5.1 Aturan penempatan

| Kondisi | Komponen | Posisi dan perilaku |
|---|---|---|
| Aksi berhasil | Floating notification ringan | Bagian atas, 2–3 detik, tidak menutupi kontrol utama |
| Informasi biasa | Snackbar ringan | Bagian bawah di atas navigation bar |
| Kesalahan input | Pesan inline | Dekat field atau tindakan yang bermasalah |
| Kesalahan jaringan pada halaman | Inline banner | Di dalam konten dan dapat dicoba ulang |
| Kegagalan total memuat halaman | Full-page error state | Menggantikan konten dengan tombol coba lagi |
| Izin kamera/lokasi penting | Dialog atau bottom sheet | Memerlukan keputusan pengguna |
| Status lokasi peta | Chip/status ringkas | Di bawah pencarian atau menjadi kontrol peta yang dapat diciutkan |
| Peringatan kamera | Safety status panel | Persisten selama mode kamera aktif; bukan snackbar |

### 5.2 Gaya visual

- Hanya tema terang yang digunakan.
- Font mengikuti font sistem aplikasi.
- Warna ungu dipakai untuk aksi atau identitas utama, bukan untuk semua jenis status.
- Ikon dan warna menjelaskan kategori: informasi, berhasil, peringatan, atau gagal.
- Notifikasi tidak menggunakan panel gelap yang terlihat terpisah dari desain aplikasi.
- Satu notifikasi sementara tampil pada satu waktu; notifikasi baru mengganti pesan lama yang setara.
- Semua teks terlokalisasi dan dapat dibaca screen reader.

## 6. Audit Bug Seluruh Aplikasi

Audit dilakukan berdasarkan alur pengguna, bukan hanya berdasarkan daftar file.

### 6.1 Area pengujian

1. Autentikasi, sesi, logout, dan token kedaluwarsa.
2. Beranda, schematic map, filter kawasan, filter jalur, zoom, dan “Kamu di sini”.
3. Pencarian stasiun, perencanaan rute, transit, jalan kaki, preview highlight antarnode, dan jadwal.
4. Chatbot, konteks percakapan, STT, TTS, pergantian bahasa, dan fallback jaringan.
5. Kamera, lifecycle, izin, rotasi, rasio preview, bounding box, performa, dan fail-safe.
6. Tiket, pembayaran demo, detail tiket, dan riwayat.
7. Alarm perjalanan, notifikasi, dan pengingat.
8. Profil, pusat bantuan, bahasa, serta aksesibilitas.
9. Bottom navigation, safe area, ukuran layar kecil, gesture navigation, dan tombol navigasi Android.
10. Integrasi Flutter, backend, Neon, dan konfigurasi environment.

### 6.2 Kondisi pengujian

- Online stabil, lambat, timeout, dan offline.
- Backend aktif, backend tidur, respons tidak valid, dan autentikasi gagal.
- Bahasa Indonesia, Inggris, Mandarin Sederhana, dan Arab termasuk RTL.
- Font scaling 100%, 130%, dan 200%.
- Layar kecil, layar tinggi, tablet, dan perubahan orientasi yang didukung.
- HP kelas bawah dan perangkat modern.
- Permission diberikan, ditolak sekali, ditolak permanen, dan dicabut saat aplikasi berjalan.
- Aplikasi masuk background lalu kembali aktif.

### 6.3 Klasifikasi temuan

- Critical: dapat membahayakan pengguna, kehilangan data, atau membuat aplikasi tidak dapat digunakan.
- High: alur utama gagal atau memberikan informasi perjalanan yang salah.
- Medium: fungsi masih dapat digunakan tetapi pengalaman atau akurasinya menurun.
- Low: masalah kosmetik tanpa dampak terhadap hasil.

Setiap laporan bug minimal berisi langkah reproduksi, hasil aktual, hasil yang diharapkan, perangkat, locale, bukti, dugaan akar masalah, dan hasil verifikasi perbaikan.

## 7. Kriteria Penerimaan

Revisi dianggap berhasil jika:

- Preview tidak stretch pada rasio layar umum 16:9, 19.5:9, dan 20:9.
- Objek berbentuk lingkaran tetap terlihat lingkaran pada preview.
- Seluruh frame kamera terlihat tanpa crop pada mode keselamatan.
- Bounding box tetap sejajar setelah rotasi dan pada perangkat berbeda.
- Tidak ada frame kamera yang disimpan di Neon atau penyimpanan permanen lainnya.
- Pipeline tidak mengantre frame dan tetap menggunakan data terbaru.
- Latensi p95 tercatat; jika melewati 200 ms, aplikasi masuk fallback performa atau status tidak andal.
- Kegagalan detektor, kamera, depth, atau jaringan tidak pernah menghasilkan pesan yang menyatakan jalur aman.
- Bahasa chatbot, STT, TTS, error, dan tombol konsisten dengan bahasa aplikasi.
- Notifikasi tidak menutupi tujuan utama halaman, schematic map, atau navigation bar.
- Semua alur utama lolos pengujian pada minimal satu perangkat fisik kelas bawah dan satu perangkat modern.

## 8. Strategi Verifikasi

- Unit test untuk pemilihan locale, pemetaan status, evaluasi hazard, dan fallback performa.
- Widget test untuk constraint preview, safe area, posisi notifikasi, dan font scaling.
- Integration test untuk lifecycle kamera, izin, chat multigilir, rute, dan kondisi jaringan.
- Golden test untuk rasio layar dan bahasa yang berbeda.
- Uji fisik dengan pola lingkaran/grid untuk mendeteksi distorsi preview.
- Uji bounding box menggunakan objek statis pada sisi tengah dan tepi frame.
- Profiling latensi dan memori melalui loop berkelanjutan, dengan median, p95, frame drop, serta penggunaan memori dicatat.
- Uji keselamatan terkontrol hanya dilakukan di lingkungan tertutup dengan pendamping; pengguna tidak diminta mengandalkan sistem sebagai satu-satunya alat navigasi.

## 9. Batas Ruang Lingkup

Dokumen ini tidak menganggap fitur berikut selesai:

- Pelatihan dan validasi dataset tactile paving.
- Deteksi lubang, perubahan tinggi, atau kaca yang terjamin pada semua perangkat.
- Pengukuran jarak 5 meter yang presisi dari kamera monokular.
- Navigasi penuh di dalam stasiun tanpa pemetaan indoor tambahan.
- Sertifikasi sebagai perangkat medis atau alat mobilitas resmi.

Fitur tersebut memerlukan eksperimen model, dataset, pengujian perangkat, dan evaluasi keselamatan terpisah.

## 10. Referensi Teknis

- [Flutter camera cookbook](https://docs.flutter.dev/cookbook/plugins/picture-using-camera)
- [Flutter CameraValue dan aspectRatio](https://pub.dev/documentation/camera/latest/camera/CameraValue-class.html)
- [Android CameraX preview dan scale type](https://developer.android.com/media/camera/camerax/preview)
- [Android CameraX image analysis dan backpressure](https://developer.android.com/media/camera/camerax/analyze)
- [ML Kit object detection dan panduan real-time](https://developers.google.com/ml-kit/vision/object-detection/android)
- [ARCore Depth API](https://developers.google.com/ar/develop/java/depth/developer-guide)
- [ARCore environmental limitations](https://developers.google.com/ar/design/environment/definition)

