## 1. Build & project settings
- [x] 1.1 Confirm Cloudflare Pages project name `frexida-homepage` and custom domain `www.frexida.com`.
- [x] 1.2 Ensure build uses `npm ci && npm run export` to `./out`.

## 2. Deployment workflow
- [x] 2.1 Add GitHub Actions workflow in `Frexida/homepage` to build/export and run `wrangler pages deploy ./out --project-name frexida-homepage`.
- [ ] 2.2 Provide Cloudflare API token secret (Pages deploy + DNS edit scopes) to the workflow.

## 3. DNS & TLS
- [ ] 3.1 Configure Cloudflare Pages custom domain `www.frexida.com` and ensure DNS record is created/validated with TLS.

## 4. Validation
- [ ] 4.1 Run workflow on main push and verify Pages deployment succeeds.
- [ ] 4.2 Access `https://www.frexida.com` and confirm the homepage renders.
