#!/usr/bin/env python3
"""
build_launcher.py — scan the skills library and emit launcher data + a self-contained
GUI (skill-launcher.html): a searchable, goal-grouped browser for every skill, with
task suggestions and one-click copy-to-run.

  python3 build_launcher.py                 # -> ../skill-launcher.html  (+ skills.json)
  python3 build_launcher.py out.html        # custom output

Data comes from each skills/<name>/SKILL.md frontmatter (name + description) and the
category headings in skills/README.md. No third-party deps.
"""
import sys, os, re, json, html

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
SKILLS_DIR = os.path.join(REPO, "skills")
README = os.path.join(SKILLS_DIR, "README.md")

# Classify each skill into a top-level GOAL the way a user thinks, by scoring
# keywords against its own name + description (the README's big import buckets are
# too coarse to browse). Highest-scoring goal wins; ties break by list order.
GOAL_KEYWORDS = [
    ("Build", ["build", "implement", "feature", "scaffold", "app ", "application",
               "api", "backend", "frontend", "component", "framework", "react",
               "next.js", "nextjs", "node", "database", "sql", "server", "game",
               "mobile", "ios", "android", "ui library", "endpoint", "full-stack",
               "fullstack", "architecture", "develop"]),
    ("Design", ["design", "visual", "typography", "color", "palette", "layout",
                "animation", "motion", "aesthetic", "brand", "prototype", "css",
                "graphic", "canvas", "slides", "poster", "art", "ui/ux", "ux ",
                "figma", "mockup", "wireframe", "landing page", "website"]),
    ("Fix & Debug", ["debug", "fix", "error", "bug", "review", "test", "tdd",
                     "quality", "lint", "refactor", "security", "vulnerab",
                     "performance", "optimize", "audit", "diagnos", "regression"]),
    ("Research", ["research", "analy", "data ", "scrape", "scraping", "vision",
                  "extract", "benchmark", "investigate", "compare", "forensic",
                  "ocr", "multimodal", "market"]),
    ("Write", ["write", "writing", "content", "docs", "document", "copy",
               "article", "blog", "email", "communication", "plain-language",
               "plain language", "notes", "summar", "changelog", "readme"]),
    ("Automate & Loop", ["automation", "automate", "loop", "agent", "harness",
                         "orchestrat", "workflow", "autonomous", "schedule",
                         "cron", "swarm", "council", "pipeline", "mcp", "recurring"]),
    ("Manage repo & config", ["git", "github", "config", "settings", "hook",
                              "permission", "control-plane", "deploy", "release",
                              "ci/cd", "infra", "devops", "sync", "memory",
                              "context", "token", "handoff", "relay", "skill"]),
]


def classify(name, desc):
    text = (name + " " + name + " " + desc).lower()  # name weighted 2x
    best, best_score = "More", 0
    for goal, keys in GOAL_KEYWORDS:
        sc = sum(text.count(k) for k in keys)
        if sc > best_score:
            best, best_score = goal, sc
    return best


def frontmatter(path):
    try:
        t = open(path, encoding="utf-8", errors="replace").read()
    except Exception:
        return None, None
    m = re.search(r"^---\s*\n(.*?)\n---", t, re.S)
    if not m:
        return None, None
    fm = m.group(1)
    name = re.search(r"^name:\s*(.+)$", fm, re.M)
    desc = re.search(r"^description:\s*(.+(?:\n\s+.+)*)$", fm, re.M)
    n = name.group(1).strip().strip("'\"") if name else None
    d = desc.group(1).strip().strip("'\"").replace("\n", " ") if desc else ""
    d = re.sub(r"\s+", " ", d)
    return n, d


def readme_categories():
    """Return {skill_name: category} parsed from README section headings + table rows."""
    cat = {}
    if not os.path.exists(README):
        return cat
    current = "Other"
    for line in open(README, encoding="utf-8", errors="replace"):
        h = re.match(r"^##+\s+(.*)", line)
        if h:
            current = re.sub(r"[^\w &/+-]", "", h.group(1)).strip()
            continue
        row = re.match(r"^\|\s*`([^`]+)`\s*\|", line)
        if row:
            cat[row.group(1).strip()] = current
    return cat


def goal_for(category):
    low = category.lower()
    for goal, keys in GOAL_OF:
        if any(k in low for k in keys):
            return goal
    return "More"


def scan():
    cats = readme_categories()
    items = []
    for name in sorted(os.listdir(SKILLS_DIR)):
        sp = os.path.join(SKILLS_DIR, name, "SKILL.md")
        if not os.path.isfile(sp):
            continue
        n, d = frontmatter(sp)
        if not n:
            continue
        category = cats.get(n, "Other")
        items.append({"name": n, "desc": d, "category": category,
                      "goal": classify(n, d)})
    return items


