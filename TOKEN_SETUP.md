# GitHub Personal Access Token セットアップ

## トークンの設定方法

提供されたGitHub Personal Access Tokenを環境変数に設定してください。

```bash
# 以下のコマンドを実行してトークンを設定
# (実際のトークン値は別途提供されています)
export GITHUB_PAT="<provided-token>"
export TF_VAR_github_token="$GITHUB_PAT"
```

## 必要な権限

GitHub Personal Access Tokenには以下の権限が必要です：

### Classic Token の場合
- ✅ **repo** - すべてのリポジトリ操作権限

### Fine-grained Token の場合
- **Contents**: Read & Write
- **Metadata**: Read

## デプロイ時の使用方法

```bash
# 1. トークンを環境変数に設定（上記参照）

# 2. デプロイスクリプトを実行
cd terraform
./deploy.sh

# または手動で実行
terraform init
terraform plan
terraform apply
```

## セキュリティ注意事項

- トークンは環境変数として保存し、ファイルには記載しない
- `.bashrc`や`.zshrc`に記載する場合は、ファイルの権限を適切に設定
- 定期的にトークンをローテーション
- 不要になったトークンは速やかに無効化

## トラブルシューティング

### "GITHUB_PAT environment variable not set" エラー

```bash
# トークンが設定されているか確認
echo $GITHUB_PAT

# 設定されていない場合は再度設定
export GITHUB_PAT="<provided-token>"
```

### 権限エラー

GitHubでトークンの権限を確認：
1. GitHub → Settings → Developer settings
2. Personal access tokens → 該当トークンを確認
3. 必要に応じて権限を更新