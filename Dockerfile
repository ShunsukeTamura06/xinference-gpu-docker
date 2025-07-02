# Xinference GPU Dockerfile (amd64)
FROM nvidia/cuda:11.8-devel-ubuntu20.04

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0
ENV PATH="/opt/miniconda3/bin:$PATH"

# 基本パッケージのインストール
RUN apt-get update && \
    apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Miniconda3のインストール
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
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