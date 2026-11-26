# The Biomass Paradox in the Global Energy-Climate Transition

**English** · [Bahasa Indonesia](README.id.md)

A multivariate analysis and interactive dashboard covering 189 sovereign economies (8.02 billion people) across six SDG 7 and SDG 13 indicators for 2015 and 2023. The project groups economies into clean-energy and emissions regimes, checks how stable those regimes are across four clustering methods, tracks shifts since 2015, and tests whether 2015 conditions predict 2023 clean cooking access.

- **Landing page:** https://febrianggi.github.io/biomass-paradox/
- **Interactive dashboard (ID/EN):** https://febrianggi.github.io/biomass-paradox/dashboard/

## Why this analysis exists

A high renewable energy share does not automatically mean modern clean electricity. On SDG 7.2.1 (renewable share of total final energy consumption), economies with low electricity access often rank near the top because households rely on firewood, charcoal, and agricultural waste for cooking. Reading that single indicator on its own blends traditional biomass with modern hydropower, solar, wind, and geothermal power.

To separate those patterns, this repository evaluates six indicators jointly and answers five questions:

1. Which energy-climate regimes emerge when 189 economies are clustered jointly on six SDG 7 and SDG 13 indicators for 2023?
2. How stable are those regimes, and how much do they depend on the choice of clustering method?
3. Where did each economy sit in 2015 when mapped onto the 2023 regime structure?
4. Do the changes from 2015 to 2023 form distinct transition pathways?
5. Do 2015 conditions predict 2023 clean cooking access better than simple persistence?

## Main findings

### Four global regimes in 2023 (K-Means, k = 4)

Among multi-regime solutions (`k >= 3`), K-Means at `k = 4` hits a clear stability peak (mean bootstrap Jaccard 0.9533, minimum 0.9114, Silhouette 0.3485; [`table_04`](output/tables/table_04_model_comparison.csv)). Globally, `k = 2` has a higher Silhouette (0.4451, mean Jaccard 0.9758), but its upper group `B2` merges all of `R3` and `R4` plus 8 `R2` economies ([`table_10`](output/tables/table_10_two_regime_alternative_k2.csv)). Both solutions are reported and available in the dashboard; `k = 4` is the primary view because it separates both the biomass paradox (`R1` vs `R2`) and fossil lock-in (`R3` vs `R4`).

| Regime | Economies | Median electricity access (%) | Median clean cooking (%) | Median renewable share (%) | Median renewable capacity (W/cap) | Median CO2 (t/cap) | Jaccard |
|---|---:|---:|---:|---:|---:|---:|---:|
| R1 Acute energy deficit and biomass trap | 27 | 40.5 | 5 | 78.98 | 11.6 | 0.17 | 0.965 |
| R2 Expanding access, cooking-lag transition | 41 | 83.6 | 44 | 40.35 | 53.2 | 0.74 | 0.963 |
| R3 Efficient electrification and modern renewables | 95 | 100.0 | 98 | 17.14 | 552.2 | 3.67 | 0.974 |
| R4 Fossil-locked and high-carbon intensive | 26 | 100.0 | 100 | 1.31 | 114.7 | 11.99 | 0.911 |

Source: [`table_06`](output/tables/table_06_global_regime_profiles_2023.csv).

`R1` shows the biomass paradox directly: it has the highest median renewable share of final energy (78.98%), yet median electricity access is only 40.5%, median clean cooking is 5%, and installed renewable power capacity is just 11.6 W per capita.

### What a regime means and how each method assigns R1 to R4

In this study, a **regime** is not a single-indicator ranking or a political bloc, but a recurring multivariate structural profile across all six SDG 7 and SDG 13 indicators jointly. Economies in the same regime face similar energy-transition constraints.

None of the four algorithms uses manual country cut-offs. All four run unsupervised on the six features after `log(1 + x)` transformation (on renewable capacity, energy intensity, and CO2) and z-score standardisation:

