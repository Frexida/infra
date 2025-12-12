#!/bin/bash

# IAMロール作成スクリプト（OIDC設定済み前提）
# 使用方法: ./create-iam-role.sh

set -e

# 設定
AWS_ACCOUNT_ID="522579114515"
ROLE_NAME="github-actions-terraform-role"

echo "🚀 GitHub Actions用のIAMロール作成"
echo "=================================="
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "Role Name: $ROLE_NAME"
echo ""

# Step 1: 信頼ポリシーをブランチも含めて更新
echo "Step 1: 信頼ポリシーを作成..."
cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:Frexida/infra:*",
            "repo:Frexida/picture-calendar:*",
            "repo:Frexida/homepage:*",
            "repo:Frexida/app-foobar:*"
          ]
        }
      }
    }
  ]
}
EOF
echo "✅ 信頼ポリシー作成完了"

# Step 2: IAMロール作成
echo ""
echo "Step 2: IAMロール作成..."
if aws iam get-role --role-name "${ROLE_NAME}" 2>/dev/null; then
    echo "⚠️  ロールは既に存在します。信頼ポリシーを更新..."
    aws iam update-assume-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-document file:///tmp/trust-policy.json
    echo "✅ 信頼ポリシー更新完了"
else
    aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "GitHub Actions用のTerraform実行ロール"
    echo "✅ IAMロール作成完了"
fi

# Step 3: 権限ポリシー作成（CodeBuild, Lambda等に必要な権限）
echo ""
echo "Step 3: 権限ポリシー作成..."
cat > /tmp/permissions.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformState",
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": [
        "arn:aws:s3:::frexida-terraform-state",
        "arn:aws:s3:::frexida-terraform-state/*",
        "arn:aws:dynamodb:ap-northeast-1:${AWS_ACCOUNT_ID}:table/terraform-lock"
      ]
    },
    {
      "Sid": "SelfHealingCICD",
      "Effect": "Allow",
      "Action": [
        "codebuild:*",
        "lambda:*",
        "iam:*",
        "logs:*",
        "cloudwatch:*",
        "events:*",
        "sns:*",
        "secretsmanager:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# 管理ポリシーとして作成
POLICY_NAME="github-actions-terraform-policy"
if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" 2>/dev/null; then
    echo "⚠️  ポリシーは既に存在します"
    POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
else
    aws iam create-policy \
        --policy-name "${POLICY_NAME}" \
        --policy-document file:///tmp/permissions.json \
        --description "GitHub Actions Terraform実行権限"
    POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    echo "✅ ポリシー作成完了"
fi

# ポリシーをロールにアタッチ
aws iam attach-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-arn "${POLICY_ARN}" 2>/dev/null || true
echo "✅ ポリシーアタッチ完了"

# Step 4: S3バケットとDynamoDBテーブル作成
echo ""
echo "Step 4: Terraformバックエンドリソース作成..."

# S3バケット
if aws s3api head-bucket --bucket "frexida-terraform-state" 2>/dev/null; then
    echo "✅ S3バケット 'frexida-terraform-state' は既に存在"
else
    aws s3api create-bucket \
        --bucket "frexida-terraform-state" \
        --region ap-northeast-1 \
        --create-bucket-configuration LocationConstraint=ap-northeast-1

    aws s3api put-bucket-versioning \
        --bucket "frexida-terraform-state" \
        --versioning-configuration Status=Enabled

    echo "✅ S3バケット作成完了"
fi

# DynamoDBテーブル
if aws dynamodb describe-table --table-name "terraform-lock" --region ap-northeast-1 2>/dev/null; then
    echo "✅ DynamoDBテーブル 'terraform-lock' は既に存在"
else
    aws dynamodb create-table \
        --table-name "terraform-lock" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region ap-northeast-1

    echo "✅ DynamoDBテーブル作成完了"
fi

echo ""
echo "=================================="
echo "✅ セットアップ完了！"
echo "=================================="
echo ""
echo "📝 GitHubリポジトリに以下を設定してください："
echo ""
echo "1. Settings → Secrets and variables → Actions → Secrets"
echo ""
echo "   AWS_ROLE_ARN:"
echo "   arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo ""
echo "   GH_PAT:"
echo "   https://github.com/settings/tokens/new"
echo "   （repoスコープ付きのPersonal Access Token）"
echo ""
echo "2. Settings → Secrets and variables → Actions → Variables"
echo ""
echo "   AI_AGENT_ENDPOINT:"
echo "   https://api.frexida.com/ci-result"
echo ""
echo "=================================="