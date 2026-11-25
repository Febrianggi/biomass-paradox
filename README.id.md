# biomass-paradox

[English](README.md) · **Bahasa Indonesia**

Pengelompokan 189 ekonomi berdaulat berdasarkan enam indikator energi bersih dan emisi (SDG 7 dan SDG 13) tahun 2023, dengan perbandingan empat metode *clustering* dan uji stabilitas bootstrap. Repositori ini juga mengelompokkan perubahan dari 2015 ke 2023 dan menguji apakah kondisi 2015 memprediksi akses memasak bersih 2023.

Dashboard interaktif (ID/EN): https://febrianggi.github.io/biomass-paradox/

## Pertanyaan penelitian

Peringkat berbasis satu indikator bisa menyesatkan. Pada SDG 7.2.1 (pangsa energi terbarukan dalam konsumsi energi final), negara dengan akses listrik rendah sering tampak unggul karena konsumsi kayu bakar dan biomassa tradisional. Repositori ini menanyakan:

1. Rezim apa yang terbentuk bila 189 ekonomi dikelompokkan secara multivariat pada enam indikator SDG 7 dan SDG 13 tahun 2023?
2. Seberapa stabil rezim tersebut, dan seberapa jauh hasilnya bergantung pada pilihan metode?
3. Bagaimana posisi tiap ekonomi pada tahun 2015 bila dipetakan ke struktur rezim 2023?
4. Apakah perubahan dari 2015 ke 2023 membentuk jalur yang berbeda-beda?
5. Apakah kondisi 2015 memprediksi akses memasak bersih 2023 lebih baik daripada persistensi sederhana?

## Data

Sumber: UN SDG Indicators Database (API UNSD) dan World Bank Open Data. Kode seri, kustodian, satuan, dan transformasi tiap variabel ada di [`data/sdg_data_dictionary.csv`](data/sdg_data_dictionary.csv).

| Fitur | Indikator | Transformasi |
|---|---|---|
| `elec_access` | SDG 7.1.1, akses listrik (% populasi) | z-score |
| `clean_cooking` | SDG 7.1.2, akses bahan bakar dan teknologi memasak bersih (% populasi) | z-score |
| `renew_share_tfec` | SDG 7.2.1, pangsa energi terbarukan dalam konsumsi energi final (%) | z-score |
| `renew_cap_wpc` | SDG 7.b.1, kapasitas listrik terbarukan (W per kapita) | log(1 + x), lalu z-score |
| `energy_intensity` | SDG 7.3.1, intensitas energi primer (MJ per USD PPP 2021) | log(1 + x), lalu z-score |
| `co2_per_capita` | Emisi CO2 per kapita (ton) | log(1 + x), lalu z-score |

- Panel [`data/sdg_energy_climate_panel_2015_2023.csv`](data/sdg_energy_climate_panel_2015_2023.csv) memuat 215 ekonomi untuk tahun 2015, 2022, dan 2023. Analisis memakai 2015 dan 2023.
- Model hanya memakai ekonomi yang lengkap pada keenam fitur: 189 dari 215 ekonomi, mencakup 8,02 miliar jiwa ([`output/console_summary.txt`](output/console_summary.txt)). Data hilang terbanyak ada pada `clean_cooking` (23 ekonomi, 10,7%) ([`table_01`](output/tables/table_01_data_quality_audit_2023.csv)).
- Emisi CO2 per kapita diambil dari World Bank (EDGAR, AR5). Bila kosong, nilainya diisi dari seri UNSD (IEA). Sumber per baris tercatat di kolom `co2_source`.
- PDB per kapita PPP dan persentase penduduk perkotaan tidak masuk model. Keduanya hanya dipakai sebagai validator eksternal.

## Metode

Semua langkah ada di [`sdg_energy_transition_analysis.R`](sdg_energy_transition_analysis.R), dengan `set.seed(2026)`.

