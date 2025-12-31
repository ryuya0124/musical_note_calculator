#!/bin/bash
# ============================================================
# iOS TestFlight アップロードスクリプト（fastlane版）
# ローカル環境からIPAをビルドしてTestFlightにアップロード
# ============================================================

set -e

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== iOS TestFlight アップロードスクリプト (fastlane) ===${NC}"

# プロジェクトのルートディレクトリに移動
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)
echo -e "${GREEN}プロジェクトルート: $PROJECT_ROOT${NC}"

# Flutterの依存関係をインストール
echo -e "${YELLOW}Flutterの依存関係をインストール中...${NC}"
flutter pub get

# fastlaneディレクトリに移動
cd "$PROJECT_ROOT/ios"

# Bundlerがインストールされているか確認
if ! command -v bundle &> /dev/null; then
    echo -e "${YELLOW}Bundlerをインストール中...${NC}"
    gem install bundler
fi

# fastlane依存関係をインストール
if [ ! -f "Gemfile" ]; then
    echo -e "${YELLOW}Gemfileを作成中...${NC}"
    cat > Gemfile << 'EOF'
source "https://rubygems.org"

gem "fastlane"
EOF
fi

echo -e "${YELLOW}fastlane依存関係をインストール中...${NC}"
bundle install

# fastlane betaレーンを実行
echo -e "${YELLOW}fastlane betaレーンを実行中...${NC}"
bundle exec fastlane beta

echo ""
echo -e "${GREEN}=== アップロード完了 ===${NC}"
echo "App Store Connectで処理状況を確認してください"
echo "https://appstoreconnect.apple.com"
