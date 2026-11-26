/*
  Cloudflare Worker proxy for the Biomass Paradox data assistant.
  Primary: Google AI Studio (Gemini API via GEMINI_API_KEY secret).
  Failover: Groq (Llama 3.3 70B via GROQ_API_KEY secret).
  Configure at least one secret in Cloudflare Dashboard -> Settings -> Variables and Secrets.
  Never commit API keys to Git.
*/

const DEFAULT_ORIGINS = [
  "https://febrianggi.github.io",
  "http://localhost:8000",
  "http://127.0.0.1:8000"
];

const WINDOW_MS = 10 * 60 * 1000;
const MAX_REQ_PER_WINDOW = 40;
const rateBuckets = new Map();

function allowedOrigins(env) {
  const raw = env.ALLOWED_ORIGINS || "";
  const list = raw.split(",").map((s) => s.trim()).filter(Boolean);
  return list.length ? list : DEFAULT_ORIGINS;
}

function corsHeaders(origin, allowed) {
  const h = {
    "Vary": "Origin",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400"
  };
  if (origin && allowed.includes(origin)) h["Access-Control-Allow-Origin"] = origin;
  return h;
}

function json(data, status, headers) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...headers }
  });
}

function checkRate(ip) {
  const now = Date.now();
  const prev = (rateBuckets.get(ip) || []).filter((t) => now - t < WINDOW_MS);
  if (prev.length >= MAX_REQ_PER_WINDOW) return false;
  prev.push(now);
  rateBuckets.set(ip, prev);
  if (rateBuckets.size > 2000) {
    for (const [k, v] of rateBuckets) {
      if (!v.length || now - v[v.length - 1] >= WINDOW_MS) rateBuckets.delete(k);
    }
  }
  return true;
}

function buildSystemPrompt(lang, context, selectedCountry) {
  const isEn = lang === "en";
  return [
    "You are the data assistant for the Biomass Paradox Dashboard (SDG 7 and SDG 13, 189 sovereign economies, 2015 and 2023).",
    isEn
      ? "Reply in clear, natural English."
      : "Jawab dalam bahasa Indonesia yang natural, ramah, dan jelas (pakai koma untuk desimal bila sesuai).",
    "Rules:",
    "1. Use ONLY the verified dataset and methodological facts in the DATA block below. Never invent numbers, rankings, years, or external facts.",
    "2. Understand ISO 3166-1 Alpha-3 (e.g. IDN, MYS, ESP), Alpha-2 (e.g. ID, MY, ES, GB, CN, CD), Indonesian ISO 3166-1 names (NameID), English names (NameEN), casual abbreviations, and typos (for example Indo = Indonesia, Malay = Malaysia, SG = Singapore, Pinoy = Philippines, Kongo = Kongo, Republik Demokratik). When naming a country, keep its Alpha-3 code in parentheses (e.g. Spanyol (ESP) in ID, Spain (ESP) in EN).",
    "3. Keep answers concise (2 to 5 sentences, or short plain lines for comparisons). Avoid heavy markdown formatting (no **bold** clutter, no em dashes).",
    "4. Respect methodological limits: 2015 vs 2023 regime moves are descriptive positions against 2023 centroids (not causal policy effects); clean cooking prediction is cross-country validation over 2015 to 2023 (not a future forecast); change pathways P1/P2 have weak cluster structure (Silhouette 0.205).",
    "5. If the question asks about a country or topic outside the data, say so honestly in one or two sentences and suggest what the dashboard can answer.",
    selectedCountry ? `Currently selected country on the user's dashboard map: ${selectedCountry}. If they ask about "negara ini" / "this country", use this country.` : "",
    "",
    "DATA:",
    context
  ].filter(Boolean).join("\n");
}

async function callGemini(apiKey, model, systemPrompt, history, question) {
  const contents = [];
  for (const h of history) {
    contents.push({
      role: h.role === "assistant" ? "model" : "user",
      parts: [{ text: h.text }]
    });
  }
  contents.push({ role: "user", parts: [{ text: question }] });

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey
    },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: systemPrompt }] },
      contents,
      generationConfig: {
        maxOutputTokens: 512
      }
    }),
    signal: AbortSignal.timeout(12000)
  });
  if (!res.ok) throw new Error(`${model}:${res.status}`);
  const body = await res.json();
  const text = body?.candidates?.[0]?.content?.parts
    ?.filter((p) => !p.thought)
    .map((p) => p.text || "")
    .join("")
    .trim();
  if (!text) throw new Error(`${model}:empty`);
  return text;
}

