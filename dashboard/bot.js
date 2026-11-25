/*
  "Tanya data": a rule-based assistant that answers from dashboard_data.json. No language model,
  no download and no server: it recognises a few kinds of question (one country, a comparison,
  ASEAN, a regime, the highest or lowest countries on an indicator, regime changes since 2015,
  the biomass paradox itself) and fills a sentence template with the exact figures.
  Used by both the landing page and the dashboard; the data path is resolved from this file's
  URL, so it works at / and at /dashboard/.
*/
const DATA_URL = new URL("./data/dashboard_data.json", import.meta.url);

const UI = {
  id: {
    launch: "Tanya data", title: "Tanya data Biomass Paradox", close: "Tutup",
    intro: "Tanyakan rezim sebuah negara, bandingkan dua negara, atau cari negara dengan nilai tertinggi dan terendah. Jawaban diambil langsung dari data atlas ini.",
    label: "Pertanyaan Anda", placeholder: "Contoh: rezim Indonesia apa?", send: "Kirim",
    you: "Anda", bot: "Data", loading: "Memuat data...",
    error: "Data gagal dimuat. Muat ulang halaman, lalu coba lagi.",
    suggestions: ["Indonesia masuk rezim apa?", "Bandingkan Indonesia dan Viet Nam", "Negara ASEAN", "Negara dengan memasak bersih terendah", "Apa itu paradoks biomassa?"],
    foot: "Jawaban disusun dari dashboard_data.json dengan aturan sederhana, bukan model AI.",
    help: "Saya belum menangkap pertanyaannya. Coba sebut nama negara (misalnya Indonesia atau Jerman), dua negara untuk dibandingkan, ASEAN, R1 sampai R4, atau \"memasak bersih terendah\".",
    nf: (v, d = 1) => Number(v).toLocaleString("id-ID", { minimumFractionDigits: d, maximumFractionDigits: d }),
    country: (c, r, n) => `${c.country_en} (${c.iso3}) masuk ${r.kode_rezim}, ${r.nama_id}${c.kode_2015 !== c.kode_2023 ? `; pada 2015 masih di ${c.kode_2015}` : ""}. ` +
      `Pada 2023: akses listrik ${n(c.elec_2023)}%, memasak bersih ${n(c.cooking_2023, 0)}% (2015: ${n(c.cooking_2015, 0)}%), pangsa energi terbarukan ${n(c.renew_share_2023)}%, ` +
      `kapasitas listrik terbarukan ${n(c.renew_cap_2023)} W per orang, intensitas energi ${n(c.energy_int_2023, 2)} MJ per USD PPP, dan CO2 ${n(c.co2_pc_2023, 2)} ton per orang.`,
    compare: (cs, n) => "Perbandingan 2023:\n" + cs.map((c) => `${c.country_en}: ${c.kode_2023}, listrik ${n(c.elec_2023)}%, memasak bersih ${n(c.cooking_2023, 0)}%, terbarukan ${n(c.renew_share_2023)}%, kapasitas ${n(c.renew_cap_2023)} W per orang, CO2 ${n(c.co2_pc_2023, 2)} t per orang`).join("\n"),
    asean: (cs, n) => "Negara ASEAN, 2023 (rezim, memasak bersih, kapasitas listrik terbarukan per orang):\n" + cs.map((c) => `${c.country_en}: ${c.kode_2023}, ${n(c.cooking_2023, 0)}%, ${n(c.renew_cap_2023)} W`).join("\n"),
    regime: (r, n) => `${r.kode_rezim}, ${r.nama_id}: ${r.n_negara} negara dengan ${n(r.populasi_miliar, 2)} miliar penduduk. Rata-rata akses listrik ${n(r.elec_mean)}%, memasak bersih ${n(r.cooking_mean)}%, pangsa terbarukan ${n(r.renew_share_mean)}%; median kapasitas listrik terbarukan ${n(r.renew_cap_median)} W per orang dan median CO2 ${n(r.co2_pc_median, 2)} ton per orang.`,
    regimes: (rs) => "Empat rezim 2023: " + rs.map((r) => `${r.kode_rezim} ${r.nama_id} (${r.n_negara} negara)`).join("; ") + ". Sebut R1 sampai R4 untuk rinciannya.",
    extreme: (lbl, hi, cs, n, d) => `${hi ? "Tertinggi" : "Terendah"} untuk ${lbl} (2023): ` + cs.map((c, i) => `${i + 1}. ${c.country_en} ${n(c.v, d)}`).join(", ") + ".",
    labels: { cooking_2023: "memasak bersih (%)", elec_2023: "akses listrik (%)", renew_share_2023: "pangsa energi terbarukan (%)", renew_cap_2023: "kapasitas listrik terbarukan (W per orang)", energy_int_2023: "intensitas energi (MJ per USD PPP)", co2_pc_2023: "CO2 per orang (ton)" },
    moves: (list) => "Perpindahan rezim 2015 ke 2023: " + list.map((m) => `${m.kode_2015} ke ${m.kode_2023}: ${m.n} negara`).join("; ") + ". Negara lain tetap di rezimnya. Ini perbandingan dua titik waktu, bukan dampak kebijakan.",
    paradox: (k, rs, n) => `Pangsa energi terbarukan (SDG 7.2.1) ikut menghitung kayu bakar dan arang di tungku rumah. Akibatnya, pada 2023 ada ${k} negara dengan pangsa terbarukan di atas 50% tetapi memasak bersih di bawah 20%. Di rezim R1 rata-rata pangsa terbarukannya ${n(rs.renew_share_mean)}%, sementara memasak bersih hanya ${n(rs.cooking_mean)}%.`
  },
  en: {
    launch: "Ask the data", title: "Ask the Biomass Paradox data", close: "Close",
    intro: "Ask for a country's regime, compare two countries, or find the highest and lowest countries on an indicator. Answers come straight from this atlas's data.",
    label: "Your question", placeholder: "Example: Indonesia's regime?", send: "Send",
    you: "You", bot: "Data", loading: "Loading the data...",
    error: "The data failed to load. Reload the page and try again.",
    suggestions: ["Which regime is Indonesia in?", "Compare Indonesia and Viet Nam", "ASEAN countries", "Countries with the lowest clean cooking", "What is the biomass paradox?"],
    foot: "Answers are built from dashboard_data.json with simple rules, not an AI model.",
    help: "I did not catch the question. Try a country name (for example Indonesia or Germany), two countries to compare, ASEAN, R1 to R4, or \"lowest clean cooking\".",
    nf: (v, d = 1) => Number(v).toLocaleString("en-US", { minimumFractionDigits: d, maximumFractionDigits: d }),
    country: (c, r, n) => `${c.country_en} (${c.iso3}) is in ${r.kode_rezim}, ${r.nama_en}${c.kode_2015 !== c.kode_2023 ? `; in 2015 it was in ${c.kode_2015}` : ""}. ` +
      `In 2023: electricity access ${n(c.elec_2023)}%, clean cooking ${n(c.cooking_2023, 0)}% (2015: ${n(c.cooking_2015, 0)}%), renewable share ${n(c.renew_share_2023)}%, ` +
      `renewable power capacity ${n(c.renew_cap_2023)} W per person, energy intensity ${n(c.energy_int_2023, 2)} MJ per PPP USD, and CO2 ${n(c.co2_pc_2023, 2)} t per person.`,
    compare: (cs, n) => "Comparison, 2023:\n" + cs.map((c) => `${c.country_en}: ${c.kode_2023}, electricity ${n(c.elec_2023)}%, clean cooking ${n(c.cooking_2023, 0)}%, renewable ${n(c.renew_share_2023)}%, capacity ${n(c.renew_cap_2023)} W per person, CO2 ${n(c.co2_pc_2023, 2)} t per person`).join("\n"),
    asean: (cs, n) => "ASEAN countries, 2023 (regime, clean cooking, renewable power capacity per person):\n" + cs.map((c) => `${c.country_en}: ${c.kode_2023}, ${n(c.cooking_2023, 0)}%, ${n(c.renew_cap_2023)} W`).join("\n"),
    regime: (r, n) => `${r.kode_rezim}, ${r.nama_en}: ${r.n_negara} countries with ${n(r.populasi_miliar, 2)} billion people. Mean electricity access ${n(r.elec_mean)}%, clean cooking ${n(r.cooking_mean)}%, renewable share ${n(r.renew_share_mean)}%; median renewable capacity ${n(r.renew_cap_median)} W per person and median CO2 ${n(r.co2_pc_median, 2)} t per person.`,
    regimes: (rs) => "The four 2023 regimes: " + rs.map((r) => `${r.kode_rezim} ${r.nama_en} (${r.n_negara} countries)`).join("; ") + ". Name R1 to R4 for details.",
    extreme: (lbl, hi, cs, n, d) => `${hi ? "Highest" : "Lowest"} ${lbl} (2023): ` + cs.map((c, i) => `${i + 1}. ${c.country_en} ${n(c.v, d)}`).join(", ") + ".",
    labels: { cooking_2023: "clean cooking (%)", elec_2023: "electricity access (%)", renew_share_2023: "renewable share (%)", renew_cap_2023: "renewable power capacity (W per person)", energy_int_2023: "energy intensity (MJ per PPP USD)", co2_pc_2023: "CO2 per person (t)" },
    moves: (list) => "Regime changes from 2015 to 2023: " + list.map((m) => `${m.kode_2015} to ${m.kode_2023}: ${m.n} countries`).join("; ") + ". All other countries stayed in their regime. This compares two points in time, not a policy effect.",
    paradox: (k, rs, n) => `The renewable share (SDG 7.2.1) counts firewood and charcoal burned in home stoves. So in 2023, ${k} countries had a renewable share above 50% but clean cooking below 20%. In regime R1 the mean renewable share is ${n(rs.renew_share_mean)}%, while clean cooking is only ${n(rs.cooking_mean)}%.`
  }
};

