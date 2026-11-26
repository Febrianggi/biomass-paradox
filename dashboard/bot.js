/*
  "Tanya data": hybrid assistant for the Biomass Paradox Atlas.
  - When WORKER_URL is configured, sends the question plus a compact full-189-country context
    from dashboard_data.json to the Cloudflare Worker proxy (Gemini primary, Groq failover).
  - When WORKER_URL is empty, offline, or the proxy is unavailable/rate-limited, falls back
    automatically to a local fuzzy rule engine (slang aliases, typo tolerance, methodology intents)
    with zero external requests.
  Used by both the landing page (/) and the dashboard (/dashboard/).
*/
const DATA_URL = new URL("./data/dashboard_data.json", import.meta.url);
// Paste your deployed Cloudflare Worker URL here (e.g. "https://biomass-paradox-bot.yourname.workers.dev").
// Leave empty ("") to stay 100% local with the smart fuzzy engine.
const WORKER_URL = "https://biomass-paradox-bot.febrianggicaesarimmanuel.workers.dev";

const UI = {
  id: {
    launch: "Tanya data", title: "Tanya data Biomass Paradox", close: "Tutup",
    intro: "Tanyakan apa saja soal 189 negara, perbandingan, rezim, atau metode dashboard ini. Mendukung kode Alpha-3, Alpha-2, singkatan santai, dan salah ketik ringan.",
    label: "Pertanyaan Anda", placeholder: "Contoh: Indo gimana? atau bandingkan MY dan VN", send: "Kirim",
    you: "Anda", bot: "Data", loading: "Memuat data...", thinking: "Menyusun jawaban...",
    error: "Data gagal dimuat. Muat ulang halaman, lalu coba lagi.",
    suggestions: ["Indo gimana?", "Bandingkan Malay dan Viet Nam", "Negara ASEAN", "Memasak bersih terendah", "Kenapa pakai K-Means bukan GMM?"],
    footLocal: "Mode lokal: Tidak ada AI yang terlibat.",
    footAi: (prov) => `Dijawab AI (${prov === "groq" ? "Groq" : "Gemini"}) berdasarkan isi dashboard.`,
    footFallback: "Mode lokal: Tidak ada AI yang terlibat.",
    help: "Saya belum menangkap pertanyaannya. Coba sebut negara atau kodenya (misalnya \"Indo gimana?\", \"MY\", \"Spanyol\", \"ESP\"), bandingkan dua negara, ASEAN, R1 sampai R4, \"memasak bersih terendah\", atau tanya metode (K-Means, GMM, jalur P1/P2, prediksi).",
    nf: (v, d = 1) => Number(v).toLocaleString("id-ID", { minimumFractionDigits: d, maximumFractionDigits: d }),
    country: (c, r, n, pw, nm) => `${nm(c)} (${c.iso3}) masuk ${r.kode_rezim}, ${r.nama_id}${c.kode_2015 !== c.kode_2023 ? `; pada 2015 masih di ${c.kode_2015}` : ""}${pw ? ` (jalur perubahan ${pw.pathway})` : ""}. ` +
      `Pada 2023: akses listrik ${n(c.elec_2023)}%, memasak bersih ${n(c.cooking_2023, 0)}% (2015: ${n(c.cooking_2015, 0)}%), pangsa energi terbarukan ${n(c.renew_share_2023)}%, ` +
      `kapasitas listrik terbarukan ${n(c.renew_cap_2023)} W per orang, intensitas energi ${n(c.energy_int_2023, 2)} MJ per USD PPP, dan CO2 ${n(c.co2_pc_2023, 2)} ton per orang.`,
    compare: (cs, n, nm) => "Perbandingan 2023:\n" + cs.map((c) => `${nm(c)} (${c.iso3}): ${c.kode_2023}, listrik ${n(c.elec_2023)}%, memasak bersih ${n(c.cooking_2023, 0)}%, terbarukan ${n(c.renew_share_2023)}%, kapasitas ${n(c.renew_cap_2023)} W per orang, CO2 ${n(c.co2_pc_2023, 2)} t per orang`).join("\n"),
    asean: (cs, n, nm) => "Negara ASEAN, 2023 (rezim, memasak bersih, kapasitas listrik terbarukan per orang):\n" + cs.map((c) => `${nm(c)} (${c.iso3}): ${c.kode_2023}, ${n(c.cooking_2023, 0)}%, ${n(c.renew_cap_2023)} W`).join("\n"),
    regime: (r, n) => `${r.kode_rezim}, ${r.nama_id}: ${r.n_negara} negara dengan ${n(r.populasi_miliar, 2)} miliar penduduk. Rata-rata akses listrik ${n(r.elec_mean)}%, memasak bersih ${n(r.cooking_mean)}%, pangsa terbarukan ${n(r.renew_share_mean)}%; median kapasitas listrik terbarukan ${n(r.renew_cap_median)} W per orang dan median CO2 ${n(r.co2_pc_median, 2)} ton per orang.`,
    regimes: (rs) => "Empat rezim 2023: " + rs.map((r) => `${r.kode_rezim} ${r.nama_id} (${r.n_negara} negara)`).join("; ") + ". Sebut R1 sampai R4 untuk rinciannya.",
    extreme: (lbl, hi, cs, n, d) => `${hi ? "Tertinggi" : "Terendah"} untuk ${lbl} (2023): ` + cs.map((c, i) => `${i + 1}. ${c.name} (${c.iso3}) ${n(c.v, d)}`).join(", ") + ".",
    labels: { cooking_2023: "memasak bersih (%)", elec_2023: "akses listrik (%)", renew_share_2023: "pangsa energi terbarukan (%)", renew_cap_2023: "kapasitas listrik terbarukan (W per orang)", energy_int_2023: "intensitas energi (MJ per USD PPP)", co2_pc_2023: "CO2 per orang (ton)" },
    moves: (list) => "Perpindahan rezim 2015 ke 2023: " + list.map((m) => `${m.kode_2015} ke ${m.kode_2023}: ${m.n} negara`).join("; ") + ". Negara lain tetap di rezimnya. Ini perbandingan dua titik waktu, bukan dampak kebijakan.",
    paradox: (k, rs, n) => `Pangsa energi terbarukan (SDG 7.2.1) ikut menghitung kayu bakar dan arang di tungku rumah. Akibatnya, pada 2023 ada ${k} negara dengan pangsa terbarukan di atas 50% tetapi memasak bersih di bawah 20%. Di rezim R1 rata-rata pangsa terbarukannya ${n(rs.renew_share_mean)}%, sementara memasak bersih hanya ${n(rs.cooking_mean)}%.`,
    methods: (km4, gmm4, meta, n) => `K-Means k=4 dipilih untuk analisis utama karena stabil di antara model multi-rezim (rerata Jaccard ${n(km4.jaccard_mean, 3)}, minimum ${n(km4.jaccard_min, 3)}, Silhouette ${n(km4.silhouette, 3)}, dan sepakat dengan Ward D2 ARI 0,795). Alternatif biner k=2 lebih tinggi secara kasar (B1 dan B2), tetapi menggabungkan negara bersih R3 dengan fosil tinggi R4. GMM bebas (VEV) turun ke Silhouette ${n(gmm4.silhouette, 3)} dan sensitif terhadap kovarians (dengan model sferis EII, Silhouette naik ke ${n(meta.gmm_eii_sil_k4, 3)} dan ARI ke ${n(meta.gmm_eii_ari_k4, 3)}).`,
    pathways: (p1, p2, pw, n) => `Pengelompokan perubahan 2015 ke 2023 (FANNY k=2) membentuk dua arah, tetapi strukturnya lemah (Silhouette ${n(pw.k_comparison.find((x) => x.k === pw.k).silhouette, 3)}): P1 (${p1.n_negara} negara) menambah akses (median listrik +${n(p1.med_d_elec_pp)} poin, memasak bersih +${n(p1.med_d_cook_pp, 0)} poin), sedangkan P2 (${p2.n_negara} negara) bergerak ke karbon lebih rendah (kapasitas EBT +${n(p2.med_d_cap_wpc)} W, CO2 ${n(p2.med_d_co2_t, 2)} t).`,
    forecast: (pers, ols, enet, n) => `Prediksi akses memasak bersih 2023 dari data 2015 (validasi silang 10 lipatan): MAE out-of-fold persistensi ${n(pers.mae_pp, 2)} poin persen, regresi linear memasak 2015 ${n(ols.mae_pp, 2)} poin, dan elastic net keenam indikator ${n(enet.mae_pp, 2)} poin. Ini validasi historis antarnegara 2015 ke 2023, bukan peramalan tahun mendatang.`,
    outliers: (list, n, nm) => `Enam pencilan multivariat Mahalanobis (D2 > 22,46, tetap dipertahankan karena mewakili kondisi nyata): ` + list.map((o) => `${nm(o)} (${o.iso3}, D2 ${n(o.mahalanobis_d2, 1)})`).join("; ") + "."
  },
  en: {
    launch: "Ask the data", title: "Ask the Biomass Paradox data", close: "Close",
    intro: "Ask anything about the 189 countries, comparisons, regimes, or dashboard methods. Supports Alpha-3, Alpha-2, casual names, and minor typos.",
    label: "Your question", placeholder: "Example: How is Indo doing? or Compare MY and VN", send: "Send",
    you: "You", bot: "Data", loading: "Loading the data...", thinking: "Writing answer...",
    error: "The data failed to load. Reload the page and try again.",
    suggestions: ["How is Indonesia doing?", "Compare Malaysia and Viet Nam", "ASEAN countries", "Lowest clean cooking", "Why K-Means instead of GMM?"],
    footLocal: "Local mode: No AI involved.",
    footAi: (prov) => `Answered by AI (${prov === "groq" ? "Groq" : "Gemini"}) based on dashboard content.`,
    footFallback: "Local mode: No AI involved.",
    help: "I did not catch the question. Try a country name or code (for example \"Indo\", \"MY\", \"Spain\", \"ESP\"), two countries to compare, ASEAN, R1 to R4, \"lowest clean cooking\", or ask about methods (K-Means, GMM, pathways P1/P2, forecast).",
    nf: (v, d = 1) => Number(v).toLocaleString("en-US", { minimumFractionDigits: d, maximumFractionDigits: d }),
    country: (c, r, n, pw, nm) => `${nm(c)} (${c.iso3}) is in ${r.kode_rezim}, ${r.nama_en}${c.kode_2015 !== c.kode_2023 ? `; in 2015 it was in ${c.kode_2015}` : ""}${pw ? ` (change pathway ${pw.pathway})` : ""}. ` +
      `In 2023: electricity access ${n(c.elec_2023)}%, clean cooking ${n(c.cooking_2023, 0)}% (2015: ${n(c.cooking_2015, 0)}%), renewable share ${n(c.renew_share_2023)}%, ` +
      `renewable power capacity ${n(c.renew_cap_2023)} W per person, energy intensity ${n(c.energy_int_2023, 2)} MJ per PPP USD, and CO2 ${n(c.co2_pc_2023, 2)} t per person.`,
    compare: (cs, n, nm) => "Comparison, 2023:\n" + cs.map((c) => `${nm(c)} (${c.iso3}): ${c.kode_2023}, electricity ${n(c.elec_2023)}%, clean cooking ${n(c.cooking_2023, 0)}%, renewable ${n(c.renew_share_2023)}%, capacity ${n(c.renew_cap_2023)} W per person, CO2 ${n(c.co2_pc_2023, 2)} t per person`).join("\n"),
    asean: (cs, n, nm) => "ASEAN countries, 2023 (regime, clean cooking, renewable power capacity per person):\n" + cs.map((c) => `${nm(c)} (${c.iso3}): ${c.kode_2023}, ${n(c.cooking_2023, 0)}%, ${n(c.renew_cap_2023)} W`).join("\n"),
    regime: (r, n) => `${r.kode_rezim}, ${r.nama_en}: ${r.n_negara} countries with ${n(r.populasi_miliar, 2)} billion people. Mean electricity access ${n(r.elec_mean)}%, clean cooking ${n(r.cooking_mean)}%, renewable share ${n(r.renew_share_mean)}%; median renewable capacity ${n(r.renew_cap_median)} W per person and median CO2 ${n(r.co2_pc_median, 2)} t per person.`,
    regimes: (rs) => "The four 2023 regimes: " + rs.map((r) => `${r.kode_rezim} ${r.nama_en} (${r.n_negara} countries)`).join("; ") + ". Name R1 to R4 for details.",
    extreme: (lbl, hi, cs, n, d) => `${hi ? "Highest" : "Lowest"} ${lbl} (2023): ` + cs.map((c, i) => `${i + 1}. ${c.name} (${c.iso3}) ${n(c.v, d)}`).join(", ") + ".",
    labels: { cooking_2023: "clean cooking (%)", elec_2023: "electricity access (%)", renew_share_2023: "renewable share (%)", renew_cap_2023: "renewable power capacity (W per person)", energy_int_2023: "energy intensity (MJ per PPP USD)", co2_pc_2023: "CO2 per person (t)" },
    moves: (list) => "Regime changes from 2015 to 2023: " + list.map((m) => `${m.kode_2015} to ${m.kode_2023}: ${m.n} countries`).join("; ") + ". All other countries stayed in their regime. This compares two points in time, not a policy effect.",
    paradox: (k, rs, n) => `The renewable share (SDG 7.2.1) counts firewood and charcoal burned in home stoves. So in 2023, ${k} countries had a renewable share above 50% but clean cooking below 20%. In regime R1 the mean renewable share is ${n(rs.renew_share_mean)}%, while clean cooking is only ${n(rs.cooking_mean)}%.`,
    methods: (km4, gmm4, meta, n) => `K-Means k=4 is the chosen multi-regime model for its stability (mean Jaccard ${n(km4.jaccard_mean, 3)}, min ${n(km4.jaccard_min, 3)}, Silhouette ${n(km4.silhouette, 3)}, Ward D2 ARI 0.795). Coarse binary k=2 scores higher globally (B1/B2) but merges clean R3 and fossil-heavy R4. Unconstrained BIC GMM (VEV) drops to Silhouette ${n(gmm4.silhouette, 3)} due to covariance sensitivity (spherical EII raises Silhouette to ${n(meta.gmm_eii_sil_k4, 3)} and ARI to ${n(meta.gmm_eii_ari_k4, 3)}).`,
    pathways: (p1, p2, pw, n) => `2015 to 2023 change clustering (FANNY k=2) summarises two directions with weak structure (Silhouette ${n(pw.k_comparison.find((x) => x.k === pw.k).silhouette, 3)}): P1 (${p1.n_negara} countries) gained access (median electricity +${n(p1.med_d_elec_pp)} pp, clean cooking +${n(p1.med_d_cook_pp, 0)} pp), while P2 (${p2.n_negara} countries) shifted toward lower carbon (renewable capacity +${n(p2.med_d_cap_wpc)} W, CO2 ${n(p2.med_d_co2_t, 2)} t).`,
    forecast: (pers, ols, enet, n) => `Predicting 2023 clean cooking from 2015 data (10-fold cross-validation): out-of-fold MAE is ${n(pers.mae_pp, 2)} pp for persistence, ${n(ols.mae_pp, 2)} pp for 2015 cooking regression, and ${n(enet.mae_pp, 2)} pp for elastic net on all six indicators. This is historical cross-country validation, not a future forecast.`,
    outliers: (list, n, nm) => `Six Mahalanobis multivariate outliers (D2 > 22.46, retained as real regimes): ` + list.map((o) => `${nm(o)} (${o.iso3}, D2 ${n(o.mahalanobis_d2, 1)})`).join("; ") + "."
  }
};

