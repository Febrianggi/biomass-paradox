# ==============================================================================
# Judul Analisis : Membongkar Paradoks Biomassa dan Trilema Transisi Energi-Iklim
#                  Global (SDG 7 & SDG 13): Perbandingan Empat Metode Clustering,
#                  Dinamika Rezim 2019-2023, dan Proyeksi 2027
# Sumber Data    : UN SDG Indicators Database (https://unstats.un.org/sdgs/dataportal)
#                  & World Bank Open Data (https://data.worldbank.org)
# Seed           : 2026 (reprodusibilitas penuh seluruh analisis & bootstrap B=500)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(scales)
  library(psych)
  library(cluster)
  library(glmnet)
  library(mclust)
  library(fpc)
  library(hopkins)
  library(missMDA)
  library(jsonlite)
  library(rnaturalearth)
  library(sf)
})

select <- dplyr::select
filter <- dplyr::filter
count  <- dplyr::count

get_base_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
  }
  if (file.exists("data/sdg_energy_climate_panel_2023.csv")) {
    return(normalizePath(getwd()))
  }
  stop("Jalankan skrip dari folder proyek yang memuat subfolder 'data/'.")
}

base_dir <- get_base_dir()
data_dir <- file.path(base_dir, "data")
tab_dir  <- file.path(base_dir, "output", "tables")
fig_dir  <- file.path(base_dir, "output", "figures")
dash_dir <- file.path(base_dir, "dashboard", "data")

dir.create(tab_dir,  recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir,  recursive = TRUE, showWarnings = FALSE)
dir.create(dash_dir, recursive = TRUE, showWarnings = FALSE)

set.seed(2026)
B_BOOT <- 500L

cat("======================================================================\n")
cat("ANALISIS DATA MINING: TRANSISI ENERGI BERSIH & AKSI IKLIM (SDG 7 & 13)\n")
cat("======================================================================\n\n")

# ==============================================================================
# TAHAP 1: PERUMUSAN MASALAH & PEMERIKSAAN KUALITAS DATA
# ==============================================================================
panel <- read_csv(
  file.path(data_dir, "sdg_energy_climate_panel_2023.csv"),
  show_col_types = FALSE
)

core_vars <- c(
  "elec_access",      # X1: SDG 7.1.1 Akses listrik (% populasi)
  "clean_cooking",    # X2: SDG 7.1.2 Akses memasak bersih (% populasi)
  "renew_share_tfec", # X3: SDG 7.2.1 Pangsa EBT dlm konsumsi energi final (%)
  "renew_cap_wpc",    # X4: SDG 7.b.1 Kapasitas pembangkit listrik EBT (Watt/kapita)
  "energy_intensity", # X5: SDG 7.3.1 Intensitas energi primer (MJ / USD PPP 2021)
  "co2_per_capita"    # X6: SDG 13 / 9.4.1 Emisi CO2 per kapita (ton CO2/kapita)
)

n_dup <- sum(duplicated(panel[, c("iso3", "year")]))
stopifnot("Ditemukan duplikasi iso3 x year!" = n_dup == 0L)

d2023_all <- panel |> filter(year == 2023L)
panel_2019_path <- file.path(data_dir, "sdg_energy_climate_panel_2019.csv")
stopifnot("Berkas data/sdg_energy_climate_panel_2019.csv tidak ditemukan!" = file.exists(panel_2019_path))
d2019_all <- read_csv(panel_2019_path, show_col_types = FALSE) |> filter(year == 2019L)

audit_missing <- tibble(
  variabel = core_vars,
  label_id = c(
    "Akses Listrik (SDG 7.1.1, %)",
    "Memasak Bersih (SDG 7.1.2, %)",
    "Pangsa EBT Final (SDG 7.2.1, %)",
    "Kapasitas Listrik EBT (SDG 7.b.1, W/kap)",
    "Intensitas Energi Primer (SDG 7.3.1, MJ/$)",
    "Emisi CO2 per Kapita (SDG 13, t/kap)"
  ),
  n_total_ekonomi_wb = nrow(d2023_all),
  n_tersedia_2023    = sapply(core_vars, function(v) sum(!is.na(d2023_all[[v]]))),
  n_hilang_2023      = sapply(core_vars, function(v) sum(is.na(d2023_all[[v]]))),
  persen_hilang_2023 = round(100 * sapply(core_vars, function(v) mean(is.na(d2023_all[[v]]))), 2),
  min_2023           = round(sapply(core_vars, function(v) min(d2023_all[[v]], na.rm = TRUE)), 3),
  median_2023        = round(sapply(core_vars, function(v) median(d2023_all[[v]], na.rm = TRUE)), 3),
  maks_2023          = round(sapply(core_vars, function(v) max(d2023_all[[v]], na.rm = TRUE)), 3),
  persen_nilai_100   = round(100 * sapply(core_vars, function(v) mean(d2023_all[[v]] == 100, na.rm = TRUE)), 1)
)
write_csv(audit_missing, file.path(tab_dir, "table_01_data_quality_audit_2023.csv"))

d23 <- d2023_all |> filter(complete.cases(across(all_of(core_vars))))
cat("[Tahap 1] Audit Kualitas Data (2023):\n")
cat("  - Total ekonomi berdaulat World Bank :", nrow(d2023_all), "\n")
cat("  - Duplikasi observasi (iso3 x year)  :", n_dup, "\n")
cat("  - Ekonomi berdaulat lengkap (6 fitur):", nrow(d23),
    sprintf("(mencakup %.2f miliar jiwa)\n\n", sum(d23$population, na.rm = TRUE) / 1e9))

# ==============================================================================
# TAHAP 2: PERSIAPAN DATA, PENCEGAHAN KEBOCORAN DATA, & EKSPLORASI
# ==============================================================================
calc_skew <- function(x) {
  x <- x[!is.na(x)]
  m <- mean(x); s <- sd(x)
  mean(((x - m) / s)^3)
}

transform_features <- function(df) {
  tibble(
    elec_access      = df$elec_access,
    clean_cooking    = df$clean_cooking,
    renew_share_tfec = df$renew_share_tfec,
    log_renew_cap    = log1p(df$renew_cap_wpc),
    log_energy_int   = log1p(df$energy_intensity),
    log_co2_pc       = log1p(df$co2_per_capita)
  )
}

X23_raw   <- d23 |> select(all_of(core_vars))
X23_trans <- transform_features(d23)

desc_stats <- tibble(
  fitur_asli       = core_vars,
  fitur_model      = names(X23_trans),
  mean_asli        = round(sapply(X23_raw, mean), 3),
  sd_asli          = round(sapply(X23_raw, sd), 3),
  median_asli      = round(sapply(X23_raw, median), 3),
  iqr_asli         = round(sapply(X23_raw, IQR), 3),
  skew_sebelum     = round(sapply(X23_raw, calc_skew), 3),
  skew_sesudah_log = round(sapply(X23_trans, calc_skew), 3)
)
write_csv(desc_stats, file.path(tab_dir, "table_02_descriptive_stats_transformation.csv"))

X23_scaled <- scale(X23_trans)
mu_2023    <- attr(X23_scaled, "scaled:center")
sd_2023    <- attr(X23_scaled, "scaled:scale")
rownames(X23_scaled) <- d23$iso3

cov_mat <- cov(X23_scaled)
maha_d2 <- mahalanobis(X23_scaled, center = colMeans(X23_scaled), cov = cov_mat)
chi_cut <- qchisq(0.999, df = ncol(X23_scaled))
outliers_maha <- d23 |>
  mutate(mahalanobis_d2 = round(maha_d2, 3), is_outlier = maha_d2 > chi_cut) |>
  filter(is_outlier) |>
  arrange(desc(mahalanobis_d2)) |>
  select(iso3, country_en, mahalanobis_d2, all_of(core_vars))
write_csv(outliers_maha, file.path(tab_dir, "table_03_mahalanobis_outliers.csv"))

cor_mat  <- cor(X23_scaled)
kmo_res  <- psych::KMO(X23_scaled)
bart_res <- psych::cortest.bartlett(cor_mat, n = nrow(X23_scaled))
set.seed(2026)
hop_stat <- as.numeric(hopkins::hopkins(X23_scaled, m = floor(0.2 * nrow(X23_scaled))))

pca_fit  <- prcomp(X23_scaled, center = FALSE, scale. = FALSE)
pca_var  <- (pca_fit$sdev^2) / sum(pca_fit$sdev^2)

cat("[Tahap 2] Diagnostik Eksplorasi & Kecenderungan Clustering:\n")
cat(sprintf("  - Skewness maksimum: %.2f (asli) -> %.2f (pasca transformasi log1p)\n",
            max(abs(desc_stats$skew_sebelum)), max(abs(desc_stats$skew_sesudah_log))))
cat(sprintf("  - Pencilan Mahalanobis (D2 > %.2f): %d negara (%s)\n",
            chi_cut, nrow(outliers_maha), paste(outliers_maha$iso3, collapse = ", ")))
cat(sprintf("  - Overall KMO MSA  : %.3f (min MSA item = %.3f)\n",
            kmo_res$MSA, min(kmo_res$MSAi)))
cat(sprintf("  - Uji Bartlett     : Chi-Sq = %.2f, df = %d, p = %.3e\n",
            bart_res$chisq, bart_res$df, bart_res$p.value))
cat(sprintf("  - Statistik Hopkins: H = %.4f (> 0.75 menunjukkan struktur klaster kuat)\n", hop_stat))
cat(sprintf("  - Varians PCA      : PC1 = %.1f%%, PC2 = %.1f%%, PC3 = %.1f%% (Kumulatif 2 PC = %.1f%%)\n\n",
            100 * pca_var[1], 100 * pca_var[2], 100 * pca_var[3], 100 * sum(pca_var[1:2])))

# Uji Sensitivitas Penanganan Missing Data (Imputasi PCA Reguler missMDA pada n=207 ekonomi
# yang memiliki minimal 4 dari 6 indikator, dievaluasi pada 189 observasi bersama)
d23_partial <- d2023_all |> filter(rowSums(!is.na(across(all_of(core_vars)))) >= 4)
X_part_tr   <- as.matrix(transform_features(d23_partial))
imp_pca     <- missMDA::imputePCA(X_part_tr, ncp = 2, scale = TRUE)$completeObs
X_part_sc   <- scale(imp_pca)
set.seed(2026)
km_sens     <- kmeans(X_part_sc, centers = 4, nstart = 100, iter.max = 200)