// Indonesian names that differ from the English ones in the data.
const ALIASES = {
  vietnam: "VNM", filipina: "PHL", singapura: "SGP", kamboja: "KHM", laos: "LAO", "timor leste": "TLS", brunei: "BRN",
  tiongkok: "CHN", cina: "CHN", china: "CHN", "amerika serikat": "USA", amerika: "USA", usa: "USA", jepang: "JPN", jerman: "DEU",
  norwegia: "NOR", islandia: "ISL", rusia: "RUS", "arab saudi": "SAU", brasil: "BRA", inggris: "GBR", uk: "GBR", prancis: "FRA",
  perancis: "FRA", "korea selatan": "KOR", "korea utara": "PRK", "afrika selatan": "ZAF", mesir: "EGY", belanda: "NLD", swedia: "SWE",
  italia: "ITA", spanyol: "ESP", turki: "TUR", swiss: "CHE", belgia: "BEL", "selandia baru": "NZL",
  drc: "COD", kongo: "COD"
};
// ISO3 codes that collide with common English or Indonesian words require uppercase.
const ISO3_UPPER_ONLY = new Set(["AGO", "ARE", "ARM", "BEN", "CAN", "COD", "CUB", "FIN", "GIN", "GUY", "JAM", "KEN", "MAR", "NOR", "PAN", "PER", "SEN", "SUR", "TON"]);
// Indicator words, checked in this order (capacity before the general "renewable" words).
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
const stateBox = $(".bp-state"), log = $(".bp-log"), chips = $(".bp-chips"), input = $("#bp-q"), sendBtn = $("[data-send]");
let data = null, status = "idle";

