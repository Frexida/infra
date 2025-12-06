# Change: Daily app delivery environment

## Why
We want to make it possible to create and deploy a small app every day without repeatedly solving infrastructure, CI/CD, and operational setup.

## What Changes
- Provide a standard service template (frontend + backend) built for Docker/Docker Compose with health endpoints, env-based config, tests, and deployment config.
- Add a GitHub-push CI/CD path that builds/tests, ships frontend artifacts to Cloudflare Pages, builds/pushes backend images to AWS ECS, and routes via Cloudflare-managed domains with HTTPS, secrets, and observability defaults.
- Define an operations baseline (logging, metrics, alerts, rollbacks) across Pages + ECS so every daily app inherits the same guardrails.
- Provide a standardized開発環境: Dockerベースのdevコンテナでgit worktreeを使った並列開発・テストを行い、Issues起票をトリガーにClaudeで開発を自動進行、要件定義はCodexで行うガイドを用意。
- Document the day-1 workflow so developers (and AI assistants) can scaffold, develop, and ship within a single workday.

## Impact
- Affected specs: app-delivery-environment
- Affected code: infra IaC modules, CI/CD pipelines (GitHub Actions), developer onboarding docs, AI-facing scaffolding scripts
