#!/bin/bash

set -e

echo "🚀 Xinference GPU Docker セットアップ開始"

# 必要なディレクトリの作成
echo "📁 ディレクトリ作成中..."
mkdir -p models logs

# NVIDIA Container Toolkitのインストール確認
echo "🔧 NVIDIA Container Toolkit確認中..."
if ! command -v nvidia-container-runtime &> /dev/null; then
    echo "❌ NVIDIA Container Toolkitがインストールされていません。インストール中..."
    
    # GPGキーの追加
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    # リポジトリの追加
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    # パッケージの更新とインストール
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    
    # Dockerデーモンの再起動
    sudo systemctl restart docker
    
    echo "✅ NVIDIA Container Toolkitのインストール完了"
else
    echo "✅ NVIDIA Container Toolkitは既にインストールされています"
fi

# GPU確認
echo "🖥️  GPU確認中..."
nvidia-smi

# Dockerコンテナの構築
echo "🐳 Dockerイメージ構築中..."
docker-compose build

echo "🎉 セットアップ完了！"
echo ""
echo "🚀 Xinferenceサーバーを起動するには:"
echo "   docker-compose up -d"
echo ""
echo "📊 ログを確認するには:"
echo "   docker-compose logs -f xinference"
echo ""
echo "🌐 サーバーへのアクセス:"
echo "   http://localhost:9997"
echo ""
echo "🛑 サーバーを停止するには:"
echo "   docker-compose down"