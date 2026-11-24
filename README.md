# biomass-paradox

**English** · [Bahasa Indonesia](README.id.md)

Clustering of 189 sovereign economies on six clean energy and emissions indicators (SDG 7 and SDG 13) for 2023, comparing four clustering methods with bootstrap stability checks.

Interactive dashboard (ID/EN): https://febrianggi.github.io/biomass-paradox/

## Research questions

Rankings built on a single indicator can mislead. On SDG 7.2.1 (renewable share of final energy consumption), economies with low electricity access often score high because they rely on firewood and traditional biomass. This repository asks:

1. Which regimes emerge when 189 economies are clustered jointly on six SDG 7 and SDG 13 indicators for 2023?
2. How stable are those regimes, and how much do they depend on the choice of method?
3. Where does each economy sit in 2015 when mapped onto the 2023 regime structure?

## Data

Sources: UN SDG Indicators Database (UNSD API) and World Bank Open Data. Series codes, custodians, units, and transformations for every variable are listed in [`data/kamus_data_sdg.csv`](data/kamus_data_sdg.csv).

| Feature | Indicator | Transformation |
|---|---|---|
| `elec_access` | SDG 7.1.1, access to electricity (% of population) | z-score |
| `clean_cooking` | SDG 7.1.2, access to clean cooking fuels and technologies (% of population) | z-score |
| `renew_share_tfec` | SDG 7.2.1, renewable share of total final energy consumption (%) | z-score |
| `renew_cap_wpc` | SDG 7.b.1, renewable electricity capacity (W per capita) | log(1 + x), then z-score |
| `energy_intensity` | SDG 7.3.1, primary energy intensity (MJ per 2021 PPP USD) | log(1 + x), then z-score |
| `co2_per_capita` | CO2 emissions per capita (tonnes) | log(1 + x), then z-score |

- The panel [`data/sdg_energy_climate_panel_2015_2023.csv`](data/sdg_energy_climate_panel_2015_2023.csv) covers 215 economies for 2015, 2022, and 2023. The analysis uses 2015 and 2023.
- Models use only economies complete on all six features: 189 of 215, covering 8.02 billion people ([`output/ringkasan_konsol.txt`](output/ringkasan_konsol.txt)). The most missing values are in `clean_cooking` (23 economies, 10.7%) ([`tabel_01`](output/tables/tabel_01_audit_kualitas_data_2023.csv)).
- CO2 per capita comes from the World Bank (EDGAR, AR5). Where it is missing, the UNSD (IEA) series fills the gap. The source of each row is recorded in the `co2_source` column.
- GDP per capita (PPP) and urban population share are not used in the models. They serve only as external validators.

## Method

Every step is in [`analisis_sdg_transisi_energi.R`](analisis_sdg_transisi_energi.R), with `set.seed(2026)`.

1. **Preprocessing.** The three strongly skewed features are transformed with log(1 + x). The largest absolute skewness falls from 5.87 to 1.74 ([`tabel_02`](output/tables/tabel_02_statistik_deskriptif_transformasi.csv)). All six features are then standardised with the 2023 means and standard deviations.
2. **Diagnostics.** Outliers are screened with Mahalanobis distance (D² > 22.46, the 0.999 chi-square quantile). Six economies exceed this cut-off and are kept ([`tabel_03`](output/tables/tabel_03_pencilan_mahalanobis.csv)). Overall KMO is 0.767, the Hopkins statistic is 0.9995, and PC1 explains 59.4% of the variance ([`output/ringkasan_konsol.txt`](output/ringkasan_konsol.txt)).
3. **Four methods for k = 2 to 6.** The methods compared are K-Means (`nstart = 100`), PAM/K-Medoids, hierarchical Ward D2 (Euclidean distance), and a Gaussian Mixture Model (`mclust`, with the covariance model chosen by BIC). Together they cover different approaches: mean-based, representative-object (more robust to outliers), agglomerative hierarchy, and probabilistic.
4. **Evaluation.** The internal indices are Silhouette, Davies-Bouldin, Calinski-Harabasz, and Dunn. Stability is measured with bootstrap Jaccard (`fpc::clusterboot`, B = 500). For GMM the bootstrap loop is written by hand, and successful replicates are counted from the bootstrap results themselves ([`tabel_04`](output/tables/tabel_04_evaluasi_komparatif_model.csv)). Agreement between methods is measured with the Adjusted Rand Index ([`tabel_05`](output/tables/tabel_05_kesepakatan_ari_antar_metode.csv)).
5. **Sensitivity checks.** (a) Missing data are imputed with `missMDA::imputePCA` on the 207 economies that have at least 4 of the 6 indicators, and the result is compared on the 189 shared economies. (b) GMM covariance specification: the unconstrained BIC choice (VEV) is compared with a spherical EII model ([`tabel_11`](output/tables/tabel_11_uji_hipotesis_batas_atas_gmm.csv)).
6. **External validation.** Kruskal-Wallis tests for GDP per capita (PPP) and urbanisation across regimes.
7. **2015 versus 2023.** The 2015 data are scaled with the 2023 parameters, and each economy is assigned to the nearest 2023 K-Means centroid. This way the model is not refitted on 2015 data.

## Main results

**Choice of k.** For K-Means, k = 2 gives the highest Silhouette (0.4451) and a mean Jaccard of 0.9758. Among k ≥ 3, stability peaks at k = 4, with a mean Jaccard of 0.9533, a minimum of 0.9114, and a Silhouette of 0.3485 ([`tabel_04`](output/tables/tabel_04_evaluasi_komparatif_model.csv)). The main analysis uses k = 4 because its four regimes separate policy patterns that k = 2 merges. The k = 2 solution is still reported as an alternative. At k = 2, regime B2 combines all of R3 and R4 plus 8 R2 economies ([`tabel_10`](output/tables/tabel_10_alternatif_dua_rezim_k2.csv)).

