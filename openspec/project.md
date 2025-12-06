# Project Context

## Purpose
毎日1本の小さなアプリを開発し、GitHubへのpushだけで自動ビルド・デプロイできる環境を整備する。開発はAI主体で進め、共通のテンプレートとCI/CDで手戻りを最小化する。

## Tech Stack
- 開発/ローカル: Docker, Docker Compose
- フロント: Vite + React（ビルド成果物をCloudflare Pagesへ配信）
- バックエンド: Node.js + Express（コンテナ化してAWS ECS/Fargateへ配置）
- CI/CD: GitHub Actions（mainブランチpushで自動ビルド・テスト・デプロイ）
- インフラ: Cloudflare（DNS/TLS/Pages）, AWS ECS/Fargate + ECR, CloudWatch

## Project Conventions

### Code Style
- JS/TSはPrettier/ESLint準拠を基本とし、テンプレートに設定を同梱する予定。

### Architecture Patterns
- フロント（Pages）+ バックエンド（ECS）の2面デプロイ。バックエンドはシンプルなAPIサーバとし、環境変数で設定。

### Testing Strategy
- GitHub Actionsでユニット/スモークテストを実行。デプロイ後のHTTPスモークで失敗時はロールバック/停止。

### Git Workflow
- mainブランチへのpushで自動デプロイ。PRベース運用は任意だが、main保護とレビューが望ましい。

## Domain Context
- ドメインはCloudflareで管理。`{app}.example.com` 形式（実ドメインに置換）でAppsを割り当て、TLSはCloudflareで終端。Pagesプロジェクトは `{app}-pages` を基本命名とする。

## Important Constraints
- AI主導で作業するため、ローカル手順や手動オペレーションを最小化し、push一発で完結するパスを優先。
- Secretsは長期キーを避け、GitHub OIDCでAWSへAssumeRole。Cloudflare Pages用トークンはリポジトリシークレットに最小権限で格納。

## External Dependencies
- Cloudflare Pages, Cloudflare DNS/TLS
- AWS ECS/Fargate, ECR, CloudWatch
- GitHub Actions (OIDC for AWS, トークンでCloudflare操作)