# ==============================================================================
# TAHAP 3: PEMODELAN & EVALUASI 4 METODE DATA MINING - B = 500 BOOTSTRAP
# ==============================================================================
calc_davies_bouldin <- function(X, cl) {
  labs <- sort(unique(cl))
  k <- length(labs)
  centers <- t(sapply(labs, function(g) colMeans(X[cl == g, , drop = FALSE])))
  scatter <- sapply(seq_along(labs), function(i) {
    pts <- X[cl == labs[i], , drop = FALSE]
    mean(sqrt(rowSums(sweep(pts, 2, centers[i, ])^2)))
  })
  R <- matrix(0, k, k)
  for (i in seq_len(k)) {
    for (j in seq_len(k)) {
      if (i != j) {
        dist_ij <- sqrt(sum((centers[i, ] - centers[j, ])^2))
        R[i, j] <- (scatter[i] + scatter[j]) / dist_ij
      }
    }
  }
  mean(apply(R, 1, max))
}

# Fungsi pencocokan Jaccard per klaster dari partisi referensi clusterboot ke partisi tampilan
match_jaccard_to_partition <- function(target_cl, boot_ref_cl, boot_means) {
  target_ids <- sort(unique(target_cl))
  ref_ids    <- sort(unique(boot_ref_cl))
  sapply(target_ids, function(tid) {
    A <- target_cl == tid
    j_scores <- sapply(seq_along(ref_ids), function(ridx) {
      B <- boot_ref_cl == ref_ids[ridx]
      sum(A & B) / sum(A | B)
    })
    boot_means[which.max(j_scores)]
  })
}

dist_euc <- dist(X23_scaled, method = "euclidean")
hc_tree  <- hclust(dist_euc, method = "ward.D2")

eval_rows   <- list()
models_by_k <- list()

cat(sprintf("[Tahap 3] Menjalankan evaluasi 4 metode x k=2..6 dengan Bootstrap B = %d ...\n", B_BOOT))

for (k in 2:6) {
  set.seed(2026)
  km_fit  <- kmeans(X23_scaled, centers = k, nstart = 100, iter.max = 200)
  pam_fit <- pam(X23_scaled, k = k, metric = "euclidean")
  hc_cut  <- cutree(hc_tree, k = k)
  gmm_fit <- Mclust(X23_scaled, G = k, verbose = FALSE)

  # Bootstrap B = 500 untuk K-Means (runs = 100, iter.max = 200 selaras dengan km_fit)
  set.seed(2026)
  cb_km <- clusterboot(
    X23_scaled, B = B_BOOT, bootmethod = "boot",
    clustermethod = kmeansCBI, krange = k, runs = 100, iter.max = 200,
    seed = 2026, count = FALSE
  )
  set.seed(2026)
  cb_pam <- clusterboot(
    X23_scaled, B = B_BOOT, bootmethod = "boot",
    clustermethod = claraCBI, k = k, usepam = TRUE, count = FALSE
  )
  set.seed(2026)
  cb_hc <- clusterboot(
    X23_scaled, B = B_BOOT, bootmethod = "boot",
    clustermethod = hclustCBI, method = "ward.D2", k = k, count = FALSE
  )

  # Bootstrap B = 500 penuh untuk GMM dengan pencatatan jumlah replikasi berhasil
  set.seed(2026)
  gmm_jac_mat <- matrix(NA_real_, nrow = k, ncol = B_BOOT)
  gmm_ok <- 0L
  for (b in seq_len(B_BOOT)) {
    idx <- sample(seq_len(nrow(X23_scaled)), replace = TRUE)
    ub  <- unique(idx)
    fit_b <- tryCatch(
      Mclust(X23_scaled[idx, , drop = FALSE], G = k, modelNames = gmm_fit$modelName, verbose = FALSE),
      error = function(e) NULL
    )
    if (!is.null(fit_b) && !is.null(fit_b$parameters)) {
      pred_b <- tryCatch(
        predict(fit_b, newdata = X23_scaled[ub, , drop = FALSE])$classification,
        error = function(e) NULL
      )
      if (!is.null(pred_b)) {
        gmm_ok <- gmm_ok + 1L
        orig_u <- gmm_fit$classification[ub]
        for (g in seq_len(k)) {
          A <- orig_u == g
          if (any(A)) {
            gmm_jac_mat[g, b] <- max(sapply(seq_len(k), function(h) {
              B_set <- pred_b == h
              sum(A & B_set) / sum(A | B_set)
            }))
          }
        }
      }
    }
  }
  gmm_boot_vec <- rowMeans(gmm_jac_mat, na.rm = TRUE)

  # Ukur langsung jumlah replikasi bootstrap berhasil dari matriks hasil bootstrap (k x B_BOOT)
  count_measured_boot_ok <- function(boot_mat) {
    as.integer(sum(colSums(!is.na(boot_mat)) > 0L))
  }
  count_measured_boot_complete <- function(boot_mat) {
    as.integer(sum(colSums(is.na(boot_mat)) == 0L))
  }

  km_ok  <- count_measured_boot_ok(cb_km$bootresult)
  pam_ok <- count_measured_boot_ok(cb_pam$bootresult)
  hc_ok  <- count_measured_boot_ok(cb_hc$bootresult)
  gmm_ok <- count_measured_boot_ok(gmm_jac_mat)

  # Pastikan kesesuaian klaster referensi bootstrap ke partisi tampilan
  km_jac_matched  <- match_jaccard_to_partition(km_fit$cluster,     cb_km$result$partition,  cb_km$bootmean)
  pam_jac_matched <- match_jaccard_to_partition(pam_fit$clustering, cb_pam$result$partition, cb_pam$bootmean)
  hc_jac_matched  <- match_jaccard_to_partition(hc_cut,             cb_hc$result$partition,  cb_hc$bootmean)

  cat(sprintf("  k = %d | Replikasi bootstrap terukur berhasil -> KMeans: %d/%d, WardD2: %d/%d, PAM: %d/%d, GMM (%s): %d/%d\n",
              k, km_ok, B_BOOT, hc_ok, B_BOOT, pam_ok, B_BOOT, gmm_fit$modelName, gmm_ok, B_BOOT))

  cand_list <- list(
    KMeans = list(cl = km_fit$cluster,        jac = km_jac_matched,  boot_ok = km_ok,  boot_comp = count_measured_boot_complete(cb_km$bootresult),  fit = km_fit,  cb_part = cb_km$result$partition),
    PAM    = list(cl = pam_fit$clustering,    jac = pam_jac_matched, boot_ok = pam_ok, boot_comp = count_measured_boot_complete(cb_pam$bootresult), fit = pam_fit, cb_part = cb_pam$result$partition),
    WardD2 = list(cl = hc_cut,                jac = hc_jac_matched,  boot_ok = hc_ok,  boot_comp = count_measured_boot_complete(cb_hc$bootresult),  fit = hc_cut,  cb_part = cb_hc$result$partition),
    GMM    = list(cl = gmm_fit$classification, jac = gmm_boot_vec,   boot_ok = gmm_ok, boot_comp = count_measured_boot_complete(gmm_jac_mat),       fit = gmm_fit, cb_part = gmm_fit$classification)
  )
  models_by_k[[as.character(k)]] <- cand_list

  for (m_name in names(cand_list)) {
    cl_vec <- as.integer(factor(cand_list[[m_name]]$cl))
    cs     <- fpc::cluster.stats(dist_euc, cl_vec)
    jac_v  <- cand_list[[m_name]]$jac
    eval_rows[[length(eval_rows) + 1L]] <- tibble(
      metode               = m_name,
      k                    = k,
      silhouette           = round(cs$avg.silwidth, 4),
      davies_bouldin       = round(calc_davies_bouldin(X23_scaled, cl_vec), 4),
      calinski_harabasz    = round(cs$ch, 2),
      dunn                 = round(cs$dunn, 4),
      jaccard_mean         = round(mean(jac_v, na.rm = TRUE), 4),
      jaccard_min          = round(min(jac_v, na.rm = TRUE), 4),
      boot_berhasil        = as.integer(cand_list[[m_name]]$boot_ok),
      boot_lengkap_klaster = as.integer(cand_list[[m_name]]$boot_comp),
      boot_total           = B_BOOT,
      ukuran_klaster_min   = as.integer(min(table(cl_vec)))
    )
  }
}

eval_table <- bind_rows(eval_rows) |> arrange(k, desc(silhouette))
write_csv(eval_table, file.path(tab_dir, "table_04_model_comparison.csv"))

# Verifikasi ketat bahwa partisi referensi clusterboot K-Means k=4 identik 100% dengan km_fit
ari_km4_cb <- mclust::adjustedRandIndex(models_by_k[["4"]]$KMeans$cl, models_by_k[["4"]]$KMeans$cb_part)
stopifnot("Partisi KMeans k=4 dan referensi clusterboot tidak identik!" = abs(ari_km4_cb - 1.0) < 1e-12)

cat("\n[Tahap 3] Verifikasi Referensi Bootstrap K-Means (k=4): ARI(km_fit, cb_ref) =", ari_km4_cb, "\n")
cat("[Tahap 3] Perbandingan Optimum Biner Kasar (k=2) vs Puncak Multi-Rezim (k=4):\n")
print(eval_table |> filter(k %in% c(2, 4)))
cat("\n")

# Diagnostik Konsentrasi Batas Atas 100% & Sensitivitas Spesifikasi Kovarians GMM (k = 4)
gmm4_vev <- models_by_k[["4"]]$GMM$fit
gmm4_eii <- Mclust(X23_scaled, G = 4, modelNames = "EII", verbose = FALSE)
sig_arr  <- gmm4_vev$parameters$variance$sigma

gmm_ceiling_diag <- bind_rows(
  lapply(1:4, function(g) {
    dg <- diag(sig_arr[, , g])
    tibble(
      spesifikasi_gmm  = paste0("GMM Bebas BIC (", gmm4_vev$modelName, ") - Komponen ", g),
      n_negara         = sum(gmm4_vev$classification == g),
      var_elec_access  = round(dg["elec_access"], 5),
      var_clean_cook   = round(dg["clean_cooking"], 5),
      var_renew_share  = round(dg["renew_share_tfec"], 5),
      var_log_rcap     = round(dg["log_renew_cap"], 5),
      silhouette_k4    = round(fpc::cluster.stats(dist_euc, gmm4_vev$classification)$avg.silwidth, 4),
      ari_vs_kmeans4   = round(mclust::adjustedRandIndex(models_by_k[["4"]]$KMeans$cl, gmm4_vev$classification), 4)
    )
  }),
  tibble(
    spesifikasi_gmm  = "GMM Sferis Terkendala (EII - kovarians isotropik 6 fitur)",
    n_negara         = nrow(X23_scaled),
    var_elec_access  = round(gmm4_eii$parameters$variance$sigmasq[1], 5),
    var_clean_cook   = round(gmm4_eii$parameters$variance$sigmasq[1], 5),
    var_renew_share  = round(gmm4_eii$parameters$variance$sigmasq[1], 5),
    var_log_rcap     = round(gmm4_eii$parameters$variance$sigmasq[1], 5),
    silhouette_k4    = round(fpc::cluster.stats(dist_euc, gmm4_eii$classification)$avg.silwidth, 4),
    ari_vs_kmeans4   = round(mclust::adjustedRandIndex(models_by_k[["4"]]$KMeans$cl, gmm4_eii$classification), 4)
  )
)
write_csv(gmm_ceiling_diag, file.path(tab_dir, "table_11_gmm_covariance_sensitivity.csv"))
cat("[Tahap 3] Diagnostik Konsentrasi Batas Atas & Sensitivitas Kovarians GMM (k=4):\n")
print(gmm_ceiling_diag |> select(spesifikasi_gmm, n_negara, var_elec_access, var_clean_cook, silhouette_k4, ari_vs_kmeans4))
cat("\n")

