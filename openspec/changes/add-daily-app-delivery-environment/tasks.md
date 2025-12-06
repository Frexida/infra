## 1. Foundations
- [ ] 1.1 Capture project conventions in `openspec/project.md` (Docker/Docker Compose dev flow, Cloudflare Pages for frontend, AWS ECS for backend, domains on Cloudflare).
- [ ] 1.2 Define registry, AWS region/account, and naming schemes for ECR repos, Cloudflare Pages projects, and subdomains; document in design.
- [ ] 1.3 Lock secrets/auth patterns (GitHub OIDC to AWS, Cloudflare API tokens) and add to conventions.
- [ ] 1.4 Define AI usage policy and guardrails: Claude for implementation/issue automation, Codex for requirements/spec refinement, allowed commands/paths, and logging/audit expectations.

## 2. Template & Tooling
- [ ] 2.1 Build the base app template (frontend + backend) with health endpoint, env-based config, Dockerfile + docker-compose for local dev, basic tests, example telemetry hooks.
- [ ] 2.2 Create a scaffolding command/script that spins up a new repo from the template and injects GitHub Actions CI/CD config in one step (AI-friendly, no manual steps).
- [ ] 2.3 Create a dev container image/setup with required CLIs (Node, pnpm/yarn, git, aws, gh, wrangler/Cloudflare, docker-in-docker or socket), and baked-in git worktree helpers.
- [ ] 2.4 Add GitHub issue templates and automation to trigger Claude for implementation tasks and Codex for requirement/spec refinement.

## 3. Infrastructure & Delivery
- [ ] 3.1 Implement IaC module/blueprint for an app slot (Cloudflare DNS/Pages project, ECS service/task with TLS, secrets, logging/metrics sinks, resource limits).
- [ ] 3.2 Wire GitHub Actions workflow: build/test, build/push backend image to ECR, deploy to ECS, build/upload frontend to Cloudflare Pages, health check, and manual prod promotion.
- [ ] 3.3 Add rollout safety: smoke test step post-deploy, rollback/disable toggle, and alerts for failures across Pages + ECS.

## 4. Validation & Enablement
- [ ] 4.1 Ship a sample “day-zero” app through the pipeline to verify end-to-end timing (<1 day).
- [ ] 4.2 Document the daily workflow (scaffold → configure → deploy) and any per-app inputs developers/AI must supply.
- [ ] 4.3 Document AI workflows (issue-driven Claude steps, Codex requirement prompts, search tool usage) and how to run worktree-based local tests inside the dev container.
