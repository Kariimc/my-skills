/**
 * Council — a provider-agnostic Mixture-of-Agents decision engine (TypeScript).
 *
 * Pipeline: triage -> propose -> debate -> synthesize -> verify -> refine.
 * Zero dependencies — the built-in callers use global `fetch` (Node 18+, Bun, Deno).
 *
 * Library:
 *   import { council, anthropicCall } from "./council";
 *   const rec = await council("Should we adopt microservices?", { depth: "deep", call: anthropicCall() });
 *   console.log(rec.decision);
 *
 * Mixed-tier models (the big quality lever):
 *   const call = anthropicCall({ models: {
 *     triage: "claude-haiku-4-5-20251001", proposer: "claude-sonnet-5",
 *     aggregator: "claude-opus-4-8", verifier: "claude-opus-4-8",
 *   }});
 *
 * CLI:  npx tsx council.ts "your question" --depth deep
 */

export type Role = "triage" | "proposer" | "aggregator" | "verifier";
export type CallFn = (
  role: Role, system: string, user: string,
  opts?: { wantJson?: boolean; grounded?: boolean }
) => Promise<string>;
export type Depth = "quick" | "deep" | "max";

interface Advisor { id: string; name: string; lens: string; prompt: string; r1?: string; rebuttal?: string; }

export const ROSTER: Record<string, { name: string; lens: string; prompt: string }> = {
  pragmatist: { name: "The Pragmatist", lens: "what works",
    prompt: "what actually works in the real world — feasibility, cost, simplicity, time, and shipping something that survives contact with reality. You distrust elegance that doesn't pay rent." },
  skeptic: { name: "The Skeptic", lens: "risk & failure",
    prompt: "risk and failure — the hidden assumptions, the ways this goes wrong, the costs nobody priced in, the second-order damage. You are the red team; surface what everyone else is too optimistic to see." },
  analyst: { name: "The Analyst", lens: "rigor & tradeoffs",
    prompt: "rigor — first principles, explicit tradeoffs, and evidence. You decompose the problem, weigh options against each other, and quantify wherever quantifying is honest." },
  visionary: { name: "The Visionary", lens: "ambition & horizon",
    prompt: "ambition and the long horizon — the boldest version that's still defensible, the non-obvious angle, what this could become if it works. You refuse to think small." },
  humanist: { name: "The Humanist", lens: "people & ethics",
    prompt: "people and ethics — the human stakes, who is affected, the second-order effects on real people, fairness, and lived experience. You keep the decision honest about its impact on humans." },
  engineer: { name: "The Engineer", lens: "build & correctness",
    prompt: "technical correctness and implementation — how this is actually built, the edge cases, the failure surfaces, the systems realities, and what breaks under load. You think in mechanisms, not slogans." },
  strategist: { name: "The Strategist", lens: "incentives & game",
    prompt: "incentives and strategy — competition, game theory, leverage, positioning, and how other actors will respond. You think several moves ahead about who benefits and who pushes back." },
};
const DEFAULT_COUNCIL = ["pragmatist", "skeptic", "analyst", "visionary"];
const DEPTHS: Record<Depth, { triage: boolean; rebuttal: boolean; verify: boolean }> = {
  quick: { triage: false, rebuttal: false, verify: false },
  deep:  { triage: true,  rebuttal: true,  verify: true },
  max:   { triage: true,  rebuttal: true,  verify: true },
};

const TRIAGE_SYSTEM = `You are the Convener of a council of advisors. Given a question, prepare the deliberation. Return ONLY a JSON object, no fences or extra text:
{"type":"<one of: technical, strategic, factual, creative, interpersonal, ethical, analytical, other>","grounding_useful":<true if a correct answer depends on current facts, data, prices, events, named real-world entities, or anything that should be checked against sources; else false>,"council":["<4 advisor ids>"],"reasoning":"<one short sentence>"}
Choose the council as the 4 most useful advisors for THIS question from exactly: pragmatist, skeptic, analyst, visionary, humanist, engineer, strategist. ALWAYS include "skeptic". Pick the other three for fit (e.g. engineer for technical builds, humanist for interpersonal/ethical, strategist for business/competition, visionary for open-ended).`;

