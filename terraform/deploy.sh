#!/bin/bash

# Self-Healing CI/CD Pipeline デプロイスクリプト
# 使用方法: ./deploy.sh

set -e

echo "=========================================="
echo "Self-Healing CI/CD Pipeline Deployment"
echo "=========================================="

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 環境変数チェック
echo -e "${YELLOW}Checking environment variables...${NC}"

# GitHub Token設定（環境変数から取得）
if [ -z "$GITHUB_PAT" ]; then
    echo -e "${RED}Error: GITHUB_PAT environment variable not set${NC}"
    echo "Please set your GitHub Personal Access Token:"
    echo "  export GITHUB_PAT='your-github-token'"
    exit 1
fi
export TF_VAR_github_token="$GITHUB_PAT"

# AI Agent Endpoint確認
if [ -z "$TF_VAR_ai_agent_endpoint" ]; then
    echo -e "${YELLOW}AI Agent Endpoint not set. Please enter the endpoint URL:${NC}"
    read -p "AI Agent Endpoint (e.g., https://api.example.com/ci_result): " endpoint
    export TF_VAR_ai_agent_endpoint="$endpoint"
fi

# GitHub Repository確認
if [ -z "$TF_VAR_github_repository" ]; then
    echo -e "${YELLOW}GitHub Repository not set. Please enter the repository URL:${NC}"
    read -p "GitHub Repository (e.g., https://github.com/org/repo.git): " repo
    export TF_VAR_github_repository="$repo"
fi

# AWS認証確認
echo -e "${YELLOW}Checking AWS credentials...${NC}"
aws sts get-caller-identity > /dev/null 2>&1 || {
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Please configure AWS credentials using:"
    echo "  aws configure"
    echo "or set environment variables:"
    echo "  export AWS_ACCESS_KEY_ID=..."
    echo "  export AWS_SECRET_ACCESS_KEY=..."
    echo "  export AWS_REGION=ap-northeast-1"
    exit 1
}

echo -e "${GREEN}AWS credentials OK${NC}"
aws sts get-caller-identity --query Account --output text

# Terraform初期化
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

# Terraform計画
echo -e "${YELLOW}Creating Terraform plan...${NC}"
terraform plan -out=tfplan

# デプロイ確認
echo -e "${YELLOW}=========================================="
echo "Review the plan above."
echo -e "Do you want to apply these changes? (yes/no)${NC}"
read -p "> " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

# Terraform適用
echo -e "${YELLOW}Applying Terraform configuration...${NC}"
terraform apply tfplan

# 出力取得
echo -e "${GREEN}=========================================="
echo "Deployment completed successfully!"
echo "==========================================${NC}"

# 重要な出力を表示
echo -e "${YELLOW}Important outputs:${NC}"
echo ""
echo -e "${GREEN}Webhook URL (Add this to GitHub):${NC}"
terraform output -raw webhook_url 2>/dev/null || echo "Not available"
echo ""
echo ""
echo -e "${GREEN}CloudWatch Dashboard:${NC}"
terraform output -raw dashboard_url 2>/dev/null || echo "Not available"
echo ""

# GitHub Webhook設定手順
echo -e "${YELLOW}=========================================="
echo "Next steps:"
echo "1. Go to your GitHub repository settings"
echo "2. Navigate to Settings > Webhooks"
echo "3. Click 'Add webhook'"
echo "4. Paste the Webhook URL shown above"
echo "5. Set Content type to 'application/json'"
echo "6. Select 'Just the push event'"
echo "7. Click 'Add webhook'"
echo "==========================================${NC}"

# buildspec.yml確認
echo -e "${YELLOW}Don't forget to add buildspec.yml to your repository root!${NC}"
echo "You can use the example from: modules/self-healing-cicd/buildspec.yml"

echo -e "${GREEN}Deployment complete!${NC}"