1. **Prapengolahan.** Tiga fitur yang sangat menceng ditransformasi dengan log(1 + x). Skewness absolut maksimum turun dari 5,87 menjadi 1,74 ([`table_02`](output/tables/table_02_descriptive_stats_transformation.csv)). Keenam fitur lalu distandardisasi memakai rata-rata dan simpangan baku tahun 2023.
2. **Diagnostik.** Pencilan diperiksa dengan jarak Mahalanobis (D² > 22,46, kuantil chi-kuadrat 0,999). Enam ekonomi melewati batas ini dan tetap dipertahankan ([`table_03`](output/tables/table_03_mahalanobis_outliers.csv)). Nilai KMO keseluruhan 0,767, statistik Hopkins 0,9995, dan PC1 menjelaskan 59,4% varians ([`output/console_summary.txt`](output/console_summary.txt)).
3. **Empat metode untuk k = 2 sampai 6.** Metode yang dibandingkan: K-Means (`nstart = 100`), PAM/K-Medoids, hierarki Ward D2 (jarak Euklides), dan Gaussian Mixture Model (`mclust`, model kovarians dipilih dengan BIC). Keempatnya mewakili pendekatan yang berbeda: berbasis rata-rata, berbasis objek representatif yang lebih tahan pencilan, hierarki aglomeratif, dan model probabilistik.
4. **Evaluasi.** Indeks internal yang dipakai: Silhouette, Davies-Bouldin, Calinski-Harabasz, dan Dunn. Stabilitas diukur dengan Jaccard bootstrap (`fpc::clusterboot`, B = 500). Untuk GMM, bootstrap ditulis manual, dan jumlah replikasi yang berhasil dihitung dari hasil bootstrap itu sendiri ([`table_04`](output/tables/table_04_model_comparison.csv)). Kesepakatan antarmetode diukur dengan Adjusted Rand Index ([`table_05`](output/tables/table_05_ari_agreement_between_methods.csv)).
5. **Uji sensitivitas.** (a) Data hilang diimputasi dengan `missMDA::imputePCA` pada 207 ekonomi yang punya minimal 4 dari 6 indikator, lalu hasilnya dibandingkan pada 189 ekonomi yang sama. (b) Spesifikasi kovarians GMM: model bebas pilihan BIC (VEV) dibandingkan dengan model sferis EII ([`table_11`](output/tables/table_11_gmm_covariance_sensitivity.csv)).
6. **Validasi eksternal.** Uji Kruskal-Wallis untuk PDB per kapita PPP dan urbanisasi antarrezim.
7. **Perbandingan 2015 dengan 2023.** Data 2015 diskalakan memakai parameter 2023, lalu tiap ekonomi ditempatkan ke centroid K-Means 2023 terdekat. Dengan cara ini model tidak dilatih ulang pada data 2015.
8. **Jalur perubahan.** Untuk 189 ekonomi yang sama, perubahan dari 2015 ke 2023 dihitung pada keenam indikator: selisih poin persen untuk tiga pangsa, dan selisih log(1 + x) untuk kapasitas EBT, intensitas energi, dan CO2. Kolom-kolomnya distandardisasi lalu dikelompokkan dengan FANNY fuzzy (`cluster::fanny`) untuk k = 2 sampai 6. Eksponen keanggotaan adalah nilai terbesar di {2; 1,7; 1,5; 1,3; 1,2} yang menghasilkan k klaster berbeda untuk setiap k; nilai bawaan 2 membuat keanggotaan seragam pada data ini. Kandidat dibandingkan pada Silhouette, koefisien Dunn ternormalisasi, ambiguitas keanggotaan, konvergensi, ukuran klaster, dan stabilitas pada 200 sub-sampel 80% dengan label yang disejajarkan ke solusi penuh. Aturan memilih k paling stabil dengan setiap klaster minimal 10 ekonomi, dan struktur disebut lemah bila Silhouette di bawah 0,25 atau Jaccard rata-rata di bawah 0,75. Grid eksponen dan ambang struktur lemah ini adalah pilihan eksploratif yang ditetapkan setelah fit awal menunjukkan eksponen bawaan menghasilkan keanggotaan seragam. PAM pada fitur yang sama dan FANNY pada selisih mentah (tanpa transformasi) menjadi uji sensitivitas ([`table_12`](output/tables/table_12_change_pathways_k_comparison.csv)).
9. **Prediksi memasak bersih 2023.** Targetnya akses memasak bersih 2023, dan prediktornya hanya data 2015. Tiga model memakai 10 lipatan luar negara yang sama: persistensi (nilai 2015), regresi linear pada memasak bersih 2015, dan elastic net (`glmnet`) pada keenam indikator 2015. Alpha (0,1 sampai 1) dan lambda elastic net dipilih di 10 lipatan dalam, dan standardisasi hanya dipelajari dari lipatan latih. Prediksi di luar 0 sampai 100 dipotong ke rentang itu untuk semua model, aturan yang ditetapkan sebelum fit. Interval kepercayaan untuk selisih MAE berasal dari pengambilan sampel ulang berpasangan atas galat out-of-fold yang sudah ada (2.000 sampel ulang negara); model tidak di-fit ulang.

