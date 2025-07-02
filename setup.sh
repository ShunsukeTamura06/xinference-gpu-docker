#!/bin/bash

set -e

echo "🚀 Xinference GPU Docker セットアップ開始"

# プロキシ設定の確認と警告
echo "🌐 プロキシ環境確認中..."
if [ -n "$HTTP_PROXY" ] || [ -n "$http_proxy" ]; then
    echo "✅ プロキシ設定が検出されました: $HTTP_PROXY$http_proxy"
else
    echo "⚠️  プロキシ設定が検出されませんでした"
    echo "   企業ネットワーク環境の場合は、以下を実行してください:"
    echo "   export HTTP_PROXY=http://hn02-outbound.gm.internal:8080"
    echo "   export HTTPS_PROXY=http://hn02-outbound.gm.internal:8080"
    echo ""
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "セットアップを中止しました"
        exit 1
    fi
fi

# 必要なディレクトリの作成
echo "📁 ディレクトリ作成中..."
mkdir -p models logs

# NVIDIA Container Toolkitのインストール確認
echo "🔧 NVIDIA Container Toolkit確認中..."
if ! command -v nvidia-container-runtime &> /dev/null; then
    echo "❌ NVIDIA Container Toolkitがインストールされていません。インストール中..."
    
    # プロキシ環境でのcurl/wget設定
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

# Dockerコンテナの構築
echo "🐳 Dockerイメージ構築中..."
echo "   ⚠️  初回ビルドは大きなCUDAイメージのダウンロードのため時間がかかります"
docker compose build

echo "🎉 セットアップ完了！"
echo ""
echo "🚀 Xinferenceサーバーを起動するには:"
echo "   docker compose up -d"
echo ""
echo "📊 ログを確認するには:"
echo "   docker compose logs -f xinference"
echo ""
echo "🌐 サーバーへのアクセス:"
echo "   http://localhost:9997"
echo ""
echo "🛑 サーバーを停止するには:"
echo "   docker compose down"