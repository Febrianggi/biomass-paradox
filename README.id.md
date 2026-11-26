# Paradoks Biomassa dalam Transisi Energi-Iklim Global

[English](README.md) · **Bahasa Indonesia**

Analisis multivariat dan dashboard interaktif untuk 189 ekonomi berdaulat (8,02 miliar jiwa) pada enam indikator SDG 7 dan SDG 13 tahun 2015 dan 2023. Proyek ini mengelompokkan negara ke dalam rezim energi bersih dan emisi, menguji kestabilannya pada empat metode *clustering*, melacak perubahan sejak 2015, serta menguji apakah kondisi 2015 dapat memprediksi akses memasak bersih 2023.

- **Halaman pembuka:** https://febrianggi.github.io/biomass-paradox/
- **Dashboard interaktif (ID/EN):** https://febrianggi.github.io/biomass-paradox/dashboard/

## Mengapa analisis ini dibuat

Pangsa energi terbarukan yang tinggi tidak otomatis berarti listrik bersih modern. Pada indikator SDG 7.2.1 (pangsa energi terbarukan dalam konsumsi energi final), negara dengan akses listrik rendah sering berada di peringkat atas karena rumah tangga masih mengandalkan kayu bakar, arang, dan biomassa tradisional untuk memasak. Membaca satu indikator ini saja mencampurkan biomassa tradisional dengan pembangkit modern seperti air, surya, angin, dan panas bumi.

Untuk memisahkan kedua pola tersebut, repositori ini mengevaluasi enam indikator secara bersama-sama dan menjawab lima pertanyaan:

1. Rezim energi-iklim apa yang terbentuk saat 189 ekonomi dikelompokkan secara multivariat pada enam indikator SDG 7 dan SDG 13 tahun 2023?
2. Seberapa stabil rezim tersebut, dan seberapa besar hasilnya dipengaruhi pilihan metode *clustering*?
3. Di mana posisi tiap ekonomi pada 2015 bila dipetakan ke struktur rezim 2023?
4. Apakah perubahan dari 2015 ke 2023 membentuk jalur transisi yang berbeda-beda?
5. Apakah kondisi 2015 memprediksi akses memasak bersih 2023 lebih baik daripada persistensi sederhana?

## Temuan utama

### Empat rezim global tahun 2023 (K-Means, k = 4)

Di antara solusi multi-rezim (`k >= 3`), K-Means pada `k = 4` mencapai puncak stabilitas yang jelas (Jaccard bootstrap rata-rata 0,9533, minimum 0,9114, Silhouette 0,3485; [`table_04`](output/tables/table_04_model_comparison.csv)). Secara global, `k = 2` memang memiliki Silhouette lebih tinggi (0,4451, Jaccard rata-rata 0,9758), tetapi kelompok atasnya (`B2`) menggabungkan seluruh `R3` dan `R4` beserta 8 ekonomi `R2` ([`table_10`](output/tables/table_10_two_regime_alternative_k2.csv)). Kedua solusi tetap dilaporkan dan dapat dipilih di dashboard; `k = 4` dipakai sebagai tampilan utama karena memisahkan paradoks biomassa (`R1` vs `R2`) sekaligus ketergantungan fosil (`R3` vs `R4`).

| Rezim | Negara | Median akses listrik (%) | Median memasak bersih (%) | Median pangsa EBT (%) | Median kapasitas EBT (W/kap) | Median CO2 (t/kap) | Jaccard |
|---|---:|---:|---:|---:|---:|---:|---:|
| R1 Defisit akses dan perangkap biomassa | 27 | 40,5 | 5 | 78,98 | 11,6 | 0,17 | 0,965 |
| R2 Transisi akses berkembang | 41 | 83,6 | 44 | 40,35 | 53,2 | 0,74 | 0,963 |
| R3 Elektrifikasi efisien dan EBT modern | 95 | 100,0 | 98 | 17,14 | 552,2 | 3,67 | 0,974 |
| R4 Intensif fosil dan emisi tinggi | 26 | 100,0 | 100 | 1,31 | 114,7 | 11,99 | 0,911 |

Sumber: [`table_06`](output/tables/table_06_global_regime_profiles_2023.csv).

`R1` memperlihatkan paradoks biomassa secara langsung: median pangsa energi terbarukannya paling tinggi (78,98%), padahal median akses listriknya hanya 40,5%, median memasak bersih 5%, dan kapasitas pembangkit listrik terbarukannya baru 11,6 W per kapita.

### Apa itu rezim dan kriteria klaster R1 sampai R4 di keempat metode

Dalam analisis ini, **rezim** bukan peringkat dari satu indikator atau kelompok politik, melainkan pola struktural multivariat yang muncul dari keenam indikator SDG 7 dan SDG 13 secara bersamaan. Negara dalam rezim yang sama menghadapi tantangan transisi energi yang serupa.