- **K-Means (chosen model):** Assigns each economy to the nearest cluster centroid (mean vector across the six standardised features) minimising squared Euclidean distance (`nstart = 100`, `iter.max = 200`).
- **Hierarchical Ward D2:** Starts with each economy as its own cluster and iteratively merges the pair that causes the smallest increase in total within-cluster variance, then cuts the dendrogram at `k = 4`.
- **PAM (K-Medoids):** Selects four actual economies as representative medoids (`TZA`, `PAK`, `JAM`, `SVN`) and assigns every economy to its nearest Euclidean medoid, making boundaries less sensitive to extreme values.
- **GMM (`mclust`, BIC-selected `VEV`):** Fits four ellipsoidal multivariate Gaussian distributions via Expectation-Maximisation and assigns each economy to the component with the highest posterior probability.

**Deterministic label alignment (identical for all four methods):** Because raw cluster numbers from unsupervised algorithms are arbitrary, `order_regime_labels()` in `sdg_energy_transition_analysis.R` maps the four clusters consistently: **R1** is the cluster with the lowest mean electricity access; among the remaining three, **R4** is the cluster with the highest mean CO2 per capita; between the remaining two, **R2** has the lower mean electricity access; and the remaining cluster becomes **R3** (high access, low energy intensity, and higher modern renewable capacity).

### Why K-Means k = 4 was chosen over k = 2

On purely global internal indices, K-Means at `k = 2` scores higher (Silhouette 0.4451, Davies-Bouldin 0.9291, Calinski-Harabasz 163.44, mean Jaccard 0.9758) than `k = 4` (Silhouette 0.3485, Davies-Bouldin 1.1096, Calinski-Harabasz 120.77, mean Jaccard 0.9533; [`table_04`](output/tables/table_04_model_comparison.csv)). K-Means `k = 4` was selected as the primary model for three reasons:

1. **Why `k = 2` wins geometrically:** The widest single gap in the global data is a coarse binary split between basic-access deficit economies (`B1`, 60 economies) and electrified economies (`B2`, 129 economies).
2. **Why `k = 2` hides the core policy questions:** `B2` merges clean-power leaders such as Norway and Sweden (`R3`) into the same cluster as fossil-intensive high emitters such as Qatar and Russia (`R4`), while `B1` merges acute traditional-biomass poverty (`R1`, 5% median clean cooking) with expanding transition economies (`R2`, 44%).
3. **Why specifically `k = 4` (not `k = 3` or `k = 5`):** Among multi-regime models (`k >= 3`) that separate both the biomass paradox (`R1` vs `R2`) and fossil lock-in (`R3` vs `R4`), `k = 4` forms a sharp local stability peak: mean bootstrap Jaccard jumps from 0.7981 at `k = 3` (min 0.6951) to 0.9533 at `k = 4` (min 0.9114, 500/500 replicates, ARI 0.795 vs Ward D2), while `k = 5` drops sharply in compactness (Silhouette 0.2672, min Jaccard 0.8282). The `k = 2` alternative remains selectable directly on the dashboard map.

### Other core results