# Penyelarasan urutan label rezim k=4 (R1 s/d R4) dan alternatif biner k=2 (B1 s/d B2)
order_regime_labels <- function(raw_cl, df_ref) {
  agg <- df_ref |>
    mutate(raw_cl = raw_cl) |>
    group_by(raw_cl) |>
    summarise(elec = mean(elec_access), co2 = mean(co2_per_capita), .groups = "drop")
  r1 <- agg$raw_cl[which.min(agg$elec)]
  rem1 <- setdiff(agg$raw_cl, r1)
  r4 <- rem1[which.max(agg$co2[match(rem1, agg$raw_cl)])]
  rem2 <- setdiff(rem1, r4)
  r2 <- rem2[which.min(agg$elec[match(rem2, agg$raw_cl)])]
  r3 <- setdiff(rem2, r2)
  map_vec <- setNames(1:4, c(r1, r2, r3, r4))
  list(
    aligned = unname(map_vec[as.character(raw_cl)]),
    perm    = c(r1, r2, r3, r4)
  )
}

k2_models <- models_by_k[["2"]]
k2_means  <- tapply(d23$elec_access, k2_models$KMeans$cl, mean)
k2_perm   <- as.integer(names(sort(k2_means))) # B1 = defisit akses, B2 = terelektrifikasi
k2_map    <- setNames(1:2, k2_perm)
cl_k2_ord <- unname(k2_map[as.character(k2_models$KMeans$cl)])
jac_k2_ord <- round(k2_models$KMeans$jac[k2_perm], 4)

k4_models <- models_by_k[["4"]]
km4_ord   <- order_regime_labels(k4_models$KMeans$cl, d23)
pam4_ord  <- order_regime_labels(k4_models$PAM$cl, d23)
hc4_ord   <- order_regime_labels(k4_models$WardD2$cl, d23)
gmm4_ord  <- order_regime_labels(k4_models$GMM$cl, d23)

cl4_list <- list(
  KMeans = km4_ord$aligned,
  PAM    = pam4_ord$aligned,
  WardD2 = hc4_ord$aligned,
  GMM    = gmm4_ord$aligned
)
ari_mat <- outer(names(cl4_list), names(cl4_list),
                 Vectorize(function(a, b) round(mclust::adjustedRandIndex(cl4_list[[a]], cl4_list[[b]]), 4)))
dimnames(ari_mat) <- list(names(cl4_list), names(cl4_list))
ari_df <- as_tibble(ari_mat, rownames = "metode")
write_csv(ari_df, file.path(tab_dir, "table_05_ari_agreement_between_methods.csv"))

# Sensitivitas imputasi missMDA: model di-fit pada n=207 ekonomi, ARI dihitung pada 189 kasus bersama
sens_ord <- order_regime_labels(km_sens$cluster[match(d23$iso3, d23_partial$iso3)], d23)
ari_sens <- mclust::adjustedRandIndex(km4_ord$aligned, sens_ord$aligned)
cat(sprintf("[Validasi Sensitivitas] ARI pada %d negara bersama (fit Complete-Case n=%d vs fit Imputasi PCA missMDA n=%d): %.4f\n\n",
            nrow(d23), nrow(d23), nrow(d23_partial), ari_sens))

# ==============================================================================
# TAHAP 4: INTERPRETASI REZIM (k=4 & ALTERNATIF k=2), DINAMIKA 2019-2023, & ASEAN
# ==============================================================================
# Tabel 10: Profil Alternatif Dua Rezim (k = 2) & Hubungan Bersarang terhadap k = 4
k2_profiles <- d23 |>
  mutate(regime_k2 = cl_k2_ord, regime_k4 = km4_ord$aligned) |>
  group_by(regime_k2) |>
  summarise(
    kode_k2            = paste0("B", first(regime_k2)),
    nama_id            = ifelse(first(regime_k2) == 1L,
                                "Defisit Energi & Transisi Akses Dasar",
                                "Ekonomi Terelektrifikasi (Efisien & Intensif Fosil Tergabung)"),
    nama_en            = ifelse(first(regime_k2) == 1L,
                                "Energy-Deficit & Basic Access Transition",
                                "Electrified Economies (Clean & Fossil-Locked Combined)"),
    jaccard_km_k2      = jac_k2_ord[first(regime_k2)],
    n_negara           = n(),
    populasi_miliar    = round(sum(population, na.rm = TRUE) / 1e9, 3),
    elec_mean          = round(mean(elec_access), 2),
    cooking_mean       = round(mean(clean_cooking), 2),
    renew_share_mean   = round(mean(renew_share_tfec), 2),
    renew_cap_median   = round(median(renew_cap_wpc), 1),
    energy_int_mean    = round(mean(energy_intensity), 2),
    co2_pc_median      = round(median(co2_per_capita), 2),
    komposisi_rezim_k4 = paste(
      sapply(1:4, function(r) sprintf("R%d=%d", r, sum(regime_k4 == r))),
      collapse = ", "
    ),
    .groups = "drop"
  )
write_csv(k2_profiles, file.path(tab_dir, "table_10_two_regime_alternative_k2.csv"))

regime_meta <- tibble(
  regime_id  = 1:4,
  kode_rezim = c("R1", "R2", "R3", "R4"),
  nama_id    = c(
    "Defisit Akses & Perangkap Biomassa",
    "Transisi Akses Berkembang",
    "Elektrifikasi Efisien & Transisi EBT",
    "Intensif Fosil & Emisi Tinggi"
  ),
  nama_en    = c(
    "Acute Energy Deficit & Biomass Trap",
    "Expanding Access, Cooking-Lag Transition",
    "Efficient Electrification & Modern Renewables",
    "Fossil-Locked & High-Carbon Intensive"
  ),
  jaccard_km = round(k4_models$KMeans$jac[km4_ord$perm], 3)
)

centers_km4 <- k4_models$KMeans$fit$centers[km4_ord$perm, , drop = FALSE]
rownames(centers_km4) <- paste0("R", 1:4)

pam_medoid_iso <- rownames(k4_models$PAM$fit$medoids)[pam4_ord$perm]
sil_km4 <- silhouette(km4_ord$aligned, dist_euc)[, "sil_width"]

d23_res <- d23 |>
  mutate(
    regime_k2   = cl_k2_ord,
    kode_k2     = paste0("B", cl_k2_ord),
    regime_km   = km4_ord$aligned,
    regime_pam  = pam4_ord$aligned,
    regime_ward = hc4_ord$aligned,
    regime_gmm  = gmm4_ord$aligned,
    sil_width   = round(sil_km4, 4),
    gmm_uncert  = round(k4_models$GMM$fit$uncertainty, 4),
    pc1         = round(pca_fit$x[, 1], 4),
    pc2         = round(pca_fit$x[, 2], 4),
    pc3         = round(pca_fit$x[, 3], 4),
    maha_d2     = round(maha_d2, 3),
    dist_to_centroid = round(sapply(seq_len(nrow(X23_scaled)), function(i) {
      sqrt(sum((X23_scaled[i, ] - centers_km4[km4_ord$aligned[i], ])^2))
    }), 4)
  ) |>
  left_join(regime_meta, by = c("regime_km" = "regime_id"))

regime_profiles <- d23_res |>
  group_by(regime_km, kode_rezim, nama_id, nama_en, jaccard_km) |>
  summarise(
    n_negara            = n(),
    populasi_miliar     = round(sum(population, na.rm = TRUE) / 1e9, 3),
    elec_mean           = round(mean(elec_access), 2),
    elec_median         = round(median(elec_access), 2),
    cooking_mean        = round(mean(clean_cooking), 2),
    cooking_median      = round(median(clean_cooking), 2),
    renew_share_mean    = round(mean(renew_share_tfec), 2),
    renew_share_median  = round(median(renew_share_tfec), 2),
    renew_cap_mean      = round(mean(renew_cap_wpc), 1),
    renew_cap_median    = round(median(renew_cap_wpc), 1),
    energy_int_mean     = round(mean(energy_intensity), 2),
    energy_int_median   = round(median(energy_intensity), 2),
    co2_pc_mean         = round(mean(co2_per_capita), 2),
    co2_pc_median       = round(median(co2_per_capita), 2),
    gdp_ppp_median_ext  = round(median(gdp_pc_ppp, na.rm = TRUE), 0),
    urban_mean_ext      = round(mean(urban_pct, na.rm = TRUE), 1),
    negara_contoh_pusat = country_en[which.min(dist_to_centroid)],
    iso3_contoh_pusat   = iso3[which.min(dist_to_centroid)],
    .groups = "drop"
  ) |>
  mutate(medoid_pam_iso3 = pam_medoid_iso)

write_csv(regime_profiles, file.path(tab_dir, "table_06_global_regime_profiles_2023.csv"))

kw_gdp <- kruskal.test(gdp_pc_ppp ~ factor(regime_km), data = d23_res)
kw_urb <- kruskal.test(urban_pct  ~ factor(regime_km), data = d23_res)
cat(sprintf("[Validasi Eksternal Bebas Bocor] Kruskal-Wallis PDB PPP per kapita antar-rezim: H = %.2f, p = %.3e\n",
            kw_gdp$statistic, kw_gdp$p.value))
cat(sprintf("[Validasi Eksternal Bebas Bocor] Kruskal-Wallis Urbanisasi antar-rezim       : H = %.2f, p = %.3e\n\n",
            kw_urb$statistic, kw_urb$p.value))

d19 <- d2019_all |>
  filter(iso3 %in% d23_res$iso3, complete.cases(across(all_of(core_vars)))) |>
  arrange(match(iso3, d23_res$iso3))
stopifnot("Kohort 2019 harus lengkap pada seluruh 189 negara 2023!" = identical(d19$iso3, d23_res$iso3))

X19_scaled <- scale(transform_features(d19), center = mu_2023, scale = sd_2023)
assign_nearest_centroid <- function(Xmat, Cmat) {
  apply(Xmat, 1, function(r) which.min(rowSums(sweep(Cmat, 2, r)^2)))
}
cl19_proj <- assign_nearest_centroid(X19_scaled, centers_km4)
pc19_proj <- X19_scaled %*% pca_fit$rotation