// Indonesian names, casual abbreviations, and slang mapped to ISO3.
const ALIASES = {
  indo: "IDN", ri: "IDN", malay: "MYS", msia: "MYS", sg: "SGP", singapor: "SGP", singapura: "SGP",
  vietnam: "VNM", viet: "VNM", filipina: "PHL", filipin: "PHL", pinoy: "PHL", thai: "THA", thail: "THA",
  kamboja: "KHM", laos: "LAO", "timor leste": "TLS", timor: "TLS", brunei: "BRN", burma: "MMR",
  tiongkok: "CHN", cina: "CHN", china: "CHN", "amerika serikat": "USA", amerika: "USA", amrik: "USA", usa: "USA",
  jepang: "JPN", jerman: "DEU", norwegia: "NOR", islandia: "ISL", rusia: "RUS", ukraina: "UKR",
  "arab saudi": "SAU", saudi: "SAU", uea: "ARE", uae: "ARE", irak: "IRQ", yordania: "JOR",
  brasil: "BRA", kanada: "CAN", meksiko: "MEX", kolombia: "COL", chili: "CHL",
  inggris: "GBR", uk: "GBR", prancis: "FRA", perancis: "FRA", "korea selatan": "KOR", korsel: "KOR",
  "korea utara": "PRK", korut: "PRK", "afrika selatan": "ZAF", afsel: "ZAF", mesir: "EGY", maroko: "MAR",
  belanda: "NLD", swedia: "SWE", finlandia: "FIN", italia: "ITA", spanyol: "ESP", turki: "TUR",
  swiss: "CHE", belgia: "BEL", yunani: "GRC", polandia: "POL", irlandia: "IRL",
  aussie: "AUS", "selandia baru": "NZL", drc: "COD", kongo: "COD"
};

