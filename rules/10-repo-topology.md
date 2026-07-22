# Repo topology - enumerate correctly, and never assert an absence

## There are TWO namespaces, not one

| Namespace | Kind | Contains |
|---|---|---|
| `Kariimc` | **user** | 31 repos - xavier-agentic-os, my-skills, relay, Just-a-pinch, Flow-State, brain, Hoopclone, claude-eyes, Omni-3d, ... |
| `shift9-studio` | **org** | `shift9-studio/.github` - the shift9.dev + Just-a-Pinch monorepo. The studio's flagship, most-active work. |

`gh repo list Kariimc` returns **only the first**. So does
`github.com/Kariimc?tab=repositories`. Any agent that enumerates by user
**silently skips shift9-studio and reports success** - no error, no warning.

This already happened, for the entire life of the project: shift9 went
un-audited and carried no `HANDOFF.md` because agents were told
*"every repo lives under the Kariimc GitHub org."* That sentence was false, it
was written into a handoff doc as fact, and every agent after it inherited the
blind spot.

## Enumerate like this, always

    gh api '/user/repos?per_page=100&affiliation=owner,collaborator,organization_member' --jq '.[].full_name'

Never `gh repo list Kariimc` on its own. If a script, loop, or doc scopes to a
single namespace, it is wrong - fix the scope, do not work around it.

## Repos are NOT all public

Any doc claiming *"all Kariimc repos are public"* is false. Private today
include: xavier-agentic-os, Flow-State, claude-eyes, brain, second-brain,
my-coding-journey, Sub-Scraper, agentkit, sightline-ar, wpt-30, lovable-clone,
Faceless-Tech-youtube, and the four `*-handoff` repos. Unauthenticated
`raw.githubusercontent.com` fetches work for public repos only. Check; never assume.

## The rule this file exists to enforce

**Never assert an absence, a status, or a completion without first proving your
scope was exhaustive.**

A *positive* finding is safe - the evidence was in front of you. A *negative*
finding - "X does not exist", "nothing else references this", "that is all of
them", "it is done" - is a claim about **coverage**. Coverage is the one thing a
narrow query cannot prove. Silence from a tool is not evidence of absence; it is
evidence you asked a narrow question.

Before writing any absence or completion into a doc, `PROGRESS.md`, `HANDOFF.md`,
or a report:

1. Name the scope your query actually covered.
2. Name what it structurally **could not** cover.
3. Widen it, or state the gap in the doc. Never let the reader infer completeness.

## The same rule applied to the network (egress is a coverage claim too)

"The network blocks it" is an absence claim — a CDN 403 proves only that *one
host* is denied, never that downloads are impossible. Before concluding a cloud
session can't fetch something: read `/root/.ccr/README.md`, hit
`$HTTPS_PROXY/__agentproxy/status`, and **probe a spread of hosts** —
`for h in example.com github.com raw.githubusercontent.com pypi.org <the-cdn>; do
curl -o /dev/null -w "%{http_code}" https://$h; done`. On this env that probe
shows a GitHub+package allowlist: generic sites blocked, but GitHub raw and PyPI
open — so real CC0 assets pull straight from GitHub mirrors (PLAYBOOK P-16).
Never write "no downloads possible" from a partial probe (I did, then had to
rewrite FAILURES F-45). Approved rule, 2026-07-22.

## The same rule applied to dependencies on an ephemeral box

"The engine/tool isn't installed" is also an absence claim. A cloud container is
wiped between sessions, so a dependency genuinely can be gone — but PROVE it before
reinstalling or telling Kariim it's missing. Locate the interpreter and attempt the
import (`for py in python3.11 python3; do "$py" -c "import bpy" 2>/dev/null; done`),
or search the disk (`find / -name "<mod>" -maxdepth 8`). State the finding — "bpy is
not on disk anywhere; the box was wiped" — before you act. I reinstalled bpy after
Kariim said it was there; it HAD been wiped, but the proof must come first, not the
reinstall (the classic absence-without-coverage trap, applied to deps). Approved
rule, 2026-07-22.

## Why this is the root of doc drift

Stale docs are the symptom. The disease is an agent confidently recording a
**partial view as a complete one** - and the next agent inheriting that blind
spot and writing it forward. A doc updated every single day still rots if the
agent writing it never checked whether it was looking at the whole thing.
Freshness gates catch the symptom. This rule catches the cause.
