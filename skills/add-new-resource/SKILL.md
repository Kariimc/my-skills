---
name: add-new-resource
description: >
  Add a single file or resource to the second brain. Use when the user wants to
  save, file, ingest, or "add this to my brain/knowledge base" — a document,
  link, note, export, image, or any artifact worth keeping. Places the file in
  raw/ unaltered and updates the wiki/ entries that should reference it.
---

# add-new-resource

Files one resource into the brain and wires it into the wiki. The atomic ingest
primitive — the sync skills lean on this contract.

## Paths
Resolve the brain dir once: $BRAIN_DIR -> ~/.claude/brain-paths.json (brain_dir)
-> ~/brain. All paths below are relative to it.

## Steps
1. Identify the resource and the right raw/ subfolder:
   - session/transcript -> raw/inputs/
   - email/Takeout/local file -> raw/ecosystem/
   - saved article/bookmark/highlight/note -> raw/curated/
   - anything else -> raw/ (root) unless an obvious bucket fits
2. Place it in raw/ UNALTERED. Copy (don't move) if the source must stay put.
   Never rename or reorganize anything already in raw/.
3. Read it enough to summarize accurately. If you can't open it (binary/opaque),
   record what it is by filename + type — do not invent contents.
4. Update wiki/: create or update the topic note(s) that should reference it,
   each linking back to the raw/ path; update wiki/README.md so it's indexed.
   Distill the reusable point — don't copy the source into the wiki.
5. Append one entry to outputs/ingestion-log.md (source, what it is, wiki links).

## Report
State where it landed in raw/, which wiki entries changed, and the index update —
one paragraph. If you couldn't read the file, say so plainly.