// ISO3 and ISO2 codes that collide with common English or Indonesian words require uppercase.
const ISO3_UPPER_ONLY = new Set(["AGO", "ARE", "ARM", "BEN", "CAN", "COD", "CUB", "FIN", "GIN", "GUY", "JAM", "KEN", "MAR", "NOR", "PAN", "PER", "SEN", "SUR", "TON"]);
const ISO2_UPPER_ONLY = new Set([
  "AM", "AR", "AS", "AT", "BE", "BI", "BO", "BY", "CA", "CO", "DE", "DO", "ER", "ES", "ET", "FI", "GE",
  "ID", "IN", "IR", "IS", "IT", "KE", "LA", "MA", "ME", "MY", "NA", "NE", "NI", "NO", "OM", "PA", "PE",
  "PR", "SA", "SE", "SI", "SO", "TO", "US", "YE"
]);

// Common question and domain words excluded from fuzzy typo matching.
const STOP_WORDS = new Set([
  "negara", "rezim", "listrik", "memasak", "masak", "bersih", "energi", "terbarukan", "kapasitas", "intensitas",
  "karbon", "emisi", "bandingkan", "dibanding", "antara", "gimana", "bagaimana", "kenapa", "mengapa", "berapa",
  "siapa", "apakah", "dengan", "sejak", "tahun", "lebih", "paling", "masuk", "adalah", "untuk", "dalam",
  "tertinggi", "terendah", "sedikit", "banyak", "besar", "kecil", "pindah", "perpindahan", "migrasi", "bergerak",
  "berubah", "perubahan", "paradoks", "biomassa", "metode", "algoritma", "klaster", "kelompok", "jalur",
  "prediksi", "ramalan", "persistensi", "elastic", "pencilan", "outlier", "outliers", "mahalanobis", "median",
  "dunia", "global", "orang", "persen", "terpilih", "bagusan", "unggul", "kalah", "menang", "bukan", "tetapi",
  "jelaskan", "ceritakan", "tolong", "coba", "pilih", "peta", "grafik", "tabel", "dashboard", "atlas",
  "country", "countries", "regime", "regimes", "electric", "electricity", "cooking", "clean", "energy",
  "renewable", "capacity", "intensity", "carbon", "emission", "emissions", "compare", "comparison", "between",
  "about", "which", "where", "since", "moved", "migration", "change", "changes", "paradox", "biomass",
  "method", "methods", "algorithm", "cluster", "clusters", "pathway", "pathways", "predict", "prediction",
  "forecast", "persistence", "highest", "lowest", "least", "smallest", "largest", "world", "people",
  "selected", "better", "worse", "versus", "explain", "describe", "please", "chart", "table", "model", "models",
  "kmeans", "silhouette", "jaccard", "bootstrap", "chosen", "binary", "modern", "fossil", "traditional", "doing"
]);

