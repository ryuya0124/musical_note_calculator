#!/bin/bash
# ============================================================
# macOS TestFlightアップロードスクリプト
# 使い方: ./deploy_testflight_macos.sh
# ============================================================

set -e

# 色付きメッセージ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# プロジェクトルートに移動
cd "$(dirname "$0")"

# pubspec.yamlからバージョン情報を取得
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
VERSION_NAME=$(echo "$VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$VERSION" | cut -d'+' -f2)

echo -e "${YELLOW}📦 pubspec.yaml から取得: バージョン ${VERSION_NAME}, ビルド番号 ${BUILD_NUMBER}${NC}"

# macosディレクトリでfastlaneを実行
echo -e "${YELLOW}🚀 fastlane local_testflight を実行中...${NC}"
cd macos

OUTPUT=$(fastlane local_testflight 2>&1) || {
    EXIT_CODE=$?
    
    # ビルド番号重複エラーチェック
    if echo "$OUTPUT" | grep -qE "(redundant binary upload|already exists|This build already exists|has already been uploaded)"; then
        echo ""
        echo -e "${RED}❌ ビルド番号 ${BUILD_NUMBER} は既にTestFlightにアップロード済みです！${NC}"
        echo ""
        echo -e "${YELLOW}📝 解決方法: pubspec.yaml の version を更新してください。${NC}"
        echo -e "   現在: version: ${VERSION_NAME}+${BUILD_NUMBER}"
        echo -e "   変更例: version: ${VERSION_NAME}+$((BUILD_NUMBER + 1))"
        exit 1
    else
        echo "$OUTPUT"
        exit $EXIT_CODE
    fi
}

echo "$OUTPUT"
echo ""
echo -e "${GREEN}✅ macOS版 TestFlightへのアップロード完了！${NC}"
