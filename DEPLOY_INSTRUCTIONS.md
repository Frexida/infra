# Self-Healing CI/CD Pipeline デプロイ手順

## 前提条件

1. AWS CLIがインストールされ、認証情報が設定されていること
2. Terraformがインストールされていること（v1.5以上）
3. GitHub Personal Access Tokenが作成されていること

## デプロイ手順

### 1. GitHub Personal Access Tokenを環境変数に設定

```bash
# GitHub Personal Access Tokenを環境変数に設定
export GITHUB_PAT="your-github-token"  # 実際のトークンに置き換えてください
```

### 2. デプロイスクリプトを実行

```bash
cd terraform
./deploy.sh
```

スクリプトが以下を順番に実行します：
1. 環境変数の確認
2. AI AgentエンドポイントURLの入力
3. GitHubリポジトリURLの入力
4. Terraformの初期化と実行
5. Webhook URLの出力

### 3. GitHub Webhookを設定

Terraformの出力からWebhook URLをコピーして、GitHubリポジトリに設定：

1. リポジトリの Settings → Webhooks
2. Add webhook をクリック
3. Payload URL: Terraform出力のURLを貼り付け
4. Content type: `application/json`
5. Which events?: `Just the push event`を選択
6. Active: チェック
7. Add webhook をクリック

### 4. buildspec.ymlをリポジトリに追加

`modules/self-healing-cicd/buildspec.yml`をプロジェクトのルートディレクトリにコピーして、プロジェクトに合わせてカスタマイズしてください。

## 環境変数での実行（代替方法）

```bash
# 必要な環境変数を設定
export TF_VAR_github_token="$GITHUB_PAT"
export TF_VAR_github_repository="https://github.com/Frexida/your-repo.git"
export TF_VAR_ai_agent_endpoint="https://your-ai-agent.com/ci_result"

# Terraform実行
cd terraform
terraform init
terraform plan
terraform apply

# Webhook URL取得
terraform output -raw webhook_url
```

## 確認方法

1. CloudWatchダッシュボードで監視
   ```bash
   terraform output dashboard_url
   ```

2. 意図的にビルドエラーを起こしてテスト
   - エラーのあるコードをプッシュ
   - CodeBuildがトリガーされることを確認
   - Lambda経由でAI AgentにPOSTが送信されることを確認

## トラブルシューティング

### エラー: GITHUB_PAT environment variable not set
GitHub Personal Access Tokenを環境変数に設定してください：
```bash
export GITHUB_PAT="your-github-token"
```

### エラー: AWS credentials not configured
AWS認証情報を設定してください：
```bash
aws configure
```

### Webhookが動作しない
1. GitHub Webhook設定を確認
2. CodeBuildプロジェクトのソース設定を確認
3. CloudWatch Logsでエラーを確認