Tidak ada aturan ambang potong manual per negara. Keempat algoritma berjalan secara tak terawasi (*unsupervised*) pada keenam fitur setelah transformasi `log(1 + x)` (untuk kapasitas EBT, intensitas energi, dan CO2) serta standardisasi z-score:

- **K-Means (model terpilih):** Menempatkan setiap ekonomi ke centroid (vektor rata-rata keenam fitur z-score) terdekat yang meminimalkan jarak Euklides kuadrat (`nstart = 100`, `iter.max = 200`).
- **Hierarki Ward D2:** Memulai setiap ekonomi sebagai klaster terpisah lalu menggabungkan pasangan klaster secara bertahap dengan kenaikan total varians dalam-klaster terkecil, kemudian memotong dendrogram pada `k = 4`.
- **PAM (K-Medoids):** Memilih empat ekonomi nyata sebagai medoid representatif (`TZA`, `PAK`, `JAM`, `SVN`) lalu memasukkan setiap ekonomi ke medoid Euklides terdekat, sehingga batas klaster lebih tahan terhadap nilai ekstrem.
- **GMM (`mclust`, spesifikasi `VEV` pilihan BIC):** Memodelkan empat distribusi normal multivariat berbentuk elipsoidal dengan Expectation-Maximisation dan menempatkan setiap ekonomi ke komponen dengan probabilitas posterior tertinggi.

**Penyelarasan label deterministik (sama untuk keempat metode):** Karena nomor klaster mentah dari algoritma tak terawasi bersifat acak, fungsi `order_regime_labels()` di `sdg_energy_transition_analysis.R` menyelaraskan keempat label secara konsisten: **R1** adalah klaster dengan rata-rata akses listrik terendah; dari tiga klaster sisanya, **R4** adalah klaster dengan rata-rata CO2 per kapita tertinggi; dari dua sisanya, **R2** adalah yang memiliki rata-rata akses listrik lebih rendah; dan sisanya menjadi **R3** (akses tinggi, intensitas energi rendah, dan kapasitas listrik EBT modern lebih kuat).

### Mengapa K-Means k = 4 dipilih meski skor k = 2 lebih tinggi

Secara matematis murni pada indeks validitas internal global, K-Means `k = 2` memang unggul (Silhouette 0,4451; Davies-Bouldin 0,9291; Calinski-Harabasz 163,44; Jaccard rata-rata 0,9758) dibandingkan `k = 4` (Silhouette 0,3485; Davies-Bouldin 1,1096; Calinski-Harabasz 120,77; Jaccard rata-rata 0,9533; [`table_04`](output/tables/table_04_model_comparison.csv)). K-Means `k = 4` dipilih sebagai model utama atas tiga alasan:

1. **Mengapa `k = 2` unggul secara geometri:** Celah tunggal terbesar di data global adalah pemisahan biner kasar antara ekonomi defisit akses dasar (`B1`, 60 ekonomi) dan ekonomi yang sudah terelektrifikasi (`B2`, 129 ekonomi).
2. **Mengapa `k = 2` mengaburkan isu kebijakan utama:** `B2` mencampurkan pemimpin listrik terbarukan seperti Norwegia dan Swedia (`R3`) ke klaster yang sama dengan negara intensif fosil seperti Qatar dan Rusia (`R4`), sementara `B1` menggabungkan krisis biomassa tradisional akut (`R1`, memasak bersih median 5%) dengan ekonomi transisi berkembang (`R2`, 44%).
3. **Mengapa tepat `k = 4` (bukan `k = 3` atau `k = 5`):** Di antara model multi-rezim (`k >= 3`) yang memisahkan paradoks biomassa (`R1` vs `R2`) sekaligus ketergantungan fosil (`R3` vs `R4`), `k = 4` membentuk puncak stabilitas lokal yang tajam: Jaccard bootstrap rata-rata melonjak dari 0,7981 pada `k = 3` (min 0,6951) menjadi 0,9533 pada `k = 4` (min 0,9114, 500/500 replikasi, ARI 0,795 vs Ward D2), sedangkan pada `k = 5` kekompakan turun tajam (Silhouette 0,2672; min Jaccard 0,8282). Alternatif `k = 2` tetap dapat dipilih langsung di peta dashboard.

### Hasil inti lainnya

