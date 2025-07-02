# Xinference GPU Dockerfile (amd64)
FROM quay.io/pypa/manylinux2014_x86_64:latest

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0

# 基本パッケージのインストール
RUN yum update -y && \
    yum install -y \
    wget \
    curl \
    git \
    && yum clean all

# CUDA 11.8のインストール
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-keyring-1.0-1.noarch.rpm && \
    rpm -i cuda-keyring-1.0-1.noarch.rpm && \
    yum install -y cuda-toolkit-11-8

# Python 3.10のインストール
RUN /opt/python/cp310-cp310/bin/python -m pip install --upgrade pip

# 作業ディレクトリの作成
WORKDIR /app

# 必要なPythonパッケージのインストール
RUN /opt/python/cp310-cp310/bin/pip install \
    torch==2.0.1+cu118 \
    torchvision==0.15.2+cu118 \
    torchaudio==2.0.2+cu118 \
    --index-url https://download.pytorch.org/whl/cu118

# Xinferenceのインストール
RUN /opt/python/cp310-cp310/bin/pip install \
    xinference[all] \
    accelerate \
    transformers \
    sentence-transformers

# ポートの公開
EXPOSE 9997

# Xinferenceサーバーの起動
CMD ["/opt/python/cp310-cp310/bin/xinference-local", "--host", "0.0.0.0", "--port", "9997"]