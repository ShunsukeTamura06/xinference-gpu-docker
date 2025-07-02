# Xinference GPU Dockerfile (amd64)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0

# プロキシ設定（環境変数で設定）
ENV HTTP_PROXY=http://hn02-outbound.gm.internal:8080
ENV HTTPS_PROXY=http://hn02-outbound.gm.internal:8080
ENV http_proxy=http://hn02-outbound.gm.internal:8080
ENV https_proxy=http://hn02-outbound.gm.internal:8080

# 基本パッケージのインストール
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリの作成
WORKDIR /app

# pipのアップグレード
RUN python3 -m pip install --upgrade pip

# 必要なPythonパッケージのインストール
RUN pip install --no-cache-dir \
    torch==2.0.1+cu118 \
    torchvision==0.15.2+cu118 \
    torchaudio==2.0.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Xinferenceのインストール
RUN pip install --no-cache-dir \
    xinference[all] \
    accelerate \
    transformers \
    sentence-transformers

# ポートの公開
EXPOSE 9997

# Xinferenceサーバーの起動
CMD ["xinference-local", "--host", "0.0.0.0", "--port", "9997"]