- **Pilihan metode dan sensitivitas GMM:** Pada `k = 4`, K-Means sepakat cukup kuat dengan hierarki Ward D2 (ARI 0,795), tetapi rendah dengan GMM elipsoidal `VEV` pilihan BIC (ARI 0,3671, Silhouette 0,1975; [`table_05`](output/tables/table_05_ari_agreement_between_methods.csv)). Pada GMM `VEV`, dua komponen menyusut pada varians `elec_access` terstandar yang sangat kecil (0,00308 dan 0,00300), sejalan dengan 59,3% negara yang terkumpul di batas atas 100% akses listrik ([`table_01`](output/tables/table_01_data_quality_audit_2023.csv)). Saat kovarians GMM diganti menjadi sferis `EII`, Silhouette naik menjadi 0,3599 dan ARI terhadap K-Means melonjak menjadi 0,8421 ([`table_11`](output/tables/table_11_gmm_covariance_sensitivity.csv)), menunjukkan bahwa selisih GMM mencerminkan sensitivitas terhadap spesifikasi kovarians pada keenam fitur.
- **Imputasi dan validasi eksternal:** Imputasi data hilang dengan `missMDA` pada `n = 207` ekonomi menghasilkan partisi yang identik pada 189 ekonomi bersama (ARI 1,0000). Dua variabel luar yang tidak dimasukkan ke model juga berbeda sangat tajam antarrezim: PDB per kapita PPP (Kruskal-Wallis H = 116,03, p = 5,527e-25) dan persentase penduduk perkotaan (H = 67,79, p = 1,271e-14) ([`output/console_summary.txt`](output/console_summary.txt)).
- **Posisi rezim 2015 ke 2023:** Saat diproyeksikan ke centroid 2023, 165 dari 189 ekonomi bertahan di rezim yang sama ([`table_08`](output/tables/table_08_migration_matrix_2015_2023.csv)). Sebanyak 22 ekonomi naik akses atau menurunkan intensitas karbon (7 dari R1 ke R2, 8 dari R2 ke R3, 7 dari R4 ke R3 termasuk Malaysia), 2 ekonomi bergeser dari R3 ke R4, dan 0 kembali ke R1. Ini perbandingan deskriptif terhadap struktur 2023, bukan estimasi dampak kebijakan.
- **Jalur perubahan 2015 ke 2023:** Pengelompokan perubahan delapan tahun dengan FANNY fuzzy memilih `k = 2` (eksponen keanggotaan 1,3, Jaccard sub-sampel rata-rata 0,9334), tetapi pemisahannya lemah (Silhouette 0,2047; ARI 0,208 terhadap PAM; ARI 0,6195 terhadap FANNY selisih mentah; [`table_12`](output/tables/table_12_change_pathways_k_comparison.csv), [`table_13`](output/tables/table_13_change_pathway_profiles.csv), [`table_14`](output/tables/table_14_change_pathway_memberships.csv)). Jalur `P1` (100 ekonomi) memperluas akses dasar (median listrik +6,9 poin persen, memasak bersih +7 poin, pangsa EBT -2,19 poin, CO2 +0,128 t). Jalur `P2` (89 ekonomi) sudah mendekati akses penuh (listrik +0, memasak bersih +1) dan bergerak ke arah rendah karbon (pangsa EBT +2,74 poin, kapasitas EBT +143,22 W/kap, CO2 -0,53 t). Kesepakatannya dengan rezim 2023 rendah (ARI 0,112), sehingga `P1` dan `P2` merangkum arah perubahan, bukan kelompok yang terpisah tajam.
- **Prediksi memasak bersih 2023 dari data 2015:** Pada 10 lipatan negara yang sama ([`table_15`](output/tables/table_15_clean_cooking_forecast_metrics.csv), [`table_16`](output/tables/table_16_clean_cooking_forecast_oof.csv), [`table_17`](output/tables/table_17_clean_cooking_forecast_tuning.csv)), MAE out-of-fold adalah 5,19 poin persen untuk persistensi (nilai 2015), 3,79 untuk regresi linear pada memasak bersih 2015, dan 3,33 untuk elastic net pada keenam indikator 2015 (RMSE 8,24; 6,04; dan 5,39). Pada interval ini, MAE elastic net lebih rendah 1,86 poin daripada persistensi (IK 95% 1,19 sampai 2,51) dan 0,46 poin daripada regresi khusus memasak bersih (IK 95% 0,086 sampai 0,826), dengan IK dari pengambilan sampel ulang berpasangan atas galat out-of-fold. Karena perbandingan elastic net dengan OLS mengubah prediktor sekaligus metode estimasi, selisih 0,46 poin mengukur kinerja model secara keseluruhan dan tidak memisahkan sumbangan lima indikator tambahan. Sebelum dipotong ke rentang `[0, 100]`, 61 prediksi regresi linear dan 50 prediksi elastic net berada di luar rentang tersebut.
- **Posisi Indonesia dan ASEAN:** Indonesia berada di `R3` dengan akses listrik 99,4% dan memasak bersih 89% pada 2023 (naik dari 69% pada 2015), tetapi kapasitas listrik terbarukannya baru 47,39 W per kapita, dibandingkan median `R3` sebesar 552,2 W dan Vietnam sebesar 476,30 W ([`table_09`](output/tables/table_09_indonesia_asean_benchmark.csv)).