- **Method choice and GMM sensitivity:** At `k = 4`, K-Means agrees closely with hierarchical Ward D2 (ARI 0.795) but poorly with BIC-selected ellipsoidal `VEV` GMM (ARI 0.3671, Silhouette 0.1975; [`table_05`](output/tables/table_05_ari_agreement_between_methods.csv)). In `VEV` GMM, two components collapse to tiny standardised `elec_access` variances (0.00308 and 0.00300), consistent with 59.3% of economies sitting at the 100% electricity ceiling ([`table_01`](output/tables/table_01_data_quality_audit_2023.csv)). Switching GMM to spherical `EII` covariance raises Silhouette to 0.3599 and ARI against K-Means to 0.8421 ([`table_11`](output/tables/table_11_gmm_covariance_sensitivity.csv)), showing that the GMM gap reflects sensitivity to covariance specification across all six features.
- **Imputation and external validation:** Imputing missing values with `missMDA` on `n = 207` economies yields an identical partition on the 189 shared complete-case economies (ARI 1.0000). Held-out variables excluded from clustering differ sharply across regimes: GDP per capita PPP (Kruskal-Wallis H = 116.03, p = 5.527e-25) and urban population share (H = 67.79, p = 1.271e-14) ([`output/console_summary.txt`](output/console_summary.txt)).
- **2015 to 2023 regime positions:** Projected onto the 2023 centroids, 165 of 189 economies stay in the same regime ([`table_08`](output/tables/table_08_migration_matrix_2015_2023.csv)). 22 moved upward or toward lower carbon (7 from R1 to R2, 8 from R2 to R3, 7 from R4 to R3 including Malaysia), 2 shifted from R3 to R4, and 0 regressed into R1. This is a descriptive comparison of positions against the 2023 structure, not an estimate of policy impact.
- **2015 to 2023 change pathways:** Clustering the eight-year indicator changes with fuzzy FANNY selects `k = 2` (membership exponent 1.3, mean subsample Jaccard 0.9334), though the separation is weak (Silhouette 0.2047; ARI 0.208 vs PAM; ARI 0.6195 vs raw-difference FANNY; [`table_12`](output/tables/table_12_change_pathways_k_comparison.csv), [`table_13`](output/tables/table_13_change_pathway_profiles.csv), [`table_14`](output/tables/table_14_change_pathway_memberships.csv)). Pathway `P1` (100 economies) expanded basic access (median +6.9 percentage points electricity, +7 points clean cooking, renewable share -2.19 points, CO2 +0.128 t). Pathway `P2` (89 economies) already sat near full access (+0 electricity, +1 clean cooking) and shifted toward lower carbon (renewable share +2.74 points, renewable capacity +143.22 W/cap, CO2 -0.53 t). Agreement with the 2023 regimes is low (ARI 0.112), so `P1` and `P2` summarise direction of change rather than crisp groups.
- **Predicting 2023 clean cooking from 2015 data:** Across 10 shared country folds ([`table_15`](output/tables/table_15_clean_cooking_forecast_metrics.csv), [`table_16`](output/tables/table_16_clean_cooking_forecast_oof.csv), [`table_17`](output/tables/table_17_clean_cooking_forecast_tuning.csv)), out-of-fold MAE is 5.19 percentage points for persistence (2015 value), 3.79 for linear regression on 2015 clean cooking, and 3.33 for elastic net on all six 2015 indicators (RMSE 8.24, 6.04, and 5.39). Over this interval, elastic net lowers MAE by 1.86 points over persistence (95% CI 1.19 to 2.51) and by 0.46 points over the cooking-only regression (95% CI 0.086 to 0.826), with CIs from paired resampling of the out-of-fold errors. Because comparing elastic net to cooking-only OLS changes both the predictors and the estimation method, the 0.46-point gap measures overall model performance and does not isolate the contribution of the five extra indicators. Before clipping predictions to `[0, 100]`, 61 linear-regression predictions and 50 elastic-net predictions fell outside that range.
- **4-year 2027 projections and potential regime shifts (`2019 -> 2023 -> 2027`):** Official 2025-2026 UNSD/World Bank SDG 7 series are not yet published (0 rows), and 2024 drops half of `7.2.1`/`7.3.1` coverage (`271 -> 129`), whereas 2019 is 100% complete across all 189 economies ([`data/sdg_energy_climate_panel_2019.csv`](data/sdg_energy_climate_panel_2019.csv)). Validated on the matched 4-year interval `2019 -> 2023` across 10 folds ([`table_18`](output/tables/table_18_forecast_2027_cv_metrics.csv)), Elastic Net lowers OOF MAE over persistence on clean cooking (`1.865` vs `2.471` pp, 95% CI `-0.935` to `-0.257`), electricity (`1.565` vs `2.578` pp), energy intensity (`0.379` vs `0.413` MJ/USD), and renewable capacity (`88.7` vs `125.1` W/cap), while edging persistence on renewable share (`2.514` vs `2.636` pp) and tying on CO2 (`0.544` vs `0.548` t/cap). Projected onto the 2023 centroids, OOF regime accuracy reaches 97.9% (`185/189`, Kappa `0.968`) vs 96.8% for persistence ([`table_19`](output/tables/table_19_forecast_2027_regime_migration.csv)). Applying the full `2019 -> 2023` models to 2023 features projects **7 economies** shifting regimes by 2027 (0 regressing): `R1 -> R2` (`COG` margin `0.157`, `RWA` `0.047`), `R2 -> R3` (`PHL` `0.047`, `WSM` `0.039`), and `R4 -> R3` (`KOR` `0.172`, plus borderline crossings `CHN` `0.005` and `CAN` `0.003`; [`table_20`](output/tables/table_20_forecast_2027_country_projections.csv)). These are out-of-sample projections assuming 2019-2023 dynamics persist, not guaranteed forecasts.
- **Indonesia and ASEAN benchmark:** Indonesia sits in `R3` with 99.4% electricity access and 89% clean cooking in 2023 (up from 69% in 2015), yet installed renewable electricity capacity is 47.39 W per capita, compared with 552.2 W for the `R3` median and 476.30 W in Viet Nam ([`table_09`](output/tables/table_09_indonesia_asean_benchmark.csv)).