const INDICATORS = [
  [/kapasitas|capacity|watt/, "renew_cap_2023", 1], [/memasak|masak|cooking/, "cooking_2023", 0], [/co2|karbon|carbon|emisi|emission/, "co2_pc_2023", 2],
  [/intensitas|intensity/, "energy_int_2023", 2], [/listrik|electric/, "elec_2023", 1], [/terbarukan|renewable/, "renew_share_2023", 1]
];
const LOW = /terendah|paling rendah|paling sedikit|paling kecil|lowest|least|fewest|smallest|minimum/;
const HIGH = /tertinggi|paling tinggi|paling banyak|paling besar|highest|most|largest|maximum|top/;

const css = `
.bp-bot-launch {
  position: fixed; z-index: 45; right: 16px; bottom: 16px; display: inline-flex; align-items: center; gap: 8px;
  min-height: 48px; padding: 8px 16px; border-radius: 999px; border: 1px solid rgba(243, 240, 228, 0.18);
  background: #0B1711; color: #F3F0E4; font: 600 15px/1 "Manrope", system-ui, sans-serif; cursor: pointer;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25); touch-action: manipulation;
  transition: background-color 300ms cubic-bezier(0.22, 1, 0.36, 1);
}
.bp-bot-launch:hover { background: #1A2D23; }
.bp-bot-launch svg { width: 18px; height: 18px; color: #A9D85A; }
.bp-bot-launch[aria-expanded="true"] { display: none; }
.bp-bot {
  position: fixed; z-index: 46; right: 16px; bottom: 16px; width: min(420px, calc(100vw - 32px));
  max-height: min(640px, calc(100dvh - 32px)); display: flex; flex-direction: column;
  background: light-dark(#FFFFFF, #12211A); color: light-dark(#15231B, #F3F0E4);
  border: 1px solid light-dark(#D9D5C6, #2A3F33); border-radius: 16px; box-shadow: 0 16px 48px rgba(0, 0, 0, 0.28);
  font: 500 14px/1.55 "Manrope", system-ui, -apple-system, "Segoe UI", sans-serif;
}
.bp-bot[hidden], .bp-bot [hidden] { display: none !important; }
.bp-bot :focus-visible { outline: 3px solid light-dark(#3F6212, #A9D85A); outline-offset: 2px; }
.bp-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; padding: 12px 12px 12px 16px; border-bottom: 1px solid light-dark(#D9D5C6, #2A3F33); }
.bp-head h2 { margin: 0; font: 700 16px/1.3 "Manrope", system-ui, sans-serif; }
.bp-x { min-width: 44px; min-height: 44px; border: 0; border-radius: 10px; background: transparent; color: inherit; cursor: pointer; font-size: 20px; line-height: 1; }
.bp-x:hover { background: light-dark(rgba(21, 35, 27, 0.07), rgba(243, 240, 228, 0.09)); }
.bp-body { padding: 12px 16px; overflow-y: auto; display: grid; gap: 12px; flex: 1 1 auto; min-height: 0; }
.bp-body p { margin: 0; }
.bp-muted { color: light-dark(#4D5A50, #B9C2B5); }
.bp-small { font-size: 12.5px; }
.bp-btn {
  font: 600 14px/1 "Manrope", system-ui, sans-serif; min-height: 44px; padding: 8px 16px; border-radius: 12px; cursor: pointer;
  border: 1px solid #A9D85A; background: #A9D85A; color: #0B1711; touch-action: manipulation;
}
.bp-btn:hover { background: #BCE477; }
.bp-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.bp-log { display: grid; gap: 8px; }
.bp-msg { padding: 8px 12px; border-radius: 12px; white-space: pre-wrap; overflow-wrap: anywhere; }
.bp-msg b { display: block; font: 600 12px/1.4 "JetBrains Mono", ui-monospace, monospace; margin-bottom: 2px; }
.bp-msg.user { background: light-dark(#ECE9DD, #1A2D23); justify-self: end; max-width: 90%; }
.bp-msg.bot { border: 1px solid light-dark(#D9D5C6, #2A3F33); }
.bp-msg.is-thinking { color: light-dark(#4D5A50, #B9C2B5); }
.bp-chips { display: flex; flex-wrap: wrap; gap: 6px; }
.bp-chip {
  font: 500 13px/1.3 "Manrope", system-ui, -apple-system, "Segoe UI", sans-serif; min-height: 36px; padding: 6px 12px; border-radius: 999px; cursor: pointer;
  border: 1px solid light-dark(#8C8C85, #6F8A79); background: transparent; color: inherit; text-align: left; position: relative;
}
.bp-chip::after { content: ""; position: absolute; inset: -4px 0; }
.bp-chip:hover { background: light-dark(rgba(21, 35, 27, 0.07), rgba(243, 240, 228, 0.09)); }
.bp-form { display: flex; gap: 8px; padding: 12px 16px; border-top: 1px solid light-dark(#D9D5C6, #2A3F33); align-items: flex-end; }
.bp-form input {
  flex: 1 1 auto; min-width: 0; min-height: 44px; padding: 0 12px; border-radius: 12px;
  border: 1px solid light-dark(#8C8C85, #6F8A79); background: transparent; color: inherit; font: inherit;
}
.bp-foot { padding: 0 16px 12px; }
.bp-vh { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
@media (max-width: 640px) {
  .bp-bot { right: 8px; left: 8px; bottom: 8px; width: auto; max-height: calc(100dvh - 96px); }
  .bp-bot-launch { right: 12px; bottom: 12px; }
}
@media (prefers-reduced-motion: reduce) { .bp-bot-launch { transition: none; } }
`;