## Cara membaca dashboard

Halaman pembuka memperkenalkan paradoks biomassa dan menautkan langsung ke dashboard (`/dashboard/`). Di dalam dashboard, bilah atas selalu tersedia di semua tab: tombol **ID / EN** mengganti bahasa antarmuka sekaligus nama negara standar ISO 3166-1, tombol tema mengganti mode terang/gelap, dan **Unduh CSV (189 Negara)** mengunduh tabel lengkap hasil klaster. Mengklik negara mana pun di peta, scatter plot, daftar migrasi, atau tabel akan menyinkronkan pilihan di seluruh tab dan panel inspektor.

| Tab | Isi utama | Cara memakai |
|---|---|---|
| **Peta Rezim** | Peta koroplet dunia interaktif, panel inspektor negara tersinkronisasi, deret KPI ringkas, serta kartu penjelas definisi rezim dan kriteria keempat metode | Ganti **Lapisan peta** ke 6 pilihan (`2023 · K-Means k=4 (model terpilih)`, `2023 · K-Means k=2 (alternatif biner)`, `2015 · Baseline (proyeksi k=4)`, `2023 · Ward's D2 k=4`, `2023 · PAM k=4`, `2023 · GMM k=4`). Pilih **Cakupan** antara **Dunia**, **ASEAN**, **Asia**, **Afrika**, **Eropa**, **Amerika Utara**, **Amerika Selatan**, dan **Oseania** (jumlah negara tiap rezim dan kartu profil otomatis menyesuaikan wilayah terpilih), saring lewat **Sorot rezim** (`Semua`, `R1` sampai `R4`), buka akordeon kriteria metode untuk melihat cara pembentukan `R1` sampai `R4`, atau cari lewat **Cari negara** dengan nama ISO 3166-1, Alpha-3 (`IDN`), maupun Alpha-2 (`ID`). |
| **Paradoks Biomassa** | Scatter plot interaktif dengan legenda rezim `R1` sampai `R4` yang bisa diklik dan panduan cara baca otomatis per tampilan, plus diagnostik multivariat (KMO, Bartlett, Hopkins, skewness sebelum/sesudah transformasi log) | Pilih tiga tampilan: **Paradoks Biomassa (7.2.1 vs 7.b.1)**, **Biplot PCA**, atau **Intensitas vs CO2** (kotak panduan di bawah grafik otomatis menjelaskan makna kuadran setiap tampilan). Klik `R1` sampai `R4` di legenda grafik untuk menyorot seluruh negara pada satu rezim lengkap dengan animasi perpindahan antarrezim maupun kembali ke satu negara, pakai tombol sorotan (**Semua negara**, **Jebakan Biomassa (R1)**, **Indonesia vs ASEAN**, **Pencilan Mahalanobis**), lalu klik titik mana saja untuk melihat profil negaranya. |
| **Evaluasi Model** | Tabel perbandingan 20 konfigurasi model (`k = 2` sampai `6` pada empat metode), penjelasan alasan `k = 4` vs `k = 2`, matriks ARI antarmetode, dan uji sensitivitas GMM `VEV` vs `EII` | Bandingkan indeks validitas internal (Silhouette, Davies-Bouldin, Calinski-Harabasz, Dunn) bersama stabilitas Jaccard bootstrap `B = 500` untuk melihat alasan pemilihan K-Means `k = 4` dan penyebab perbedaan GMM `VEV`. |
| **2015-2023 & ASEAN** | Matriks migrasi 4x4 interaktif, tolok ukur 11 ekonomi ASEAN beserta bauran kapasitas EBT, jalur perubahan FANNY `P1`/`P2`, dan scatter prediksi memasak bersih 2023 | Arahkan kursor ke sel matriks untuk melihat negara yang berpindah antara 2015 dan 2023, atau klik sel untuk menyematkan daftarnya. Klik titik pada scatter prediksi untuk memeriksa nilai aktual dan prediksi negara tersebut. |
| **Data & Metodologi** | Tabel 189 negara yang bisa dicari dan diurutkan, kamus indikator, serta catatan metodologi | Saring menurut rezim atau wilayah (`ASEAN (11)`), cari dengan nama Indonesia/Inggris, kode Alpha-3, atau Alpha-2, urutkan kolom indikator apa pun, lalu klik baris untuk menyorot negara di panel inspektor. |

### Cara membaca tiga plot di tab Paradoks Biomassa

Setiap pilihan grafik di tab **Paradoks Biomassa** memotret sudut pandang yang berbeda dari ruang enam indikator:

