## Context
- We have no shared specs or IaC for service delivery yet, but we want a repeatable path to produce and launch one small app per day.
- Success depends on minimizing manual steps (repo setup, CI wiring, environment provisioning) and giving each app the same operational guardrails.
- Platform/tooling choices now lean toward: frontend artifacts on Cloudflare Pages, backend on AWS ECS (likely Fargate), domains on Cloudflare, and local development via Docker/Docker Compose. AI assistants are expected to drive development and rely on a single push-to-deploy path.
- Development should also be AI-first: a Docker dev container per repo, git worktree for parallel feature streams, and issue-driven automation where Claude executes implementation while Codex assists with requirements/spec refinement.

## Goals / Non-Goals
- Goals: one-command scaffold + CI/CD, shared runtime with secure defaults, production-quality observability/rollback without per-app reinvention; AI-friendly workflow where “push to GitHub” is the only required action.
- Non-Goals: building individual app features, supporting polyglot runtimes on day one (start with a single blessed template/language; allow later expansion).

## Decisions
- Runtime/stack: Docker/Docker Compose locally; backend in AWS ECS (Fargate default), frontend artifacts to Cloudflare Pages; domains on Cloudflare.
- Default language: Backend Node.js + Express; Frontend Vite + React (fast builds, AIフレンドリーなテンプレート).
- Region/registry: AWS `ap-northeast-1`, ECR repo per app at `{account-id}.dkr.ecr.ap-northeast-1.amazonaws.com/{app}`.
- Naming: Cloudflare Pagesプロジェクト `{app}-pages`; サブドメイン `{app}.example.com`（実ドメイン置換）。TLSはCloudflareで終端。
- Secrets/auth: GitHub Actions → AWSはOIDCでAssumeRole。Cloudflare Pages用APIトークンは最小権限（Pages write + 必要ならDNS write）でリポジトリシークレットへ。
- Dev env: Provide Docker dev containers with dependencies (Node, pnpm/yarn, AWS/GitHub/Cloudflare CLIs), VS Code/CLI access, and baked-in git + worktree tooling. Standardize git worktree for parallel feature development to support daily cadence.
- AI flow: Issue-driven automation that triggers Claude to implement tasks; Codex assists requirement/spec refinement. Provide templates/prompts and permissions boundaries (no credential exfiltration, safe file paths).
- Provide a minimal IaC module/blueprint for each app that wires: Cloudflare DNS/Pages project, ECS service/task with HTTPS, secrets, logging/metrics sinks, and per-app resource limits.
- Ship a GitHub Actions workflow that runs build/test, builds/pushes backend image to ECR, deploys to ECS, builds/uploads frontend to Cloudflare Pages, and registers routing; production promotion can start as a manual approval.
- Make scaffolding the orchestrator: one command creates the repo from the template, injects CI/CD config, and binds the app to Cloudflare + ECS targets so AI-driven commits can ship with a single push.

## Risks / Trade-offs
- Picking a single default runtime may not fit all future app types; mitigated by allowing template layering later.
- Shared runtime reduces per-app overhead but can create noisy-neighbor or blast-radius risk; mitigated by per-app resource limits and isolated secrets.
- Aggressive daily cadence can hide quality gaps; CI must stay fast and include smoke tests and deployment health checks.
- Cloudflare Pages + ECS introduces two deployment surfaces; we need consistent observability and alerting across both to avoid blind spots.
- Issue-driven automation (Claude) must avoid unsafe actions; need clear scopes, dry-run options, and auditability.

## Open Questions
- Are there complianceやデータ保持要件でCloudflare/AWSのログ保存期間に制限があるか？
- 追加で優先したいスタック（Go/FastAPIなど）がある場合はテンプレートを拡張する。
- Do we need a standard prompt library and guardrails for Claude (e.g., safe file paths, no credential exfiltration) and for Codex when drafting requirements?
- Which search tooling should be standardized for AI (e.g., Sourcegraph, GitHub code search) and how to expose it in the dev container?