migration_df <- d19 |>
  transmute(
    iso3,
    regime_2019      = cl19_proj,
    kode_2019        = paste0("R", cl19_proj),
    elec_2019        = elec_access,
    cooking_2019     = clean_cooking,
    renew_share_2019 = renew_share_tfec,
    renew_cap_2019   = renew_cap_wpc,
    energy_int_2019  = energy_intensity,
    co2_pc_2019      = co2_per_capita,
    pc1_2019         = round(pc19_proj[, 1], 4),
    pc2_2019         = round(pc19_proj[, 2], 4)
  ) |>
  inner_join(
    d23_res |> select(
      iso3, country_en, region, income_group, is_asean, population, gdp_pc_ppp, urban_pct,
      elec_rural, cap_solar_wpc, cap_wind_wpc, cap_hydro_wpc, cap_geothermal_wpc, cap_bioenergy_wpc,
      regime_k2, kode_k2,
      regime_2023 = regime_km, kode_2023 = kode_rezim, nama_id, nama_en,
      regime_pam, regime_ward, regime_gmm, sil_width, gmm_uncert, dist_to_centroid,
      elec_2023 = elec_access, cooking_2023 = clean_cooking,
      renew_share_2023 = renew_share_tfec, renew_cap_2023 = renew_cap_wpc,
      energy_int_2023 = energy_intensity, co2_pc_2023 = co2_per_capita,
      pc1_2023 = pc1, pc2_2023 = pc2
    ),
    by = "iso3"
  ) |>
  mutate(
    status_migrasi = case_when(
      regime_2019 == 1 & regime_2023 %in% c(2, 3) ~ "Naik Kelas Akses (R1 -> R2/R3)",
      regime_2019 == 2 & regime_2023 == 3         ~ "Lulus Elektrifikasi & Memasak Bersih (R2 -> R3)",
      regime_2019 == 4 & regime_2023 == 3         ~ "Dekarbonisasi & Efisiensi (R4 -> R3)",
      regime_2019 == 3 & regime_2023 == 4         ~ "Terkunci Intensitas Fosil (R3 -> R4)",
      TRUE                                        ~ "Bertahan di Rezim yang Sama"
    ),
    delta_cooking    = round(cooking_2023 - cooking_2019, 2),
    delta_renew_cap  = round(renew_cap_2023 - renew_cap_2019, 2),
    delta_energy_int = round(energy_int_2023 - energy_int_2019, 2),
    delta_co2_pc     = round(co2_pc_2023 - co2_pc_2019, 2)
  )

write_csv(migration_df, file.path(tab_dir, "table_07_full_results_189_countries_2019_2023.csv"))

mig_matrix <- migration_df |>
  count(kode_2019, kode_2023) |>
  pivot_wider(names_from = kode_2023, values_from = n, values_fill = 0L)
write_csv(mig_matrix, file.path(tab_dir, "table_08_migration_matrix_2019_2023.csv"))

asean_bench <- migration_df |>
  filter(is_asean) |>
  arrange(regime_2023, desc(renew_cap_2023)) |>
  select(iso3, country_en, kode_k2, kode_2019, kode_2023, elec_2023, cooking_2023,
         renew_share_2023, renew_cap_2023, delta_renew_cap,
         energy_int_2023, co2_pc_2023, cap_hydro_wpc, cap_solar_wpc,
         cap_geothermal_wpc, cap_wind_wpc, cap_bioenergy_wpc)
write_csv(asean_bench, file.path(tab_dir, "table_09_indonesia_asean_benchmark.csv"))

cat("[Tahap 4] Profil Alternatif Biner Dua Rezim (k = 2):\n")
print(k2_profiles |> select(kode_k2, jaccard_km_k2, n_negara, populasi_miliar, elec_mean, cooking_mean, co2_pc_median, komposisi_rezim_k4))
cat("\n[Tahap 4] Matriks Migrasi Rezim Energi-Iklim Global (2019 -> 2023):\n")
print(mig_matrix)

# ==============================================================================
# TAHAP 5: VISUALISASI STATIS (PNG 300 DPI)
# ==============================================================================
pal_regime <- c(
  "R1" = "#B45309",
  "R2" = "#2563EB",
  "R3" = "#0D9488",
  "R4" = "#BE123C"
)

theme_sdg <- theme_minimal(base_size = 11.5) +
  theme(
    plot.title       = element_text(face = "bold", size = 13.5, color = "#0F172A"),
    plot.subtitle    = element_text(size = 9.8, color = "#475569", margin = margin(b = 10)),
    plot.caption     = element_text(size = 8.5, color = "#64748B", margin = margin(t = 8)),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E2E8F0", linewidth = 0.35),
    legend.position  = "bottom",
    plot.background  = element_rect(fill = "#FFFFFF", color = NA)
  )

eval_long <- eval_table |>
  select(metode, k, Silhouette = silhouette, `Stabilitas Jaccard (Bootstrap B=500)` = jaccard_mean,
         `Indeks Davies-Bouldin (lebih rendah = lebih baik)` = davies_bouldin,
         `Indeks Dunn` = dunn) |>
  pivot_longer(-c(metode, k), names_to = "metrik", values_to = "nilai")

p1 <- ggplot(eval_long, aes(x = k, y = nilai, color = metode, shape = metode)) +
  geom_vline(xintercept = 2, linetype = "dotted", color = "#64748B", linewidth = 0.5) +
  geom_vline(xintercept = 4, linetype = "dashed", color = "#0F172A", linewidth = 0.55) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.6) +
  facet_wrap(~ metrik, scales = "free_y", ncol = 2) +
  scale_color_manual(values = c("KMeans" = "#0D9488", "WardD2" = "#2563EB",
                                "PAM" = "#D97706", "GMM" = "#BE123C")) +
  scale_x_continuous(breaks = 2:6) +
  labs(
    title = "Evaluasi Komparatif Empat Algoritma Clustering Data Mining (k = 2 s/d 6)",
    subtitle = "k = 2 adalah optimum biner kasar (Jaccard 0,976); pada multi-rezim (k >= 3), k = 4 mencapai puncak lokal Jaccard 0,953",
    x = "Jumlah Klaster (k)", y = "Nilai Metrik Evaluasi",
    color = "Metode", shape = "Metode",
    caption = "Sumber: Diolah dari UN SDG Indicators Database & World Bank Open Data (n = 189 negara, 2023; B = 500; seed = 2026)"
  ) +
  theme_sdg
ggsave(file.path(fig_dir, "fig01_four_method_comparison.png"), p1, width = 10, height = 6.5, dpi = 300)

highlight_iso <- c("IDN", "VNM", "MYS", "SGP", "BRN", "NOR", "ISL", "COD", "ETH", "QAT", "CHN", "USA")
d_lbl <- migration_df |> filter(iso3 %in% highlight_iso)

p2 <- ggplot(migration_df, aes(x = renew_share_2023, y = renew_cap_2023 + 1, color = kode_2023)) +
  geom_point(aes(size = population / 1e6), alpha = 0.78) +
  geom_text(data = d_lbl, aes(label = iso3), size = 3.1, fontface = "bold",
            vjust = -0.85, show.legend = FALSE, check_overlap = TRUE) +
  scale_y_log10(labels = label_number(big.mark = ",")) +
  scale_color_manual(values = pal_regime, labels = paste0(regime_meta$kode_rezim, ": ", regime_meta$nama_id)) +
  scale_size_continuous(range = c(1.8, 9), guide = "none") +
  labs(
    title = "Paradoks Biomassa: Pangsa EBT Final (SDG 7.2.1) vs Kapasitas Listrik EBT (SDG 7.b.1)",
    subtitle = "Negara R1 tampak memiliki pangsa EBT >70% karena kayu bakar/arang tradisional, padahal kapasitas listrik bersihnya <15 W/kapita",
    x = "Pangsa Energi Terbarukan dalam Konsumsi Energi Final - SDG 7.2.1 (%)",
    y = "Kapasitas Pembangkit Listrik EBT Terpasang - SDG 7.b.1 (Watt/kapita, skala log)",
    color = "Rezim K-Means (k=4)",
    caption = "Ukuran titik proporsional terhadap populasi 2023. Sumber: UN SDG Portal (EG_FEC_RNEW & EG_EGY_RNEW)"
  ) +
  theme_sdg +
  guides(color = guide_legend(nrow = 2))
ggsave(file.path(fig_dir, "fig02_biomass_paradox_sdg7.png"), p2, width = 10.5, height = 6.5, dpi = 300)

load_df <- as_tibble(pca_fit$rotation[, 1:2], rownames = "fitur") |>
  mutate(
    label = c("Akses Listrik", "Memasak Bersih", "Pangsa EBT", "log(Kapasitas EBT)",
              "log(Intensitas Energi)", "log(CO2/kapita)"),
    xend = PC1 * 3.8, yend = PC2 * 3.8
  )

p3 <- ggplot(migration_df, aes(x = pc1_2023, y = pc2_2023, color = kode_2023)) +
  geom_hline(yintercept = 0, color = "#CBD5E1", linewidth = 0.4) +
  geom_vline(xintercept = 0, color = "#CBD5E1", linewidth = 0.4) +
  geom_point(alpha = 0.75, size = 2.4) +
  geom_segment(data = load_df, aes(x = 0, y = 0, xend = xend, yend = yend),
               inherit.aes = FALSE, arrow = arrow(length = unit(0.2, "cm")),
               color = "#0F172A", linewidth = 0.65) +
  geom_label(data = load_df, aes(x = xend * 1.08, y = yend * 1.08, label = label),
             inherit.aes = FALSE, size = 2.9, fill = "#F8FAFC", color = "#0F172A", linewidth = 0.2) +
  geom_text(data = d_lbl, aes(label = iso3), size = 3, fontface = "bold", vjust = -0.8, show.legend = FALSE) +
  scale_color_manual(values = pal_regime, labels = paste0(regime_meta$kode_rezim, ": ", regime_meta$nama_id)) +
  labs(
    title = sprintf("Biplot Komponen Utama (PC1 %.1f%% & PC2 %.1f%%) atas 4 Rezim Energi-Iklim Global",
                    100 * pca_var[1], 100 * pca_var[2]),
    subtitle = "PC1 memisahkan kemajuan elektrifikasi & memasak bersih dari biomassa; PC2 memisahkan kapasitas EBT modern dari intensitas fosil",
    x = sprintf("Komponen Utama 1 (%.1f%% varians)", 100 * pca_var[1]),
    y = sprintf("Komponen Utama 2 (%.1f%% varians)", 100 * pca_var[2]),
    color = "Rezim K-Means (k=4)",
    caption = "Sumber: Hasil analisis PCA & K-Means pada 6 indikator resmi UN SDG & World Bank (n = 189 negara, 2023)"
  ) +
  theme_sdg +
  guides(color = guide_legend(nrow = 2))