1. **Paradoks Biomassa (`SDG 7.2.1 vs 7.b.1`):** Memetakan pangsa energi terbarukan dalam konsumsi energi final (%) pada sumbu X terhadap kapasitas pembangkit listrik terbarukan per kapita (W, skala log) pada sumbu Y.
   - **Kanan bawah (`R1`, perangkap biomassa):** Pangsa EBT final sangat tinggi (median 78,98%) tetapi kapasitas listrik EBT sangat kecil (median 11,6 W/kapita) karena energinya didominasi kayu bakar dan arang rumah tangga.
   - **Kanan atas (pemimpin EBT modern `R3`):** Pangsa EBT tinggi yang ditopang ribuan Watt per kapita pembangkit listrik modern (misalnya Norwegia 7.260 W, Swedia 3.817 W, Austria 2.892 W) dan akses memasak bersih penuh.
   - **Tengah bawah (`R2`, transisi berkembang):** Pangsa EBT menengah (median 40,35%) dengan kapasitas listrik terbarukan modern masih terbatas (median 53,2 W/kapita).
   - **Kiri (`R4` dan sistem dominan fosil):** Pangsa EBT sangat rendah (median R4 1,31%), mencerminkan sistem energi yang bertumpu pada minyak, gas, atau batu bara.
2. **Biplot PCA (`PC1` 59,4% vs `PC2` 17,6%, total 77,1% varians):** Meringkas enam indikator terstandardisasi menjadi dua sumbu saling tegak lurus. **PC1 (mendatar)** adalah sumbu modernisasi akses energi: ke kanan berarti akses memasak bersih (`r = +0,945`), akses listrik (`r = +0,900`), log CO2 (`r = +0,800`), dan log kapasitas EBT (`r = +0,721`) lebih tinggi; ke kiri berarti pangsa biomassa tradisional lebih tinggi (`r = -0,772`). **PC2 (tegak)** adalah sumbu intensitas energi dan beban karbon: ke atas berarti log intensitas energi primer (`r = +0,888`) dan log CO2 (`r = +0,384`) lebih tinggi; ke bawah berarti efisiensi energi lebih baik dan EBT modern lebih kuat (`r = -0,257` kapasitas, `-0,220` pangsa).
   - **Kuadran II, Kiri Atas (`PC1 < 0, PC2 > 0`):** Defisit akses energi modern sekaligus intensitas energi primer tinggi karena tungku kayu bakar/arang boros energi per dolar PDB (**18/27 R1** dan 10 R2).
   - **Kuadran I, Kanan Atas (`PC1 > 0, PC2 > 0`):** Akses dasar penuh tetapi boros energi dan tinggi emisi fosil (**24/26 R4** seperti Qatar, Rusia, Iran, Tiongkok, plus 23 R3 berintensitas lebih tinggi).
   - **Kuadran III, Kiri Bawah (`PC1 < 0, PC2 < 0`):** Ekonomi transisi yang memperluas akses dasar dengan intensitas energi lebih moderat (**31/41 R2** seperti Pakistan, Kamboja, Filipina, plus 9 R1).
   - **Kuadran IV, Kanan Bawah (`PC1 > 0, PC2 < 0`):** Akses penuh, intensitas energi paling rendah (paling efisien), dan kapasitas listrik EBT modern kuat (**72/95 R3** seperti Norwegia, Swedia, Jerman, Vietnam).
3. **Intensitas Energi vs CO2 (`SDG 7.3.1 vs SDG 13`):** Memetakan intensitas energi primer (MJ yang dipakai untuk menghasilkan 1 USD PPP PDB 2021; makin ke kiri makin efisien) pada sumbu X terhadap emisi CO2 per kapita (ton, skala log) pada sumbu Y.
   - **Kanan bawah (`R1`):** Intensitas energi tinggi (median 5,10 MJ/USD) tetapi emisi CO2 fosil sangat rendah (median 0,17 t/kapita), karena pembakaran biomassa rumah tangga boros energi secara termal namun tidak tercatat sebagai emisi fosil.
   - **Kiri bawah (`R2`):** Intensitas energi sedang (median 3,47 MJ/USD) dengan CO2 rendah (median 0,74 t/kapita) karena konsumsi energi per kapita masih berkembang.
   - **Kiri atas (`R3`):** Paling efisien menghasilkan PDB (median 2,64 MJ/USD), dengan emisi CO2 menengah (median 3,67 t/kapita) karena total konsumsi energi per kapita lebih tinggi.
   - **Kanan atas (`R4`):** Intensitas energi tinggi (median 5,85 MJ/USD; rata-rata 7,69) sekaligus CO2 per kapita tinggi (median 11,99 t/kapita) akibat industri berat dan dominasi bahan bakar fosil.

