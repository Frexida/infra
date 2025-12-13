#!/bin/bash

# TerraformExecutionRoleの権限を更新するスクリプト

set -e

AWS_ACCOUNT_ID="522579114515"
ROLE_NAME="TerraformExecutionRole"
POLICY_NAME="TerraformFullAccess"

echo "🔧 TerraformExecutionRoleの権限を更新中..."
echo "=================================="
echo ""

# 新しい権限ポリシーを作成
cat > /tmp/terraform-permissions.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateManagement",
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
      "Sid": "IAMManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:UpdateRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicies",
        "iam:ListPolicyVersions",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicyVersion",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:UpdateAssumeRolePolicy",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListInstanceProfilesForRole"
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
        "secretsmanager:TagResource",
        "secretsmanager:PutSecretValue",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "*"
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
      "Sid": "S3GeneralAccess",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketLifecycleConfiguration",
        "s3:GetBucketLifecycleConfiguration",
        "s3:ListAllMyBuckets",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBGeneralAccess",
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
        "dynamodb:UpdateTimeToLive",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": "*"
    }
  ]
}
EOF

echo "Step 1: ポリシーを作成または更新..."

# 既存のポリシーを確認
if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" 2>/dev/null; then
    echo "既存のポリシーを更新中..."
    # 新しいバージョンを作成
    aws iam create-policy-version \
        --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" \
        --policy-document file:///tmp/terraform-permissions.json \
        --set-as-default
    echo "✅ ポリシー更新完了"
else
    echo "新しいポリシーを作成中..."
    aws iam create-policy \
        --policy-name "${POLICY_NAME}" \
        --policy-document file:///tmp/terraform-permissions.json \
        --description "Full Terraform execution permissions for CI/CD"
    echo "✅ ポリシー作成完了"
fi

POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

echo ""
echo "Step 2: ポリシーをロールにアタッチ..."

# 既にアタッチされているか確認
if aws iam list-attached-role-policies --role-name "${ROLE_NAME}" | grep -q "${POLICY_NAME}"; then
    echo "✅ ポリシーは既にアタッチされています"
else
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn "${POLICY_ARN}"
    echo "✅ ポリシーをロールにアタッチ完了"
fi

echo ""
echo "=================================="
echo "✅ 権限更新完了！"
echo "=================================="
echo ""
echo "GitHub Actionsを再実行してください："
echo ""
echo "  gh workflow run platform-deploy.yml --ref main"
echo ""
echo "または、GitHub UIから再実行："
echo "  https://github.com/Frexida/infra/actions"
echo ""