async function callGroq(apiKey, model, systemPrompt, history, question) {
  const messages = [{ role: "system", content: systemPrompt }];
  for (const h of history) {
    messages.push({ role: h.role === "assistant" ? "assistant" : "user", content: h.text });
  }
  messages.push({ role: "user", content: question });

  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.2,
      max_tokens: 380
    }),
    signal: AbortSignal.timeout(12000)
  });
  if (!res.ok) throw new Error(`groq_${res.status}`);
  const body = await res.json();
  const text = body?.choices?.[0]?.message?.content?.trim();
  if (!text) throw new Error("groq_empty");
  return text;
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "";
    const allowed = allowedOrigins(env);
    const cors = corsHeaders(origin, allowed);

    if (request.method === "OPTIONS") {
      if (origin && !allowed.includes(origin)) return new Response("Forbidden", { status: 403 });
      return new Response(null, { status: 204, headers: cors });
    }

    if (request.method === "GET") {
      const providers = [];
      if (env.GEMINI_API_KEY) providers.push("gemini");
      if (env.GROQ_API_KEY) providers.push("groq");
      return json({ ok: true, providers }, 200, cors);
    }

    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405, cors);
    }

    if (origin && !allowed.includes(origin)) {
      return json({ error: "origin_not_allowed" }, 403, cors);
    }

    const ip = request.headers.get("CF-Connecting-IP") || "local";
    if (!checkRate(ip)) {
      return json({ error: "rate_limited" }, 429, cors);
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({ error: "invalid_json" }, 400, cors);
    }

    const question = typeof payload?.question === "string" ? payload.question.trim() : "";
    const lang = payload?.lang === "en" ? "en" : "id";
    const context = typeof payload?.context === "string" ? payload.context.trim() : "";
    const selected = typeof payload?.selected === "string" ? payload.selected.trim().slice(0, 80) : "";
    const rawHistory = Array.isArray(payload?.history) ? payload.history : [];
    const history = rawHistory
      .slice(-4)
      .filter((h) => h && (h.role === "user" || h.role === "assistant") && typeof h.text === "string")
      .map((h) => ({ role: h.role, text: h.text.trim().slice(0, 600) }))
      .filter((h) => h.text);

    if (!question || question.length > 500) {
      return json({ error: "invalid_question" }, 400, cors);
    }
    if (!context || context.length > 32000) {
      return json({ error: "invalid_context" }, 400, cors);
    }

    const systemPrompt = buildSystemPrompt(lang, context, selected);
    const geminiModels = [...new Set([
      env.GEMINI_MODEL || "gemini-3.5-flash-lite",
      "gemini-3.5-flash-lite",
      "gemini-flash-latest",
      "gemini-2.5-flash"
    ])];
    const groqModel = env.GROQ_MODEL || "llama-3.3-70b-versatile";
    const errors = [];

    // Tier 1: Gemini API (Gemini 3.5 Flash-Lite primary, with fallbacks)
    if (env.GEMINI_API_KEY) {
      for (const model of geminiModels) {
        try {
          const reply = await callGemini(env.GEMINI_API_KEY, model, systemPrompt, history, question);
          return json({ reply, provider: "gemini", model }, 200, cors);
        } catch (e) {
          errors.push(String(e.message || e));
        }
      }
    }

    // Tier 2: Groq API failover
    if (env.GROQ_API_KEY) {
      try {
        const reply = await callGroq(env.GROQ_API_KEY, groqModel, systemPrompt, history, question);
        return json({ reply, provider: "groq", model: groqModel }, 200, cors);
      } catch (e) {
        errors.push(String(e.message || e));
      }
    }

    return json({ error: "upstream_unavailable", tried: errors.length, codes: errors }, 503, cors);
  }
};