const ARBITER_SYSTEM = `You are the Arbiter. Several advisors have each answered the user's question through a distinct lens, then revised after debate. Produce the final decision.

First, think carefully (in the "reasoning" field) about: where the advisors agree — treat that as high-confidence; where they conflict — decide which side is right and why; what every one of them missed; and the implicit requirements or constraints in the question itself.

Then write the final answer. It must be strictly better than any single advisor's: decisive, complete, and shaped to fit the question — if it is a decision, lead with the call; if it is an open question, lead with the best synthesized answer. Where it matters, name the strongest counter-consideration, state your confidence honestly, and say what would change the answer. Do not hedge everything; commit, then caveat once. Use clean markdown.

Score each advisor 0-10 for how much their contribution actually advanced a good decision, with one sentence naming its strongest contribution and its main blind spot.

Return ONLY a JSON object, no fences or extra text:
{"reasoning":"<your private analysis>","evaluations":[{"agent":"<name>","score":<int>,"critique":"<one sentence>"}],"consensus":"<strong | mixed | divided>","synthesis":"<the final decision, in markdown>"}`;

const VERIFY_SYSTEM = `You are the Adversary — an independent verifier with no loyalty to the Arbiter. You are given a question and the Arbiter's proposed decision. Attack it honestly.

Check: (1) does it actually and fully answer the question asked; (2) factual accuracy — if any claim is checkable and you can verify it, do; (3) logical consistency and hidden holes; (4) missed constraints, requirements, or materially better options; (5) overconfidence or unsupported claims. List ONLY material problems — ones that would change or meaningfully weaken the decision. Be specific and fair; if the decision is sound, say so.

Return ONLY a JSON object, no fences or extra text:
{"verdict":"<pass | revise>","issues":[{"severity":"<high | medium>","issue":"<specific problem>"}],"notes":"<short; any corrected facts or the single most important fix>"}
If sound, return verdict "pass" with an empty issues array.`;

const REFINE_SYSTEM = `You are the Arbiter. An independent verifier found material issues with your decision. Revise the decision to fix every issue while preserving its strengths and decisiveness. Do not get defensive — incorporate the corrections.
Return ONLY a JSON object, no fences or extra text:
{"synthesis":"<the revised decision, in markdown>","changes":"<one line on what you changed>"}`;

const r1System = (a: Advisor) =>
  `You are ${a.name}, one of four advisors on a council convened to reason through a hard question. ` +
  `You think exclusively through one lens: ${a.prompt} ` +
  `Give your own best answer, reasoned through your lens and fully committed to — do not hedge, do not defer to other advisors, do not try to be balanced or cover every angle. Owning your perspective is the point; the council's other voices cover the rest. Lead with your verdict, then your sharpest reasons. A few tight paragraphs or crisp bullets. No preamble, no restating the question.`;

const rebuttalSystem = (a: Advisor) =>
  `You are ${a.name}. You think through one lens: ${a.prompt} ` +
  `You gave an initial answer; now you have read the other advisors' answers. Revise YOUR answer: keep what holds up, concede anything they got right that you missed, sharpen the places you disagree and say plainly why they are wrong, and strengthen your single strongest point. Stay firmly in your lens — do not drift into bland consensus. Output only your revised answer, tightly.`;

function parseJson(raw: string): any {
  let t = raw.trim();
  if (t.startsWith("```")) t = t.replace(/^```(?:json)?/i, "").replace(/```$/, "").trim();
  const a = t.indexOf("{"), b = t.lastIndexOf("}");
  if (a !== -1 && b !== -1) t = t.slice(a, b + 1);
  return JSON.parse(t);
}
function joinAnswers(advisors: Advisor[], which: "r1" | "rebuttal"): string {
  return advisors.map(a => {
    const ans = which === "rebuttal" ? (a.rebuttal || a.r1) : a.r1;
    return `--- ${a.name} (${a.lens}) ---\n${ans}`;
  }).join("\n\n");
}
type Emit = (stage: string, status: string, data?: any) => void;

export interface CouncilOptions {
  call: CallFn;
  depth?: Depth;
  grounded?: boolean;
  councilIds?: string[];
  onEvent?: Emit;
}

