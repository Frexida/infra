#!/bin/bash

# AWS IAM OIDC Provider and Role Setup Script for GitHub Actions
# Usage: ./setup-aws-oidc.sh

set -e

# Configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
OIDC_PROVIDER="token.actions.githubusercontent.com"
GITHUB_ORG="Frexida"
GITHUB_REPO="infra"
ROLE_NAME="github-actions-terraform-role"
POLICY_NAME="github-actions-terraform-policy"

echo "🚀 Starting AWS OIDC and IAM Role setup for GitHub Actions"
echo "=================================================="
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "GitHub Repo: $GITHUB_ORG/$GITHUB_REPO"
echo "Role Name: $ROLE_NAME"
echo ""

# Step 1: Create OIDC Provider
echo "Step 1: Creating OIDC Provider..."
THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"

# Check if OIDC provider already exists
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}" 2>/dev/null; then
    echo "✅ OIDC Provider already exists"
else
    aws iam create-open-id-connect-provider \
        --url "https://${OIDC_PROVIDER}" \
        --client-id-list "sts.amazonaws.com" \
        --thumbprint-list "${THUMBPRINT}"
    echo "✅ OIDC Provider created"
fi

# Step 2: Create Trust Policy
echo ""
echo "Step 2: Creating Trust Policy..."
cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "${OIDC_PROVIDER}:sub": [
            "repo:${GITHUB_ORG}/${GITHUB_REPO}:*",
            "repo:${GITHUB_ORG}/picture-calendar:*",
            "repo:${GITHUB_ORG}/homepage:*",
            "repo:${GITHUB_ORG}/app-foobar:*"
          ]
        }
      }
    }
  ]
}
EOF
echo "✅ Trust policy created at /tmp/trust-policy.json"

# Step 3: Create IAM Role
echo ""
echo "Step 3: Creating IAM Role..."
if aws iam get-role --role-name "${ROLE_NAME}" 2>/dev/null; then
    echo "⚠️  Role already exists, updating trust policy..."
    aws iam update-assume-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-document file:///tmp/trust-policy.json
    echo "✅ Trust policy updated"
else
    aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "IAM role for GitHub Actions to deploy infrastructure via Terraform"
    echo "✅ IAM Role created"
fi

# Step 4: Create Permissions Policy
echo ""
echo "Step 4: Creating Permissions Policy..."
cat > /tmp/permissions-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetBucketVersioning",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::frexida-terraform-state",
        "arn:aws:s3:::frexida-terraform-state/*"
      ]
    },
    {
      "Sid": "DynamoDBLockAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-northeast-1:${AWS_ACCOUNT_ID}:table/terraform-lock"
    },
    {
      "Sid": "CodeBuildManagement",
      "Effect": "Allow",
      "Action": [
        "codebuild:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:UpdateRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:UpdateAssumeRolePolicy",
        "iam:ListInstanceProfilesForRole",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchManagement",
      "Effect": "Allow",
      "Action": [
        "logs:*",
        "cloudwatch:*",
        "events:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SNSManagement",
      "Effect": "Allow",
      "Action": [
        "sns:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:UpdateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:TagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3BuildArtifacts",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBRetryTable",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:UpdateTable",
        "dynamodb:TagResource",
        "dynamodb:UntagResource",
        "dynamodb:ListTables",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:UpdateTimeToLive"
      ],
      "Resource": "*"
    }
  ]
}
EOF
echo "✅ Permissions policy created at /tmp/permissions-policy.json"

# Step 5: Attach Policy to Role
echo ""
echo "Step 5: Attaching Policy to Role..."

# Check if policy exists
if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" 2>/dev/null; then
    echo "⚠️  Policy already exists, updating..."
    POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

    # Create new version
    aws iam create-policy-version \
        --policy-arn "${POLICY_ARN}" \
        --policy-document file:///tmp/permissions-policy.json \
        --set-as-default
    echo "✅ Policy updated"
else
    # Create new policy
    aws iam create-policy \
        --policy-name "${POLICY_NAME}" \
        --policy-document file:///tmp/permissions-policy.json \
        --description "Permissions for GitHub Actions to manage infrastructure"
    POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    echo "✅ Policy created"
fi

# Attach policy to role
aws iam attach-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-arn "${POLICY_ARN}"
echo "✅ Policy attached to role"

# Step 6: Create S3 Backend Resources
echo ""
echo "Step 6: Creating S3 Backend Resources..."

# Create S3 bucket for Terraform state
if aws s3api head-bucket --bucket "frexida-terraform-state" 2>/dev/null; then
    echo "✅ S3 bucket 'frexida-terraform-state' already exists"
else
    aws s3api create-bucket \
        --bucket "frexida-terraform-state" \
        --region ap-northeast-1 \
        --create-bucket-configuration LocationConstraint=ap-northeast-1

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "frexida-terraform-state" \
        --versioning-configuration Status=Enabled

    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "frexida-terraform-state" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'

    echo "✅ S3 bucket created with versioning and encryption"
fi

# Create DynamoDB table for state locking
if aws dynamodb describe-table --table-name "terraform-lock" 2>/dev/null; then
    echo "✅ DynamoDB table 'terraform-lock' already exists"
else
    aws dynamodb create-table \
        --table-name "terraform-lock" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region ap-northeast-1

    echo "✅ DynamoDB table created"
fi

# Output summary
echo ""
echo "=================================================="
echo "✅ Setup Complete!"
echo "=================================================="
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Add the following secrets to your GitHub repository:"
echo "   (Settings -> Secrets and variables -> Actions)"
echo ""
echo "   AWS_ROLE_ARN:"
echo "   arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo ""
echo "   GH_PAT:"
echo "   Create a Personal Access Token with 'repo' scope at:"
echo "   https://github.com/settings/tokens/new"
echo ""
echo "2. Add the following variable:"
echo "   AI_AGENT_ENDPOINT:"
echo "   https://api.frexida.com/ci-result"
echo ""
echo "3. Optional: Add AI_AGENT_API_KEY if your API requires authentication"
echo ""
echo "=================================================="
echo "🎉 Your AWS infrastructure is ready for GitHub Actions!"