ggsave(file.path(fig_dir, "fig03_pca_biplot_global_regimes.png"), p3, width = 10.5, height = 6.8, dpi = 300)

cent_long <- as_tibble(centers_km4, rownames = "kode_rezim") |>
  pivot_longer(-kode_rezim, names_to = "fitur", values_to = "z_score") |>
  mutate(
    fitur_lbl = factor(fitur,
      levels = c("elec_access", "clean_cooking", "renew_share_tfec",
                 "log_renew_cap", "log_energy_int", "log_co2_pc"),
      labels = c("Akses Listrik\n(SDG 7.1.1)", "Memasak Bersih\n(SDG 7.1.2)",
                 "Pangsa EBT\n(SDG 7.2.1)", "log Kapasitas EBT\n(SDG 7.b.1)",
                 "log Intensitas Energi\n(SDG 7.3.1)", "log Emisi CO2/kap\n(SDG 13)"))
  )

p4 <- ggplot(cent_long, aes(x = fitur_lbl, y = z_score, fill = kode_rezim)) +
  geom_hline(yintercept = 0, color = "#475569", linewidth = 0.45) +
  geom_col(position = position_dodge(width = 0.78), width = 0.7) +
  scale_fill_manual(values = pal_regime, labels = paste0(regime_meta$kode_rezim, ": ", regime_meta$nama_id)) +
  labs(
    title = "Profil Rata-Rata Terstandardisasi (Z-Score Centroid) Empat Rezim Global Tahun 2023",
    subtitle = "R3 unggul pada elektrifikasi dan efisiensi energi, sedangkan R4 terkunci pada intensitas energi dan emisi CO2 sangat tinggi",
    x = NULL, y = "Skor-Z terhadap Rata-Rata Global 2023",
    fill = "Rezim K-Means (k=4)",
    caption = "Sumber: Centroid K-Means (nstart = 100, seed = 2026) pada 189 negara berdaulat"
  ) +
  theme_sdg +
  guides(fill = guide_legend(nrow = 2))
ggsave(file.path(fig_dir, "fig04_centroid_zscore_profiles.png"), p4, width = 10.5, height = 6, dpi = 300)

asean_tech <- migration_df |>
  filter(is_asean) |>
  select(iso3, country_en, kode_2023,
         `Tenaga Air (Hydro)` = cap_hydro_wpc,
         `Surya (Solar)` = cap_solar_wpc,
         `Angin (Wind)` = cap_wind_wpc,
         `Panas Bumi (Geothermal)` = cap_geothermal_wpc,
         `Bioenergi Modern` = cap_bioenergy_wpc) |>
  pivot_longer(-c(iso3, country_en, kode_2023), names_to = "teknologi", values_to = "wpc") |>
  mutate(wpc = coalesce(wpc, 0))

p5 <- ggplot(asean_tech, aes(x = reorder(paste0(country_en, " (", kode_2023, ")"), wpc, FUN = sum),
                             y = wpc, fill = teknologi)) +
  geom_col(width = 0.72) +
  coord_flip() +
  scale_fill_manual(values = c(
    "Tenaga Air (Hydro)" = "#0284C7",
    "Surya (Solar)" = "#F59E0B",
    "Angin (Wind)" = "#10B981",
    "Panas Bumi (Geothermal)" = "#DC2626",
    "Bioenergi Modern" = "#7C3AED"
  )) +
  labs(
    title = "Bauran Kapasitas Pembangkit Listrik EBT Terpasang di Negara ASEAN (SDG 7.b.1, Tahun 2023)",
    subtitle = "Indonesia (47,4 W/kapita) berada di Rezim R3, namun tertinggal 10x lipat dari Vietnam (476 W/kapita) terutama pada tenaga surya",
    x = NULL, y = "Kapasitas Listrik EBT Terpasang (Watt per kapita)",
    fill = "Teknologi EBT (IRENA)",
    caption = "Sumber: UN SDG Indicators Database - Seri EG_EGY_RNEW (IRENA, 2023)"
  ) +
  theme_sdg
ggsave(file.path(fig_dir, "fig05_renewable_mix_indonesia_asean.png"), p5, width = 10.5, height = 6, dpi = 300)

mig_long <- migration_df |>
  count(kode_2019, kode_2023) |>
  complete(kode_2019 = paste0("R", 1:4), kode_2023 = paste0("R", 1:4), fill = list(n = 0L))

p6 <- ggplot(mig_long, aes(x = kode_2023, y = factor(kode_2019, levels = paste0("R", 4:1)), fill = n)) +
  geom_tile(color = "#FFFFFF", linewidth = 1.2) +
  geom_text(aes(label = n, color = n > 40), size = 5, fontface = "bold", show.legend = FALSE) +
  scale_fill_gradient(low = "#F1F5F9", high = "#0F766E") +
  scale_color_manual(values = c("FALSE" = "#0F172A", "TRUE" = "#FFFFFF")) +
  labs(
    title = "Matriks Perpindahan Rezim Energi-Iklim Global (2019 -> 2023)",
    subtitle = "Sebanyak 6 negara berpindah rezim dalam rentang 4 tahun (2019 ke 2023), tanpa satu pun mundur ke R1",
    x = "Rezim Tahun 2023",
    y = "Rezim Tahun 2019 (Baseline 4 Tahun)",
    fill = "Jumlah Negara",
    caption = "Proyeksi 2019 menggunakan parameter penskalaan & centroid 2023 agar bebas kebocoran temporal (n = 189 negara)"
  ) +
  theme_sdg
ggsave(file.path(fig_dir, "fig06_migration_matrix_2019_2023.png"), p6, width = 8.5, height = 6, dpi = 300)

# ==============================================================================
# TAHAP 5B: JALUR PERUBAHAN 2019-2023 (FANNY)
# ==============================================================================
# Kohort: 189 negara yang sama (lengkap 2019 & 2023), nilai mentah tanpa pembulatan dari migration_df.
chg_raw <- with(migration_df, data.frame(
  d_elec   = elec_2023 - elec_2019,
  d_cook   = cooking_2023 - cooking_2019,
  d_rshare = renew_share_2023 - renew_share_2019,
  d_cap    = renew_cap_2023 - renew_cap_2019,
  d_int    = energy_int_2023 - energy_int_2019,
  d_co2    = co2_pc_2023 - co2_pc_2019
))
# Fitur utama: selisih poin persen untuk tiga pangsa, selisih log1p untuk tiga fitur miring
chg_feat <- transform(chg_raw,
  d_cap = log1p(migration_df$renew_cap_2023) - log1p(migration_df$renew_cap_2019),
  d_int = log1p(migration_df$energy_int_2023) - log1p(migration_df$energy_int_2019),
  d_co2 = log1p(migration_df$co2_pc_2023) - log1p(migration_df$co2_pc_2019))
stopifnot("Selisih tidak cocok dengan kolom delta yang diekspor!" =
  max(abs(round(chg_raw$d_cook, 2) - migration_df$delta_cooking)) < 1e-9 &&
  max(abs(round(chg_raw$d_cap, 2) - migration_df$delta_renew_cap)) < 1e-9 &&
  max(abs(round(chg_raw$d_int, 2) - migration_df$delta_energy_int)) < 1e-9 &&
  max(abs(round(chg_raw$d_co2, 2) - migration_df$delta_co2_pc)) < 1e-9)
Z_chg <- scale(chg_feat)
Z_raw <- scale(chg_raw)
rownames(Z_chg) <- rownames(Z_raw) <- migration_df$iso3

# Eksponen keanggotaan: nilai terbesar dari grid yang memberi k klaster tegas berbeda untuk semua k = 2..6.
# Grid ini dan ambang struktur lemah di bawah adalah pilihan eksploratif yang dibuat setelah fit awal.
# Bawaan fanny (2) menghasilkan keanggotaan seragam 1/k pada data ini, sehingga dilaporkan sebagai degenerasi.
memb_grid <- c(2, 1.7, 1.5, 1.3, 1.2)
fanny_fit <- function(Z, k, r) suppressWarnings(fanny(Z, k, memb.exp = r, maxit = 1000))
memb_check <- sapply(memb_grid, function(r) all(sapply(2:6, function(k) length(unique(fanny_fit(Z_chg, k, r)$clustering)) == k)))
MEMB_EXP <- memb_grid[which(memb_check)[1]]
stopifnot("Tidak ada eksponen keanggotaan yang menghasilkan k klaster!" = !is.na(MEMB_EXP))

perms <- function(v) if (length(v) <= 1) list(v) else
  do.call(c, lapply(seq_along(v), function(i) lapply(perms(v[-i]), function(p) c(v[i], p))))
align_labels <- function(lab, ref, k) {
  # Label sampel ulang dipetakan ke label referensi dengan permutasi yang memaksimalkan kecocokan
  P <- perms(seq_len(k))
  best <- P[[which.max(vapply(P, function(p) sum(p[lab] == ref), numeric(1)))]]
  best[lab]
}
fit_cl <- function(Z, k, method) if (method == "FANNY") fanny_fit(Z, k, MEMB_EXP)$clustering else pam(Z, k)$clustering

B_SUB <- 200L
stability <- function(Z, k, method, ref) {
  set.seed(2026)
  res <- replicate(B_SUB, {
    s <- sort(sample(nrow(Z), floor(0.8 * nrow(Z))))
    lab <- fit_cl(Z[s, , drop = FALSE], k, method)
    al <- align_labels(lab, ref[s], k)
    c(vapply(seq_len(k), function(g) {
      A <- ref[s] == g; Bq <- al == g
      if (!any(A | Bq)) NA_real_ else sum(A & Bq) / sum(A | Bq)
    }, numeric(1)), mclust::adjustedRandIndex(lab, ref[s]))
  })
  list(jac = rowMeans(res[seq_len(k), , drop = FALSE], na.rm = TRUE), ari = mean(res[k + 1, ]))
}