## How to read the dashboard

The landing page introduces the biomass paradox and links directly to the dashboard (`/dashboard/`). Inside the dashboard, the top bar stays consistent across all views: **ID / EN** switches both interface copy and ISO 3166-1 country names, the theme button toggles light and dark mode, and **Download CSV (189 Countries)** exports the complete country dataset. Clicking any country on the map, scatter plots, migration lists, or table selects it globally and updates the inspector panel.

| Tab | What it shows | How to use it |
|---|---|---|
| **Regime Map** | Interactive world choropleth, synchronized country inspector panel, KPI strip, and a built-in regime & method-criteria explainer | Switch **Map layer** across all 7 views (`2023 · K-Means k=4 (chosen model)`, `2023 · K-Means k=2 (binary alternative)`, `2015 · Baseline (projected k=4)`, `2027 · Elastic Net projection (k=4)`, `2023 · Ward's D2 k=4`, `2023 · PAM k=4`, `2023 · GMM k=4`). Switch **Extent** across **World**, **ASEAN**, **Asia**, **Africa**, **Europe**, **North America**, **South America**, and **Oceania** (per-regime country counts and profile cards update automatically for the chosen region), filter with **Highlight regime** (`All`, `R1` to `R4`), expand the criteria accordion to compare how all four methods form `R1` to `R4`, or search via **Find a country** using ISO 3166-1 names, Alpha-3 (`IDN`), or Alpha-2 (`ID`). |
| **Biomass Paradox** | Interactive scatter plots with clickable `R1` to `R4` regime legend, clickable PCA quadrant cards, and synchronized plot-reading guides, plus multivariate diagnostics (KMO, Bartlett, Hopkins, skewness before/after log transform) | Switch between three views: **Biomass paradox (7.2.1 vs 7.b.1)**, **PCA biplot**, and **Intensity vs CO2** (the guide box directly below the chart updates with quadrant meanings for each view). Click `R1` to `R4` in the chart legend or click any of the four quadrant cards in **PCA biplot** to highlight all economies in that group with animated transitions, use the spotlight pills (**All countries**, **Biomass trap (R1)**, **Indonesia vs ASEAN**, **Mahalanobis outliers**), and click any point to inspect that economy. |
| **Model Evaluation** | Full 20-model comparison grid (`k = 2` to `6` across four methods), explicit `k = 4` vs `k = 2` rationale, cross-method ARI matrix, and GMM `VEV` vs `EII` sensitivity check | Compare internal validity (Silhouette, Davies-Bouldin, Calinski-Harabasz, Dunn) alongside `B = 500` bootstrap Jaccard stability to see why `k = 4` K-Means was chosen over `k = 2` and why unconstrained `VEV` GMM diverges. |
| **2015-2023 & ASEAN** | Interactive 4x4 `2015 -> 2023` migration matrix, 11-economy ASEAN benchmark, FANNY `P1`/`P2` change pathways, `2015 -> 2023` clean cooking CV scatter, and the 4-year **2027 projections & regime shifts** card | Hover or click any cell in either migration matrix (`2015 -> 2023` or projected `2023 -> 2027`) to inspect country rosters and centroid margins. Use the target selector in the 2027 card to switch across all six SDG 7 and SDG 13 indicators. |
| **Data & Methods** | Searchable, sortable 189-country data table, indicator dictionary, and methodology accordions | Filter by regime or region (`ASEAN (11)`), search by English or Indonesian country name, Alpha-3, or Alpha-2, sort by any indicator column, and click a row to jump to that country. |

