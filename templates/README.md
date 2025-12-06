# Templates overview and placeholders

## IAM
- `templates/iam/trust-policy-terraform-role.json`
  - Uses OIDC provider `arn:aws:iam::522579114515:oidc-provider/token.actions.githubusercontent.com`.
  - Update the `token.actions.githubusercontent.com:sub` list with permitted repos/branches, e.g. `repo:Frexida/<repo>:ref:refs/heads/main`.
  - Attach this trust policy to the Terraform execution role.
- `templates/iam/policy-terraform-exec.json`
  - Broad permissions for bootstrap; tighten later per service. Attachable to the Terraform execution role.

## Terraform
- `terraform/backend.tf`
  - Currently set to `frexida-terraform-state`, key `envs/homepage/terraform.tfstate`, region `ap-northeast-1`, DynamoDB table `terraform-lock`. Adjust per environment if needed.
- `terraform/provider.tf`
  - Defaults `aws_region` to ap-northeast-1; override via `-var 'aws_region=...'` or environment variable.
- `terraform/versions.tf`
  - Pins Terraform (>=1.6.0) and AWS provider (~>5.0).

## GitHub Actions
- `.github/workflows/terraform-template.yml`
  - Reusable `workflow_call` template expecting `role_arn` and optional `aws_region`. Uses OIDC to assume the role.
- `samples/app-workflow/deploy.yml`
  - Example caller workflow for an app repo; copy into the app repo’s `.github/workflows/` and replace `<ACCOUNT_ID>` if needed.