export async function council(question: string, opts: CouncilOptions): Promise<any> {
  const depth = opts.depth || "deep";
  if (!DEPTHS[depth]) throw new Error(`depth must be one of ${Object.keys(DEPTHS).join(", ")}`);
  const cfg = DEPTHS[depth];
  const emit: Emit = opts.onEvent || (() => {});
  const call = opts.call;
  let grounded = opts.grounded;
  let councilIds = opts.councilIds;

  const rec: any = { question, depth, advisors: [], triage: null, decision: null,
    evaluations: [], consensus: null, arbiterReasoning: null, verification: null,
    refined: false, refineChanges: null };

  // Triage
  if (cfg.triage) {
    emit("triage", "start");
    try {
      const tj = parseJson(await call("triage", TRIAGE_SYSTEM, question, { wantJson: true }));
      let ids: string[] = (tj.council || []).filter((i: string) => ROSTER[i]);
      if (!ids.includes("skeptic")) ids.unshift("skeptic");
      ids = [...new Set(ids)].slice(0, 4);
      for (const d of DEFAULT_COUNCIL) { if (ids.length >= 4) break; if (!ids.includes(d)) ids.push(d); }
      councilIds = ids;
      if (grounded === undefined && depth === "deep") grounded = !!tj.grounding_useful;
      rec.triage = tj;
      emit("triage", "done", tj);
    } catch (e: any) { emit("triage", "skip", String(e?.message || e)); }
  }

  if (!councilIds) councilIds = [...DEFAULT_COUNCIL];
  if (grounded === undefined) grounded = depth === "max";
  rec.grounded = grounded;
  rec.council = councilIds;
  const advisors: Advisor[] = councilIds.map(id => ({ id, ...ROSTER[id] }));
  rec.advisors = advisors;

  // Round 1
  emit("round1", "start");
  await Promise.all(advisors.map(async a => {
    try { a.r1 = await call("proposer", r1System(a), question, { grounded }); }
    catch (e: any) { emit("advisor", "error", `${a.name}: ${e?.message || e}`); }
  }));
  const alive = advisors.filter(a => a.r1);
  if (!alive.length) throw new Error("The entire council failed to respond.");
  emit("round1", "done", { alive: alive.length });

  // Rebuttal
  if (cfg.rebuttal && alive.length > 1) {
    emit("rebuttal", "start");
    await Promise.all(alive.map(async a => {
      const others = alive.filter(x => x !== a);
      const ctx = `QUESTION:\n${question}\n\nThe other advisors said:\n\n${joinAnswers(others, "r1")}\n\nNow give your revised answer.`;
      try { a.rebuttal = await call("proposer", rebuttalSystem(a), ctx); }
      catch { a.rebuttal = a.r1; }
    }));
    emit("rebuttal", "done");
  }
  const which: "r1" | "rebuttal" = cfg.rebuttal ? "rebuttal" : "r1";

  // Synthesis
  emit("synthesis", "start");
  const synthIn = `QUESTION:\n${question}\n\nADVISOR ANSWERS:\n\n${joinAnswers(alive, which)}\n\nProduce the final decision as the specified JSON.`;
  const sraw = await call("aggregator", ARBITER_SYSTEM, synthIn, { wantJson: true });
  let synth: any;
  try { synth = parseJson(sraw); } catch { synth = { synthesis: sraw, evaluations: [], consensus: null, reasoning: null }; }
  rec.decision = synth.synthesis ?? sraw;
  rec.evaluations = synth.evaluations || [];
  rec.consensus = synth.consensus ?? null;
  rec.arbiterReasoning = synth.reasoning ?? null;
  emit("synthesis", "done", { consensus: rec.consensus });

  // Verify + bounded refine
  if (cfg.verify) {
    emit("verify", "start");
    try {
      const v = parseJson(await call("verifier", VERIFY_SYSTEM,
        `QUESTION:\n${question}\n\nPROPOSED DECISION:\n${rec.decision}\n\nVerify it.`,
        { wantJson: true, grounded }));
      rec.verification = v;
      const issues = (v.issues || []).filter((i: any) => i && i.issue);
      if (v.verdict === "revise" && issues.length) {
        emit("verify", "issues", { count: issues.length });
        emit("refine", "start");
        let issuetext = issues.map((i: any) => `- [${i.severity}] ${i.issue}`).join("\n");
        if (v.notes) issuetext += `\nVerifier note: ${v.notes}`;
        const rraw = await call("aggregator", REFINE_SYSTEM,
          `QUESTION:\n${question}\n\nYOUR DECISION:\n${rec.decision}\n\nVERIFIER FOUND:\n${issuetext}\n\nReturn the revised decision.`,
          { wantJson: true });
        try {
          const rj = parseJson(rraw);
          if (rj.synthesis) { rec.decision = rj.synthesis; rec.refined = true; rec.refineChanges = rj.changes || "Revised to address verifier issues."; }
        } catch { /* keep unrefined */ }
        emit("refine", "done");
      } else { emit("verify", "pass"); }
    } catch (e: any) { emit("verify", "skip", String(e?.message || e)); }
  }

  emit("final", "done");
  return rec;
}

