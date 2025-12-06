# Change: Cloudflare Pages deploy for homepage

## Why
Publish the Frexida homepage frontend to Cloudflare Pages (www.frexida.com) with a repeatable CI path.

## What Changes
- Build and export the Next.js homepage (`npm run export`) to `./out` and deploy to a Cloudflare Pages project `frexida-homepage`.
- Wire a GitHub Actions workflow to run build/export and publish to Pages on main pushes.
- Configure DNS so `www.frexida.com` serves the Pages site with TLS.

## Impact
- Affected specs: pages
- Affected code: `Frexida/homepage` CI, `Frexida/infra` Pages deployment workflow and DNS config