### Reading the three Biomass Paradox plots

Each chart preset in the **Biomass Paradox** tab examines a distinct angle of the six-indicator space:

1. **Biomass paradox (`SDG 7.2.1 vs 7.b.1`):** Plots renewable share of final energy (%) on X against installed renewable electricity capacity per person (W, log scale) on Y.
   - **Lower right (`R1` biomass trap):** High final renewable share (median 78.98%) paired with tiny modern renewable power capacity (median 11.6 W/cap) because household firewood and charcoal dominate energy use.
   - **Upper right (`R3` modern renewable leaders):** High renewable share backed by thousands of Watts per capita of modern clean power (for example Norway 7,260 W, Sweden 3,817 W, Austria 2,892 W) and universal clean cooking.
   - **Lower middle (`R2` expanding transition):** Moderate renewable share (median 40.35%) with modest modern generation capacity (median 53.2 W/cap).
   - **Left (`R4` and fossil-heavy economies):** Very low renewable share (R4 median 1.31%) reflecting fossil-fuel-dominated grids and transport.
2. **PCA biplot (`PC1` 59.4% vs `PC2` 17.6%, 77.1% total variance):** Compresses all six standardised indicators into two orthogonal axes. **PC1 (horizontal)** tracks energy-access modernisation: moving right increases clean cooking (`r = +0.945`), electricity access (`r = +0.900`), log CO2 (`r = +0.800`), and log renewable capacity (`r = +0.721`), while moving left reflects higher traditional biomass share (`r = -0.772`). **PC2 (vertical)** tracks energy intensity and carbon burden: moving up increases log primary energy intensity (`r = +0.888`) and log CO2 (`r = +0.384`), while moving down reflects higher energy efficiency and modern renewables (`r = -0.257` capacity, `-0.220` share).
   - **Quadrant II, Upper Left (`PC1 < 0, PC2 > 0`):** Low modern access plus high energy intensity from thermally inefficient wood and charcoal stoves per dollar of GDP (**18/27 R1**, 10 R2, and 2 R4: LBY, SYR).
   - **Quadrant I, Upper Right (`PC1 > 0, PC2 > 0`):** Full basic access paired with high energy intensity and fossil emissions (**24/26 R4** such as Qatar, Russia, Iran, China, plus 23 higher-intensity R3).
   - **Quadrant III, Lower Left (`PC1 < 0, PC2 < 0`):** Mid-transition economies expanding access at moderate energy intensity (**31/41 R2** such as Pakistan, Cambodia, Philippines, plus 9 R1).
   - **Quadrant IV, Lower Right (`PC1 > 0, PC2 < 0`):** Universal access, lowest energy intensity (most efficient), and stronger modern renewable power (**72/95 R3** such as Norway, Sweden, Germany, Viet Nam).
