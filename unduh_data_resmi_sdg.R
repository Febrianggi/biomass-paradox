# ==============================================================================
# SKRIP AKUISISI DATA RESMI: UN SDG INDICATORS DATABASE & WORLD BANK OPEN DATA
# Mata Kuliah : Data Mining (UAS Semester 5 - S1 Statistika UNPAD)
# Tema        : Trilema Transisi Energi Bersih & Dekarbonisasi Global (SDG 7 & 13)
# Sumber Utama:
#   1. UN Statistics Division SDG API (https://unstats.un.org/sdgs/dataportal)
#   2. World Bank Open Data API v2    (https://data.worldbank.org)
# Catatan     : Skrip ini mengunduh ulang data mentah langsung dari API resmi PBB
#               dan Bank Dunia, lalu menyimpannya ke folder `data/`. Salinan CSV
#               terverifikasi sudah disertakan agar `analisis_sdg_transisi_energi.R`
#               dapat langsung dijalankan secara luring tanpa kendala kuota API.
# ==============================================================================

suppressPackageStartupMessages({
  library(httr2)
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(countrycode)
})

get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
  }
  getwd()
}

base_dir <- get_script_dir()
data_dir <- file.path(base_dir, "data")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

parse_un_value <- function(x) {
  x <- trimws(as.character(x))
  ifelse(x %in% c("NaN", "N", "NA", ""), NA_real_,
    ifelse(x == ">95", 97.5,
      ifelse(x == "<5", 2.5, suppressWarnings(as.numeric(x)))))
}

fetch_un_series <- function(series_code, years = c(2015, 2022, 2023)) {
  message(sprintf("[UN SDG API] Mengunduh seri %s ...", series_code))
  pages <- list()
  pg <- 1L
  repeat {
    Sys.sleep(0.8)
    resp <- request("https://unstats.un.org/SDGAPI/v1/sdg/Series/Data") |>
      req_url_query(
        seriesCode = series_code,
        timePeriod = years,
        pageSize   = 2000,
        page       = pg,
        .multi     = "explode"
      ) |>
      req_retry(max_tries = 4, backoff = ~ 3) |>
      req_timeout(90) |>
      req_perform()

    body <- resp_body_json(resp, simplifyVector = TRUE)
    if (length(body$data) == 0) break
    df <- as_tibble(body$data)
    dims <- as_tibble(df$dimensions)
    names(dims) <- paste0("dim_", gsub("[^A-Za-z0-9]+", "_", names(dims)))
    pages[[pg]] <- bind_cols(
      tibble(
        series       = series_code,
        m49          = as.character(df$geoAreaCode),
        area_name_un = as.character(df$geoAreaName),
        year         = as.integer(df$timePeriodStart),
        value_raw    = as.character(df$value)
      ),
      dims
    )
    if (pg >= body$totalPages) break
    pg <- pg + 1L
  }
  bind_rows(pages)
}

fetch_wb_indicator <- function(ind_code, years = "2015:2023") {
  message(sprintf("[World Bank API] Mengunduh indikator %s ...", ind_code))
  Sys.sleep(1.2)
  url <- sprintf("https://api.worldbank.org/v2/en/country/all/indicator/%s", ind_code)
  resp <- request(url) |>
    req_url_query(format = "json", date = years, per_page = 10000) |>
    req_retry(max_tries = 4, backoff = ~ 4) |>
    req_timeout(60) |>
    req_perform()
  dat <- as_tibble(resp_body_json(resp, simplifyVector = TRUE)[[2]])
  tibble(
    iso3  = dat$countryiso3code,
    year  = as.integer(dat$date),
    value = as.numeric(dat$value)
  ) |> filter(!is.na(iso3), nchar(iso3) == 3)
}

