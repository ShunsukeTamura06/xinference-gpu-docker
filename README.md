# Xinference GPU Docker Setup

AWS GPU搭載インスタンス（arm64）上でDockerを使用してamd64環境でXinferenceサーバーをGPU対応で動作させるための設定です。

## 📋 前提条件

- AWS GPU搭載インスタンス（例：g4dn.xlarge, p3.2xlarge など）
- Ubuntu 20.04+ または Amazon Linux 2
- Docker と Docker Compose がインストール済み
- NVIDIA GPU ドライバーがインストール済み

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/ShunsukeTamura06/xinference-gpu-docker.git
cd xinference-gpu-docker
```

### 2. セットアップスクリプトの実行

```bash
chmod +x setup.sh
./setup.sh
```

### 3. Xinferenceサーバーの起動

```bash
docker-compose up -d
```

### 4. 動作確認

```bash
# ログの確認
docker-compose logs -f xinference

# ヘルスチェック
curl http://localhost:9997/health
```

## 📁 ファイル構成

```
xinference-gpu-docker/
├── Dockerfile              # Xinference GPU用Dockerファイル
├── docker-compose.yml      # Docker Compose設定
├── setup.sh               # 環境セットアップスクリプト
├── models/                # モデルキャッシュディレクトリ
├── logs/                  # ログディレクトリ
└── README.md              # このファイル
```

## 🔧 設定のカスタマイズ

### ポート番号の変更

`docker-compose.yml`の`ports`セクションを編集：

```yaml
ports:
  - "YOUR_PORT:9997"
```

### GPU設定の変更

複数GPUを使用する場合、`docker-compose.yml`を編集：

```yaml
environment:
  - CUDA_VISIBLE_DEVICES=0,1  # 使用するGPU番号
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

### GPU認識されない場合

```bash
# GPU確認
nvidia-smi

# NVIDIA Container Toolkit確認
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

### メモリ不足エラー

モデルサイズを小さくするか、より大きなインスタンスタイプを使用：

```bash
# 現在のメモリ使用量確認
docker stats xinference-gpu-docker_xinference_1
```

### arm64プラットフォームエラー

`docker-compose.yml`で明示的にamd64を指定：

```yaml
platform: linux/amd64
```

### ポート衝突

別のポートを使用：

```yaml
ports:
  - "9998:9997"  # 9998ポートを使用
```

## 📈 パフォーマンス最適化

### 1. SHMサイズの増加

```yaml
shm_size: '2g'
```

### 2. キャッシュボリュームの最適化

SSDストレージの使用を推奨：

```yaml
volumes:
  - /mnt/ssd/models:/root/.xinference/cache
```

### 3. 並列処理の設定

```yaml
environment:
  - OMP_NUM_THREADS=4
  - XINFERENCE_MODEL_CACHE_SIZE=10
```

## 🛠️ コマンド一覧

| コマンド | 説明 |
|---------|------|
| `docker-compose up -d` | サーバー起動（バックグラウンド） |
| `docker-compose down` | サーバー停止 |
| `docker-compose logs -f` | ログリアルタイム表示 |
| `docker-compose ps` | コンテナ状態確認 |
| `docker-compose restart` | サーバー再起動 |
| `docker-compose pull` | イメージ更新 |

## 🆘 サポート

問題が発生した場合：

1. [Issues](https://github.com/ShunsukeTamura06/xinference-gpu-docker/issues) で既存の問題を確認
2. 新しいIssueを作成（ログと環境情報を含める）
3. [Xinference公式ドキュメント](https://inference.readthedocs.io/) を参照

## 📄 ライセンス

MIT License

## 🤝 コントリビューション

プルリクエストやIssueは歓迎します！