const el = (tag, attrs = {}, html = "") => {
  const n = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) n.setAttribute(k, v);
  if (html) n.innerHTML = html;
  return n;
};
const lang = () => (document.documentElement.lang === "en" ? "en" : "id");
const t = () => UI[lang()];
const apiEndpoint = () => (typeof window.__BP_BOT_API__ === "string" ? window.__BP_BOT_API__ : WORKER_URL).trim();

document.head.append(el("style", {}, css));
const launch = el("button", { type: "button", class: "bp-bot-launch", "aria-expanded": "false", "aria-controls": "bp-bot" },
  '<svg viewBox="0 0 20 20" aria-hidden="true"><path d="M4 4.5h12a1.5 1.5 0 0 1 1.5 1.5v7a1.5 1.5 0 0 1-1.5 1.5H9l-3.5 3v-3H4A1.5 1.5 0 0 1 2.5 13V6A1.5 1.5 0 0 1 4 4.5z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg><span></span>');
const panel = el("div", { id: "bp-bot", class: "bp-bot", role: "dialog", "aria-modal": "false", "aria-labelledby": "bp-bot-title", hidden: "" });
panel.innerHTML = `
  <div class="bp-head"><h2 id="bp-bot-title"></h2><button type="button" class="bp-x" data-close><span aria-hidden="true">&times;</span><span class="bp-vh"></span></button></div>
  <div class="bp-body">
    <p class="bp-intro bp-muted"></p>
    <p class="bp-state" role="status"></p>
    <div class="bp-log" role="log" aria-live="polite"></div>
    <div class="bp-chips"></div>
  </div>
  <form class="bp-form">
    <label class="bp-vh" for="bp-q"></label>
    <input id="bp-q" type="text" autocomplete="off" disabled>
    <button type="submit" class="bp-btn" disabled data-send></button>
  </form>
  <p class="bp-foot bp-small bp-muted"></p>`;
document.body.append(launch, panel);

const $ = (s) => panel.querySelector(s);
const stateBox = $(".bp-state"), log = $(".bp-log"), chips = $(".bp-chips"), input = $("#bp-q"), sendBtn = $("[data-send]"), foot = $(".bp-foot");
let data = null, status = "idle", busy = false;
let summaryContext = "", cachedContext = "", fuzzyVocab = [], pwByIso = new Map(), fcByIso = new Map(), rowByIso = new Map();
let lastMode = "local", lastProvider = "gemini";
const history = [], replyCache = new Map();
const cName = (c) => (lang() === "id" && c && c.country_id) ? c.country_id : (c ? c.country_en : "");

function updateFoot() {
  const u = t();
  if (lastMode === "ai") foot.textContent = u.footAi(lastProvider);
  else if (lastMode === "fallback") foot.textContent = u.footFallback;
  else foot.textContent = apiEndpoint() ? u.footAi(lastProvider) : u.footLocal;
}

function renderState() {
  stateBox.hidden = status === "ready";
  stateBox.textContent = status === "error" ? t().error : t().loading;
  input.disabled = sendBtn.disabled = status !== "ready" || busy;
  chips.hidden = status !== "ready";
  updateFoot();
}

