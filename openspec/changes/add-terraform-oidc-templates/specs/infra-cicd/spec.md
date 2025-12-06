## ADDED Requirements
### Requirement: Shared Terraform execution template
The platform SHALL provide a reusable GitHub Actions workflow template in `Frexida/infra` that assumes an AWS IAM role via GitHub OIDC, runs Terraform init/plan/apply, and accepts role ARN and region as inputs.

#### Scenario: App repo calls template
- **WHEN** an app repository workflow uses `Frexida/infra/.github/workflows/terraform-template.yml@main` with `role_arn` and `aws_region`
- **THEN** the workflow configures AWS credentials via OIDC, runs Terraform init/plan/apply in the infra repo path, and exits successfully on apply

### Requirement: Trust policy template for GitHub OIDC
The platform SHALL define a trust policy template that uses the existing OIDC provider ARN `arn:aws:iam::522579114515:oidc-provider/token.actions.githubusercontent.com` and allows multiple repositories/branches via `StringLike` on `token.actions.githubusercontent.com:sub`.

#### Scenario: Multiple repos permitted
- **WHEN** the trust policy includes `repo:Frexida/<name>:ref:refs/heads/main` entries
- **THEN** those repositories can assume the Terraform execution role via OIDC without long-lived credentials

### Requirement: Terraform backend and provider scaffolding
The platform SHALL supply Terraform scaffolding with `versions.tf`, `backend.tf` using S3+DynamoDB (encrypt enabled), and `provider.tf` with `aws_region` variable defaulting to `ap-northeast-1`.

#### Scenario: Backend configured
- **WHEN** the placeholder bucket, key, region, and DynamoDB table are populated
- **THEN** Terraform init succeeds using the S3 backend with DynamoDB state locking and the AWS provider is configured with the specified region

### Requirement: App-side caller workflow sample
The platform SHALL provide an example app-side GitHub Actions workflow that invokes the shared template, passing the Terraform execution role ARN and optional AWS region override.

#### Scenario: Sample deploy workflow
- **WHEN** the sample `deploy.yml` is placed in an app repo
- **THEN** a push to main triggers the shared template with the provided role ARN, enabling Terraform plan/apply through the infra workflow