3. **Energy intensity vs CO2 (`SDG 7.3.1 vs SDG 13`):** Plots primary energy intensity (MJ consumed per 2021 PPP USD of GDP; farther left = more efficient) on X against CO2 per capita (tonnes, log scale) on Y.
   - **Lower right (`R1`):** High energy intensity (median 5.10 MJ/USD) yet very low fossil CO2 (median 0.17 t/cap), because inefficient household biomass burns many MJ per dollar of output without counting as fossil emissions.
   - **Lower left (`R2`):** Moderate energy intensity (median 3.47 MJ/USD) and low CO2 (median 0.74 t/cap) as per-capita energy consumption is still expanding.
   - **Upper left (`R3`):** Most energy-efficient per dollar of GDP (median 2.64 MJ/USD), with moderate per-capita CO2 (median 3.67 t/cap) reflecting higher total consumption per person.
   - **Upper right (`R4`):** Both high energy intensity (median 5.85 MJ/USD; mean 7.69) and high per-capita CO2 (median 11.99 t/cap) from fossil-heavy industry and power systems.

Additional reading tips:
- **Reading the country inspector:** Each country's six indicators are plotted against both its regime median and the global median, with 2015 vs 2023 regime labels and its `P1`/`P2` pathway tag.
- **Comparing model layers:** Switching **Map layer** from `K-Means k=4` to `Ward's D2 k=4`, `PAM k=4`, or `GMM k=4` highlights where different clustering assumptions agree or diverge on individual countries.

## Using the data assistant

Both the landing page and the dashboard include a floating **Ask the data** button in the bottom-right corner (`dashboard/bot.js`). Click it to open the assistant panel, or pick one of the starter suggestion chips right away.

What you can ask:
- **Single country lookup:** Use English or Indonesian ISO 3166-1 names, Alpha-3 codes, Alpha-2 codes, casual names, or minor typos. Examples: `How is Indonesia doing?`, `GB`, `ESP`, `Turkiye`, `Cote d'Ivoire`, `VN`.
- **Country comparisons:** Compare two or more economies side by side. Examples: `Compare Malaysia and Viet Nam`, `ID vs MY vs SG`.
- **Groups and rankings:** Ask about `ASEAN countries`, any regime (`R1`, `R2`, `R3`, `R4`), or extremes such as `Lowest clean cooking` or `Highest CO2`.
- **Methods and analysis results:** Ask `Why K-Means instead of GMM?`, `2015 to 2023 migration`, `pathways P1 and P2`, `clean cooking prediction`, or `Mahalanobis outliers`.

Two modes, shown at the bottom of the panel:
- **AI mode (`Answered by AI (Gemini / Groq) based on dashboard content.`):** Sends the question with a compact context built from `dashboard/data/dashboard_data.json` to the Cloudflare Worker proxy (`worker/worker.js`, Gemini primary with Groq failover) for free-form natural-language replies. Repeated identical questions in the same session are served from cache.
- **Local mode (`Local mode: No AI involved.`):** If the AI proxy is unreachable, rate-limited, or turned off (`WORKER_URL = ""`), the assistant falls back automatically to the built-in local engine in `dashboard/bot.js`. It resolves Alpha-3, Alpha-2, aliases, and typos directly against `dashboard_data.json` with zero external requests.

## Data and method

### Data sources and indicators

Sources: UN SDG Indicators Database (UNSD API) and World Bank Open Data. Exact series codes, custodians, units, and transformations are documented in [`data/sdg_data_dictionary.csv`](data/sdg_data_dictionary.csv).

| Feature | Indicator | Transformation |
|---|---|---|
| `elec_access` | SDG 7.1.1, access to electricity (% of population) | z-score |
| `clean_cooking` | SDG 7.1.2, access to clean cooking fuels and technologies (% of population) | z-score |
| `renew_share_tfec` | SDG 7.2.1, renewable share of total final energy consumption (%) | z-score |
| `renew_cap_wpc` | SDG 7.b.1, renewable electricity capacity (W per capita) | log(1 + x), then z-score |
| `energy_intensity` | SDG 7.3.1, primary energy intensity (MJ per 2021 PPP USD) | log(1 + x), then z-score |
| `co2_per_capita` | CO2 emissions per capita (tonnes) | log(1 + x), then z-score |