PAGE = r"""<div id="app"></div>
<style>
:root{--bg:#faf9f7;--fg:#16161a;--muted:#6b7280;--card:#fff;--line:#e6e4df;--accent:#4f46e5;--ok:#16a34a}
:root[data-theme=dark],html[data-theme=dark]{--bg:#0b0b0f;--fg:#f4f3ee;--muted:#8a8f98;--card:#15151b;--line:#26262e;--accent:#8b8cf9;--ok:#4ade80}
@media(prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#0b0b0f;--fg:#f4f3ee;--muted:#8a8f98;--card:#15151b;--line:#26262e;--accent:#8b8cf9;--ok:#4ade80}}
*{box-sizing:border-box}
body{margin:0}
#app{font:15px/1.5 ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;background:var(--bg);color:var(--fg);min-height:100vh}
.wrap{max-width:1080px;margin:0 auto;padding:28px 22px 80px}
h1{font-size:20px;margin:0 0 2px;font-weight:680;letter-spacing:.01em}
.sub{color:var(--muted);font-size:13px;margin-bottom:18px}
.search{width:100%;padding:15px 16px;font-size:16px;border:1.5px solid var(--line);border-radius:13px;background:var(--card);color:var(--fg)}
.search:focus{outline:none;border-color:var(--accent)}
.hint{color:var(--muted);font-size:12px;margin:8px 2px 0}
.goals{display:flex;gap:8px;flex-wrap:wrap;margin:18px 0}
.goal{cursor:pointer;border:1px solid var(--line);background:var(--card);color:var(--fg);border-radius:999px;padding:7px 14px;font-size:13px}
.goal.on{background:var(--accent);color:#fff;border-color:var(--accent)}
.sec{margin:22px 0 8px;font-size:12px;text-transform:uppercase;letter-spacing:.08em;color:var(--muted)}
.grid{display:grid;gap:12px;grid-template-columns:repeat(auto-fill,minmax(300px,1fr))}
.card{background:var(--card);border:1px solid var(--line);border-radius:13px;padding:14px 15px;display:flex;flex-direction:column;gap:7px}
.card .top{display:flex;align-items:center;gap:8px}
.nm{font-weight:650;font-family:ui-monospace,Menlo,Consolas,monospace;font-size:13.5px}
.why{color:var(--ok);font-size:12px}
.dsc{color:var(--muted);font-size:13px;display:-webkit-box;-webkit-line-clamp:3;-webkit-box-orient:vertical;overflow:hidden}
.row{display:flex;gap:7px;margin-top:3px}
.btn{cursor:pointer;border:1px solid var(--line);background:transparent;color:var(--fg);border-radius:8px;padding:6px 10px;font-size:12px}
.btn.p{background:var(--accent);color:#fff;border-color:var(--accent)}
.btn:active{transform:translateY(1px)}
.star{margin-left:auto;cursor:pointer;color:var(--muted);border:none;background:none;font-size:15px}
.star.on{color:#f59e0b}
.recipe{background:var(--card);border:1px dashed var(--line);border-radius:13px;padding:13px 15px;margin-bottom:10px}
.recipe b{font-size:14px}
.chain{color:var(--muted);font-size:12.5px;margin:4px 0 8px}
.toast{position:fixed;left:50%;bottom:26px;transform:translateX(-50%);background:var(--fg);color:var(--bg);padding:9px 16px;border-radius:10px;font-size:13px;opacity:0;transition:opacity .2s;pointer-events:none}
.toast.show{opacity:1}
.themebtn{position:fixed;top:14px;right:16px;cursor:pointer;border:1px solid var(--line);background:var(--card);color:var(--fg);border-radius:999px;padding:6px 12px;font-size:12px}
.count{color:var(--muted);font-size:12px}
</style>
<script>
const SKILLS = __DATA__;
const RECIPES = [
  {name:"Build a website end-to-end", chain:["web-page-builder"], prompt:"Use web-page-builder: build me a website for [describe it]. Pull a look from my taste library, commit a bold direction, and show me a clickable preview."},
  {name:"Polish an existing UI", chain:["impeccable"], prompt:"/impeccable polish"},
  {name:"Review my code changes", chain:["requesting-code-review","code-review"], prompt:"Review my current changes for correctness, security, and design. Use the code-review skill."},
  {name:"Plan before building", chain:["plan-gate","wargame"], prompt:"Before we build, run plan-gate (5-line plan) then a wargame pass on the plan."},
  {name:"Research something with sources", chain:["harness-research"], prompt:"Use harness-research: research [topic] and give me a cited, fact-checked answer."},
  {name:"Simplify / de-bloat code", chain:["ponytail","simplify"], prompt:"Run ponytail on this — find the laziest solution that works and cut the bloat."},
];
const GOAL_ORDER=["Build","Design","Fix & Debug","Research","Write","Automate & Loop","Manage repo & config","More"];
let fav=new Set(), q="", goal="All";
const $=s=>document.querySelector(s);
function score(s,terms){let t=(s.name+" "+s.desc+" "+s.category).toLowerCase(),sc=0;
  for(const w of terms){if(!w)continue; if(s.name.toLowerCase().includes(w))sc+=6; const c=(t.split(w).length-1); sc+=c;} return sc;}
function copy(txt,label){var ok=function(){toast((label||"Copied")+" — paste into Claude");};
 if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(txt).then(ok).catch(function(){fallbackCopy(txt,ok);});}
 else{fallbackCopy(txt,ok);}}
function fallbackCopy(txt,ok){try{var t=document.createElement("textarea");t.value=txt;t.style.position="fixed";t.style.opacity="0";document.body.appendChild(t);t.focus();t.select();var done=document.execCommand("copy");document.body.removeChild(t);if(done){ok();return;}}catch(e){}
 window.prompt("Copy this, then paste into Claude:",txt);}
function toast(m){let e=$(".toast");e.textContent=m;e.classList.add("show");clearTimeout(window._t);window._t=setTimeout(()=>e.classList.remove("show"),1600);}
function card(s){const on=fav.has(s.name)?"on":"";const why=s._why?`<span class="why">${s._why}</span>`:"";
 return `<div class="card"><div class="top"><span class="nm">/${s.name}</span>${why}<button class="star ${on}" data-f="${s.name}">${fav.has(s.name)?"★":"☆"}</button></div>
 <div class="dsc">${esc(s.desc)}</div>
 <div class="row"><button class="btn p" data-c="/${s.name}">Copy /${s.name}</button>
 <button class="btn" data-c="Use the ${s.name} skill to: ">Copy starter prompt</button></div></div>`;}
function esc(x){return (x||"").replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));}
function render(){
 const terms=q.toLowerCase().split(/\s+/).filter(Boolean);
 let html="";
 if(fav.size&&!terms.length&&goal==="All"){const fs=SKILLS.filter(s=>fav.has(s.name));
   html+=`<div class="sec">★ Favorites</div><div class="grid">${fs.map(card).join("")}</div>`;}
 if(terms.length){
   let ranked=SKILLS.map(s=>({...s,_sc:score(s,terms)})).filter(s=>s._sc>0).sort((a,b)=>b._sc-a._sc).slice(0,12);
   ranked.forEach((s,i)=>s._why=i===0?"top match":"");
   html+=`<div class="sec">Suggestions for “${esc(q)}” <span class="count">(${ranked.length})</span></div>`;
   html+= ranked.length?`<div class="grid">${ranked.map(card).join("")}</div>`:`<p class="hint">No match. Try simpler words, or browse by goal below.</p>`;
 } else {
   html+=`<div class="sec">Recipes — one click runs several</div>`;
   html+=RECIPES.map(r=>`<div class="recipe"><b>${esc(r.name)}</b><div class="chain">${r.chain.map(c=>"/"+c).join("  →  ")}</div>
     <button class="btn p" data-c="${esc(r.prompt).replace(/"/g,'&quot;')}">Copy recipe</button></div>`).join("");
   const goals=goal==="All"?GOAL_ORDER:[goal];
   for(const g of goals){const gs=SKILLS.filter(s=>s.goal===g);if(!gs.length)continue;
     html+=`<div class="sec">${g} <span class="count">(${gs.length})</span></div><div class="grid">${gs.map(card).join("")}</div>`;}
 }
 $("#list").innerHTML=html;
 document.querySelectorAll("[data-c]").forEach(b=>b.onclick=()=>copy(b.dataset.c,b.dataset.c.startsWith("/")?b.dataset.c:"Prompt"));
 document.querySelectorAll("[data-f]").forEach(b=>b.onclick=()=>{const n=b.dataset.f;fav.has(n)?fav.delete(n):fav.add(n);render();});
}
function boot(){
 $("#app").innerHTML=`<button class="themebtn" onclick="var r=document.documentElement;r.dataset.theme=r.dataset.theme==='dark'?'light':'dark'">theme</button>
 <div class="wrap"><h1>Skill Launcher</h1><div class="sub">${SKILLS.length} skills. Type what you want to do, or browse by goal. Click to copy — paste into Claude.</div>
 <input class="search" placeholder="What do you want to do?  e.g. build a landing page, debug this, research a topic…">
 <div class="hint">Tip: pick a goal to narrow the list, ★ to favorite, or grab a Recipe to run several skills in order.</div>
 <div class="goals"></div><div id="list"></div></div><div class="toast"></div>`;
 const goalsEl=$(".goals");["All",...GOAL_ORDER].forEach(g=>{const b=document.createElement("button");b.className="goal"+(g==="All"?" on":"");b.textContent=g;
   b.onclick=()=>{goal=g;document.querySelectorAll(".goal").forEach(x=>x.classList.remove("on"));b.classList.add("on");render();};goalsEl.appendChild(b);});
 const s=$(".search");s.oninput=()=>{q=s.value.trim();render();};s.focus();
 render();
}
boot();
</script>"""


def build(out):
    items = scan()
    doc = PAGE.replace("__DATA__", json.dumps(items))
    open(out, "w", encoding="utf-8").write(doc)
    json.dump({"skills": items}, open(os.path.join(HERE, "..", "skills.json"), "w"), indent=2)
    by = {}
    for it in items:
        by[it["goal"]] = by.get(it["goal"], 0) + 1
    print("Wrote %s — %d skills" % (out, len(items)))
    print("by goal:", by)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.normpath(
        os.path.join(HERE, "..", "skill-launcher.html"))
    build(out)


if __name__ == "__main__":
    main()