function applyText() {
  const u = t();
  launch.querySelector("span").textContent = u.launch;
  $("#bp-bot-title").textContent = u.title;
  $(".bp-x .bp-vh").textContent = u.close;
  $(".bp-intro").textContent = u.intro;
  $(".bp-form label").textContent = u.label;
  input.placeholder = u.placeholder;
  sendBtn.textContent = u.send;
  chips.innerHTML = "";
  for (const q of u.suggestions) {
    const b = el("button", { type: "button", class: "bp-chip" });
    b.textContent = q;
    b.addEventListener("click", () => ask(q));
    chips.append(b);
  }
  log.querySelectorAll(".bp-msg b").forEach((b) => { b.textContent = b.parentElement.classList.contains("user") ? u.you : u.bot; });
  renderState();
}
new MutationObserver(applyText).observe(document.documentElement, { attributes: true, attributeFilter: ["lang"] });

const norm = (s) => s.toLowerCase().replace(/[^\p{L}\p{N} ]/gu, " ").replace(/\s+/g, " ").trim();

function buildIndexes() {
  pwByIso = new Map((data.pathways?.countries || []).map((x) => [x.iso3, x]));
  fcByIso = new Map((data.cooking_forecast?.countries || []).map((x) => [x.iso3, x]));

  const vocab = [];
  const seen = new Set();
  const push = (term, iso) => {
    const clean = norm(term);
    if (clean.length < 5 || seen.has(clean + ":" + iso)) return;
    seen.add(clean + ":" + iso);
    vocab.push({ term: clean, iso });
  };
  for (const [k, iso] of Object.entries(ALIASES)) push(k, iso);
  for (const c of data.countries) {
    push(c.country_en, c.iso3);
    if (c.country_id) push(c.country_id, c.iso3);
  }
  fuzzyVocab = vocab;

  // Compact grounding blocks for the AI Worker (summary ~1.5 KB; full 189 countries ~16 KB).
  const rLines = data.regimes.map((r) =>
    `${r.kode_rezim} (${r.nama_en} / ${r.nama_id}): n=${r.n_negara}, pop=${r.populasi_miliar}B, mean elec=${r.elec_mean}%, cook=${r.cooking_mean}%, rshare=${r.renew_share_mean}%, med cap=${r.renew_cap_median}W, med CO2=${r.co2_pc_median}t, Jaccard=${r.jaccard_km}`
  );
  const k2Lines = (data.regimes_k2 || []).map((b) => `${b.kode_k2} (${b.nama_en}): n=${b.n_negara}, comp=${b.komposisi_rezim_k4}, Jaccard=${b.jaccard_km_k2}`);
  const migLines = data.migration.filter((m) => m.kode_2015 !== m.kode_2023 && m.n > 0).map((m) => `${m.kode_2015}->${m.kode_2023}:${m.n}`);
  const km4 = data.eval_grid.find((m) => m.metode === "KMeans" && m.k === 4);
  const gmm4 = data.eval_grid.find((m) => m.metode === "GMM" && m.k === 4);
  const pwLines = (data.pathways?.profiles || []).map((p) => `${p.pathway}: n=${p.n_negara}, dElec=${p.med_d_elec_pp}pp, dCook=${p.med_d_cook_pp}pp, dRSh=${p.med_d_rshare_pp}pp, dCap=${p.med_d_cap_wpc}W, dCO2=${p.med_d_co2_t}t, regimes=${p.rezim_2023}`);
  const fcLines = (data.cooking_forecast?.metrics || []).map((m) => `${m.model}: MAE=${m.mae_pp}pp, RMSE=${m.rmse_pp}pp`);
  const outLines = (data.outliers || []).map((o) => `${o.iso3}(${o.country_id || o.country_en}, D2=${o.mahalanobis_d2})`);
  const paradoxCount = data.countries.filter((c) => c.renew_share_2023 > 50 && c.cooking_2023 < 20).length;

  rowByIso = new Map();
  const rows = data.countries.map((c) => {
    const pw = pwByIso.get(c.iso3)?.pathway || "-";
    const row = `${c.iso3}|${c.iso2 || ""}|${c.country_en}|${c.country_id || c.country_en}|${c.kode_2023}|${c.kode_2015}|${c.elec_2023}|${c.cooking_2023}(${c.cooking_2015})|${c.renew_share_2023}|${c.renew_cap_2023}|${c.energy_int_2023}|${c.co2_pc_2023}|${pw}`;
    rowByIso.set(c.iso3, row);
    return row;
  });

  summaryContext = [
    `DASHBOARD: 189 sovereign economies (8.02B people), UN SDG Indicators Database + World Bank, 2015 & 2023. Biomass paradox count (2023 renew_share>50% & clean_cooking<20%): ${paradoxCount}.`,
    `REGIMES k=4 (K-Means chosen): ${rLines.join(" ; ")}`,
    `BINARY k=2: ${k2Lines.join(" ; ")}`,
    `MODELS: KMeans k=4 Sil=${km4.silhouette}, DB=${km4.davies_bouldin}, CH=${km4.calinski_harabasz}, Jaccard=${km4.jaccard_mean} (min ${km4.jaccard_min}), Ward ARI=0.795, missMDA n=207 ARI=${data.meta.ari_missmda_189}; GMM VEV k=4 Sil=${gmm4.silhouette} ARI=0.3671, spherical EII Sil=${data.meta.gmm_eii_sil_k4} ARI=${data.meta.gmm_eii_ari_k4}; KMO=${data.meta.kmo_overall}, Hopkins=${data.meta.hopkins}, PC1=59.4%, KW GDP H=${data.meta.kw_gdp_chisq}.`,
    `MIGRATION 2015->2023 (descriptive): ${migLines.join(", ")}, into R1: 0.`,
    `PATHWAYS 2015->2023 (FANNY k=2, weak Sil=0.2047): ${pwLines.join(" ; ")}`,
    `CLEAN COOKING PREDICTION (2015->2023 10-fold CV): ${fcLines.join(" ; ")}`,
    `OUTLIERS (Mahalanobis D2>22.46): ${outLines.join(", ")}`,
    `COUNTRIES (ISO3|ISO2|NameEN|NameID|R23|R15|Elec%|Cook23%(15%)|RSh%|CapW|IntMJ|CO2t|Path):`
  ].join("\n");
  cachedContext = summaryContext + "\n" + rows.join("\n");
}

