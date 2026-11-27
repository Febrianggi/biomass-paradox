# Paradoks Biomassa dalam Transisi Energi-Iklim Global

[English](README.md) · **Bahasa Indonesia**

Analisis multivariat dan dashboard interaktif untuk 189 ekonomi berdaulat (8,02 miliar jiwa) pada enam indikator SDG 7 dan SDG 13 tahun 2019 dan 2023, dilengkapi proyeksi terawasi horizon 4 tahun ke 2027. Proyek ini mengelompokkan negara ke dalam rezim energi bersih dan emisi, menguji kestabilannya pada empat metode *clustering*, melacak posisi rezim serta jalur perubahan 2019-2023, dan memvalidasi model Elastic Net multivariabel pada `2019 -> 2023` untuk memproyeksikan indikator serta potensi perpindahan rezim pada 2027.

- **Halaman pembuka:** https://febrianggi.github.io/biomass-paradox/
- **Dashboard interaktif (ID/EN):** https://febrianggi.github.io/biomass-paradox/dashboard/

## Mengapa analisis ini dibuat

Pangsa energi terbarukan yang tinggi tidak otomatis berarti listrik bersih modern. Pada indikator SDG 7.2.1 (pangsa energi terbarukan dalam konsumsi energi final), negara dengan akses listrik rendah sering berada di peringkat atas karena rumah tangga masih mengandalkan kayu bakar, arang, dan biomassa tradisional untuk memasak. Membaca satu indikator ini saja mencampurkan biomassa tradisional dengan pembangkit modern seperti air, surya, angin, dan panas bumi.

Untuk memisahkan kedua pola tersebut, repositori ini mengevaluasi enam indikator secara bersama-sama dan menjawab lima pertanyaan:

1. Rezim energi-iklim apa yang terbentuk saat 189 ekonomi dikelompokkan secara multivariat pada enam indikator SDG 7 dan SDG 13 tahun 2023?
2. Seberapa stabil rezim tersebut, dan seberapa besar hasilnya dipengaruhi pilihan metode *clustering*?
3. Di mana posisi tiap ekonomi pada 2019 bila dipetakan ke struktur rezim 2023?
4. Apakah perubahan empat tahun dari 2019 ke 2023 membentuk jalur transisi yang berbeda-beda?
5. Ketika model terawasi divalidasi pada `2019 -> 2023` dan diterapkan pada data 2023, bagaimana proyeksi keenam indikator dan potensi perubahan rezim tiap negara pada 2027?

### Landasan jurnal ilmiah (2017-2025)

Pemilihan tema paradoks biomassa, desain enam indikator, penggunaan pengelompokan multivariat, dan sorotan Indonesia/ASEAN dilandasi tujuh artikel jurnal *peer-reviewed* terbitan 10 tahun terakhir:

- **Mengapa paradoks biomassa dan memasak bersih menjadi fokus utama:** Stoner dkk. (2021) memodelkan tren bahan bakar memasak rumah tangga global hingga 2030 dan menunjukkan miliaran penduduk tetap bergantung pada biomassa padat berpolusi tanpa percepatan transisi memasak bersih ([Nature Communications, 12, 5793](https://doi.org/10.1038/s41467-021-26036-x)). Rosenthal dkk. (2018) menegaskan beban kesehatan dan lingkungan dari tungku bahan bakar padat sehingga target memasak bersih harus dipantau terpisah dari pasokan energi ([Energy for Sustainable Development, 42, 152-159](https://doi.org/10.1016/j.esd.2017.11.003)).
- **Mengapa enam indikator SDG 7 dan SDG 13 dievaluasi bersamaan:** Fuso Nerini dkk. (2018) memetakan sinergi dan *trade-off* antara target SDG 7 dan iklim, menunjukkan bahwa pembacaan indikator tunggal melewatkan ketegangan struktural ([Nature Energy, 3(1), 10-15](https://doi.org/10.1038/s41560-017-0036-5)). Gielen dkk. (2019) menekankan bahwa dekarbonisasi global menuntut kombinasi kapasitas pembangkit EBT modern dan efisiensi energi primer, bukan pangsa EBT semata ([Energy Strategy Reviews, 24, 38-50](https://doi.org/10.1016/j.esr.2019.01.006)). He dkk. (2022) mengaitkan dimensi SDG 7 dengan jejak energi terbarukan antarnegara hingga 2030, memperkuat perlunya pemisahan bioenergi tradisional dan pembangkitan modern ([Applied Energy, 317, 119167](https://doi.org/10.1016/j.apenergy.2022.119167)).
- **Mengapa pendekatan rezim klaster multivariat dipakai:** Esiyok & Antmen (2025) menerapkan analisis klaster lintas negara untuk mengelompokkan pola pertumbuhan energi terbarukan ke tipologi struktural, bukan sekadar peringkat satu angka ([Applied Sciences, 15(3), 1575](https://doi.org/10.3390/app15031575)).
- **Mengapa Indonesia dan ASEAN disorot:** Resosudarmo, Rezki, & Effendi (2023) mendokumentasikan tantangan ganda transisi energi Indonesia: capaian cepat elektrifikasi dan memasak bersih berdampingan dengan ketergantungan batu bara dan lambatnya penambahan kapasitas pembangkit EBT modern ([Bulletin of Indonesian Economic Studies, 59(2), 149-177](https://doi.org/10.1080/00074918.2023.2238336)).

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
- **Posisi rezim 2019 ke 2023:** Saat diproyeksikan ke centroid 2023, 183 dari 189 ekonomi bertahan di rezim yang sama ([`table_08`](output/tables/table_08_migration_matrix_2019_2023.csv)). Sebanyak 6 ekonomi naik akses atau menurunkan intensitas karbon (2 dari R1 ke R2: Kamerun, Lesotho; 1 dari R2 ke R3: India; 3 dari R4 ke R3: Amerika Serikat, Ukraina, Lebanon), dan 0 ekonomi turun. Ini perbandingan deskriptif terhadap struktur 2023, bukan estimasi dampak kebijakan.
- **Jalur perubahan 2019 ke 2023:** Pengelompokan perubahan empat tahun dengan FANNY fuzzy memilih `k = 3` (eksponen keanggotaan 1,3, Jaccard sub-sampel rata-rata 0,9454), tetapi pemisahannya lemah (Silhouette 0,1909; ARI 0,6316 terhadap PAM; ARI 0,7402 terhadap FANNY selisih mentah; [`table_12`](output/tables/table_12_change_pathways_k_comparison.csv), [`table_13`](output/tables/table_13_change_pathway_profiles.csv), [`table_14`](output/tables/table_14_change_pathway_memberships.csv)). Jalur `P1` (68 ekonomi) memperluas akses dasar (median listrik +5,95 pp, memasak bersih +5 pp, pangsa EBT -0,47 pp, CO2 +0,001 t). Jalur `P2` (64 ekonomi) cenderung statis (listrik 0, memasak bersih 0, kapasitas EBT +14,32 W/kap, CO2 +0,013 t). Jalur `P3` (57 ekonomi) mempercepat dekarbonisasi modern (pangsa EBT +2,95 pp, kapasitas EBT +241,22 W/kap, intensitas energi -0,38 MJ/USD, CO2 -0,828 t). Kesepakatannya dengan rezim 2023 rendah (ARI 0,1402), sehingga `P1` sampai `P3` merangkum arah perubahan, bukan kelompok yang terpisah tajam.
- **Proyeksi 2027 horizon 4 tahun dan potensi perpindahan rezim (`2019 -> 2023 -> 2027*`):** Seri resmi SDG 7 UNSD/Bank Dunia tahun 2025-2026 belum tersedia (0 baris), dan 2024 kehilangan separuh negara pada `7.2.1`/`7.3.1` (`271 -> 129`), sedangkan 2019 lengkap 100% pada seluruh 189 ekonomi ([`data/sdg_energy_climate_panel_2019.csv`](data/sdg_energy_climate_panel_2019.csv)). Divalidasi pada interval 4 tahun yang cocok `2019 -> 2023` di 10 lipatan ([`table_15`](output/tables/table_15_forecast_2027_cv_metrics.csv)), Elastic Net menurunkan MAE out-of-fold dibanding persistensi pada memasak bersih (`1,865` vs `2,471` pp, IK 95% `-0,931` sampai `-0,263`), akses listrik (`1,565` vs `2,578` pp), intensitas energi (`0,379` vs `0,413` MJ/USD), dan kapasitas listrik EBT (`88,66` vs `125,10` W/kap), sedikit lebih rendah pada pangsa EBT (`2,514` vs `2,636` pp), serta imbang pada CO2 (`0,544` vs `0,548` t/kap). Saat diproyeksikan ke centroid 2023, akurasi rezim out-of-fold mencapai 97,9% (`185/189`, Kappa `0,968`) vs 96,8% (`183/189`) untuk persistensi ([`table_16`](output/tables/table_16_forecast_2027_regime_migration.csv)). Menerapkan model penuh `2019 -> 2023` pada fitur 2023 memproyeksikan **7 ekonomi** berpindah rezim pada 2027 (0 turun; komposisi proyeksi 2027 `R1 = 25, R2 = 41, R3 = 100, R4 = 23`): `R1 -> R2` (`COG` margin `0,157`, `RWA` `0,047`), `R2 -> R3` (`PHL` `0,047`, `WSM` `0,039`), dan `R4 -> R3` (`KOR` `0,172`, plus perbatasan tipis `CHN` `0,005` dan `CAN` `0,003`; [`table_17`](output/tables/table_17_forecast_2027_country_projections.csv)). Ini adalah proyeksi out-of-sample dengan asumsi pola 2019-2023 berlanjut, bukan ramalan pasti.
- **Posisi Indonesia dan ASEAN:** Indonesia bertahan di `R3` pada 2019, 2023, dan proyeksi 2027*, dengan akses listrik 99,4% dan memasak bersih 89% pada 2023 (naik dari 81% pada 2019; proyeksi 90,9% pada 2027*), tetapi kapasitas listrik terbarukannya baru 47,39 W per kapita (proyeksi 77,45 W pada 2027*), dibandingkan median `R3` sebesar 552,2 W dan Vietnam sebesar 476,30 W ([`table_09`](output/tables/table_09_indonesia_asean_benchmark.csv)).

## Cara membaca dashboard

Halaman dibuka dengan video hutan tanpa suara. Pilih **Lewati animasi** untuk langsung melihat isinya atau **Putar ulang animasi** untuk menonton kembali. Jika preferensi kurangi gerakan aktif, halaman langsung menampilkan kanopi.

Halaman pembuka memperkenalkan paradoks biomassa dan menautkan langsung ke dashboard (`/dashboard/`). Di dalam dashboard, bilah atas selalu tersedia di semua tab: tombol **ID / EN** mengganti bahasa antarmuka sekaligus nama negara standar ISO 3166-1, tombol tema mengganti mode terang/gelap, dan **Unduh CSV (189 Negara)** mengunduh tabel lengkap multi-tahun (`2019`, `2023`, dan `2027*`). Mengklik negara mana pun di peta, scatter plot, daftar migrasi, atau tabel akan menyinkronkan pilihan di seluruh tab dan panel inspektor.

| Tab | Isi utama | Cara memakai |
|---|---|---|
| **Peta Rezim** | Peta koroplet dunia interaktif, panel inspektor negara tersinkronisasi, deret KPI ringkas, serta kartu penjelas definisi rezim dan kriteria keempat metode | Ganti **Lapisan peta** ke 7 pilihan (`2023 · K-Means k=4 (model terpilih)`, `2023 · K-Means k=2 (alternatif biner)`, `2019 · Baseline (proyeksi k=4)`, `2027 · Proyeksi Elastic Net (k=4)`, `2023 · Ward's D2 k=4`, `2023 · PAM k=4`, `2023 · GMM k=4`). Pilih **Cakupan** antara **Dunia**, **ASEAN**, **Asia**, **Afrika**, **Eropa**, **Amerika Utara**, **Amerika Selatan**, dan **Oseania** (jumlah negara tiap rezim dan kartu profil otomatis menyesuaikan wilayah terpilih), saring lewat **Sorot rezim** (`Semua`, `R1` sampai `R4`), buka akordeon kriteria metode untuk melihat cara pembentukan `R1` sampai `R4`, atau cari lewat **Cari negara** dengan nama ISO 3166-1, Alpha-3 (`IDN`), maupun Alpha-2 (`ID`). |
| **Paradoks Biomassa** | Scatter plot interaktif dengan legenda rezim `R1` sampai `R4` yang bisa diklik, bilah kuadran `K-1` sampai `K-4` (`Q-1` sampai `Q-4` di EN) di atas **Biplot PCA**, area kuadran yang bisa diklik langsung di kanvas Biplot, kartu panduan statis di bawah grafik, plus diagnostik multivariat (KMO, Bartlett, Hopkins, skewness sebelum/sesudah transformasi log) | Pilih tiga tampilan: **Paradoks Biomassa (7.2.1 vs 7.b.1)**, **Biplot PCA**, atau **Intensitas vs CO2**. Klik `R1` sampai `R4` di legenda grafik, klik `K-1` sampai `K-4` di atas **Biplot PCA**, atau klik langsung area kosong pada kuadran di dalam kanvas Biplot untuk menyorot seluruh negara di kuadran tersebut lengkap dengan animasi; pakai tombol sorotan (**Semua negara**, **Jebakan Biomassa (R1)**, **Indonesia vs ASEAN**, **Pencilan Mahalanobis**), lalu klik titik mana saja untuk melihat profil negaranya. |
| **Evaluasi Model** | Kurva validasi `k = 2` sampai `6`, tabel alternatif `k = 2` & matriks ARI antarmetode berdampingan beserta uji sensitivitas GMM `VEV` vs `EII`, serta tabel lengkap 20 konfigurasi di bawahnya | Bandingkan indeks validitas internal (Silhouette, Davies-Bouldin, Calinski-Harabasz, Dunn) bersama stabilitas Jaccard bootstrap `B = 500`, kesepakatan antarmetode pada `k = 4`, dan tabel 20 konfigurasi. |
| **2019-2027 & ASEAN** | Matriks perpindahan rezim `2019 -> 2023` dan proyeksi `2023 -> 2027*` tersusun atas-bawah dengan daftar negara di sebelah kanan (tombol `+N` membuka pop-up seluruh negara saat isi sel > 20), tabel validasi silang 6 indikator/MAE yang bisa diklik berdampingan dengan plot proyeksi 2027, tolok ukur 11 ekonomi ASEAN beserta sintesis Indonesia, serta jalur perubahan FANNY `P1`/`P2`/`P3` | Arahkan kursor atau klik sel di kedua matriks migrasi untuk melihat daftar negara di sebelah kanan (klik `+N` pada sel dengan lebih dari 20 negara untuk membuka daftar lengkapnya di pop-up). Klik baris indikator mana saja pada tabel **Validasi silang 4-tahunan** untuk langsung mengganti plot proyeksi 2027 di sampingnya. |
| **Data & Metodologi** | Tabel 189 negara dengan pemilih tahun `2019 | 2023 | 2027*` yang bisa dicari dan diurutkan, kamus indikator, catatan metodologi, serta akordeon **Landasan Jurnal Ilmiah (2017-2025)** | Ganti **Tahun** antara `2019`, `2023`, dan `2027*` untuk melihat nilai keenam indikator per tahun sekaligus kolom rezim `2019 | 2023 | 2027*` berdampingan, saring menurut rezim atau wilayah (`ASEAN (11)`), cari dengan nama Indonesia/Inggris, kode Alpha-3, atau Alpha-2, lalu buka akordeon literatur untuk referensi jurnal ber-DOI. |

### Cara membaca tiga plot di tab Paradoks Biomassa

Setiap pilihan grafik di tab **Paradoks Biomassa** memotret sudut pandang yang berbeda dari ruang enam indikator:

1. **Paradoks Biomassa (`SDG 7.2.1 vs 7.b.1`):** Memetakan pangsa energi terbarukan dalam konsumsi energi final (%) pada sumbu X terhadap kapasitas pembangkit listrik terbarukan per kapita (W, skala log) pada sumbu Y.
   - **Kanan bawah (`R1`, perangkap biomassa):** Pangsa EBT final sangat tinggi (median 78,98%) tetapi kapasitas listrik EBT sangat kecil (median 11,6 W/kapita) karena energinya didominasi kayu bakar dan arang rumah tangga.
   - **Kanan atas (pemimpin EBT modern `R3`):** Pangsa EBT tinggi yang ditopang ribuan Watt per kapita pembangkit listrik modern (misalnya Norwegia 7.260 W, Swedia 3.817 W, Austria 2.892 W) dan akses memasak bersih penuh.
   - **Tengah bawah (`R2`, transisi berkembang):** Pangsa EBT menengah (median 40,35%) dengan kapasitas listrik terbarukan modern masih terbatas (median 53,2 W/kapita).
   - **Kiri (`R4` dan sistem dominan fosil):** Pangsa EBT sangat rendah (median R4 1,31%), mencerminkan sistem energi yang bertumpu pada minyak, gas, atau batu bara.
2. **Biplot PCA (`PC1` 59,4% vs `PC2` 17,6%, total 77,1% varians):** Meringkas enam indikator terstandardisasi menjadi dua sumbu saling tegak lurus. **PC1 (mendatar)** adalah sumbu modernisasi akses energi: ke kanan berarti akses memasak bersih (`r = +0,945`), akses listrik (`r = +0,900`), log CO2 (`r = +0,800`), dan log kapasitas EBT (`r = +0,721`) lebih tinggi; ke kiri berarti pangsa biomassa tradisional lebih tinggi (`r = -0,772`). **PC2 (tegak)** adalah sumbu intensitas energi dan beban karbon: ke atas berarti log intensitas energi primer (`r = +0,888`) dan log CO2 (`r = +0,384`) lebih tinggi; ke bawah berarti efisiensi energi lebih baik dan EBT modern lebih kuat (`r = -0,257` kapasitas, `-0,220` pangsa). Klik **`K-1` sampai `K-4`** (`Q-1` sampai `Q-4` dalam bahasa Inggris) di atas grafik atau klik langsung area kosong kuadran di dalam kanvas Biplot untuk menyorot seluruh negara pada kuadran tersebut:
   - **`K-1`, Kanan Atas (`PC1 > 0, PC2 > 0`, 47 ekonomi):** Akses dasar penuh tetapi boros energi dan tinggi emisi fosil (**24/26 R4** seperti Qatar, Rusia, Iran, Tiongkok, plus 23 R3 berintensitas lebih tinggi).
   - **`K-2`, Kiri Atas (`PC1 < 0, PC2 > 0`, 30 ekonomi):** Defisit akses energi modern sekaligus intensitas energi primer tinggi karena tungku kayu bakar/arang boros energi per dolar PDB (**18/27 R1**, 10 R2, dan 2 R4: LBY, SYR).
   - **`K-3`, Kiri Bawah (`PC1 < 0, PC2 < 0`, 40 ekonomi):** Ekonomi transisi yang memperluas akses dasar dengan intensitas energi lebih moderat (**31/41 R2** seperti Pakistan, Kamboja, Filipina, plus 9 R1).
   - **`K-4`, Kanan Bawah (`PC1 > 0, PC2 < 0`, 72 ekonomi):** Akses penuh, intensitas energi paling rendah (paling efisien), dan kapasitas listrik EBT modern kuat (**72/95 R3** seperti Norwegia, Swedia, Jerman, Vietnam).
3. **Intensitas Energi vs CO2 (`SDG 7.3.1 vs SDG 13`):** Memetakan intensitas energi primer (MJ yang dipakai untuk menghasilkan 1 USD PPP PDB 2021; makin ke kiri makin efisien) pada sumbu X terhadap emisi CO2 per kapita (ton, skala log) pada sumbu Y.
   - **Kanan bawah (`R1`):** Intensitas energi tinggi (median 5,10 MJ/USD) tetapi emisi CO2 fosil sangat rendah (median 0,17 t/kapita), karena pembakaran biomassa rumah tangga boros energi secara termal namun tidak tercatat sebagai emisi fosil.
   - **Kiri bawah (`R2`):** Intensitas energi sedang (median 3,47 MJ/USD) dengan CO2 rendah (median 0,74 t/kapita) karena konsumsi energi per kapita masih berkembang.
   - **Kiri atas (`R3`):** Paling efisien menghasilkan PDB (median 2,64 MJ/USD), dengan emisi CO2 menengah (median 3,67 t/kapita) karena total konsumsi energi per kapita lebih tinggi.
   - **Kanan atas (`R4`):** Intensitas energi tinggi (median 5,85 MJ/USD; rata-rata 7,69) sekaligus CO2 per kapita tinggi (median 11,99 t/kapita) akibat industri berat dan dominasi bahan bakar fosil.

Tips baca tambahan:
- **Membaca panel inspektor:** Keenam indikator negara terpilih selalu dibandingkan langsung dengan median rezimnya dan median global, lengkap dengan label rezim `2019 -> 2023 -> 2027*` serta jalur perubahan `P1`/`P2`/`P3`.
- **Membandingkan metode di peta:** Ganti **Lapisan peta** antara `K-Means k=4`, `Ward's D2 k=4`, `PAM k=4`, dan `GMM k=4` untuk melihat langsung negara mana yang konsisten dan mana yang sensitif terhadap pilihan metode.

## Cara menggunakan asisten data

Halaman pembuka maupun dashboard dilengkapi tombol mengambang **Tanya data** di pojok kanan bawah (`dashboard/bot.js`). Klik tombol tersebut untuk membuka panel asisten, atau langsung pilih salah satu tombol saran pertanyaan di dalamnya.

Pertanyaan yang didukung:
- **Profil satu negara:** Mendukung nama ISO 3166-1 bahasa Indonesia maupun Inggris, kode Alpha-3, kode Alpha-2, nama santai, dan salah ketik ringan. Contoh: `Indo gimana?`, `GB`, `ESP`, `Turkiye`, `Cote d'Ivoire`, `VN`.
- **Perbandingan negara:** Bandingkan dua negara atau lebih sekaligus. Contoh: `Bandingkan Malay dan Vietnam`, `ID vs MY vs SG`.
- **Kelompok dan peringkat:** Tanyakan `Negara ASEAN`, rincian rezim (`R1`, `R2`, `R3`, `R4`), atau nilai ekstrem seperti `Memasak bersih terendah` maupun `CO2 tertinggi`.
- **Metode dan hasil analisis:** Tanyakan `Kenapa pakai K-Means bukan GMM?`, `perpindahan 2019 ke 2023`, `jalur P1 P2 P3`, `proyeksi 2027`, atau `pencilan Mahalanobis`.

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

- Panel 2023 tersimpan ([`data/sdg_energy_climate_panel_2023.csv`](data/sdg_energy_climate_panel_2023.csv)) dan panel baseline 2019 ([`data/sdg_energy_climate_panel_2019.csv`](data/sdg_energy_climate_panel_2019.csv)) menyediakan data 2019 dan 2023 lengkap 100% untuk 189 ekonomi berdaulat (8,02 miliar jiwa; [`output/console_summary.txt`](output/console_summary.txt)). Data hilang terbanyak pada unduhan mentah 215 ekonomi tahun 2023 berada pada `clean_cooking` (23 ekonomi, 10,7%; [`table_01`](output/tables/table_01_data_quality_audit_2023.csv)).
- Emisi CO2 per kapita berasal dari World Bank (EDGAR, AR5) dan diisi dari seri UNSD (IEA) bila kosong; sumber tiap baris tercatat di kolom `co2_source`.
- PDB per kapita PPP dan persentase penduduk perkotaan tidak dipakai dalam pelatihan model, melainkan hanya sebagai validator eksternal.

### Ringkasan alur analisis

Seluruh langkah berada di [`sdg_energy_transition_analysis.R`](sdg_energy_transition_analysis.R) dengan `set.seed(2026)`:

1. **Prapengolahan:** Menerapkan `log(1 + x)` pada tiga indikator yang menceng kanan (menurunkan skewness absolut maksimum dari 5,87 menjadi 1,74; [`table_02`](output/tables/table_02_descriptive_stats_transformation.csv)), lalu menstandardisasi keenam fitur memakai rata-rata dan simpangan baku 2023.
2. **Diagnostik:** Memeriksa pencilan multivariat dengan jarak Mahalanobis (`D^2 > 22,46`, kuantil chi-kuadrat 0,999; enam ekonomi melewati batas dan tetap dipertahankan di [`table_03`](output/tables/table_03_mahalanobis_outliers.csv)). Nilai KMO keseluruhan 0,767, Hopkins H 0,9995, dan PC1 menjelaskan 59,4% varians ([`output/console_summary.txt`](output/console_summary.txt)).
3. **Clustering (`k = 2` sampai `6`):** Membandingkan K-Means (`nstart = 100`), PAM/K-Medoids, hierarki Ward D2 (jarak Euklides), dan Gaussian Mixture Model (`mclust`, kovarians dipilih dengan BIC).
4. **Evaluasi dan stabilitas:** Menghitung Silhouette, Davies-Bouldin, Calinski-Harabasz, Dunn, ARI antarmetode ([`table_05`](output/tables/table_05_ari_agreement_between_methods.csv)), serta Jaccard bootstrap `B = 500` (`fpc::clusterboot`; untuk GMM bootstrap ditulis manual dan jumlah replikasi berhasil dihitung langsung dari matriks hasil; [`table_04`](output/tables/table_04_model_comparison.csv)).
5. **Uji sensitivitas dan validasi eksternal:** Membandingkan dengan imputasi `missMDA::imputePCA` pada `n = 207` ekonomi (minimal 4 indikator teramati), menguji GMM sferis `EII` vs `VEV` ([`table_11`](output/tables/table_11_gmm_covariance_sensitivity.csv)), serta menjalankan uji Kruskal-Wallis pada PDB per kapita PPP dan urbanisasi.
6. **Proyeksi 2019:** Menskalakan data 2019 memakai parameter 2023 dan menempatkan tiap ekonomi ke centroid K-Means 2023 terdekat tanpa melatih ulang model pada data 2019 ([`table_08`](output/tables/table_08_migration_matrix_2019_2023.csv)).
7. **Jalur perubahan 2019 ke 2023:** Menstandardisasi selisih 2019 ke 2023 (selisih poin persen untuk tiga pangsa, selisih `log(1 + x)` untuk kapasitas EBT, intensitas energi, dan CO2) lalu mengelompokkannya dengan FANNY fuzzy (`cluster::fanny`, `k = 2` sampai `6`). Eksponen keanggotaan dipilih dari nilai terbesar di `{2; 1,7; 1,5; 1,3; 1,2}` yang menghasilkan `k` klaster berbeda untuk setiap `k` (nilai bawaan 2 menghasilkan keanggotaan seragam). Aturan memilih `k` paling stabil pada 200 sub-sampel 80% dengan ukuran setiap klaster minimal 10 ekonomi, serta menandai struktur lemah bila Silhouette < 0,25 atau Jaccard rata-rata < 0,75. PAM pada fitur yang sama dan FANNY pada selisih mentah menjadi uji sensitivitas ([`table_12`](output/tables/table_12_change_pathways_k_comparison.csv)).
8. **Proyeksi terawasi 4 tahunan ke 2027:** Melatih Elastic Net multivariabel (`glmnet`, alpha 0,1 sampai 1 dan lambda dipilih di 10 lipatan dalam, standardisasi hanya dari lipatan latih) bersama OLS *own-lag* dan persistensi pada horizon 4 tahun yang cocok `2019 -> 2023` di 10 lipatan luar yang sama ([`table_15`](output/tables/table_15_forecast_2027_cv_metrics.csv)). Mengevaluasi MAE/RMSE/R2 out-of-fold per indikator (dengan IK 95% bootstrap berpasangan 2.000 sampel ulang) serta akurasi rezim out-of-fold ([`table_16`](output/tables/table_16_forecast_2027_regime_migration.csv)), lalu melatih ulang pada seluruh 189 ekonomi dan menerapkannya pada fitur 2023 untuk memproyeksikan keenam indikator, rezim 2027*, dan margin centroid ([`table_17`](output/tables/table_17_forecast_2027_country_projections.csv)).

## Keterbatasan

- Analisis *complete-case* mengeluarkan 26 dari 215 ekonomi; uji imputasi hanya mencakup ekonomi dengan minimal 4 indikator teramati.
- Akses listrik dan memasak bersih memiliki batas atas 100%, sehingga banyak negara menumpuk di nilai yang sama dan memengaruhi model berbasis bentuk kovarians seperti GMM bebas.
- Keenam fitur mendapat bobot setara setelah standardisasi; pilihan fitur atau pembobotan lain dapat menggeser batas rezim.
- Penempatan 2019 dan 2027* memakai centroid 2023 menggambarkan posisi relatif terhadap struktur 2023, bukan klaster yang akan terbentuk jika 2019 atau 2027 dikelompokkan terpisah.
- Seri CO2 per kapita menggabungkan dua sumber (EDGAR dan IEA) dengan sedikit perbedaan metode pencatatan.
- Penyedia API UNSD dan World Bank dapat merevisi data historis, sehingga pengunduhan ulang bisa memberi angka sedikit berbeda dari panel tersimpan.
- Jalur perubahan hanya mencakup satu rentang empat tahun (`2019 -> 2023`); ekonomi yang sudah di 100% akses tidak bisa naik lagi dan ikut membentuk pola jalur.
- Proyeksi 2027 mengasumsikan dinamika transisi lintas negara 2019-2023 berlanjut ke 2023-2027 dan tidak dapat mengantisipasi guncangan kebijakan mendadak, krisis pasokan, atau disrupsi makroekonomi; perpindahan di perbatasan tipis (seperti `CHN` margin `0,005` dan `CAN` `0,003`) sensitif terhadap perubahan kecil.

## Struktur repositori

```text
.
├── sdg_energy_transition_analysis.R   alur analisis R lengkap dari panel 2019 dan 2023 tersimpan
├── download_sdg_data.R                opsional: unduh ulang data dari API UNSD dan World Bank
├── data/
│   ├── sdg_energy_climate_panel_2023.csv        panel 2023 (215 ekonomi, 189 data lengkap)
│   ├── sdg_energy_climate_panel_2019.csv        panel baseline 2019 lengkap (189 ekonomi)
│   ├── iso3166_country_names.csv
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

Skrip membaca `data/sdg_energy_climate_panel_2019.csv` dan `data/sdg_energy_climate_panel_2023.csv` secara luring dan menulis ulang `output/tables/`, `output/figures/`, serta `dashboard/data/`.

### 2. Mengunduh ulang data terbaru (opsional)

Membutuhkan koneksi internet dan paket R `httr2`, `jsonlite`, `dplyr`, `tidyr`, `readr`, serta `countrycode`:

```bash
Rscript download_sdg_data.R
```

Skrip memperbarui berkas di `data/`. Isi variabel lingkungan `SDG_RDS_CACHE` dengan lokasi folder bila ingin menyimpan cache respons API. Setelah selesai, jalankan ulang langkah 1.

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
