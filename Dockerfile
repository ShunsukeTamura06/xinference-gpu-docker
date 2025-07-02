# Xinference GPU Dockerfile (amd64) - Ubuntu base with manual CUDA
FROM ubuntu:20.04

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0

# 作業ディレクトリの作成
WORKDIR /app

# ポートの公開
EXPOSE 9997