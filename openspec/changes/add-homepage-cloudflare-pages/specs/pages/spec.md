## ADDED Requirements
### Requirement: Cloudflare Pages deployment for homepage
The homepage SHALL be built via static export and deployed to a Cloudflare Pages project named `frexida-homepage`.

#### Scenario: Main branch deployment
- **WHEN** code is pushed to the main branch of `Frexida/homepage`
- **THEN** the workflow installs dependencies (currently `npm install`, switch to `npm ci` when lockfile exists), runs `npm run build` (with `output: 'export'` producing `./out`), and deploys to Cloudflare Pages project `frexida-homepage`

### Requirement: Custom domain mapping
The homepage SHALL be served at `www.frexida.com` via Cloudflare Pages with TLS enabled.

#### Scenario: Domain configured
- **WHEN** the Pages project is deployed
- **THEN** `www.frexida.com` resolves to the Pages site over HTTPS with a valid certificate