- The saved panel [`data/sdg_energy_climate_panel_2015_2023.csv`](data/sdg_energy_climate_panel_2015_2023.csv) covers 215 economies across 2015, 2022, and 2023; the analysis uses 2015 and 2023.
- Models run on the 189 economies complete on all six indicators (8.02 billion people; [`output/console_summary.txt`](output/console_summary.txt)). Missingness is highest in `clean_cooking` (23 economies, 10.7%; [`table_01`](output/tables/table_01_data_quality_audit_2023.csv)).
- Per-capita CO2 comes from World Bank (EDGAR, AR5), filled where missing by UNSD (IEA); each row's source is logged in `co2_source`.
- GDP per capita (PPP) and urban population share are excluded from model fitting and used strictly as external validators.

### Pipeline summary

All steps live in [`sdg_energy_transition_analysis.R`](sdg_energy_transition_analysis.R) with `set.seed(2026)`:

1. **Preprocessing:** Apply `log(1 + x)` to the three right-skewed indicators (reducing maximum absolute skewness from 5.87 to 1.74; [`table_02`](output/tables/table_02_descriptive_stats_transformation.csv)), then standardise all six features using 2023 means and standard deviations.
2. **Diagnostics:** Screen multivariate outliers via Mahalanobis distance (`D^2 > 22.46`, 0.999 chi-square quantile; six economies flagged and kept in [`table_03`](output/tables/table_03_mahalanobis_outliers.csv)). Overall KMO is 0.767, Hopkins H is 0.9995, and PC1 explains 59.4% of variance ([`output/console_summary.txt`](output/console_summary.txt)).
3. **Clustering (`k = 2` to `6`):** Compare K-Means (`nstart = 100`), PAM/K-Medoids, hierarchical Ward D2 (Euclidean distance), and Gaussian Mixture Models (`mclust`, covariance chosen by BIC).
4. **Evaluation and stability:** Compute Silhouette, Davies-Bouldin, Calinski-Harabasz, Dunn, cross-method ARI ([`table_05`](output/tables/table_05_ari_agreement_between_methods.csv)), and `B = 500` bootstrap Jaccard (`fpc::clusterboot`; manual bootstrap loop for GMM with successful replicates counted directly from returned matrices; [`table_04`](output/tables/table_04_model_comparison.csv)).
5. **Sensitivity and external checks:** Compare against `missMDA::imputePCA` on `n = 207` economies (4+ indicators observed), test spherical `EII` vs `VEV` GMM ([`table_11`](output/tables/table_11_gmm_covariance_sensitivity.csv)), and run Kruskal-Wallis tests on held-out GDP per capita PPP and urbanisation.
6. **2015 projection:** Scale 2015 observations with 2023 parameters and assign each economy to the nearest 2023 K-Means centroid without refitting on 2015 data ([`table_08`](output/tables/table_08_migration_matrix_2015_2023.csv)).
7. **2015 to 2023 change pathways:** Standardise 2015-to-2023 differences (percentage-point differences for the three shares, `log(1 + x)` differences for capacity, intensity, and CO2) and run fuzzy FANNY (`cluster::fanny`, `k = 2` to `6`). The membership exponent is the largest value in `{2, 1.7, 1.5, 1.3, 1.2}` producing `k` distinct clusters for every `k` (the default of 2 collapses to uniform memberships). Selection picks the most stable `k` across 200 subsamples of 80% with all clusters of size at least 10, flagging structure as weak when Silhouette < 0.25 or mean Jaccard < 0.75. Both the exponent grid and weak-structure thresholds are exploratory choices made after initial fits showed default-exponent collapse. PAM on the same features and FANNY on raw differences serve as sensitivity checks ([`table_12`](output/tables/table_12_change_pathways_k_comparison.csv)).
8. **Clean cooking prediction:** Predict 2023 clean cooking from 2015 indicators across 10 shared country folds comparing persistence, linear regression on 2015 clean cooking, and elastic net (`glmnet`, alpha 0.1 to 1 and lambda tuned in 10 inner folds, scaling learned inside training folds only). Predictions outside `[0, 100]` are clipped for all models under a pre-fit rule. MAE difference CIs come from paired resampling of the existing out-of-fold errors (2,000 country resamples; models are not refitted; [`table_15`](output/tables/table_15_clean_cooking_forecast_metrics.csv)).