Tips baca tambahan:
- **Membaca panel inspektor:** Keenam indikator negara terpilih selalu dibandingkan langsung dengan median rezimnya dan median global, lengkap dengan label rezim 2015 vs 2023 serta jalur `P1`/`P2`.
- **Membandingkan metode di peta:** Ganti **Lapisan peta** antara `K-Means k=4`, `Ward's D2 k=4`, `PAM k=4`, dan `GMM k=4` untuk melihat langsung negara mana yang konsisten dan mana yang sensitif terhadap pilihan metode.

## Cara menggunakan asisten data

Halaman pembuka maupun dashboard dilengkapi tombol mengambang **Tanya data** di pojok kanan bawah (`dashboard/bot.js`). Klik tombol tersebut untuk membuka panel asisten, atau langsung pilih salah satu tombol saran pertanyaan di dalamnya.

Pertanyaan yang didukung:
- **Profil satu negara:** Mendukung nama ISO 3166-1 bahasa Indonesia maupun Inggris, kode Alpha-3, kode Alpha-2, nama santai, dan salah ketik ringan. Contoh: `Indo gimana?`, `GB`, `ESP`, `Turkiye`, `Cote d'Ivoire`, `VN`.
- **Perbandingan negara:** Bandingkan dua negara atau lebih sekaligus. Contoh: `Bandingkan Malay dan Vietnam`, `ID vs MY vs SG`.
- **Kelompok dan peringkat:** Tanyakan `Negara ASEAN`, rincian rezim (`R1`, `R2`, `R3`, `R4`), atau nilai ekstrem seperti `Memasak bersih terendah` maupun `CO2 tertinggi`.
- **Metode dan hasil analisis:** Tanyakan `Kenapa pakai K-Means bukan GMM?`, `perpindahan 2015 ke 2023`, `jalur P1 dan P2`, `prediksi memasak bersih`, atau `pencilan Mahalanobis`.

Dua mode kerja (statusnya terlihat di bagian bawah panel):
- **Mode AI (`Dijawab AI (Gemini / Groq) berdasarkan isi dashboard.`):** Mengirim pertanyaan beserta konteks ringkas dari `dashboard/data/dashboard_data.json` ke proxy Cloudflare Worker (`worker/worker.js`, Gemini utama dengan cadangan Groq) untuk jawaban bahasa bebas. Pertanyaan yang sama dalam satu sesi diambil dari cache.
- **Mode lokal (`Mode lokal: Tidak ada AI yang terlibat.`):** Jika server AI sedang tidak terjangkau, mencapai batas kuota, atau dinonaktifkan (`WORKER_URL = ""`), asisten otomatis berpindah ke mesin lokal di dalam `dashboard/bot.js`. Mode ini mencocokkan Alpha-3, Alpha-2, alias, dan salah ketik langsung terhadap `dashboard_data.json` tanpa permintaan jaringan ke luar.

## Data dan metode

### Sumber data dan indikator

Sumber: UN SDG Indicators Database (API UNSD) dan World Bank Open Data. Kode seri, lembaga kustodian, satuan, dan transformasi lengkap tiap variabel tercatat di [`data/sdg_data_dictionary.csv`](data/sdg_data_dictionary.csv).

| Fitur | Indikator | Transformasi |
|---|---|---|
| `elec_access` | SDG 7.1.1, akses listrik (% populasi) | z-score |
| `clean_cooking` | SDG 7.1.2, akses bahan bakar dan teknologi memasak bersih (% populasi) | z-score |
| `renew_share_tfec` | SDG 7.2.1, pangsa energi terbarukan dalam konsumsi energi final (%) | z-score |
| `renew_cap_wpc` | SDG 7.b.1, kapasitas listrik terbarukan (W per kapita) | log(1 + x), lalu z-score |
| `energy_intensity` | SDG 7.3.1, intensitas energi primer (MJ per USD PPP 2021) | log(1 + x), lalu z-score |
| `co2_per_capita` | Emisi CO2 per kapita (ton) | log(1 + x), lalu z-score |

- Panel tersimpan [`data/sdg_energy_climate_panel_2015_2023.csv`](data/sdg_energy_climate_panel_2015_2023.csv) mencakup 215 ekonomi untuk tahun 2015, 2022, dan 2023; analisis memakai 2015 dan 2023.
- Model dijalankan pada 189 ekonomi yang lengkap di keenam indikator (8,02 miliar jiwa; [`output/console_summary.txt`](output/console_summary.txt)). Data hilang terbanyak berada pada `clean_cooking` (23 ekonomi, 10,7%; [`table_01`](output/tables/table_01_data_quality_audit_2023.csv)).
- Emisi CO2 per kapita berasal dari World Bank (EDGAR, AR5) dan diisi dari seri UNSD (IEA) bila kosong; sumber tiap baris tercatat di kolom `co2_source`.
- PDB per kapita PPP dan persentase penduduk perkotaan tidak dipakai dalam pelatihan model, melainkan hanya sebagai validator eksternal.