## Hasil utama

**Pemilihan k.** Untuk K-Means, k = 2 memberi Silhouette tertinggi (0,4451) dan Jaccard rata-rata 0,9758. Di antara k ≥ 3, stabilitas tertinggi ada pada k = 4, dengan Jaccard rata-rata 0,9533, minimum 0,9114, dan Silhouette 0,3485 ([`table_04`](output/tables/table_04_model_comparison.csv)). Analisis utama memakai k = 4 karena keempat rezimnya membedakan pola kebijakan yang tergabung pada k = 2. Hasil k = 2 tetap dilaporkan sebagai alternatif. Pada k = 2, rezim B2 menggabungkan seluruh R3 dan R4 serta 8 ekonomi R2 ([`table_10`](output/tables/table_10_two_regime_alternative_k2.csv)).

**Empat rezim 2023 (K-Means, k = 4)** ([`table_06`](output/tables/table_06_global_regime_profiles_2023.csv)):

| Rezim | Negara | Median akses listrik (%) | Median memasak bersih (%) | Median pangsa EBT final (%) | Median CO2 (t/kap) | Jaccard |
|---|---|---|---|---|---|---|
| R1 Defisit akses dan perangkap biomassa | 27 | 40,5 | 5 | 78,98 | 0,17 | 0,965 |
| R2 Transisi akses berkembang | 41 | 83,6 | 44 | 40,35 | 0,74 | 0,963 |
| R3 Elektrifikasi efisien dan EBT modern | 95 | 100 | 98 | 17,14 | 3,67 | 0,974 |
| R4 Intensif fosil dan emisi tinggi | 26 | 100 | 100 | 1,31 | 11,99 | 0,911 |

R1 memperlihatkan paradoks biomassa: median pangsa energi terbarukannya paling tinggi (78,98%), padahal median akses listriknya hanya 40,5% dan median akses memasak bersihnya 5%.

**Ketergantungan pada metode.** Pada k = 4, kesepakatan K-Means dengan Ward D2 cukup tinggi (ARI 0,795), tetapi dengan GMM rendah (ARI 0,3671) ([`table_05`](output/tables/table_05_ari_agreement_between_methods.csv)). Pada GMM VEV, dua komponen memiliki varians `elec_access` terstandar yang sangat kecil (0,00308 dan 0,00300). Ini konsisten dengan banyaknya ekonomi yang terkumpul di batas atas 100% akses listrik (59,3% ekonomi pada 2023, [`table_01`](output/tables/table_01_data_quality_audit_2023.csv)). Dengan kovarians sferis EII, Silhouette naik dari 0,1975 menjadi 0,3599 dan ARI terhadap K-Means naik dari 0,3671 menjadi 0,8421 ([`table_11`](output/tables/table_11_gmm_covariance_sensitivity.csv)). Jadi hasil GMM sensitif terhadap spesifikasi kovarians pada keenam fitur.

