# Deploy

The last step. Deploy is outward-facing, so **confirm with the user before running it**
— one line ("Ready to deploy to <target> — go?"). Everything before this the skill does
without asking; this it asks once.

## Pick the path

- **Vercel (default for Next.js / static / most sites).** Use the Vercel MCP tools:
  `deploy_to_vercel`, then `get_deployment` / `get_deployment_build_logs` to confirm the
  build, and `get_runtime_errors` / `get_runtime_logs` if it misbehaves. For a claude.ai
  design already built, `import-claude-design-from-url` can seed the project.
- **Higgsfield (its own bundles).** If the site was built through Higgsfield's website
  flow, use `deploy_website` (and `website_status` / `publish_website`). Load
  `get_website_creation_instructions` first if you didn't build it that way.
- **Docker / CI / self-host.** For a containerized app, CI/CD pipeline, rollback
  strategy, Postgres pooling, or anything infra-shaped, hand off to the `web-deployment`
  skill.

## Before you deploy

- Production build passes locally (or in CI) — never deploy a red build.
- Real env vars set on the host; no secrets in the repo or the client bundle.
- The quality floor holds in a production build, not just dev (`quality-floor.md`).
- Assets are optimized and referenced by real paths (`assets.md`).

## After you deploy

- Verify the **live URL** actually renders — open it, don't trust the "deployed"
  message. Check the hero, one interaction, mobile width, and reduced-motion.
- Report the live URL and the build status. If the build or runtime failed, say so with
  the log line, and fix — don't report success on a proxy.