### Ringkasan alur analisis

Seluruh langkah berada di [`sdg_energy_transition_analysis.R`](sdg_energy_transition_analysis.R) dengan `set.seed(2026)`:

1. **Prapengolahan:** Menerapkan `log(1 + x)` pada tiga indikator yang menceng kanan (menurunkan skewness absolut maksimum dari 5,87 menjadi 1,74; [`table_02`](output/tables/table_02_descriptive_stats_transformation.csv)), lalu menstandardisasi keenam fitur memakai rata-rata dan simpangan baku 2023.
2. **Diagnostik:** Memeriksa pencilan multivariat dengan jarak Mahalanobis (`D^2 > 22,46`, kuantil chi-kuadrat 0,999; enam ekonomi melewati batas dan tetap dipertahankan di [`table_03`](output/tables/table_03_mahalanobis_outliers.csv)). Nilai KMO keseluruhan 0,767, Hopkins H 0,9995, dan PC1 menjelaskan 59,4% varians ([`output/console_summary.txt`](output/console_summary.txt)).
3. **Clustering (`k = 2` sampai `6`):** Membandingkan K-Means (`nstart = 100`), PAM/K-Medoids, hierarki Ward D2 (jarak Euklides), dan Gaussian Mixture Model (`mclust`, kovarians dipilih dengan BIC).
4. **Evaluasi dan stabilitas:** Menghitung Silhouette, Davies-Bouldin, Calinski-Harabasz, Dunn, ARI antarmetode ([`table_05`](output/tables/table_05_ari_agreement_between_methods.csv)), serta Jaccard bootstrap `B = 500` (`fpc::clusterboot`; untuk GMM bootstrap ditulis manual dan jumlah replikasi berhasil dihitung langsung dari matriks hasil; [`table_04`](output/tables/table_04_model_comparison.csv)).
5. **Uji sensitivitas dan validasi eksternal:** Membandingkan dengan imputasi `missMDA::imputePCA` pada `n = 207` ekonomi (minimal 4 indikator teramati), menguji GMM sferis `EII` vs `VEV` ([`table_11`](output/tables/table_11_gmm_covariance_sensitivity.csv)), serta menjalankan uji Kruskal-Wallis pada PDB per kapita PPP dan urbanisasi.
6. **Proyeksi 2015:** Menskalakan data 2015 memakai parameter 2023 dan menempatkan tiap ekonomi ke centroid K-Means 2023 terdekat tanpa melatih ulang model pada data 2015 ([`table_08`](output/tables/table_08_migration_matrix_2015_2023.csv)).
7. **Jalur perubahan 2015 ke 2023:** Menstandardisasi selisih 2015 ke 2023 (selisih poin persen untuk tiga pangsa, selisih `log(1 + x)` untuk kapasitas EBT, intensitas energi, dan CO2) lalu mengelompokkannya dengan FANNY fuzzy (`cluster::fanny`, `k = 2` sampai `6`). Eksponen keanggotaan dipilih dari nilai terbesar di `{2; 1,7; 1,5; 1,3; 1,2}` yang menghasilkan `k` klaster berbeda untuk setiap `k` (nilai bawaan 2 menghasilkan keanggotaan seragam). Aturan memilih `k` paling stabil pada 200 sub-sampel 80% dengan ukuran setiap klaster minimal 10 ekonomi, serta menandai struktur lemah bila Silhouette < 0,25 atau Jaccard rata-rata < 0,75. Grid eksponen dan ambang struktur lemah ini adalah pilihan eksploratif setelah fit awal menunjukkan keanggotaan seragam pada eksponen bawaan. PAM pada fitur yang sama dan FANNY pada selisih mentah menjadi uji sensitivitas ([`table_12`](output/tables/table_12_change_pathways_k_comparison.csv)).
8. **Prediksi memasak bersih 2023:** Memprediksi akses memasak bersih 2023 dari indikator 2015 pada 10 lipatan luar yang sama dengan membandingkan persistensi, regresi linear pada memasak bersih 2015, dan elastic net (`glmnet`, alpha 0,1 sampai 1 dan lambda dipilih di 10 lipatan dalam, standardisasi hanya dari lipatan latih). Prediksi di luar `[0, 100]` dipotong ke rentang tersebut untuk semua model sesuai aturan sebelum fit. IK selisih MAE berasal dari pengambilan sampel ulang berpasangan atas galat out-of-fold yang sudah ada (2.000 sampel ulang negara; model tidak di-fit ulang; [`table_15`](output/tables/table_15_clean_cooking_forecast_metrics.csv)).

## Keterbatasan

