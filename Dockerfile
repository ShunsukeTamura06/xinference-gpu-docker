# Xinference GPU Dockerfile (amd64)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0

# 基本ツールのみインストール（シンプルに）
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリの作成
WORKDIR /app

# エントリーポイントスクリプトを作成
RUN echo '#!/bin/bash\n\
export HTTP_PROXY=http://hn02-outbound.gm.internal:8080\n\
export HTTPS_PROXY=http://hn02-outbound.gm.internal:8080\n\
export http_proxy=http://hn02-outbound.gm.internal:8080\n\
export https_proxy=http://hn02-outbound.gm.internal:8080\n\
\n\
echo "Installing packages with proxy..."\n\
apt-get -o Acquire::http::Proxy="$HTTP_PROXY" -o Acquire::https::Proxy="$HTTPS_PROXY" update\n\
apt-get -o Acquire::http::Proxy="$HTTP_PROXY" -o Acquire::https::Proxy="$HTTPS_PROXY" install -y python3 python3-pip python3-dev build-essential git\n\
\n\
echo "Installing Python packages..."\n\
python3 -m pip install --upgrade pip\n\
pip install torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2+cu118 --extra-index-url https://download.pytorch.org/whl/cu118\n\
pip install xinference[all] accelerate transformers sentence-transformers\n\
\n\
echo "Starting Xinference server..."\n\
exec xinference-local --host 0.0.0.0 --port 9997\n\
' > /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

# ポートの公開
EXPOSE 9997

# エントリーポイント
ENTRYPOINT ["/app/entrypoint.sh"]