export function toMarkdown(rec: any): string {
  const L: string[] = ["# The Council — Deliberation Record", "",
    `**Question:** ${rec.question}`, "",
    `**Depth:** ${rec.depth} · **Grounded:** ${rec.grounded ? "yes" : "no"} · **Consensus:** ${rec.consensus || "—"} · **Verification:** ${(rec.verification?.verdict) || "—"}${rec.refined ? " (refined)" : ""}`,
    "", "---", "", "## The Decision", "", rec.decision || "", ""];
  if (rec.verification) {
    L.push("", "## Verification", "", `Verdict: **${rec.verification.verdict}**`);
    (rec.verification.issues || []).forEach((i: any) => L.push(`- [${i.severity}] ${i.issue}`));
    if (rec.verification.notes) L.push(`\nNotes: ${rec.verification.notes}`);
    if (rec.refineChanges) L.push(`\nRefinement: ${rec.refineChanges}`);
  }
  if (rec.evaluations?.length) {
    L.push("", "## Council Scores", "");
    rec.evaluations.forEach((e: any) => L.push(`- **${e.agent}** — ${e.score}/10 — ${e.critique || ""}`));
  }
  L.push("", "## Full Deliberation", "");
  if (rec.triage) L.push("", "### Triage", `- Type: ${rec.triage.type}`, `- Grounding: ${rec.grounded ? "on" : "off"}`, `- Council: ${(rec.council || []).join(", ")}`, `- ${rec.triage.reasoning || ""}`);
  for (const a of rec.advisors || []) {
    if (!a.r1) continue;
    L.push("", `### ${a.name} — ${a.lens}`, "", "**Round 1:**", "", a.r1);
    if (a.rebuttal && a.rebuttal !== a.r1) L.push("", "**Rebuttal:**", "", a.rebuttal);
  }
  if (rec.arbiterReasoning) L.push("", "### Arbiter's reasoning", "", rec.arbiterReasoning);
  return L.join("\n");
}

/* ----------------------------- Provider callers ----------------------------- */
const A_MODELS = { triage: "claude-haiku-4-5-20251001", proposer: "claude-sonnet-5", aggregator: "claude-opus-4-8", verifier: "claude-opus-4-8" };

export function anthropicCall(cfg: { models?: Partial<Record<Role, string>>; webSearch?: boolean; maxTokens?: number; apiKey?: string } = {}): CallFn {
  const models = { ...A_MODELS, ...(cfg.models || {}) };
  const key = cfg.apiKey || process.env.ANTHROPIC_API_KEY;
  const webSearch = cfg.webSearch !== false;
  const maxTokens = cfg.maxTokens || 2048;
  return async (role, system, user, opts = {}) => {
    const body: any = { model: models[role] || models.proposer, max_tokens: maxTokens, system, messages: [{ role: "user", content: user }] };
    if (opts.grounded && webSearch) body.tools = [{ type: "web_search_20250305", name: "web_search", max_uses: 3 }];
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "content-type": "application/json", "x-api-key": key as string, "anthropic-version": "2023-06-01" },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`Anthropic HTTP ${res.status}: ${await res.text()}`);
    const data: any = await res.json();
    return (data.content || []).filter((b: any) => b.type === "text").map((b: any) => b.text).join("").trim();
  };
}