path_configs <- list(
  list(method = "FANNY", fitur = "log_diff_std", Z = Z_chg),
  list(method = "PAM",   fitur = "log_diff_std", Z = Z_chg),
  list(method = "FANNY", fitur = "raw_diff_std", Z = Z_raw)
)
path_fits <- list()
path_eval <- bind_rows(lapply(path_configs, function(cfg) bind_rows(lapply(2:6, function(k) {
  if (cfg$method == "FANNY") {
    f <- fanny_fit(cfg$Z, k, MEMB_EXP); cl <- f$clustering; U <- f$membership
    conv <- unname(f$convergence["converged"] == 1); iters <- unname(f$convergence["iterations"])
    dunn_n <- unname(f$coeff["normalized"])
  } else {
    f <- pam(cfg$Z, k); cl <- f$clustering; U <- NULL; conv <- NA; iters <- NA_integer_; dunn_n <- NA_real_
  }
  path_fits[[paste(cfg$method, cfg$fitur, k)]] <<- list(cl = cl, U = U)
  top2 <- if (is.null(U)) NULL else t(apply(U, 1, function(u) sort(u, decreasing = TRUE)[1:2]))
  st <- stability(cfg$Z, k, cfg$method, cl)
  tibble(
    metode = cfg$method, fitur = cfg$fitur, k = k,
    memb_exp = if (cfg$method == "FANNY") MEMB_EXP else NA_real_,
    konvergen = conv, iterasi = iters,
    n_klaster_tegas = length(unique(cl)),
    ukuran_klaster = paste(as.integer(table(factor(cl, levels = seq_len(k)))), collapse = "/"),
    ukuran_min = min(as.integer(table(factor(cl, levels = seq_len(k))))),
    silhouette = round(mean(silhouette(cl, dist(cfg$Z))[, "sil_width"]), 4),
    dunn_normalized = round(dunn_n, 4),
    keanggotaan_maks_rerata = if (is.null(U)) NA_real_ else round(mean(top2[, 1]), 4),
    persen_ambigu = if (is.null(U)) NA_real_ else round(100 * mean(top2[, 1] - top2[, 2] < 0.2), 1),
    jaccard_rerata = round(mean(st$jac), 4),
    jaccard_min = round(min(st$jac), 4),
    ari_rerata = round(st$ari, 4)
  )
}))))
write_csv(path_eval, file.path(tab_dir, "table_12_change_pathways_k_comparison.csv"))

# Aturan pemilihan: FANNY pada fitur utama, ukuran klaster minimum >= 10, Jaccard rerata tertinggi.
# Struktur dilaporkan lemah bila Silhouette < 0,25 (Kaufman & Rousseeuw, 1990) atau Jaccard < 0,75 (Hennig, 2007).
cand <- path_eval |> filter(metode == "FANNY", fitur == "log_diff_std", n_klaster_tegas == k, ukuran_min >= 10)
K_PATH <- cand$k[which.max(cand$jaccard_rerata)]
path_weak <- with(cand[which.max(cand$jaccard_rerata), ], silhouette < 0.25 || jaccard_rerata < 0.75)
fz <- path_fits[[paste("FANNY", "log_diff_std", K_PATH)]]
# Urutan jalur: median kenaikan memasak bersih menurun (P1 = kenaikan terbesar)
path_order <- order(-tapply(chg_raw$d_cook, fz$cl, median), -tabulate(fz$cl, K_PATH))
path_id <- match(fz$cl, path_order)
U_path <- fz$U[, path_order, drop = FALSE]
colnames(U_path) <- paste0("memb_P", seq_len(K_PATH))
pam_k <- path_fits[[paste("PAM", "log_diff_std", K_PATH)]]$cl
raw_k <- path_fits[[paste("FANNY", "raw_diff_std", K_PATH)]]$cl
ari_path_pam <- round(mclust::adjustedRandIndex(path_id, pam_k), 4)
ari_path_raw <- round(mclust::adjustedRandIndex(path_id, raw_k), 4)
ari_path_regime <- round(mclust::adjustedRandIndex(path_id, migration_df$regime_2023), 4)

path_df <- tibble(iso3 = migration_df$iso3, country_en = migration_df$country_en,
                  kode_2019 = migration_df$kode_2019, kode_2023 = migration_df$kode_2023,
                  pathway = paste0("P", path_id), memb_max = round(apply(U_path, 1, max), 4)) |>
  bind_cols(as_tibble(round(U_path, 4)), as_tibble(chg_raw))
write_csv(path_df, file.path(tab_dir, "table_14_change_pathway_memberships.csv"))

Z_centroid <- apply(Z_chg, 2, function(z) tapply(z, path_id, mean))
path_profiles <- path_df |>
  group_by(pathway) |>
  summarise(
    n_negara = n(),
    keanggotaan_rerata = round(mean(memb_max), 3),
    med_d_elec_pp = round(median(d_elec), 2), med_d_cook_pp = round(median(d_cook), 2),
    med_d_rshare_pp = round(median(d_rshare), 2), med_d_cap_wpc = round(median(d_cap), 2),
    med_d_int_mj = round(median(d_int), 3), med_d_co2_t = round(median(d_co2), 3),
    rezim_2023 = paste(sapply(paste0("R", 1:4), function(r) sprintf("%s=%d", r, sum(kode_2023 == r))), collapse = ", "),
    .groups = "drop"
  ) |>
  bind_cols(as_tibble(round(Z_centroid, 3), .name_repair = ~ paste0("z_", names(chg_raw))))
write_csv(path_profiles, file.path(tab_dir, "table_13_change_pathway_profiles.csv"))

cat(sprintf("\n[Tahap 5B] Jalur perubahan FANNY (memb.exp = %.1f): k = %d dipilih, Jaccard rerata = %.4f%s\n",
            MEMB_EXP, K_PATH, max(cand$jaccard_rerata), if (path_weak) " (STRUKTUR LEMAH)" else ""))
cat(sprintf("  ARI jalur vs PAM = %.4f, vs FANNY selisih mentah = %.4f, vs rezim 2023 = %.4f\n",
            ari_path_pam, ari_path_raw, ari_path_regime))
print(path_profiles |> select(pathway, n_negara, keanggotaan_rerata, starts_with("med_")))

# ==============================================================================
# TAHAP 5C: PROYEKSI 2027 HORIZON 4 TAHUN (2019 -> 2023 -> 2027) & PERPINDAHAN REZIM
# ==============================================================================
# Data resmi UNSD & World Bank tahun 2025-2026 belum tersedia (0 baris pada seri SDG 7),
# sementara 2024 kehilangan separuh negara pada 7.2.1 & 7.3.1. Tahun 2019 lengkap 189/189,
# sehingga horizon 4 tahun (2019 -> 2023) dipakai untuk validasi silang 10 lipatan dan
# memproyeksikan 2027 (2023 + 4) pada keenam indikator serta posisi rezim pada centroid 2023.
K_OUTER <- 10L
alpha_grid <- seq(0.1, 1, by = 0.1)
set.seed(2026)
fold_out <- sample(rep(seq_len(K_OUTER), length.out = nrow(migration_df)))
boot_idx <- replicate(2000, sample(nrow(migration_df), replace = TRUE))
tune_enet <- function(X, y, foldid) {
  cvs <- lapply(alpha_grid, function(a) cv.glmnet(X, y, alpha = a, foldid = foldid, standardize = TRUE))
  best <- which.min(vapply(cvs, function(cv) min(cv$cvm), numeric(1)))
  list(cv = cvs[[best]], alpha = alpha_grid[best])
}

X19 <- with(migration_df, cbind(
  elec    = elec_2019,
  cook    = cooking_2019,
  rshare  = renew_share_2019,
  log_cap = log1p(renew_cap_2019),
  log_int = log1p(energy_int_2019),
  log_co2 = log1p(co2_pc_2019)
))
X23_fc <- with(migration_df, cbind(
  elec    = elec_2023,
  cook    = cooking_2023,
  rshare  = renew_share_2023,
  log_cap = log1p(renew_cap_2023),
  log_int = log1p(energy_int_2023),
  log_co2 = log1p(co2_pc_2023)
))

target_specs_2027 <- list(
  list(id = "clean_cooking",    col_x = "cook",    y23 = migration_df$cooking_2023,     y19 = d19$clean_cooking,     log_scale = FALSE, clip_max = 100, unit = "pp"),
  list(id = "renew_share_tfec", col_x = "rshare",  y23 = migration_df$renew_share_2023, y19 = d19$renew_share_tfec,  log_scale = FALSE, clip_max = 100, unit = "pp"),
  list(id = "energy_intensity", col_x = "log_int", y23 = migration_df$energy_int_2023,  y19 = d19$energy_intensity,  log_scale = TRUE,  clip_max = Inf, unit = "MJ/$"),
  list(id = "elec_access",      col_x = "elec",    y23 = migration_df$elec_2023,        y19 = d19$elec_access,       log_scale = FALSE, clip_max = 100, unit = "pp"),
  list(id = "renew_cap_wpc",    col_x = "log_cap", y23 = migration_df$renew_cap_2023,   y19 = d19$renew_cap_wpc,     log_scale = TRUE,  clip_max = Inf, unit = "W/cap"),
  list(id = "co2_per_capita",   col_x = "log_co2", y23 = migration_df$co2_pc_2023,      y19 = d19$co2_per_capita,    log_scale = TRUE,  clip_max = Inf, unit = "t/cap")
)

back_clip <- function(val, spec) {
  if (spec$log_scale) pmax(0, expm1(val)) else pmin(pmax(val, 0), spec$clip_max)
}
cohen_kappa <- function(a, b, lvls = 1:4) {
  cm <- table(factor(a, levels = lvls), factor(b, levels = lvls))
  po <- sum(diag(cm)) / sum(cm)
  pe <- sum(rowSums(cm) * colSums(cm)) / (sum(cm)^2)
  if (pe >= 1) 1 else (po - pe) / (1 - pe)
}

oof_en_23  <- matrix(NA_real_, nrow(X19), length(target_specs_2027), dimnames = list(migration_df$iso3, sapply(target_specs_2027, `[[`, "id")))
oof_ols_23 <- oof_en_23
proj_en_27 <- oof_en_23
fc27_cv_rows <- list()

