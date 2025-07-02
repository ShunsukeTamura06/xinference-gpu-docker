# Xinference GPU Docker Setup for AWS T4G Instances

AWS T4G GPU搭載インスタンス（ARM64）上でDockerを使用してXinferenceサーバーをGPU対応で動作させるための設定です。プロキシ環境での使用にも対応しています。

## 📋 前提条件

- AWS T4G GPU搭載インスタンス（g5g.xlarge, g5g.2xlarge など）
- Ubuntu 20.04+ または Amazon Linux 2
- Docker と Docker Compose がインストール済み
- NVIDIA GPU ドライバーとCUDA 12.9がインストール済み
- 企業ネットワーク環境の場合はプロキシ設定

## 🔧 T4G GPU の特徴

- **ARM64アーキテクチャ**: ネイティブARM64コンテナを使用
- **CUDA 12.9対応**: ホストのCUDAインストールを活用
- **高効率**: ARM64最適化されたPyTorchを使用

## 🌐 プロキシ環境での設定

企業ネットワーク環境の場合、以下のプロキシ設定を行ってください：

### 1. 環境変数の設定

```bash
export HTTP_PROXY=http://hn02-outbound.gm.internal:8080
export HTTPS_PROXY=http://hn02-outbound.gm.internal:8080
export http_proxy=http://hn02-outbound.gm.internal:8080
export https_proxy=http://hn02-outbound.gm.internal:8080
export NO_PROXY=localhost,127.0.0.1,.internal,.local
export no_proxy=localhost,127.0.0.1,.internal,.local
```

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/ShunsukeTamura06/xinference-gpu-docker.git
cd xinference-gpu-docker
```

### 2. CUDA環境確認

```bash
# CUDA バージョン確認
nvcc --version

# GPU確認
nvidia-smi

# CUDA インストールパス確認
ls -la /usr/local/cuda/
```

### 3. プロキシ設定（企業環境の場合）

```bash
# プロキシ設定
export HTTP_PROXY=http://hn02-outbound.gm.internal:8080
export HTTPS_PROXY=http://hn02-outbound.gm.internal:8080
```

### 4. セットアップスクリプトの実行

```bash
chmod +x setup.sh
./setup.sh
```

### 5. Xinferenceサーバーの起動

```bash
docker compose up -d
```

### 6. 動作確認

```bash
# ログの確認
docker compose logs -f xinference

# GPU認識確認
curl http://localhost:9997/v1/models
```

## 📁 ファイル構成

```
xinference-gpu-docker/
├── Dockerfile              # ARM64用Dockerファイル
├── docker-compose.yml      # T4G GPU対応設定
├── setup.sh               # 環境セットアップスクリプト
├── models/                # モデルキャッシュディレクトリ
├── logs/                  # ログディレクトリ
└── README.md              # このファイル
```

## 🔧 設定のカスタマイズ

### プロキシ設定の変更

`docker-compose.yml`でプロキシURLを変更：

```yaml
environment:
  - HTTP_PROXY=http://your-proxy:port
  - HTTPS_PROXY=http://your-proxy:port
```

### CUDA パスの変更

ホストのCUDAインストールパスが異なる場合：

```yaml
volumes:
  - /your/cuda/path:/usr/local/cuda:ro
```

### メモリ制限の設定

```yaml
deploy:
  resources:
    limits:
      memory: 8G
```

## 📊 使用方法

### Xinference Web UI へのアクセス

ブラウザで `http://YOUR_SERVER_IP:9997` にアクセス

### API経由での利用

```bash
# 利用可能なモデルの確認
curl http://localhost:9997/v1/models

# モデルの起動例
curl -X POST http://localhost:9997/v1/models \
  -H "Content-Type: application/json" \
  -d '{
    "model_name": "vicuna-v1.3",
    "model_size_in_billions": 7
  }'
```

### Python クライアントでの利用

```python
from xinference.client import Client

client = Client("http://localhost:9997")

# モデルの起動
model = client.launch_model(
    model_name="vicuna-v1.3",
    model_size_in_billions=7
)

# 推論の実行
response = model.chat(
    "こんにちは、元気ですか？"
)
print(response)
```

## 🔍 トラブルシューティング

### T4G GPU特有の問題

#### CUDA認識されない場合

```bash
# ホストのCUDA確認
nvcc --version
ls -la /usr/local/cuda/

# コンテナ内でCUDA確認
docker compose exec xinference nvcc --version
docker compose exec xinference python3 -c "import torch; print(torch.cuda.is_available())"
```

#### ARM64パッケージエラー

```bash
# ARM64用パッケージが正しくインストールされているか確認
docker compose exec xinference uname -a
docker compose exec xinference python3 -c "import torch; print(torch.__version__)"
```

### 一般的な問題

#### プロキシ関連エラー

```bash
# プロキシ設定確認
echo $HTTP_PROXY

# 手動でプロキシ設定
export HTTP_PROXY=http://hn02-outbound.gm.internal:8080
export HTTPS_PROXY=http://hn02-outbound.gm.internal:8080

# 再ビルド
docker compose build --no-cache
```

#### メモリ不足エラー

```bash
# 現在のメモリ使用量確認
docker stats xinference-gpu-server
```

## 📈 T4G GPU最適化

### 1. ARM64最適化されたライブラリ使用

```yaml
volumes:
  - /usr/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu:ro
```

### 2. CUDA 12.9活用

```yaml
environment:
  - CUDA_HOME=/usr/local/cuda
  - LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

### 3. T4G GPU推奨設定

```yaml
environment:
  - CUDA_VISIBLE_DEVICES=0
  - NVIDIA_VISIBLE_DEVICES=all
```

## 🛠️ コマンド一覧

| コマンド | 説明 |
|---------|------|
| `docker compose up -d` | サーバー起動（バックグラウンド） |
| `docker compose down` | サーバー停止 |
| `docker compose logs -f` | ログリアルタイム表示 |
| `docker compose ps` | コンテナ状態確認 |
| `docker compose restart` | サーバー再起動 |
| `docker compose build --no-cache` | 強制再ビルド |

## 🆘 サポート

問題が発生した場合：

1. [Issues](https://github.com/ShunsukeTamura06/xinference-gpu-docker/issues) で既存の問題を確認
2. 新しいIssueを作成（ログと環境情報を含める）
3. [Xinference公式ドキュメント](https://inference.readthedocs.io/) を参照

## 📄 ライセンス

MIT License

## 🤝 コントリビューション

プルリクエストやIssueは歓迎します！