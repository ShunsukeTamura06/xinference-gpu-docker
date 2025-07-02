#!/bin/bash

set -e

echo "🚀 Xinference GPU Docker セットアップ開始（T4G GPU対応）"

# T4G GPU環境確認
echo "🔧 T4G GPU環境確認中..."
if command -v nvcc &> /dev/null; then
    echo "✅ CUDA が検出されました:"
    nvcc --version
    echo ""
else
    echo "❌ CUDA が検出されません。CUDA 12.9がインストールされていることを確認してください。"
    exit 1
fi

# 必要なディレクトリの作成
echo "📁 ディレクトリ作成中..."
mkdir -p models logs

# NVIDIA Container Toolkitのインストール確認
echo "🔧 NVIDIA Container Toolkit確認中..."
if ! command -v nvidia-container-runtime &> /dev/null; then
    echo "❌ NVIDIA Container Toolkitがインストールされていません。インストール中..."
    
    # プロキシ環境でのcurl設定
    PROXY_ARGS=""
    if [ -n "$HTTP_PROXY" ]; then
        PROXY_ARGS="--proxy $HTTP_PROXY"
    fi
    
    # GPGキーの追加
    curl $PROXY_ARGS -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    # リポジトリの追加
    curl $PROXY_ARGS -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    # プロキシ設定をapt用に追加
    if [ -n "$HTTP_PROXY" ]; then
        echo "Acquire::http::Proxy \"$HTTP_PROXY\";" | sudo tee /etc/apt/apt.conf.d/01proxy
        echo "Acquire::https::Proxy \"$HTTPS_PROXY\";" | sudo tee -a /etc/apt/apt.conf.d/01proxy
    fi
    
    # パッケージの更新とインストール
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    
    # Dockerデーモンの再起動
    sudo systemctl restart docker
    
    echo "✅ NVIDIA Container Toolkitのインストール完了"
else
    echo "✅ NVIDIA Container Toolkitは既にインストールされています"
fi

# T4G GPU確認
echo "🖥️  T4G GPU確認中..."
nvidia-smi
echo ""

# CUDAパス確認
echo "📚 CUDA インストール確認..."
if [ -d "/usr/local/cuda" ]; then
    echo "✅ CUDA インストールパス: /usr/local/cuda"
    ls -la /usr/local/cuda/bin/nvcc
else
    echo "❌ /usr/local/cuda が見つかりません"
    echo "CUDA 12.9のインストールパスを確認してください"
    exit 1
fi

# Dockerイメージの構築（ARM64ネイティブ）
echo "🐳 ARM64 Dockerイメージ構築中..."
echo "   ℹ️  T4G GPU用のARM64ネイティブイメージを構築します"
docker compose build

echo "🎉 T4G GPU環境セットアップ完了！"
echo ""
echo "🚀 Xinferenceサーバーを起動するには:"
echo "   docker compose up -d"
echo ""
echo "📊 初回起動時のログを確認するには:"
echo "   docker compose logs -f xinference"
echo ""
echo "ℹ️  初回起動時は以下の処理のため数分かかります:"
echo "   - ARM64用パッケージのインストール"
echo "   - PyTorch（CUDA 12.x対応）のインストール"
echo "   - CUDA環境の設定"
echo "   進行状況はログで確認できます"
echo ""
echo "🌐 サーバーへのアクセス:"
echo "   http://localhost:9997"
echo ""
echo "🔧 CUDA動作確認:"
echo "   起動後、ログで 'CUDA available: True' が表示されることを確認してください"
echo ""
echo "🛑 サーバーを停止するには:"
echo "   docker compose down"