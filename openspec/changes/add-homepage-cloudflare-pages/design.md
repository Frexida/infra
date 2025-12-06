## Context
- Goal: Deploy the Next.js homepage to Cloudflare Pages under `www.frexida.com`, using `frexida-homepage` as the Pages project name.
- Build strategy: static export (`npm run export`) to `./out`, then publish to Pages.
- Deployment trigger: GitHub Actions on main branch push.
- DNS: Cloudflare-managed domain `frexida.com`, map `www.frexida.com` to the Pages project with TLS.

## Decisions
- Pages project name: `frexida-homepage`.
- Domain mapping: custom domain `www.frexida.com` on Cloudflare Pages.
- Build command: `npm install` (no lock yet) && `npm run build` with `output: 'export'` in next.config.js. If/when a lockfile is added, switch to `npm ci`.
- Publish command: `wrangler pages deploy ./out --project-name frexida-homepage`.
- Workflow location: in `Frexida/homepage` (can later centralize in infra if desired).

## Risks / Trade-offs
- Static export must cover all routes; dynamic SSR features won’t work without adapters.
- Wrangler token (Cloudflare API token) must be provided securely to the workflow.
- DNS change may take time to propagate.

## Open Questions
- None blocking; assuming Cloudflare API token with Pages + DNS edit scopes is available.