**Sensitivitas dan validasi** ([`output/console_summary.txt`](output/console_summary.txt)):
- Model hasil imputasi (n = 207) memberi pengelompokan yang identik pada 189 ekonomi yang sama (ARI 1,0000).
- Rezim berbeda nyata dalam PDB per kapita PPP (Kruskal-Wallis H = 116,03, p = 5,527e-25) dan urbanisasi (H = 67,79, p = 1,271e-14), padahal kedua variabel ini tidak dipakai dalam model.

**2015 dibanding 2023** ([`table_08`](output/tables/table_08_migration_matrix_2015_2023.csv)): 165 dari 189 ekonomi berada di rezim yang sama. 7 ekonomi pindah dari R1 ke R2, 8 dari R2 ke R3, 7 dari R4 ke R3, dan 2 dari R3 ke R4. Ini perbandingan deskriptif posisi terhadap struktur rezim 2023, bukan estimasi dampak suatu kebijakan.

**Jalur perubahan 2015 ke 2023** ([`table_12`](output/tables/table_12_change_pathways_k_comparison.csv), [`table_13`](output/tables/table_13_change_pathway_profiles.csv), [`table_14`](output/tables/table_14_change_pathway_memberships.csv)): Aturan pemilihan memberi k = 2 (FANNY, eksponen keanggotaan 1,3, Jaccard sub-sampel rata-rata 0,9334), tetapi strukturnya lemah: Silhouette 0,2047, kesepakatan dengan PAM pada fitur yang sama hanya ARI 0,208, dan dengan FANNY pada selisih mentah ARI 0,6195. Jalur P1 (100 ekonomi) menambah akses, dengan median perubahan +6,9 poin persen pada akses listrik dan +7 poin pada memasak bersih, sementara pangsa EBT turun 2,19 poin dan CO2 per kapita naik 0,128 t. Jalur P2 (89 ekonomi) hampir tidak punya ruang menambah akses (median +0 poin listrik, +1 poin memasak bersih) dan bergerak ke arah karbon lebih rendah: pangsa EBT naik 2,74 poin, kapasitas EBT naik 143,22 W per kapita, dan CO2 per kapita turun 0,53 t. Kesepakatan dengan rezim 2023 hanya ARI 0,112: P2 berisi 62 ekonomi R3 dan 17 ekonomi R4, sedangkan P1 tersebar di keempat rezim. Jalur ini merangkum arah perubahan, bukan kelompok yang terpisah tegas.

**Prediksi memasak bersih 2023** ([`table_15`](output/tables/table_15_clean_cooking_forecast_metrics.csv), [`table_16`](output/tables/table_16_clean_cooking_forecast_oof.csv), [`table_17`](output/tables/table_17_clean_cooking_forecast_tuning.csv)): MAE out-of-fold adalah 5,19 poin persen untuk persistensi, 3,79 untuk regresi linear pada memasak bersih 2015, dan 3,33 untuk elastic net (RMSE 8,24; 6,04; dan 5,39). Pada interval ini, MAE elastic net lebih rendah 1,86 poin daripada persistensi (IK 95% 1,19 sampai 2,51) dan 0,46 poin daripada regresi yang hanya memakai memasak bersih (IK 95% 0,086 sampai 0,826), dengan interval dari pengambilan sampel ulang berpasangan atas galat out-of-fold. Perbandingan dengan regresi mengubah prediktor sekaligus metode estimasi, jadi selisihnya mengukur kinerja model secara keseluruhan dan tidak memisahkan sumbangan lima indikator tambahan. Sebelum dipotong, 61 prediksi regresi linear dan 50 prediksi elastic net berada di luar 0 sampai 100. Ini validasi antarnegara pada satu interval, bukan peramalan tahun-tahun berikutnya.

