# 0003 — The brain has no git remote (single point of failure)

- **Status:** Accepted — **amended 2026-07-03 (same day):** rotation is
  IMPOSSIBLE user-side. Higgsfield has no token regeneration — verified via
  the platform's own `website_repo_access` API, which returns the same
  standing token on every call. **Second verification, same day:** the token
  is **account-scoped, not per-repo** — a freshly created website returned
  the byte-identical token (rebuild/delete-recreate is therefore closed as a
  rotation path; a support ticket is the only rotation). Everywhere this ADR
  says "rotate at the provider", read: *cannot be done; the token is
  permanently live.* This makes the **history purge strictly mandatory** (the
  only way the secret ever stops being recoverable from the repo) and hardens
  the remote gate: any future remote must be private **and client-side
  encrypted**, no exceptions. Details: `brain/wiki/credential-map.md` §1.
- **Date:** 2026-07-03
- **Deciders:** control-plane owner
- **Grounds:** `C:/Dev/brain` working tree (git repo, branch `master`, **no
  remote**, 54 tracked files, ~6.1 MB); brain history commits `d2ebebe`
  ("Security: redact plaintext Higgsfield token from all brain files"),
  `6f774bc` ("… token exposure flagged"), `3a5fa81`; `C:/Dev/brain/wiki/
  credential-map.md`; the `add-new-resource` / second-brain ingest contract
- **Related:** `C:/Users/karii/Agetnic OS/data/decisions/2026-07-02-unified-
  memory-architecture.md` (the brain is the long-term memory tier)

## Context

The second brain at `C:/Dev/brain` is the durable long-term memory of the whole
system — per the unified-memory ADR it is the *only* home for lessons,
preferences, how-tos, and reference, and JARVIS takes a boot-time read
dependency on it. It is a real git repo (`master`, 54 tracked files, ~6.1 MB)
but has **no configured remote**. Every distilled lesson lives on exactly one
disk. If that disk dies or the folder is lost, the entire long-term tier is
gone — a genuine single point of failure under the durable-knowledge store.

The obvious fix (push it to a git remote) collides with a second, hard fact from
the brain's own history: **the brain has already held a plaintext secret.** The
Higgsfield token was committed in cleartext and later scrubbed in commit
`d2ebebe`, which touched 8 content files across `raw/` and `wiki/`; `6f774bc`
records the exposure being flagged during a `data-ingestion` run. Critically,
`d2ebebe` **redacted the token in-tree — it did not rewrite history.** The
pre-redaction blobs are still reachable from earlier commits, so *the plaintext
token remains recoverable from the git history today.* The repo also tracks
`wiki/credential-map.md`, i.e. it is a store that structurally attracts
sensitive references.

So the decision is not "remote vs. no remote" in the abstract. It is: how do we
kill the SPOF **without** publishing a history that still contains a live
secret?

## Options

1. **Private GitHub remote, push as-is.** Simplest durability: `git push` and
   it's backed up and multi-machine. **Unacceptable as-is** — pushing the
   current history uploads the still-recoverable plaintext token to a hosted
   third party. Redaction-in-tree (`d2ebebe`) does not make the old blob safe to
   publish; a private repo still means the secret leaves the machine in a form
   an org member, a token leak, or a future visibility change could expose.

2. **Local-only + external encrypted backup (chosen for the durability half).**
   Keep the repo local (no hosted remote), and remove the SPOF with an
   **encrypted** off-machine backup — a second physical/cloud copy of the whole
   directory, encrypted at rest, restore-tested. Durability without handing the
   git history (secret and all) to a hosted git service. Cost: manual-ish
   backup discipline; not the seamless multi-machine sync a remote gives.

3. **Encrypted git remote (the only acceptable *remote* option, and only after
   history surgery).** A remote where the repo is encrypted before it leaves the
   machine (e.g. an encrypted bundle, or a client-side-encrypted remote), so the
   host never sees plaintext. Closest to "real backup + sync," but it does
   **not** by itself neutralize the secret already in history — an encrypted
   remote protects against the *host* reading it, not against anyone who can
   decrypt the repo. It is only safe **after** the token is purged from history
   *and* rotated.

## Decision

Two parts, because the SPOF and the secret are separate problems and the secret
gates the remote:

1. **Secret first, unconditionally.** Treat the token as compromised: **rotate
   it at the provider** (redaction ≠ rotation — the old value must be made
   worthless), and **purge it from brain git history** (history rewrite, not
   just the in-tree redaction already done in `d2ebebe`). Until both are done,
   **no remote of any kind** — nothing leaves the machine while a live secret is
   recoverable from the history. `wiki/credential-map.md` must reference secrets
   by *location*, never by value.

2. **Durability without a plaintext-history remote.** Adopt **Option 2 now** —
   local-only plus an **encrypted, restore-tested, off-machine backup** — to
   kill the SPOF immediately without publishing the history. A hosted git remote
   (Option 1 private, or Option 3 encrypted) is **gated on part 1 being
   complete**: only after the token is rotated and history-purged is a remote
   even eligible, and even then it should be **private and client-side
   encrypted**, given the repo's demonstrated tendency to accumulate sensitive
   material (`credential-map.md`, and the token incident itself).

Net: the brain stops being a single-disk SPOF via encrypted external backup;
the secret is rotated and scrubbed from history before any remote is considered;
and if/when a remote is added it is private + encrypted, never a plain push of
the current history.

## Consequences

- **Good:** SPOF is removed without ever uploading a secret-bearing history to a
  third party. The secret is actually neutralized (rotated + purged), not merely
  hidden in-tree. The bar for any future remote is set explicitly: private +
  client-side encrypted, only post-scrub.
- **Cost / carried risk:** Encrypted external backup needs real discipline (and
  a periodic **restore test** — an unverified backup is not a backup). Local-
  only forgoes the seamless multi-machine sync a remote would give until part 1
  is done. History rewrite is disruptive if any other clone ever exists (it must
  be coordinated), which is one more reason to keep clones minimal until then.
- **Standing rule:** The brain must never again commit a secret in plaintext.
  Ingest flows that touch `raw/ecosystem/` (session transcripts, handoffs) are
  the known exposure path — this is exactly how the token got in (`6f774bc`).
  Secret-scan the brain as part of ingest, not after.

## Revisit trigger

Reopen if **any** of:

- The token is confirmed rotated **and** purged from history — then re-evaluate
  moving from local-only to a **private, client-side-encrypted** remote (Option
  3) for real multi-machine sync; **or**
- The brain grows enough, or is accessed from enough machines, that manual
  encrypted backup + no sync becomes the operational bottleneck; **or**
- Another plaintext secret is found in the brain — in which case this decision
  failed at its standing rule, and the ingest-time secret-scan must be hardened
  (ratchet it) before anything else.

Until the secret is rotated and history-purged: **local-only + encrypted
external backup. No remote.**