## Limitations

- The complete-case analysis drops 26 of 215 economies; the imputation check covers only economies with at least 4 observed indicators.
- Electricity access and clean cooking are bounded at 100%, creating ceiling concentration that affects covariance-based models such as unconstrained GMM.
- All six features receive equal weight after standardisation; alternative feature sets or weights can shift regime boundaries.
- Projecting 2015 onto 2023 centroids measures relative position against the 2023 structure, not the clusters that 2015 alone would form.
- Per-capita CO2 combines two sources (EDGAR and IEA) with slightly different accounting methods.
- Upstream UNSD and World Bank APIs can revise historical series, so re-downloading data may slightly change numbers relative to the saved panel.
- Change pathways cover one eight-year window; economies already at 100% access cannot increase further, which shapes the resulting pathways.
- Clean cooking prediction is cross-country validation over one historical interval (2015 to 2023) and does not measure forecast accuracy for future years.

## Repository structure

```text
.
├── sdg_energy_transition_analysis.R   full R pipeline from the saved panel
├── download_sdg_data.R                optional: re-download data from UNSD and World Bank APIs
├── data/
│   ├── sdg_energy_climate_panel_2015_2023.csv
│   └── sdg_data_dictionary.csv
├── output/
│   ├── tables/    table_01 to table_17 (CSV)
│   ├── figures/   fig01 to fig06 (PNG, 300 DPI)
│   └── console_summary.txt
├── dashboard/
│   ├── index.html
│   ├── bot.js
│   ├── data/      dashboard_data.json, dashboard_data.js
│   └── img/       photos, illustrations, and mist texture
├── worker/
│   ├── worker.js      optional Cloudflare Worker proxy (Gemini primary, Groq failover)
│   └── wrangler.toml
└── index.html         bilingual landing page linking to dashboard/
```

## How to reproduce and run locally

Run all commands from the repository root.

### 1. Re-run the analysis from the saved panel

Install the required R packages:

```r
install.packages(c(
  "dplyr", "tidyr", "readr", "ggplot2", "scales", "psych", "cluster",
  "mclust", "fpc", "hopkins", "missMDA", "jsonlite", "glmnet",
  "rnaturalearth", "rnaturalearthdata", "sf"
))
```

Then run:

```bash
Rscript sdg_energy_transition_analysis.R
```

This reads `data/sdg_energy_climate_panel_2015_2023.csv` offline and regenerates `output/tables/`, `output/figures/`, and `dashboard/data/`.

### 2. Re-download fresh data (optional)

Requires internet access and the R packages `httr2`, `jsonlite`, `dplyr`, `tidyr`, `readr`, and `countrycode`:

```bash
Rscript download_sdg_data.R
```

This overwrites both files in `data/`. Set `SDG_RDS_CACHE` to a folder path if you want to cache raw API responses. Re-run step 1 afterwards to refresh outputs.

### 3. Open the landing page and dashboard locally

Serve the repository root over HTTP so `dashboard/index.html` and `dashboard/bot.js` can fetch `dashboard/data/dashboard_data.json`:

```bash
python -m http.server 8000
```

Open http://localhost:8000 for the landing page and http://localhost:8000/dashboard/ for the dashboard.

### 4. Configure the optional AI proxy for the assistant

Without a proxy, `dashboard/bot.js` runs in local mode automatically. To enable AI-backed free-form answers:

1. Deploy `worker/worker.js` using Cloudflare Workers (`worker/wrangler.toml`).
2. Add `GEMINI_API_KEY` and/or `GROQ_API_KEY` as Cloudflare Worker Secrets (never commit API keys to Git).
3. Point `WORKER_URL` at the top of `dashboard/bot.js` to your Worker URL. If the Worker is offline or hits a rate limit, the assistant switches back to local mode automatically.