async function loadData() {
  if (data) return;
  try {
    const r = await fetch(DATA_URL);
    if (!r.ok) throw new Error("HTTP " + r.status);
    data = await r.json();
  } catch (_) {
    data = window.__SDG_DASHBOARD_DATA__ || null;
  }
  if (data) buildIndexes();
  status = data ? "ready" : "error";
  renderState();
}

async function open() {
  panel.hidden = false;
  launch.setAttribute("aria-expanded", "true");
  renderState();
  $(".bp-x").focus();
  await loadData();
  if (status === "ready" && !panel.hidden) input.focus();
}
function close() {
  panel.hidden = true;
  launch.setAttribute("aria-expanded", "false");
  launch.focus();
}
launch.addEventListener("click", open);
$("[data-close]").addEventListener("click", close);
panel.addEventListener("keydown", (e) => { if (e.key === "Escape") { e.preventDefault(); close(); } });

/* ---- fuzzy & local answering ---- */
function lev(a, b, maxD) {
  if (Math.abs(a.length - b.length) > maxD) return maxD + 1;
  let prev2 = null;
  let prev = Array.from({ length: b.length + 1 }, (_, j) => j);
  for (let i = 1; i <= a.length; i++) {
    const cur = [i];
    let rowMin = i;
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      let v = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
      if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) {
        v = Math.min(v, prev2[j - 2] + 1);
      }
      cur.push(v);
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > maxD) return maxD + 1;
    prev2 = prev;
    prev = cur;
  }
  return prev[b.length];
}

function findCountries(q) {
  const cleaned = norm(q);
  const padded = " " + cleaned + " ";
  const hits = [];
  const usedTerms = new Set();
  const add = (iso, pos, matched = "") => {
    if (pos >= 0 && !hits.some((h) => h.iso === iso)) hits.push({ iso, pos });
    if (matched) for (const w of matched.split(" ")) usedTerms.add(w);
  };

  const tokens = cleaned.split(" ").filter(Boolean);
  const isAllCapsSentence = q === q.toUpperCase() && tokens.length > 3;

  for (const [name, iso] of Object.entries(ALIASES)) {
    const pos = padded.indexOf(" " + name + " ");
    if (pos >= 0) add(iso, pos, name);
  }
  for (const c of data.countries) {
    const cn = norm(c.country_en);
    const pos = padded.indexOf(" " + cn + " ");
    if (pos >= 0) add(c.iso3, pos, cn);
    if (c.country_id) {
      const cid = norm(c.country_id);
      const posId = padded.indexOf(" " + cid + " ");
      if (posId >= 0) add(c.iso3, posId, cid);
    }
    const m3 = q.search(new RegExp(`\\b${c.iso3}\\b`, ISO3_UPPER_ONLY.has(c.iso3) ? "" : "i"));
    if (m3 >= 0) add(c.iso3, m3, c.iso3.toLowerCase());
    if (c.iso2) {
      const upperOnly2 = ISO2_UPPER_ONLY.has(c.iso2);
      if (!(upperOnly2 && isAllCapsSentence)) {
        const m2 = q.search(new RegExp(`\\b${c.iso2}\\b`, upperOnly2 ? "" : "i"));
        if (m2 >= 0) add(c.iso3, m2, c.iso2.toLowerCase());
      }
    }
  }

  // Fuzzy typo fallback on remaining unrecognized words (>= 5 chars) and bigrams.
  const candidates = [];
  for (let i = 0; i < tokens.length; i++) {
    const w = tokens[i];
    if (w.length >= 5 && !STOP_WORDS.has(w) && !usedTerms.has(w)) {
      candidates.push({ text: w, pos: cleaned.indexOf(w) });
    }
    if (i + 1 < tokens.length) {
      const w2 = tokens[i + 1];
      if (!STOP_WORDS.has(w) && !STOP_WORDS.has(w2) && !usedTerms.has(w) && !usedTerms.has(w2)) {
        const pair = w + " " + w2;
        if (pair.length >= 7) candidates.push({ text: pair, pos: cleaned.indexOf(pair) });
      }
    }
  }

  for (const cand of candidates) {
    const maxD = cand.text.length >= 7 ? 2 : 1;
    let best = null;
    for (const v of fuzzyVocab) {
      if (cand.text.includes(" ") !== v.term.includes(" ")) continue;
      // Require matching initial character (or adjacent swap) for short 5-6 char tokens to avoid false positives.
      if (maxD === 1 && cand.text[0] !== v.term[0] && !(cand.text[0] === v.term[1] && cand.text[1] === v.term[0])) continue;
      const d = lev(cand.text, v.term, maxD);
      if (d <= maxD && d / Math.max(cand.text.length, v.term.length) <= 0.28) {
        if (!best || d < best.d) best = { iso: v.iso, d };
      }
    }
    if (best) add(best.iso, cand.pos, cand.text);
  }

  return hits.sort((a, b) => a.pos - b.pos).map((h) => data.countries.find((c) => c.iso3 === h.iso)).filter(Boolean);
}

function selectedCountry() {
  const sub = document.getElementById("insp-sub");
  const m = sub && sub.textContent.match(/^([A-Z]{3})\b/);
  return m ? data.countries.find((c) => c.iso3 === m[1]) : null;
}

