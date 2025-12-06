## Context
- Goal: Centralize Terraform + GitHub Actions templates in `Frexida/infra` so app repos can call a shared workflow to deploy via AWS OIDC (no long-lived creds).
- AWS OIDC provider is already created: `arn:aws:iam::522579114515:oidc-provider/token.actions.githubusercontent.com`.
- Scope now: minimal foundation only (backend config, provider, trust policy template, IAM role pattern, reusable workflow_call template, sample caller workflow). No app infra modules yet.

## Decisions
- Trust policy uses the existing OIDC provider ARN and `StringLike` on `token.actions.githubusercontent.com:sub` with a list of allowed repos/branches; expandable by app.
- State backend: S3 bucket + DynamoDB table placeholders; key pattern is configurable. Encrypt = true.
- Terraform versions: Terraform >=1.6, AWS provider ~>5.0 (boring, current).
- Workflow: GitHub Actions `workflow_call` template in `Frexida/infra/.github/workflows/terraform-template.yml`; inputs `role_arn`, `aws_region` (default ap-northeast-1); steps checkout, configure-aws-credentials v4 (OIDC), setup-terraform, init/plan/apply.
- Caller sample: app repo `.github/workflows/deploy.yml` uses `Frexida/infra/.github/workflows/terraform-template.yml@main` with `role_arn` and region.

## Risks / Trade-offs
- Trust policy must be updated per repo addition; missing entries will block assume-role.
- Initial IAM policy is broad for bootstrap; must be tightened later.
- State bucket/table creation is not covered here; users must supply real names/regions.

## Open Questions
- None blocking this template; future: minimum-permission policies, per-environment keys.
