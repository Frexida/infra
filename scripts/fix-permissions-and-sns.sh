#!/bin/bash

set -e

AWS_ACCOUNT_ID="522579114515"
ROLE_NAME="TerraformExecutionRole"
POLICY_NAME="TerraformFullAccess"

echo "🔧 権限の追加修正を実行中..."
echo "=================================="
echo ""

# Step 1: Secrets Manager権限を追加
echo "Step 1: Secrets Manager GetResourcePolicy権限を追加..."

cat > /tmp/additional-permissions.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SecretsManagerFullAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# 既存のポリシーを取得して更新
aws iam get-policy-version \
    --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" \
    --version-id "$(aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" --query 'Policy.DefaultVersionId' --output text)" \
    --query 'PolicyVersion.Document' \
    --output json > /tmp/current-policy.json

# Python3を使用してポリシーをマージ（Secrets Managerセクションを完全な権限に更新）
python3 << 'PYTHON'
import json

with open('/tmp/current-policy.json', 'r') as f:
    policy = json.load(f)

# Secrets Manager権限を完全に置き換え
for statement in policy['Statement']:
    if statement.get('Sid') == 'SecretsManagerAccess':
        statement['Action'] = ["secretsmanager:*"]
        break
else:
    # 存在しない場合は追加
    policy['Statement'].append({
        "Sid": "SecretsManagerFullAccess",
        "Effect": "Allow",
        "Action": ["secretsmanager:*"],
        "Resource": "*"
    })

with open('/tmp/updated-policy.json', 'w') as f:
    json.dump(policy, f, indent=2)
PYTHON

echo "新しいポリシーバージョンを作成中..."
aws iam create-policy-version \
    --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" \
    --policy-document file:///tmp/updated-policy.json \
    --set-as-default

echo "✅ Secrets Manager権限を更新完了"

# Step 2: 既存のSNSトピックとポリシーをクリーンアップ
echo ""
echo "Step 2: 既存のSNSリソースをクリーンアップ..."

# SNSトピックが存在する場合は削除
if aws sns get-topic-attributes --topic-arn "arn:aws:sns:ap-northeast-1:${AWS_ACCOUNT_ID}:frexida-self-healing-pipeline-build-failures" 2>/dev/null; then
    echo "既存のSNSトピックを削除中..."
    aws sns delete-topic --topic-arn "arn:aws:sns:ap-northeast-1:${AWS_ACCOUNT_ID}:frexida-self-healing-pipeline-build-failures"
    echo "✅ SNSトピック削除完了"
else
    echo "✅ 既存のSNSトピックなし"
fi

# Step 3: 部分的に作成されたリソースをクリーンアップ
echo ""
echo "Step 3: 部分的に作成されたリソースをクリーンアップ..."

# Secrets Managerシークレットの削除（存在する場合）
if aws secretsmanager describe-secret --secret-id "frexida-self-healing-pipeline/github-token" --region ap-northeast-1 2>/dev/null; then
    echo "Secrets Managerシークレットを削除中..."
    aws secretsmanager delete-secret \
        --secret-id "frexida-self-healing-pipeline/github-token" \
        --force-delete-without-recovery \
        --region ap-northeast-1
    echo "✅ シークレット削除完了"
fi

echo ""
echo "=================================="
echo "✅ 修正完了！"
echo "=================================="
echo ""
echo "GitHub Actionsを再実行してください："
echo ""
echo "  gh run rerun 20182760608 --failed"
echo ""