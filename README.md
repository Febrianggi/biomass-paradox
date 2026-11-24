# Panduan Menjalankan Kode R & Dashboard UAS Data Mining (SDG 7 & SDG 13)

**Judul Penelitian:** Membongkar Paradoks Biomassa dan Trilema Transisi Energi-Iklim Global (SDG 7 & SDG 13): Perbandingan Empat Metode Clustering Data Mining dan Dinamika Rezim Pasca-Kesepakatan Paris (2015 s/d 2023)

Proyek ini disusun untuk memenuhi seluruh ketentuan **UAS Data Mining Semester 5 (S1 Statistika UNPAD)**: mencakup rumusan masalah SDGs, pengumpulan dan audit data terbuka resmi, prapengolahan bebas kebocoran data (*zero data leakage*), perbandingan empat algoritma *clustering*, evaluasi bootstrap, hingga komunikasi temuan melalui grafik publikasi 300 DPI dan dashboard web interaktif dwibahasa (ID/EN).

## Struktur Berkas

- `analisis_sdg_transisi_energi.R`: Skrip utama analisis Data Mining lengkap (Tahap 1 s/d Tahap 6, `seed = 2026`).
- `unduh_data_resmi_sdg.R`: Skrip akuisisi ulang data langsung dari API resmi UN SDG Portal (`unstats.un.org/SDGAPI`) dan World Bank Open Data (`api.worldbank.org/v2`).
- `data/sdg_energy_climate_panel_2015_2023.csv`: Dataset terverifikasi 215 ekonomi berdaulat (189 negara berdaulat memiliki observasi lengkap pada ke-6 indikator inti baik di tahun 2015 maupun 2023, mencakup 8,02 miliar jiwa).
- `data/kamus_data_sdg.csv`: Kamus metadata resmi (kode seri PBB/Bank Dunia, target & indikator SDG, lembaga kustodian IEA/IRENA/WHO/UNSD, satuan, dan peran variabel).
- `output/tables/`: Sebelas tabel CSV hasil audit data, statistik deskriptif transformasi, pencilan Mahalanobis, evaluasi 20 model (4 metode x k=2..6 dengan perhitungan terukur replikasi bootstrap `B=500` berhasil langsung dari matriks hasil bootstrap), matriks kesepakatan ARI, profil 4 rezim global, hasil lengkap 189 negara, matriks migrasi 2015 ke 2023, benchmark ASEAN-11, alternatif biner dua rezim (`k=2`), dan diagnostik sensitivitas spesifikasi kovarians GMM (`tabel_11`).
- `output/figures/`: Enam grafik PNG resolusi tinggi (300 DPI) siap sisip untuk Laporan Penelitian (BAB IV) dan X-Banner.
- `dashboard/index.html` & `dashboard/data/`: Dashboard interaktif dwibahasa (ID/EN) dengan dukungan mode terang/gelap, peta dunia proyeksi Robinson, zoom ASEAN, inspeksi 189 negara, eksplorasi PCA & Paradoks Biomassa, kurva evaluasi 4 metode, matriks migrasi interaktif, dan tabel urut (*sortable*).

## Dependensi Paket R

Pastikan R (>= 4.3) terpasang bersama paket berikut:

```r
install.packages(c(
  "dplyr", "tidyr", "readr", "ggplot2", "scales",
  "psych", "cluster", "mclust", "fpc", "hopkins",
  "missMDA", "jsonlite", "rnaturalearth", "rnaturalearthdata", "sf",
  "httr2", "countrycode"
))
```

## Cara Menjalankan Ulang Analisis R

Buka PowerShell (atau jalankan melalui RStudio dengan *working directory* pada folder ini):

```powershell
cd "D:\Tugas Anggi\anggi\Repos\biomass-paradox"
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" analisis_sdg_transisi_energi.R
```

Seluruh tabel CSV di `output/tables/`, keenam grafik PNG di `output/figures/`, serta berkas data `dashboard/data/dashboard_data.json` akan dibangun ulang secara deterministik (`set.seed(2026)`).

## Cara Membuka Dashboard Interaktif

Sesuai standar web modern (pemuatan JSON via `fetch`), jalankan server lokal dari folder `dashboard`:

```powershell
cd "D:\Tugas Anggi\anggi\Repos\biomass-paradox\dashboard"
python -m http.server 8000
```

Lalu buka http://localhost:8000 di peramban (Chrome/Edge/Firefox). Hentikan server dengan `Ctrl+C`.

## Pemetaan ke Sistematika Laporan UAS (50%) & X-Banner (4%)

1. **BAB I (Pendahuluan)**: Gunakan konteks Trilema Energi Global & *Paradoks Biomassa* pada indikator tunggal SDG 7.2.1 (negara defisit listrik tampak memiliki pangsa EBT >75% akibat kayu bakar tradisional).
2. **BAB II (Tinjauan Pustaka)**: Bandingkan empat paradigma *clustering*: partisi berbasis rata-rata (*K-Means*), partisi berbasis objek representatif tahan pencilan (*PAM / K-Medoids*), hierarki aglomeratif (*Ward's D2*), dan model campuran probabilistik (*GMM / EM*), beserta validasi stabilitas bootstrap Jaccard (Hennig, 2007).
3. **BAB III (Data & Metodologi)**: Gunakan `data/kamus_data_sdg.csv`, `tabel_01_audit_kualitas_data_2023.csv`, `tabel_02_statistik_deskriptif_transformasi.csv`, dan `tabel_03_pencilan_mahalanobis.csv`. Jelaskan pencegahan *data leakage* (PDB PPP & urbanisasi ditahan sebagai validator eksternal; data 2015 diproyeksikan memakai parameter penskalaan 2023).
4. **BAB IV (Hasil & Pembahasan)**: Gunakan `fig01` s/d `fig06` dan `tabel_04` s/d `tabel_11`. Soroti pemisahan antara optimum biner kasar pada `k = 2` (Jaccard 0,976; Silhouette 0,445) dan puncak stabilitas multi-rezim (`k >= 3`) pada `k = 4` (Jaccard rata-rata 0,953; seluruh klaster >= 0,911), diagnostik GMM (`VEV` varians `elec_access` 0,0030 dan 0,0031 yang konsisten dengan konsentrasi di batas atas 100%, serta sensitivitas terhadap spesifikasi kovarians di keenam fitur ketika `GMM EII` sferis menghasilkan Silhouette 0,360 dan ARI 0,842), sensitivitas imputasi `missMDA` (`n = 207`, dievaluasi pada 189 kasus bersama dengan ARI = 1,0000), migrasi positif 22 negara pasca-Kesepakatan Paris, serta posisi Indonesia di Rezim R3 (akses listrik 99,4%, tetapi kapasitas listrik EBT baru 47,4 W/kapita dibanding Vietnam 476 W/kapita).
5. **BAB V (Kesimpulan & Saran)**: Rumuskan rekomendasi spesifik per rezim (R1 s/d R4) dan peta jalan akselerasi PLTS, panas bumi, serta interkoneksi jaringan antarpulau bagi Indonesia.