export function openaiCall(cfg: { models?: Partial<Record<Role, string>>; apiKey?: string; baseUrl?: string; defaultModel?: string } = {}): CallFn {
  const dm = cfg.defaultModel || "gpt-4o-mini";
  const base = (cfg.baseUrl || "https://api.openai.com/v1").replace(/\/+$/, "");
  const models = { triage: dm, proposer: dm, aggregator: dm, verifier: dm, ...(cfg.models || {}) } as Record<Role, string>;
  const key = cfg.apiKey || process.env.OPENAI_API_KEY;
  let warned = false;
  return async (role, system, user, opts = {}) => {
    if (opts.grounded && !warned) { console.error("[council] web grounding unsupported by this caller; continuing ungrounded."); warned = true; }
    const messages = [{ role: "system", content: system }, { role: "user", content: user }];
    const post = async (useJson: boolean) => {
      const body: any = { model: models[role] || models.proposer, messages };
      if (useJson) body.response_format = { type: "json_object" };
      const res = await fetch(`${base}/chat/completions`, {
        method: "POST",
        headers: { "content-type": "application/json", authorization: `Bearer ${key}` },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
      const data: any = await res.json();
      return (data.choices?.[0]?.message?.content || "").trim();
    };
    try { return await post(!!opts.wantJson); }
    catch (e) { if (opts.wantJson) return await post(false); throw e; }   // provider may reject response_format
  };
}

// Free / no-cost presets (all OpenAI-compatible)
export const ollamaCall = (model = "llama3.1", baseUrl = "http://localhost:11434/v1"): CallFn =>
  openaiCall({ baseUrl, apiKey: "ollama", models: { triage: model, proposer: model, aggregator: model, verifier: model } });

export const groqCall = (models?: Partial<Record<Role, string>>): CallFn =>
  openaiCall({ baseUrl: "https://api.groq.com/openai/v1", apiKey: process.env.GROQ_API_KEY,
    models: models || { triage: "llama-3.3-70b-versatile", proposer: "llama-3.3-70b-versatile", aggregator: "llama-3.3-70b-versatile", verifier: "llama-3.3-70b-versatile" } });

export const openrouterCall = (models?: Partial<Record<Role, string>>): CallFn =>
  openaiCall({ baseUrl: "https://openrouter.ai/api/v1", apiKey: process.env.OPENROUTER_API_KEY,
    models: models || { triage: "meta-llama/llama-3.3-70b-instruct:free", proposer: "meta-llama/llama-3.3-70b-instruct:free", aggregator: "deepseek/deepseek-r1:free", verifier: "meta-llama/llama-3.3-70b-instruct:free" } });

export const geminiCall = (models?: Partial<Record<Role, string>>): CallFn =>
  openaiCall({ baseUrl: "https://generativelanguage.googleapis.com/v1beta/openai/", apiKey: process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY,
    models: models || { triage: "gemini-2.5-flash", proposer: "gemini-2.5-flash", aggregator: "gemini-2.5-flash", verifier: "gemini-2.5-flash" } });

/* --------------------------------- CLI ------------------------------------- */
async function cli() {
  const argv = process.argv.slice(2);
  const flag = (n: string) => argv.includes(n);
  const val = (n: string, d?: string) => { const i = argv.indexOf(n); return i !== -1 ? argv[i + 1] : d; };
  const q = argv.filter(a => !a.startsWith("--"))[0];
  if (!q) { console.error('Usage: npx tsx council.ts "your question" --depth deep'); process.exit(1); }
  const depth = (val("--depth", "deep") as Depth);
  const grounded = flag("--grounded") ? true : flag("--no-grounded") ? false : undefined;
  const prov = val("--provider", "auto");
  const model = val("--model");
  const mk = (m?: string) => (m ? { triage: m, proposer: m, aggregator: m, verifier: m } as any : undefined);
  let call: CallFn | null = null;
  if (prov === "ollama") call = ollamaCall(model || "llama3.1");
  else if (prov === "groq") call = groqCall(mk(model));
  else if (prov === "openrouter") call = openrouterCall(mk(model));
  else if (prov === "gemini") call = geminiCall(mk(model));
  else if (prov === "openai") call = openaiCall({ models: mk(model) });
  else if (prov === "anthropic") call = anthropicCall({ models: mk(model) });
  else call = process.env.ANTHROPIC_API_KEY ? anthropicCall()
    : process.env.OPENAI_API_KEY ? openaiCall()
    : process.env.GROQ_API_KEY ? groqCall()
    : process.env.OPENROUTER_API_KEY ? openrouterCall()
    : (process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY) ? geminiCall()
    : null;
  if (!call) { console.error("[council] No provider key. Set ANTHROPIC/OPENAI/GROQ/OPENROUTER/GEMINI_API_KEY (free keys work), or use --provider ollama (no key)."); process.exit(1); }
  const rec = await council(q, { call, depth, grounded, onEvent: (s, st, d) => console.error(`  · ${s}: ${st}${d ? " " + JSON.stringify(d) : ""}`) });
  if (flag("--json")) { console.log(JSON.stringify(rec, null, 2)); return; }
  const save = val("--save");
  if (save) { const fs = await import("fs"); fs.writeFileSync(save, toMarkdown(rec)); console.error(`[council] record written to ${save}`); }
  console.log(rec.decision);
}

// Run as CLI only when invoked directly (not when imported).
const _isMain = typeof process !== "undefined" && process.argv?.[1] && /council\.(ts|js|mjs)$/.test(process.argv[1]);
if (_isMain) cli().catch(e => { console.error(e); process.exit(1); });
