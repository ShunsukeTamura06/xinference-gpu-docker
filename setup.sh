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

# GPU確認
echo "🖥️  GPU確認中..."
nvidia-smi

# Dockerイメージの構築（軽量になりました）
echo "🐳 Dockerイメージ構築中..."
echo "   ℹ️  ベースイメージのダウンロードのみ行います"
docker compose build

echo "🎉 セットアップ完了！"
echo ""
echo "🚀 Xinferenceサーバーを起動するには:"
echo "   docker compose up -d"
echo ""
echo "📊 初回起動時のログを確認するには:"
echo "   docker compose logs -f xinference"
echo ""
echo "ℹ️  初回起動時はパッケージのインストールのため数分かかります"
echo "   進行状況はログで確認できます"
echo ""
echo "🌐 サーバーへのアクセス:"
echo "   http://localhost:9997"
echo ""
echo "🛑 サーバーを停止するには:"
echo "   docker compose down"