- Analisis *complete-case* mengeluarkan 26 dari 215 ekonomi; uji imputasi hanya mencakup ekonomi dengan minimal 4 indikator teramati.
- Akses listrik dan memasak bersih memiliki batas atas 100%, sehingga banyak negara menumpuk di nilai yang sama dan memengaruhi model berbasis bentuk kovarians seperti GMM bebas.
- Keenam fitur mendapat bobot setara setelah standardisasi; pilihan fitur atau pembobotan lain dapat menggeser batas rezim.
- Penempatan 2015 memakai centroid 2023 menggambarkan posisi relatif terhadap struktur 2023, bukan klaster yang akan terbentuk jika 2015 dikelompokkan terpisah.
- Seri CO2 per kapita menggabungkan dua sumber (EDGAR dan IEA) dengan sedikit perbedaan metode pencatatan.
- Penyedia API UNSD dan World Bank dapat merevisi data historis, sehingga pengunduhan ulang bisa memberi angka sedikit berbeda dari panel tersimpan.
- Jalur perubahan hanya mencakup satu rentang delapan tahun; ekonomi yang sudah di 100% akses tidak bisa naik lagi dan ikut membentuk pola jalur.
- Prediksi memasak bersih adalah validasi antarnegara pada satu interval historis (2015 ke 2023) dan tidak mengukur akurasi peramalan tahun-tahun mendatang.

## Struktur repositori

```text
.
├── sdg_energy_transition_analysis.R   alur analisis R lengkap dari panel tersimpan
├── download_sdg_data.R                opsional: unduh ulang data dari API UNSD dan World Bank
├── data/
│   ├── sdg_energy_climate_panel_2015_2023.csv
│   └── sdg_data_dictionary.csv
├── output/
│   ├── tables/    table_01 s.d. table_17 (CSV)
│   ├── figures/   fig01 s.d. fig06 (PNG, 300 DPI)
│   └── console_summary.txt
├── dashboard/
│   ├── index.html
│   ├── bot.js
│   ├── data/      dashboard_data.json, dashboard_data.js
│   └── img/       foto, ilustrasi, dan tekstur kabut
├── worker/
│   ├── worker.js      proxy Cloudflare Worker opsional (Gemini utama, Groq cadangan)
│   └── wrangler.toml
└── index.html         halaman pembuka dwibahasa yang menautkan ke dashboard/
```

## Cara mereproduksi dan menjalankan di lokal

Jalankan semua perintah dari folder utama repositori.

### 1. Menjalankan ulang analisis dari panel tersimpan

Pasang paket R yang dibutuhkan:

```r
install.packages(c(
  "dplyr", "tidyr", "readr", "ggplot2", "scales", "psych", "cluster",
  "mclust", "fpc", "hopkins", "missMDA", "jsonlite", "glmnet",
  "rnaturalearth", "rnaturalearthdata", "sf"
))
```

Lalu jalankan:

```bash
Rscript sdg_energy_transition_analysis.R
```

Skrip membaca `data/sdg_energy_climate_panel_2015_2023.csv` secara luring dan menulis ulang `output/tables/`, `output/figures/`, serta `dashboard/data/`.

### 2. Mengunduh ulang data terbaru (opsional)

Membutuhkan koneksi internet dan paket R `httr2`, `jsonlite`, `dplyr`, `tidyr`, `readr`, serta `countrycode`:

```bash
Rscript download_sdg_data.R
```

Skrip menimpa kedua berkas di `data/`. Isi variabel lingkungan `SDG_RDS_CACHE` dengan lokasi folder bila ingin menyimpan cache respons API. Setelah selesai, jalankan ulang langkah 1.

### 3. Membuka halaman pembuka dan dashboard di lokal

Jalankan server HTTP lokal dari folder utama repositori agar `dashboard/index.html` dan `dashboard/bot.js` dapat memuat `dashboard/data/dashboard_data.json`:

```bash
python -m http.server 8000
```

Buka http://localhost:8000 untuk halaman pembuka dan http://localhost:8000/dashboard/ untuk dashboard.

### 4. Mengatur proxy AI opsional untuk asisten data

Tanpa proxy, `dashboard/bot.js` berjalan otomatis dalam mode lokal. Untuk mengaktifkan jawaban bahasa bebas berbasis AI:

1. Deploy `worker/worker.js` ke Cloudflare Workers (`worker/wrangler.toml`).
2. Tambahkan `GEMINI_API_KEY` dan/atau `GROQ_API_KEY` sebagai Cloudflare Worker Secret (jangan pernah memasukkan kunci API ke Git).
3. Arahkan `WORKER_URL` di bagian atas `dashboard/bot.js` ke URL Worker Anda. Jika Worker tidak terjangkau atau mencapai batas kuota, asisten otomatis beralih kembali ke mode lokal.
