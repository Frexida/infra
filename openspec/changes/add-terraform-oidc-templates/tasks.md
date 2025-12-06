## 1. Inputs & trust
- [x] 1.1 Confirm allowed repo list for trust policy (start with infra/homepage/app-foobar).
- [x] 1.2 Draft trust policy JSON using OIDC provider ARN `arn:aws:iam::522579114515:oidc-provider/token.actions.githubusercontent.com` with StringLike sub list and aud check.

## 2. Terraform scaffolding
- [x] 2.1 Add versions.tf with Terraform and AWS provider constraints.
- [x] 2.2 Add backend.tf with S3+DynamoDB placeholders (bucket/key/region/table/encrypt=true).
- [x] 2.3 Add provider.tf with aws provider and aws_region variable defaulting to ap-northeast-1.

## 3. GitHub Actions templates
- [x] 3.1 Add workflow_call template `.github/workflows/terraform-template.yml` with inputs role_arn/aws_region, OIDC credentials, init/plan/apply steps.
- [x] 3.2 Add sample caller workflow `.github/workflows/deploy.yml` for an app repo referencing infra template.

## 4. Validation & docs
- [x] 4.1 Ensure instructions note placeholder replacements (account ID, bucket, table, state key).
- [x] 4.2 Run `openspec validate add-terraform-oidc-templates --strict`.
