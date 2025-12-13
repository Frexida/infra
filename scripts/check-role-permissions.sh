#!/bin/bash

# TerraformExecutionRoleの権限を確認するスクリプト

AWS_ACCOUNT_ID="522579114515"
ROLE_NAME="TerraformExecutionRole"

echo "🔍 TerraformExecutionRoleの権限を確認中..."
echo "=================================="
echo ""

echo "1. アタッチされているポリシー:"
aws iam list-attached-role-policies --role-name "${ROLE_NAME}" --output table

echo ""
echo "2. インラインポリシー:"
aws iam list-role-policies --role-name "${ROLE_NAME}" --output table

echo ""
echo "3. TerraformFullAccessポリシーの確認:"
if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/TerraformFullAccess" 2>/dev/null; then
    echo "✅ TerraformFullAccessポリシーが存在します"

    # 最新バージョンを取得
    LATEST_VERSION=$(aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/TerraformFullAccess" --query 'Policy.DefaultVersionId' --output text)

    echo ""
    echo "4. ポリシーの内容（バージョン: ${LATEST_VERSION}）:"
    aws iam get-policy-version \
        --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/TerraformFullAccess" \
        --version-id "${LATEST_VERSION}" \
        --query 'PolicyVersion.Document' \
        --output json | python3 -m json.tool | grep -A 2 -B 2 "secretsmanager\|iam:CreateRole\|SNS:TagResource"
else
    echo "❌ TerraformFullAccessポリシーが存在しません"
fi

echo ""
echo "=================================="
echo ""
echo "必要な権限の確認:"
echo "- secretsmanager:CreateSecret ... $(aws iam get-policy-version --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/TerraformFullAccess" --version-id "${LATEST_VERSION}" --query 'PolicyVersion.Document' --output text 2>/dev/null | grep -q 'secretsmanager:CreateSecret' && echo '✅' || echo '❌')"
echo "- iam:CreateRole ... $(aws iam get-policy-version --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/TerraformFullAccess" --version-id "${LATEST_VERSION}" --query 'PolicyVersion.Document' --output text 2>/dev/null | grep -q 'iam:CreateRole' && echo '✅' || echo '❌')"
echo "- sns:TagResource ... $(aws iam get-policy-version --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/TerraformFullAccess" --version-id "${LATEST_VERSION}" --query 'PolicyVersion.Document' --output text 2>/dev/null | grep -q 'sns:\*\|sns:TagResource' && echo '✅' || echo '❌')"