function answerLocal(q) {
  const u = t(), n = u.nf, low = q.toLowerCase();
  const regime = (code) => data.regimes.find((r) => r.kode_rezim === code);
  if (/paradoks|paradox/.test(low)) {
    const k = data.countries.filter((c) => c.renew_share_2023 > 50 && c.cooking_2023 < 20).length;
    return u.paradox(k, regime("R1"), n);
  }
  if (/\basean\b/.test(low)) return u.asean(data.countries.filter((c) => c.is_asean).sort((a, b) => cName(a).localeCompare(cName(b))), n, cName);
  const dirLow = LOW.test(low), dirHigh = HIGH.test(low);
  if (dirLow || dirHigh) {
    const ind = INDICATORS.find(([re]) => re.test(low));
    if (ind) {
      const [, key, d] = ind;
      const s = data.countries.map((c) => ({ name: cName(c), iso3: c.iso3, v: c[key] })).sort((a, b) => a.v - b.v);
      return u.extreme(u.labels[key], dirHigh && !dirLow, (dirHigh && !dirLow ? s.reverse() : s).slice(0, 5), n, d);
    }
  }
  let cs = findCountries(q);
  if (!cs.length && /negara ini|negara terpilih|this country|selected country/.test(low)) { const s = selectedCountry(); if (s) cs = [s]; }
  if (!cs.length && /pindah|perpindahan|migrasi|bergerak|berubah|moved|move|migration|change|since 2015|sejak 2015/.test(low)) {
    return u.moves(data.migration.filter((m) => m.kode_2015 !== m.kode_2023 && m.n > 0));
  }
  if (cs.length === 1) return u.country(cs[0], regime(cs[0].kode_2023), n, pwByIso.get(cs[0].iso3), cName);
  if (cs.length > 1) return u.compare(cs.slice(0, 6), n, cName);
  if (/kmeans|k-means|gmm|\bpam\b|ward|metode|method|algoritma|algorithm|jaccard|silhouette|k\s*=\s*2/.test(low)) {
    const km4 = data.eval_grid.find((m) => m.metode === "KMeans" && m.k === 4);
    const gmm4 = data.eval_grid.find((m) => m.metode === "GMM" && m.k === 4);
    return u.methods(km4, gmm4, data.meta, n);
  }
  if (/jalur|pathway|\bp1\b|\bp2\b|fanny/.test(low) && data.pathways?.profiles?.length >= 2) {
    const p1 = data.pathways.profiles.find((p) => p.pathway === "P1");
    const p2 = data.pathways.profiles.find((p) => p.pathway === "P2");
    if (p1 && p2) return u.pathways(p1, p2, data.pathways, n);
  }
  if (/prediksi|ramal|forecast|predict|elastic net|persistensi|persistence|\bmae\b/.test(low) && data.cooking_forecast?.metrics) {
    const ms = data.cooking_forecast.metrics;
    const pers = ms.find((m) => m.model === "persistence");
    const ols = ms.find((m) => m.model === "ols_cook2015");
    const enet = ms.find((m) => m.model === "elastic_net");
    if (pers && ols && enet) return u.forecast(pers, ols, enet, n);
  }
  if (/outlier|pencilan|mahalanobis/.test(low) && data.outliers?.length) {
    return u.outliers(data.outliers, n, cName);
  }
  const code = q.toUpperCase().match(/\bR([1-4])\b/);
  if (code) return u.regime(regime("R" + code[1]), n);
  if (/rezim|regime|kelompok|group|cluster|klaster/.test(low)) return u.regimes(data.regimes);
  return u.help;
}

function addMsg(role, text, extraClass = "") {
  const m = el("div", { class: ("bp-msg " + role + " " + extraClass).trim() });
  const who = el("b"); who.textContent = role === "user" ? t().you : t().bot;
  const body = el("span"); body.textContent = text;
  m.append(who, body); log.append(m);
  m.scrollIntoView({ block: "nearest" });
  return { box: m, body };
}

function contextFor(q, sel) {
  const low = q.toLowerCase();
  const needsAll = /\basean\b/.test(low) || LOW.test(low) || HIGH.test(low);
  if (!needsAll) {
    const cs = findCountries(q);
    if (cs.length >= 1 && cs.length <= 6) {
      const isos = new Set(cs.map((c) => c.iso3));
      if (sel) isos.add(sel.iso3);
      return summaryContext + "\n" + [...isos].map((id) => rowByIso.get(id)).filter(Boolean).join("\n");
    }
  }
  return cachedContext;
}

async function askRemote(endpoint, q) {
  const sel = selectedCountry();
  const cacheKey = `${lang()}|${sel ? sel.iso3 : ""}|${norm(q)}`;
  if (replyCache.has(cacheKey)) return replyCache.get(cacheKey);
  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      question: q,
      lang: lang(),
      context: contextFor(q, sel),
      selected: sel ? `${cName(sel)} (${sel.iso3})` : "",
      history: history.slice(-4)
    }),
    signal: AbortSignal.timeout(15000)
  });
  if (!res.ok) throw new Error("HTTP " + res.status);
  const out = await res.json();
  if (!out || typeof out.reply !== "string" || !out.reply.trim()) throw new Error("empty_reply");
  const result = { reply: out.reply.trim(), provider: out.provider === "groq" ? "groq" : "gemini" };
  replyCache.set(cacheKey, result);
  return result;
}

async function ask(q) {
  q = q.trim();
  if (!q || status !== "ready" || busy) return;
  input.value = "";
  addMsg("user", q);
  const endpoint = apiEndpoint();

  if (!endpoint) {
    const reply = answerLocal(q);
    addMsg("bot", reply);
    history.push({ role: "user", text: q }, { role: "assistant", text: reply });
    lastMode = "local";
    updateFoot();
    input.focus();
    return;
  }

  busy = true;
  renderState();
  const pending = addMsg("bot", t().thinking, "is-thinking");
  let reply = "";
  try {
    const res = await askRemote(endpoint, q);
    reply = res.reply;
    lastMode = "ai";
    lastProvider = res.provider;
  } catch (_) {
    reply = answerLocal(q);
    lastMode = "fallback";
  }
  pending.box.classList.remove("is-thinking");
  pending.body.textContent = reply;
  pending.box.scrollIntoView({ block: "nearest" });
  history.push({ role: "user", text: q }, { role: "assistant", text: reply });
  busy = false;
  renderState();
  input.focus();
}

$(".bp-form").addEventListener("submit", (e) => { e.preventDefault(); ask(input.value); });

applyText();