**Indonesia dan ASEAN** ([`table_09`](output/tables/table_09_indonesia_asean_benchmark.csv)): Indonesia berada di R3, dengan akses listrik 99,4% pada 2023 dan kapasitas listrik terbarukan 47,39 W per kapita. Sebagai pembanding, Viet Nam memiliki 476,30 W per kapita.

## Keterbatasan

- Analisis *complete-case* mengeluarkan 26 dari 215 ekonomi. Uji imputasi hanya mencakup ekonomi dengan minimal 4 indikator.
- Akses listrik dan memasak bersih memiliki batas atas 100%, sehingga banyak ekonomi bernilai sama. Ini memengaruhi metode yang memodelkan bentuk kovarians.
- Keenam fitur diberi bobot setara setelah standardisasi. Pilihan fitur dan transformasi memengaruhi rezim yang terbentuk.
- Penempatan 2015 memakai centroid 2023. Hasilnya menggambarkan posisi relatif, bukan rezim yang akan terbentuk bila 2015 dikelompokkan sendiri.
- Seri CO2 menggabungkan dua sumber (EDGAR dan IEA) yang metodenya berbeda.
- Data API dapat direvisi oleh penyedianya, sehingga pengunduhan ulang bisa menghasilkan angka yang sedikit berbeda dari panel tersimpan.
- Jalur perubahan hanya mencakup satu interval delapan tahun. Ekonomi yang sudah mencapai 100% akses listrik atau memasak bersih tidak bisa naik lagi, dan hal ini ikut membentuk jalur.
- Prediksi memasak bersih adalah validasi antarnegara pada satu interval historis (2015 ke 2023). Hasilnya tidak menunjukkan seberapa baik model meramal tahun-tahun berikutnya.

## Struktur repositori

```
.
├── sdg_energy_transition_analysis.R   analisis lengkap dari panel tersimpan
├── download_sdg_data.R           opsional: unduh ulang data dari API UNSD dan World Bank
├── data/
│   ├── sdg_energy_climate_panel_2015_2023.csv
│   └── sdg_data_dictionary.csv
├── output/
│   ├── tables/    table_01 s.d. table_17 (CSV)
│   ├── figures/   fig01 s.d. fig06 (PNG, 300 DPI)
│   └── console_summary.txt
├── dashboard/
│   ├── index.html
│   └── data/      dashboard_data.json, dashboard_data.js
└── index.html     mengarahkan ke dashboard/
```

## Reproduksi

Semua perintah dijalankan dari folder utama repositori, dengan `Rscript` tersedia di PATH.

### 1. Analisis dari panel tersimpan (alur utama)

Paket R yang dibutuhkan:

```r
install.packages(c(
  "dplyr", "tidyr", "readr", "ggplot2", "scales", "psych", "cluster",
  "mclust", "fpc", "hopkins", "missMDA", "jsonlite", "glmnet",
  "rnaturalearth", "rnaturalearthdata", "sf"
))
```

```bash
Rscript sdg_energy_transition_analysis.R
```

Skrip ini membaca `data/sdg_energy_climate_panel_2015_2023.csv` lalu menulis ulang `output/tables/`, `output/figures/`, dan `dashboard/data/`. Tidak perlu koneksi internet.

### 2. Unduh ulang data (opsional)

Skrip ini membutuhkan koneksi internet dan paket `httr2`, `jsonlite`, `dplyr`, `tidyr`, `readr`, dan `countrycode`.

```bash
Rscript download_sdg_data.R
```

Skrip ini menimpa kedua berkas di `data/`. Variabel lingkungan `SDG_RDS_CACHE` dapat diisi dengan sebuah folder untuk menyimpan respons API sebagai cache. Setelah mengunduh ulang, jalankan langkah 1 lagi.

### 3. Dashboard

Dashboard memuat `dashboard/data/dashboard_data.json` lewat `fetch`, dengan `dashboard_data.js` sebagai cadangan. Sebaiknya buka melalui server lokal:

```bash
python -m http.server 8000 --directory dashboard
```

Lalu buka http://localhost:8000.