**Four regimes in 2023 (K-Means, k = 4)** ([`tabel_06`](output/tables/tabel_06_profil_rezim_global_2023.csv)):

| Regime | Countries | Median electricity access (%) | Median clean cooking (%) | Median renewable share of final energy (%) | Median CO2 (t per capita) | Jaccard |
|---|---|---|---|---|---|---|
| R1 Acute energy deficit and biomass trap | 27 | 40.5 | 5 | 78.98 | 0.17 | 0.965 |
| R2 Expanding access, cooking-lag transition | 41 | 83.6 | 44 | 40.35 | 0.74 | 0.963 |
| R3 Efficient electrification and modern renewables | 95 | 100 | 98 | 17.14 | 3.67 | 0.974 |
| R4 Fossil-locked and high-carbon intensive | 26 | 100 | 100 | 1.31 | 11.99 | 0.911 |

R1 shows the biomass paradox: it has the highest median renewable share (78.98%), yet its median electricity access is only 40.5% and its median clean cooking access is 5%.

**Dependence on method.** At k = 4, K-Means agrees fairly well with Ward D2 (ARI 0.795) but poorly with GMM (ARI 0.3671) ([`tabel_05`](output/tables/tabel_05_kesepakatan_ari_antar_metode.csv)). In the VEV GMM, two components have very small standardised `elec_access` variances (0.00308 and 0.00300). This is consistent with many economies sitting at the 100% electricity access ceiling (59.3% of economies in 2023, [`tabel_01`](output/tables/tabel_01_audit_kualitas_data_2023.csv)). With spherical EII covariance, Silhouette rises from 0.1975 to 0.3599 and ARI against K-Means rises from 0.3671 to 0.8421 ([`tabel_11`](output/tables/tabel_11_uji_hipotesis_batas_atas_gmm.csv)). The GMM result is therefore sensitive to the covariance specification across all six features.

**Sensitivity and validation** ([`output/ringkasan_konsol.txt`](output/ringkasan_konsol.txt)):
- The imputed model (n = 207) gives an identical partition on the 189 shared economies (ARI 1.0000).
- Regimes differ clearly in GDP per capita (PPP) (Kruskal-Wallis H = 116.03, p = 5.527e-25) and urbanisation (H = 67.79, p = 1.271e-14), even though neither variable is used in the models.

**2015 versus 2023** ([`tabel_08`](output/tables/tabel_08_matriks_migrasi_2015_2023.csv)): 165 of 189 economies sit in the same regime. 7 economies moved from R1 to R2, 8 from R2 to R3, 7 from R4 to R3, and 2 from R3 to R4. This is a descriptive comparison of positions against the 2023 regime structure, not an estimate of the effect of any policy.

**Indonesia and ASEAN** ([`tabel_09`](output/tables/tabel_09_benchmark_indonesia_asean.csv)): Indonesia is in R3, with 99.4% electricity access in 2023 and renewable electricity capacity of 47.39 W per capita. For comparison, Viet Nam has 476.30 W per capita.

## Limitations

- The complete-case analysis drops 26 of 215 economies. The imputation check covers only economies with at least 4 indicators.
- Electricity access and clean cooking are capped at 100%, so many economies share the same value. This affects methods that model the shape of the covariance.
- All six features carry equal weight after standardisation. The choice of features and transformations shapes the regimes.
- The 2015 assignment uses the 2023 centroids. It describes relative position, not the regimes that would emerge if 2015 were clustered on its own.
- The CO2 series combines two sources (EDGAR and IEA) with different methods.
- Data providers can revise their API data, so re-downloading may give slightly different numbers from the saved panel.

## Repository structure

```
.
├── analisis_sdg_transisi_energi.R   full analysis from the saved panel
├── unduh_data_resmi_sdg.R           optional: re-download data from the UNSD and World Bank APIs
├── data/
│   ├── sdg_energy_climate_panel_2015_2023.csv
│   └── kamus_data_sdg.csv
├── output/
│   ├── tables/    tabel_01 to tabel_11 (CSV)
│   ├── figures/   fig01 to fig06 (PNG, 300 DPI)
│   └── ringkasan_konsol.txt
├── dashboard/
│   ├── index.html
│   └── data/      dashboard_data.json, dashboard_data.js
└── index.html     redirects to dashboard/
```

## Reproduction

Run every command from the repository root, with `Rscript` on your PATH.

### 1. Analysis from the saved panel (main workflow)

Required R packages:

```r
install.packages(c(
  "dplyr", "tidyr", "readr", "ggplot2", "scales", "psych", "cluster",
  "mclust", "fpc", "hopkins", "missMDA", "jsonlite",
  "rnaturalearth", "rnaturalearthdata", "sf"
))
```

```bash
Rscript analisis_sdg_transisi_energi.R
```

The script reads `data/sdg_energy_climate_panel_2015_2023.csv` and rewrites `output/tables/`, `output/figures/`, and `dashboard/data/`. No internet connection is needed.

### 2. Re-download the data (optional)

This step needs an internet connection and the packages `httr2`, `jsonlite`, `dplyr`, `tidyr`, `readr`, and `countrycode`.

```bash
Rscript unduh_data_resmi_sdg.R
```

The script overwrites both files in `data/`. Set the environment variable `SDG_RDS_CACHE` to a folder to cache the API responses there. After re-downloading, run step 1 again.

### 3. Dashboard

The dashboard loads `dashboard/data/dashboard_data.json` with `fetch`, falling back to `dashboard_data.js`. Opening it through a local server is recommended:

```bash
python -m http.server 8000 --directory dashboard
```

Then open http://localhost:8000.
