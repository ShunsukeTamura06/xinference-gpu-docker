# Xinference GPU Dockerfile (amd64)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# プロキシ設定（ビルド時）
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG http_proxy
ARG https_proxy
ARG no_proxy

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0
ENV PATH="/opt/miniconda3/bin:$PATH"

# プロキシ環境変数を設定（必要に応じて）
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV NO_PROXY=${NO_PROXY}
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
ENV no_proxy=${no_proxy}

# apt-get用のプロキシ設定
RUN if [ -n "$HTTP_PROXY" ]; then \
        echo "Acquire::http::Proxy \"$HTTP_PROXY\";" > /etc/apt/apt.conf.d/01proxy && \
        echo "Acquire::https::Proxy \"$HTTPS_PROXY\";" >> /etc/apt/apt.conf.d/01proxy; \
    fi

# 基本パッケージのインストール
RUN apt-get update && \
    apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Miniconda3のインストール（プロキシ対応）
RUN if [ -n "$HTTP_PROXY" ]; then \
        wget --proxy=on --http-proxy="$HTTP_PROXY" --https-proxy="$HTTPS_PROXY" \
             --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh; \
    else \
        wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh; \
    fi && \
    /bin/bash ~/miniconda.sh -b -p /opt/miniconda3 && \
    rm ~/miniconda.sh && \
    /opt/miniconda3/bin/conda clean -ya

# Python環境の設定
RUN conda install python=3.10 -y && \
    conda clean -ya

# 作業ディレクトリの作成
WORKDIR /app

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

# ヘルスチェック用エンドポイント
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9997/v1/models || exit 1

# Xinferenceサーバーの起動
CMD ["xinference-local", "--host", "0.0.0.0", "--port", "9997"]