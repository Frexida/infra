# Change: AWS OIDC Terraform templates for Frexida apps

## Why
We need a reusable, centralized template in `Frexida/infra` for GitHub Actions + Terraform on AWS using OIDC, so any app repo can deploy without long-lived credentials.

## What Changes
- Define AWS-side trust policy template using the existing GitHub OIDC provider ARN `arn:aws:iam::522579114515:oidc-provider/token.actions.githubusercontent.com` and a pattern for adding repos.
- Provide Terraform backend/provider scaffolding (S3 + DynamoDB lock) with required versions and placeholders.
- Publish a reusable GitHub Actions workflow template (workflow_call) in `Frexida/infra` for terraform init/plan/apply via OIDC AssumeRole.
- Supply a sample app-side caller workflow showing how to use the infra template with role ARN and region inputs.

## Impact
- Affected specs: infra-cicd
- Affected code: `Frexida/infra` Terraform scaffolding and `.github/workflows/terraform-template.yml`; sample caller workflow pattern for app repos