function renderState() {
  stateBox.hidden = status === "ready";
  stateBox.textContent = status === "error" ? t().error : t().loading;
  input.disabled = sendBtn.disabled = status !== "ready";
  chips.hidden = status !== "ready";
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
  $(".bp-foot").textContent = u.foot;
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

async function loadData() {
  if (data) return;
  try {
    const r = await fetch(DATA_URL);
    if (!r.ok) throw new Error("HTTP " + r.status);
    data = await r.json();
  } catch (err) {
    data = window.__SDG_DASHBOARD_DATA__ || null;
  }
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

/* ---- answering ---- */
function findCountries(q) {
  const low = " " + q.toLowerCase().replace(/[^\p{L}\p{N} ]/gu, " ").replace(/\s+/g, " ") + " ";
  const hits = [];
  const add = (iso, pos) => { if (pos >= 0 && !hits.some((h) => h.iso === iso)) hits.push({ iso, pos }); };
  for (const [name, iso] of Object.entries(ALIASES)) add(iso, low.indexOf(" " + name + " "));
  for (const c of data.countries) {
    add(c.iso3, low.indexOf(" " + c.country_en.toLowerCase().replace(/[^\p{L}\p{N} ]/gu, " ").replace(/\s+/g, " ") + " "));
    const m = q.search(new RegExp(`\\b${c.iso3}\\b`, ISO3_UPPER_ONLY.has(c.iso3) ? "" : "i"));
    if (m >= 0) add(c.iso3, m);
  }
  return hits.sort((a, b) => a.pos - b.pos).map((h) => data.countries.find((c) => c.iso3 === h.iso));
}
function selectedCountry() {
  const sub = document.getElementById("insp-sub");
  const m = sub && sub.textContent.match(/^([A-Z]{3})\b/);
  return m ? data.countries.find((c) => c.iso3 === m[1]) : null;
}
function answer(q) {
  const u = t(), n = u.nf, low = q.toLowerCase();
  const regime = (code) => data.regimes.find((r) => r.kode_rezim === code);
  if (/paradoks|paradox/.test(low)) {
    const k = data.countries.filter((c) => c.renew_share_2023 > 50 && c.cooking_2023 < 20).length;
    return u.paradox(k, regime("R1"), n);
  }
  if (/\basean\b/.test(low)) return u.asean(data.countries.filter((c) => c.is_asean).sort((a, b) => a.country_en.localeCompare(b.country_en)), n);
  const dirLow = LOW.test(low), dirHigh = HIGH.test(low);
  if (dirLow || dirHigh) {
    const ind = INDICATORS.find(([re]) => re.test(low));
    if (ind) {
      const [, key, d] = ind;
      const s = data.countries.map((c) => ({ country_en: c.country_en, v: c[key] })).sort((a, b) => a.v - b.v);
      return u.extreme(u.labels[key], dirHigh && !dirLow, (dirHigh && !dirLow ? s.reverse() : s).slice(0, 5), n, d);
    }
  }
  let cs = findCountries(q);
  if (!cs.length && /negara ini|negara terpilih|this country|selected country/.test(low)) { const s = selectedCountry(); if (s) cs = [s]; }
  if (!cs.length && /pindah|perpindahan|migrasi|bergerak|berubah|moved|move|migration|change|since 2015|sejak 2015/.test(low)) {
    return u.moves(data.migration.filter((m) => m.kode_2015 !== m.kode_2023 && m.n > 0));
  }
  if (cs.length === 1) return u.country(cs[0], regime(cs[0].kode_2023), n);
  if (cs.length > 1) return u.compare(cs.slice(0, 6), n);
  const code = q.toUpperCase().match(/\bR([1-4])\b/);
  if (code) return u.regime(regime("R" + code[1]), n);
  if (/rezim|regime|kelompok|group|cluster|klaster/.test(low)) return u.regimes(data.regimes);
  return u.help;
}
function addMsg(role, text) {
  const m = el("div", { class: "bp-msg " + role });
  const who = el("b"); who.textContent = role === "user" ? t().you : t().bot;
  const body = el("span"); body.textContent = text;
  m.append(who, body); log.append(m);
  m.scrollIntoView({ block: "nearest" });
}
function ask(q) {
  q = q.trim();
  if (!q || status !== "ready") return;
  input.value = "";
  addMsg("user", q);
  addMsg("bot", answer(q));
  input.focus();
}
$(".bp-form").addEventListener("submit", (e) => { e.preventDefault(); ask(input.value); });

applyText();