for (ti in seq_along(target_specs_2027)) {
  sp <- target_specs_2027[[ti]]
  y_mod <- if (sp$log_scale) log1p(sp$y23) else sp$y23
  x_own <- X19[, sp$col_x]
  p_raw <- matrix(NA_real_, nrow(X19), 3, dimnames = list(NULL, c("persistence", "ols_own_lag", "elastic_net")))

  for (f in seq_len(K_OUTER)) {
    tr <- fold_out != f; te <- !tr
    p_raw[te, "persistence"] <- x_own[te]
    ols_f <- lm(y ~ x, data = data.frame(y = y_mod[tr], x = x_own[tr]))
    p_raw[te, "ols_own_lag"] <- predict(ols_f, newdata = data.frame(x = x_own[te]))
    set.seed(2026 + ti * 100 + f)
    tn_f <- tune_enet(X19[tr, ], y_mod[tr], sample(rep(1:10, length.out = sum(tr))))
    p_raw[te, "elastic_net"] <- as.numeric(predict(tn_f$cv, X19[te, , drop = FALSE], s = "lambda.min"))
  }

  p_orig <- apply(p_raw, 2, back_clip, spec = sp)
  oof_ols_23[, sp$id] <- p_orig[, "ols_own_lag"]
  oof_en_23[, sp$id]  <- p_orig[, "elastic_net"]

  ae <- abs(p_orig - sp$y23)
  ci_en_pers <- {
    d <- ae[, "elastic_net"] - ae[, "persistence"]
    ci <- quantile(apply(boot_idx, 2, function(i) mean(d[i])), c(0.025, 0.975))
    c(mean(d), ci)
  }
  ci_en_ols <- {
    d <- ae[, "elastic_net"] - ae[, "ols_own_lag"]
    ci <- quantile(apply(boot_idx, 2, function(i) mean(d[i])), c(0.025, 0.975))
    c(mean(d), ci)
  }

  # Fit penuh 2019 -> 2023 lalu proyeksikan ke 2027 memakai fitur 2023
  set.seed(2026 + ti * 100)
  tn_full <- tune_enet(X19, y_mod, sample(rep(1:10, length.out = nrow(X19))))
  pred27_mod <- as.numeric(predict(tn_full$cv, X23_fc, s = "lambda.min"))
  proj_en_27[, sp$id] <- back_clip(pred27_mod, sp)

  for (m_name in colnames(p_orig)) {
    err_m <- p_orig[, m_name] - sp$y23
    r2_m <- 1 - sum(err_m^2) / sum((sp$y23 - mean(sp$y23))^2)
    fc27_cv_rows[[length(fc27_cv_rows) + 1L]] <- tibble(
      target = sp$id,
      satuan = sp$unit,
      skala_model = if (sp$log_scale) "log1p" else "asli",
      model = m_name,
      mae_oof = round(mean(abs(err_m)), 3),
      rmse_oof = round(sqrt(mean(err_m^2)), 3),
      r2_oof = round(r2_m, 4),
      alpha_penuh = if (m_name == "elastic_net") tn_full$alpha else NA_real_,
      selisih_mae_vs_pers = if (m_name == "elastic_net") round(ci_en_pers[1], 3) else NA_real_,
      ci95_bawah_vs_pers  = if (m_name == "elastic_net") round(ci_en_pers[2], 3) else NA_real_,
      ci95_atas_vs_pers   = if (m_name == "elastic_net") round(ci_en_pers[3], 3) else NA_real_,
      selisih_mae_vs_ols  = if (m_name == "elastic_net") round(ci_en_ols[1], 3) else NA_real_,
      ci95_bawah_vs_ols   = if (m_name == "elastic_net") round(ci_en_ols[2], 3) else NA_real_,
      ci95_atas_vs_ols    = if (m_name == "elastic_net") round(ci_en_ols[3], 3) else NA_real_
    )
  }
}

fc27_cv_tbl <- bind_rows(fc27_cv_rows)
write_csv(fc27_cv_tbl, file.path(tab_dir, "table_15_forecast_2027_cv_metrics.csv"))

# Validasi out-of-fold perpindahan rezim (2019 -> 2023) & proyeksi rezim 2027 pada centroid 2023
project_to_2023_regimes <- function(df6) {
  Z <- scale(transform_features(df6), center = mu_2023, scale = sd_2023)
  dists <- t(apply(Z, 1, function(r) sqrt(rowSums(sweep(centers_km4, 2, r)^2))))
  ord <- t(apply(dists, 1, order))
  reg <- ord[, 1]
  d1 <- dists[cbind(seq_len(nrow(dists)), ord[, 1])]
  d2 <- dists[cbind(seq_len(nrow(dists)), ord[, 2])]
  pc <- Z %*% pca_fit$rotation
  list(regime = reg, dist1 = d1, margin = d2 - d1, pc1 = pc[, 1], pc2 = pc[, 2])
}

reg19_proj    <- project_to_2023_regimes(d19[, core_vars])
reg23_oof_en  <- project_to_2023_regimes(as_tibble(oof_en_23[, core_vars]))
reg23_oof_ols <- project_to_2023_regimes(as_tibble(oof_ols_23[, core_vars]))
reg27_proj    <- project_to_2023_regimes(as_tibble(proj_en_27[, core_vars]))

regime_cv_summary <- tibble(
  model = c("persistence_2019", "ols_own_lag_oof", "elastic_net_oof"),
  akurasi_persen = round(100 * c(
    mean(reg19_proj$regime == migration_df$regime_2023),
    mean(reg23_oof_ols$regime == migration_df$regime_2023),
    mean(reg23_oof_en$regime == migration_df$regime_2023)
  ), 2),
  n_benar = c(
    sum(reg19_proj$regime == migration_df$regime_2023),
    sum(reg23_oof_ols$regime == migration_df$regime_2023),
    sum(reg23_oof_en$regime == migration_df$regime_2023)
  ),
  kappa = round(c(
    cohen_kappa(reg19_proj$regime, migration_df$regime_2023),
    cohen_kappa(reg23_oof_ols$regime, migration_df$regime_2023),
    cohen_kappa(reg23_oof_en$regime, migration_df$regime_2023)
  ), 4),
  n_berubah_aktual_19_23 = sum(reg19_proj$regime != migration_df$regime_2023),
  n_berubah_pred_19_23 = c(
    0L,
    sum(reg19_proj$regime != reg23_oof_ols$regime),
    sum(reg19_proj$regime != reg23_oof_en$regime)
  )
)

proj27_df <- tibble(
  iso3 = migration_df$iso3,
  country_en = migration_df$country_en,
  kode_2019 = paste0("R", reg19_proj$regime),
  kode_2023 = migration_df$kode_2023,
  regime_2027 = reg27_proj$regime,
  kode_2027 = paste0("R", reg27_proj$regime),
  berubah_2027 = migration_df$regime_2023 != reg27_proj$regime,
  margin_centroid_2027 = round(reg27_proj$margin, 3),
  elec_2027 = round(proj_en_27[, "elec_access"], 2),
  cooking_2027 = round(proj_en_27[, "clean_cooking"], 2),
  renew_share_2027 = round(proj_en_27[, "renew_share_tfec"], 2),
  renew_cap_2027 = round(proj_en_27[, "renew_cap_wpc"], 2),
  energy_int_2027 = round(proj_en_27[, "energy_intensity"], 2),
  co2_pc_2027 = round(proj_en_27[, "co2_per_capita"], 2),
  d_elec_23_27 = round(proj_en_27[, "elec_access"] - migration_df$elec_2023, 2),
  d_cook_23_27 = round(proj_en_27[, "clean_cooking"] - migration_df$cooking_2023, 2),
  d_rshare_23_27 = round(proj_en_27[, "renew_share_tfec"] - migration_df$renew_share_2023, 2),
  d_cap_23_27 = round(proj_en_27[, "renew_cap_wpc"] - migration_df$renew_cap_2023, 2),
  d_int_23_27 = round(proj_en_27[, "energy_intensity"] - migration_df$energy_int_2023, 2),
  d_co2_23_27 = round(proj_en_27[, "co2_per_capita"] - migration_df$co2_pc_2023, 2)
)
write_csv(proj27_df, file.path(tab_dir, "table_17_forecast_2027_country_projections.csv"))

mig_2027 <- proj27_df |>
  count(kode_2023, kode_2027) |>
  complete(kode_2023 = paste0("R", 1:4), kode_2027 = paste0("R", 1:4), fill = list(n = 0L))
write_csv(bind_rows(mig_2027, regime_cv_summary), file.path(tab_dir, "table_16_forecast_2027_regime_migration.csv"))

cat("\n[Tahap 5C] Validasi silang 4-tahunan (2019 -> 2023) 6 indikator (Elastic Net):\n")
print(fc27_cv_tbl |> filter(model == "elastic_net") |> select(target, satuan, mae_oof, rmse_oof, r2_oof, selisih_mae_vs_pers, ci95_bawah_vs_pers, ci95_atas_vs_pers))
cat("\n[Tahap 5C] Akurasi rezim out-of-fold (2019 -> 2023):\n")
print(regime_cv_summary)
cat(sprintf("\n[Tahap 5C] Proyeksi perpindahan rezim 2023 -> 2027: %d negara diproyeksikan berubah rezim:\n", sum(proj27_df$berubah_2027)))
print(proj27_df |> filter(berubah_2027) |> select(iso3, country_en, kode_2023, kode_2027, margin_centroid_2027, d_elec_23_27, d_cook_23_27, d_rshare_23_27, d_int_23_27, d_co2_23_27))

# ==============================================================================
# TAHAP 6: EKSPOR JSON & PETA SVG ROBINSON UNTUK DASHBOARD INTERAKTIF
# ==============================================================================
sf_use_s2(FALSE)
robin_crs <- "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
# Kebijakan batas: Natural Earth 1:50m (de facto), dikoreksi ke batas negara yang diakui PBB.
# - Krimea & Sevastopol (UA-43, UA-40) -> Ukraina (Resolusi MU PBB 68/262).
# - Wilayah pecahan tanpa kode ISO 3166-1 -> negara induk: Somaliland -> SOM, Siprus Utara -> CYP.
# - Wilayah bersengketa lain (Sahara Barat, Kosovo, Siachen, garis kontrol Kashmir) dan dependensi
#   yang berkode sendiri digambar terpisah sebagai "tanpa data" kecuali termasuk 189 negara analisis.
fold_iso3 <- c(SOL = "SOM", CYN = "CYP")
world_src <- ne_countries(scale = "medium", returnclass = "sf") |>
  filter(adm0_a3 != "ATA") |>
  mutate(iso3_map = ifelse(!is.na(iso_a3_eh) & iso_a3_eh != "-99", iso_a3_eh, adm0_a3),
         iso3_map = ifelse(iso3_map %in% names(fold_iso3), fold_iso3[iso3_map], iso3_map)) |>
  st_transform(robin_crs)
crimea <- st_as_sf(rnaturalearthdata::states50) |>
  filter(iso_3166_2 %in% c("UA-43", "UA-40")) |>
  st_union() |>
  st_transform(robin_crs)
stopifnot("Poligon Krimea (UA-43, UA-40) tidak ditemukan!" = !st_is_empty(crimea))

# Sederhanakan jaringan batas SEKALI agar dua negara bertetangga berbagi garis yang identik
# (tanpa celah/tumpang tindih), lalu bentuk ulang poligon dan beri label dari sumber aslinya.
edges <- st_geometry(world_src) |> st_boundary() |> st_union() |> st_line_merge() |>
  st_simplify(dTolerance = 25000, preserveTopology = TRUE)
