# Project-Specific Infrastructure

This directory contains infrastructure configurations for individual Frexida projects.

## Directory Structure

```
projects/
├── picture-calendar/     # Picture calendar application
├── homepage/            # Frexida homepage
└── app-foobar/         # Sample application
```

## Overview

Each project directory contains its own Terraform configuration that:
- Uses the shared `self-healing-cicd` module
- Maintains separate Terraform state
- Can be deployed independently
- Inherits platform capabilities

## Key Principles

### 1. Module Reuse Only
Projects **MUST** use the existing module without modification:

```hcl
module "project_cicd" {
  source = "../../../modules/self-healing-cicd"

  # Project-specific configuration only
  project_name      = "my-project"
  github_repository = "https://github.com/Frexida/my-project.git"
  # ...
}
```

### 2. No Infrastructure Duplication
- Platform resources (Lambda, SNS) are shared
- Each project gets its own CodeBuild project
- Monitoring is centralized with project-specific views

### 3. Separation of Concerns
- **Platform**: Organization-wide resources
- **Projects**: Application-specific pipelines
- **Modules**: Reusable Terraform code

## Adding a New Project

### 1. Create Project Directory

```bash
mkdir -p projects/new-project/terraform
cd projects/new-project/terraform
```

### 2. Create Configuration Files

**main.tf**:
```hcl
module "new_project_cicd" {
  source = "../../../modules/self-healing-cicd"

  environment       = var.environment
  aws_region       = var.aws_region
  account_id       = data.aws_caller_identity.current.account_id

  project_name     = "new-project"
  github_repository = "https://github.com/Frexida/new-project.git"
  github_branch    = "main"
  github_token     = var.github_token

  ai_agent_endpoint = var.ai_agent_endpoint
  ai_agent_api_key  = var.ai_agent_api_key
}
```

**backend.tf**:
```hcl
terraform {
  backend "s3" {
    bucket         = "frexida-terraform-state"
    key            = "projects/new-project/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

### 3. Deploy via GitHub Actions

The project will be automatically deployed when:
- Changes are pushed to `projects/new-project/`
- The workflow is manually triggered
- Module changes affect all projects

## Deployment

### Automatic Deployment

Projects are deployed automatically via GitHub Actions when:
1. Changes are pushed to the project directory
2. Changes are made to shared modules
3. Manual workflow dispatch is triggered

### Manual Deployment

For a specific project:
```bash
cd projects/picture-calendar/terraform
terraform init
terraform plan
terraform apply
```

## State Management

Each project maintains independent Terraform state:
- **picture-calendar**: `projects/picture-calendar/terraform.tfstate`
- **homepage**: `projects/homepage/terraform.tfstate`
- **app-foobar**: `projects/app-foobar/terraform.tfstate`

This allows:
- Independent deployment cycles
- Isolated blast radius
- Parallel development

## Cost Allocation

Each project is tagged for cost tracking:
- Environment tag (production/staging/development)
- Project tag (project name)
- Managed-by tag (terraform)

View costs per project in AWS Cost Explorer using these tags.

## Best Practices

### DO ✅
- Use the shared module without modification
- Keep project configurations minimal
- Use consistent naming conventions
- Document project-specific requirements
- Tag resources appropriately

### DON'T ❌
- Duplicate infrastructure resources
- Modify the shared module per project
- Create project-specific Lambda functions
- Bypass the CI/CD pipeline
- Store secrets in code

## Monitoring

Each project has:
- Dedicated CodeBuild project metrics
- Project-specific CloudWatch dashboard widgets
- Build history and logs
- Cost tracking

Access via:
```bash
terraform output cloudwatch_dashboard_url
```

## Troubleshooting

### Project Not Building
1. Verify webhook is configured in GitHub
2. Check CodeBuild project exists
3. Ensure buildspec.yml is in repository root
4. Review CloudWatch logs

### State Lock Issues
```bash
aws dynamodb delete-item \
  --table-name terraform-lock \
  --key "{\"LockID\": {\"S\": \"frexida-terraform-state/projects/<project>/terraform.tfstate\"}}"
```

### Module Version Conflicts
All projects use the same module version. To update:
1. Test changes in development
2. Update module in one project
3. Verify functionality
4. Roll out to other projects

## Related Documentation

- [Platform Infrastructure](../platform/self-healing-cicd/README.md)
- [Module Documentation](../modules/self-healing-cicd/README.md)
- [GitHub Actions Workflows](../.github/workflows/README.md)