build_sdg_dataset <- function(cache_rds_dir = NULL) {
  load_or_fetch_un <- function(code, yrs = c(2015, 2022, 2023)) {
    f <- if (!is.null(cache_rds_dir)) file.path(cache_rds_dir, paste0("un_", code, ".rds")) else ""
    if (nzchar(f) && file.exists(f)) readRDS(f) else fetch_un_series(code, yrs)
  }
  load_or_fetch_wb <- function(code) {
    f <- if (!is.null(cache_rds_dir)) file.path(cache_rds_dir, paste0("wb_", code, ".rds")) else ""
    if (nzchar(f) && file.exists(f)) readRDS(f) else fetch_wb_indicator(code)
  }

  un_elec   <- load_or_fetch_un("EG_ACS_ELEC")
  un_clean  <- load_or_fetch_un("EG_EGY_CLEAN")
  un_rnewsh <- load_or_fetch_un("EG_FEC_RNEW")
  un_intens <- load_or_fetch_un("EG_EGY_PRIM")
  un_rnewcp <- load_or_fetch_un("EG_EGY_RNEW", c(2015, 2022, 2023))
  un_co2gdp <- load_or_fetch_un("EN_ATM_CO2GDP")
  un_co2tot <- load_or_fetch_un("EN_ATM_CO2")

  wb_meta_f <- if (!is.null(cache_rds_dir)) file.path(cache_rds_dir, "wb_countries.rds") else ""
  if (nzchar(wb_meta_f) && file.exists(wb_meta_f)) {
    wb_countries <- readRDS(wb_meta_f)
  } else {
    resp_c <- request("https://api.worldbank.org/v2/en/country") |>
      req_url_query(format = "json", per_page = 400) |>
      req_retry(max_tries = 4, backoff = ~ 3) |>
      req_timeout(45) |>
      req_perform()
    raw_c <- resp_body_json(resp_c, simplifyVector = TRUE)[[2]]
    wb_countries <- tibble(
      iso3         = raw_c$id,
      iso2         = raw_c$iso2Code,
      country_en   = raw_c$name,
      region       = raw_c$region$value,
      region_id    = raw_c$region$id,
      income_group = raw_c$incomeLevel$value,
      income_id    = raw_c$incomeLevel$id,
      lon          = suppressWarnings(as.numeric(raw_c$longitude)),
      lat          = suppressWarnings(as.numeric(raw_c$latitude))
    ) |>
      filter(region_id != "NA", income_id != "NA") |>
      mutate(m49 = suppressWarnings(as.character(as.integer(countrycode(iso3, "iso3c", "un")))))
  }

  wb_pop   <- load_or_fetch_wb("SP.POP.TOTL")          |> rename(population = value)
  wb_gdp   <- load_or_fetch_wb("NY.GDP.PCAP.PP.KD")    |> rename(gdp_pc_ppp = value)
  wb_co2pc <- load_or_fetch_wb("EN.GHG.CO2.PC.CE.AR5") |> rename(co2_pc_edgar = value)
  wb_urb   <- load_or_fetch_wb("SP.URB.TOTL.IN.ZS")    |> rename(urban_pct = value)

  un_193 <- codelist |> filter(!is.na(un.name.en)) |> pull(iso3c)
  asean_iso3 <- c("BRN", "IDN", "KHM", "LAO", "MMR", "MYS", "PHL", "SGP", "THA", "TLS", "VNM")

  countries_base <- wb_countries |>
    filter(!is.na(m49)) |>
    distinct(iso3, .keep_all = TRUE) |>
    mutate(
      is_un_member = iso3 %in% un_193,
      is_asean     = iso3 %in% asean_iso3
    )

  # Sub-teknologi kapasitas EBT (IRENA / SDG 7.b.1)
  tech_wide <- un_rnewcp |>
    mutate(val = parse_un_value(value_raw)) |>
    select(m49, year, tech = dim_Type_of_renewable_technology, val) |>
    distinct(m49, year, tech, .keep_all = TRUE) |>
    pivot_wider(names_from = tech, values_from = val) |>
    transmute(
      m49, year,
      renew_cap_wpc      = ALL,
      cap_solar_wpc      = SOLAR,
      cap_wind_wpc       = WIND,
      cap_hydro_wpc      = HYDROPOWER,
      cap_geothermal_wpc = GEOTHERMAL,
      cap_bioenergy_wpc  = BIOENERGY,
      cap_marine_wpc     = MARINE
    )

  panel <- expand_grid(iso3 = countries_base$iso3, year = c(2015L, 2022L, 2023L)) |>
    left_join(countries_base, by = "iso3") |>
    left_join(
      un_elec |> filter(dim_Location == "ALLAREA") |>
        transmute(m49, year, elec_access = parse_un_value(value_raw)) |>
        distinct(m49, year, .keep_all = TRUE),
      by = c("m49", "year")
    ) |>
    left_join(
      un_elec |> filter(dim_Location == "RURAL") |>
        transmute(m49, year, elec_rural = parse_un_value(value_raw)) |>
        distinct(m49, year, .keep_all = TRUE),
      by = c("m49", "year")
    ) |>
    left_join(
      un_clean |> filter(dim_Location == "ALLAREA") |>
        transmute(m49, year, clean_cooking = parse_un_value(value_raw)) |>
        distinct(m49, year, .keep_all = TRUE),
      by = c("m49", "year")
    ) |>
    left_join(
      un_rnewsh |>
        transmute(m49, year, renew_share_tfec = parse_un_value(value_raw)) |>
        distinct(m49, year, .keep_all = TRUE),
      by = c("m49", "year")
    ) |>
    left_join(
      un_intens |>
        transmute(m49, year, energy_intensity = parse_un_value(value_raw)) |>
        distinct(m49, year, .keep_all = TRUE),
      by = c("m49", "year")
    ) |>
    left_join(tech_wide, by = c("m49", "year")) |>
    left_join(
      un_co2gdp |>
        transmute(m49, year, co2_gdp_ppp_iea = parse_un_value(value_raw)) |>
        distinct(m49, year, .keep_all = TRUE),
      by = c("m49", "year")
    ) |>
    left_join(
      un_co2tot |> filter(dim_Activity == "TOTAL") |>
        transmute(m49, year, co2_mt_iea = parse_un_value(value_raw)) |>
        distinct(m49, year, .keep_all = TRUE),
      by = c("m49", "year")
    ) |>
    left_join(wb_pop, by = c("iso3", "year")) |>
    left_join(wb_gdp, by = c("iso3", "year")) |>
    left_join(wb_co2pc, by = c("iso3", "year")) |>
    left_join(wb_urb, by = c("iso3", "year")) |>
    mutate(
      co2_pc_iea     = (co2_mt_iea * 1e6) / population,
      co2_per_capita = coalesce(co2_pc_edgar, co2_pc_iea),
      co2_source     = ifelse(!is.na(co2_pc_edgar), "WB_EDGAR_AR5", ifelse(!is.na(co2_pc_iea), "UN_SDG_IEA", NA_character_))
    ) |>
    arrange(year, iso3)

  write_csv(panel, file.path(data_dir, "sdg_energy_climate_panel_2015_2023.csv"))

  kamus <- tribble(
    ~variabel,             ~kode_resmi,            ~target_sdg, ~indikator_sdg, ~kustodian,                   ~satuan,                        ~peran_analisis,                  ~transformasi_model,
    "elec_access",         "EG_ACS_ELEC",          "SDG 7.1",   "7.1.1",        "World Bank / ESMAP (UNSD)",  "% populasi",                   "Fitur Inti Clustering (X1)",     "Z-score",
    "clean_cooking",       "EG_EGY_CLEAN",         "SDG 7.1",   "7.1.2",        "WHO (UNSD)",                 "% populasi",                   "Fitur Inti Clustering (X2)",     "Z-score",
    "renew_share_tfec",    "EG_FEC_RNEW",          "SDG 7.2",   "7.2.1",        "IEA / IRENA / UNSD",         "% konsumsi energi final",      "Fitur Inti Clustering (X3)",     "Z-score",
    "renew_cap_wpc",       "EG_EGY_RNEW (ALL)",    "SDG 7.b",   "7.b.1 / 12.a.1","IRENA (UNSD)",              "Watt per kapita",              "Fitur Inti Clustering (X4)",     "log(1 + x) lalu Z-score",
    "energy_intensity",    "EG_EGY_PRIM",          "SDG 7.3",   "7.3.1",        "IEA / UNSD",                 "MJ per USD PPP konstan 2021",  "Fitur Inti Clustering (X5)",     "log(1 + x) lalu Z-score",
    "co2_per_capita",      "EN.GHG.CO2.PC.CE.AR5 / EN_ATM_CO2", "SDG 13.2 / 9.4", "13.2.2 / 9.4.1", "EC-JRC EDGAR AR5 (WB) & IEA (UNSD)", "ton CO2 per kapita", "Fitur Inti Clustering (X6)", "log(1 + x) lalu Z-score",
    "elec_rural",          "EG_ACS_ELEC (RURAL)",  "SDG 7.1",   "7.1.1",        "World Bank / UNSD",          "% populasi perdesaan",         "Eksplorasi Ketimpangan Desa",    "Tidak masuk fit model (eksternal)",
    "cap_solar_wpc",       "EG_EGY_RNEW (SOLAR)",  "SDG 7.b",   "7.b.1",        "IRENA (UNSD)",               "Watt per kapita",              "Bauran Teknologi EBT",           "Tidak masuk fit model (eksternal)",
    "cap_wind_wpc",        "EG_EGY_RNEW (WIND)",   "SDG 7.b",   "7.b.1",        "IRENA (UNSD)",               "Watt per kapita",              "Bauran Teknologi EBT",           "Tidak masuk fit model (eksternal)",
    "cap_hydro_wpc",       "EG_EGY_RNEW (HYDRO)",  "SDG 7.b",   "7.b.1",        "IRENA (UNSD)",               "Watt per kapita",              "Bauran Teknologi EBT",           "Tidak masuk fit model (eksternal)",
    "cap_geothermal_wpc",  "EG_EGY_RNEW (GEOTH)",  "SDG 7.b",   "7.b.1",        "IRENA (UNSD)",               "Watt per kapita",              "Bauran Teknologi EBT",           "Tidak masuk fit model (eksternal)",
    "cap_bioenergy_wpc",   "EG_EGY_RNEW (BIO)",    "SDG 7.b",   "7.b.1",        "IRENA (UNSD)",               "Watt per kapita",              "Bauran Teknologi EBT",           "Tidak masuk fit model (eksternal)",
    "gdp_pc_ppp",          "NY.GDP.PCAP.PP.KD",    "SDG 8.1",   "8.1.1 (proksi)","World Bank WDI",            "USD PPP konstan 2021",         "Validasi Eksternal (Bebas Bocor)","Tidak masuk fit model",
    "urban_pct",           "SP.URB.TOTL.IN.ZS",    "SDG 11",    "Konteks",      "UN Population Div / WB",     "% populasi perkotaan",         "Validasi Eksternal (Bebas Bocor)","Tidak masuk fit model",
    "population",          "SP.POP.TOTL",          "Konteks",   "Konteks",      "UN Population Div / WB",     "Jiwa",                         "Bobot Populasi & Per Kapita",    "Tidak masuk fit model"
  )
  write_csv(kamus, file.path(data_dir, "kamus_data_sdg.csv"))
  message(sprintf("Selesai! Tersimpan %d baris (%d ekonomi x 3 tahun) di %s",
                  nrow(panel), length(unique(panel$iso3)), data_dir))
}

if (sys.nframe() == 0) {
  cache_arg <- Sys.getenv("SDG_RDS_CACHE", unset = "")
  build_sdg_dataset(if (nzchar(cache_arg)) cache_arg else NULL)
}