faces <- st_sf(geometry = st_collection_extract(st_polygonize(edges), "POLYGON"))
faces$face <- seq_len(nrow(faces))
# Label = negara dengan tumpang tindih terluas. Muka dengan porsi daratan <25% adalah perairan yang
# tertutup garis pantai (Laut Kaspia 1%, Pamlico Sound 15%) dan dibuang; pulau tipis/atol yang
# bergeser karena simplifikasi tetap >=28% (Bahama, Kiribati, Diego Garcia).
face_lab <- st_intersection(faces, world_src["iso3_map"]) |>
  mutate(a = as.numeric(st_area(geometry))) |>
  st_drop_geometry() |>
  group_by(face, iso3_map) |> summarise(a = sum(a), .groups = "drop") |>
  slice_max(a, n = 1, by = face, with_ties = FALSE)
lab <- face_lab[match(faces$face, face_lab$face), ]
faces$iso3_map <- ifelse(!is.na(lab$a) & lab$a >= 0.25 * as.numeric(st_area(faces)), lab$iso3_map, NA)
faces$iso3_map[!is.na(faces$iso3_map) & lengths(st_intersects(st_point_on_surface(faces), crimea)) > 0] <- "UKR"
map_names <- world_src |> st_drop_geometry() |>
  arrange(adm0_a3 != iso3_map) |> distinct(iso3_map, .keep_all = TRUE) |> select(iso3_map, name)
world_sf <- faces |>
  filter(!is.na(iso3_map)) |>
  group_by(iso3_map) |>
  summarise(.groups = "drop") |>
  left_join(map_names, by = "iso3_map")

bb_world <- st_bbox(world_sf)
W_svg <- 1000
H_svg <- round(W_svg * (bb_world["ymax"] - bb_world["ymin"]) / (bb_world["xmax"] - bb_world["xmin"]))

geom_to_svg <- function(geom, bb, W, H) {
  if (st_is_empty(geom)) return("")
  xy <- st_coordinates(geom)
  if (nrow(xy) < 3) return("")
  # Semua kolom L (cincin, poligon, fitur): tiap batas luar & lubang menjadi subpath sendiri
  ring_id <- do.call(paste, c(as.data.frame(xy[, -(1:2), drop = FALSE]), sep = "_"))
  rings <- split(seq_len(nrow(xy)), ring_id)
  parts <- vapply(rings, function(idx) {
    if (length(idx) < 3) return("")
    x <- round((xy[idx, 1] - bb["xmin"]) / (bb["xmax"] - bb["xmin"]) * W, 1)
    y <- round((bb["ymax"] - xy[idx, 2]) / (bb["ymax"] - bb["ymin"]) * H, 1)
    keep <- c(TRUE, diff(x) != 0 | diff(y) != 0)
    x <- x[keep]; y <- y[keep]
    if (length(x) < 3) return("")
    paste0("M", x[1], ",", y[1], "L", paste0(x[-1], ",", y[-1], collapse = " "), "Z")
  }, character(1))
  paste(parts[nzchar(parts)], collapse = " ")
}

svg_paths <- vapply(seq_len(nrow(world_sf)), function(i) geom_to_svg(world_sf$geometry[i], bb_world, W_svg, H_svg), character(1))
map_df <- tibble(iso3 = world_sf$iso3_map, name_map = world_sf$name, d = svg_paths) |>
  filter(nzchar(d)) |>
  group_by(iso3) |>
  summarise(name_map = first(name_map), d = paste(d, collapse = " "), .groups = "drop")

# Pemeriksaan geometri peta
svg_rings <- function(d) regmatches(d, gregexpr("M[^MZ]*Z", d))[[1]]
ring_pts <- function(s) sort(unique(strsplit(trimws(gsub("[MLZ]", " ", s)), "\\s+")[[1]]))
lso_rings <- svg_rings(map_df$d[map_df$iso3 == "LSO"])
zaf_rings <- svg_rings(map_df$d[map_df$iso3 == "ZAF"])
stopifnot(
  "Ada negara analisis tanpa path peta!" = all(migration_df$iso3 %in% map_df$iso3),
  "Lesotho harus satu cincin tertutup!" = length(lso_rings) == 1L,
  "Lubang Lesotho di ZAF harus subpath sendiri dengan titik identik (tanpa garis penghubung)!" =
    sum(vapply(zaf_rings, function(s) identical(ring_pts(s), ring_pts(lso_rings)), logical(1))) == 1L,
  "Krimea harus masuk UKR dan Laut Kaspia tidak boleh menjadi daratan!" = {
    pts <- st_transform(st_sfc(st_point(c(34.1, 45.0)), st_point(c(51.0, 42.0)), crs = 4326), robin_crs)
    owner <- lapply(st_intersects(pts, world_sf), function(i) world_sf$iso3_map[i])
    identical(owner, list("UKR", character(0)))
  },
  "Segmen melintasi peta (antimeridian)!" = all(vapply(unlist(lapply(map_df$d, svg_rings)), function(s) {
    x <- as.numeric(sub(",.*", "", strsplit(trimws(gsub("[MLZ]", " ", s)), "\\s+")[[1]]))
    all(abs(diff(c(x, x[1]))) < W_svg / 4)
  }, logical(1)))
)

asean_sf <- world_sf |> filter(iso3_map %in% asean_bench$iso3)
bb_asean <- st_bbox(asean_sf)
asean_viewbox <- round(c(
  x = (bb_asean["xmin"] - bb_world["xmin"]) / (bb_world["xmax"] - bb_world["xmin"]) * W_svg - 18,
  y = (bb_world["ymax"] - bb_asean["ymax"]) / (bb_world["ymax"] - bb_world["ymin"]) * H_svg - 14,
  w = (bb_asean["xmax"] - bb_asean["xmin"]) / (bb_world["xmax"] - bb_world["xmin"]) * W_svg + 36,
  h = (bb_asean["ymax"] - bb_asean["ymin"]) / (bb_world["ymax"] - bb_world["ymin"]) * H_svg + 28
), 1)

iso_names_path <- file.path(data_dir, "iso3166_country_names.csv")
iso_names_df <- if (file.exists(iso_names_path)) {
  read_csv(iso_names_path, show_col_types = FALSE, na = character())
} else {
  tibble(iso3 = character(), iso2 = character(), country_en_iso = character(), country_id = character())
}

outliers_export <- outliers_maha |>
  left_join(iso_names_df, by = "iso3") |>
  mutate(country_en = ifelse(!is.na(country_en_iso) & nzchar(country_en_iso), country_en_iso, country_en)) |>
  select(-any_of("country_en_iso"))

countries_export <- migration_df |>
  left_join(proj27_df |> select(iso3, regime_2027, kode_2027, berubah_2027, margin_centroid_2027,
                                elec_2027, cooking_2027, renew_share_2027, renew_cap_2027, energy_int_2027, co2_pc_2027),
            by = "iso3") |>
  left_join(iso_names_df, by = "iso3") |>
  mutate(
    country_en   = ifelse(!is.na(country_en_iso) & nzchar(country_en_iso), country_en_iso, country_en),
    population_m = round(population / 1e6, 2),
    gdp_pc_ppp   = round(gdp_pc_ppp, 0),
    urban_pct    = round(urban_pct, 1),
    across(c(elec_2023, cooking_2023, renew_share_2023, renew_cap_2023, energy_int_2023, co2_pc_2023,
             elec_2019, cooking_2019, renew_share_2019, renew_cap_2019, energy_int_2019, co2_pc_2019,
             cap_solar_wpc, cap_wind_wpc, cap_hydro_wpc, cap_geothermal_wpc, cap_bioenergy_wpc),
           ~ round(.x, 2))
  ) |>
  select(-any_of("country_en_iso"))

dashboard_payload <- list(
  meta = list(
    generated_at     = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    seed             = 2026L,
    boot_replicates  = B_BOOT,
    n_countries      = nrow(migration_df),
    n_imputed_fit    = nrow(d23_partial),
    n_wb_total       = nrow(d2023_all),
    world_pop_bn     = round(sum(migration_df$population, na.rm = TRUE) / 1e9, 2),
    kmo_overall      = round(kmo_res$MSA, 3),
    kmo_items        = as.list(round(kmo_res$MSAi, 3)),
    bartlett_chisq   = round(bart_res$chisq, 2),
    bartlett_df      = bart_res$df,
    bartlett_p       = bart_res$p.value,
    hopkins          = round(hop_stat, 4),
    ari_missmda_189  = round(ari_sens, 4),
    ari_km4_cb_ref   = round(ari_km4_cb, 4),
    gmm_eii_sil_k4   = gmm_ceiling_diag$silhouette_k4[5],
    gmm_eii_ari_k4   = gmm_ceiling_diag$ari_vs_kmeans4[5],
    kw_gdp_chisq     = round(as.numeric(kw_gdp$statistic), 2),
    kw_gdp_p         = kw_gdp$p.value,
    pca_var_pct      = round(100 * pca_var, 2),
    pca_loadings     = as_tibble(round(pca_fit$rotation[, 1:3], 4), rownames = "feature"),
    svg_viewbox      = c(0, 0, W_svg, H_svg),
    asean_viewbox    = unname(asean_viewbox)
  ),
  regimes       = regime_profiles,
  regimes_k2    = k2_profiles,
  gmm_ceiling   = gmm_ceiling_diag,
  pathways      = list(
    memb_exp = MEMB_EXP, k = K_PATH, weak = path_weak, b_subsample = B_SUB,
    ari_vs_pam = ari_path_pam, ari_vs_raw = ari_path_raw, ari_vs_regime_2023 = ari_path_regime,
    k_comparison = path_eval, profiles = path_profiles,
    countries = path_df |> select(iso3, pathway, memb_max, starts_with("memb_P"))
  ),
  forecast_2027 = list(
    train_from = 2019L, train_to = 2023L, horizon_years = 4L, target_year = 2027L,
    k_outer = K_OUTER,
    cv_metrics = fc27_cv_tbl,
    regime_cv = regime_cv_summary,
    migration_2027 = mig_2027,
    n_shifted = sum(proj27_df$berubah_2027)
  ),
  centroids_z   = as_tibble(round(centers_km4, 4), rownames = "kode_rezim"),
  eval_grid     = eval_table,
  ari_matrix    = ari_df,
  migration     = mig_long,
  audit_data    = audit_missing,
  desc_stats    = desc_stats,
  outliers      = outliers_export,
  countries     = countries_export,
  world_map     = map_df
)

json_txt <- toJSON(dashboard_payload, auto_unbox = TRUE, digits = 4, na = "null")
writeLines(json_txt, file.path(dash_dir, "dashboard_data.json"), useBytes = TRUE)
writeLines(paste0("window.__SDG_DASHBOARD_DATA__ = ", json_txt, ";"),
           file.path(dash_dir, "dashboard_data.js"), useBytes = TRUE)

cat("\n======================================================================\n")
cat("SELESAI! Seluruh 17 tabel CSV, 6 grafik PNG (300 DPI), dan data JSON\n")
cat("dashboard berhasil dibangun ulang secara konsisten.\n")
cat("======================================================================\n")
