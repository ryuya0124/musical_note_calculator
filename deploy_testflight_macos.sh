#!/bin/bash
# ============================================================
# macOS TestFlightアップロードスクリプト
# 使い方: ./deploy_testflight_macos.sh
# ============================================================

set -e
set -o pipefail # パイプエラーを検出

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

# 証明書を同期
echo -e "${YELLOW}🔐 証明書を同期中...${NC}"
cd macos
fastlane sync_certificates
cd ..

# Xcodeプロジェクトのビルド番号をpubspec.yamlの値に同期 (agvtool)
echo -e "${YELLOW}🔧 Xcodeプロジェクトのビルド番号を同期中... (agvtool)${NC}"
cd macos
agvtool new-version -all "${BUILD_NUMBER}" 2>/dev/null || echo "agvtool failed to update project version (non-fatal)"
cd ..

# Info.plistを直接書き換え (PlistBuddy)
echo -e "${YELLOW}🔧 Info.plistのビルド番号を直接設定中... (PlistBuddy)${NC}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" macos/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION_NAME}" macos/Runner/Info.plist

# ビルドキャッシュをクリーン
echo -e "${YELLOW}🧹 ビルドキャッシュをクリーン中...${NC}"
flutter clean
flutter pub get

# macosディレクトリでPod install
echo -e "${YELLOW}📦 CocoaPodsをインストール中...${NC}"
cd macos
pod install --repo-update
cd ..

# Flutter build macosを実行して必要なファイル(xcfilelist等)を生成
# fastlane build_mac_app (xcodebuild) が失敗しないように事前ビルドが必要
echo -e "${YELLOW}🏗️ Flutter macOS アプリを事前ビルド中 (生成ファイル準備)...${NC}"
flutter build macos --release

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 事前ビルドに失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 事前ビルド完了${NC}"

# fastlaneでビルド(署名・パッケージ化) & TestFlightにアップロード
echo -e "${YELLOW}🚀 fastlane local_testflight を実行中...${NC}"
cd macos

# fastlaneのclean: trueはFlutter生成ファイルを消す可能性があるので、Fastfile側でオフにするか検討が必要だが、
# build_mac_appのcleanはxcodebuild cleanなので、通常はFlutterのアーティファクトまでは消さないはず。
# しかし念のため、Fastfileのclean: trueが原因で再発する場合はオフにする。
# 今回はそのまま実行。

# 出力を表示しつつログにも保存して後で解析
fastlane local_testflight 2>&1 | tee /tmp/fastlane_macos.log
EXIT_CODE=${PIPESTATUS[0]}

OUTPUT=$(cat /tmp/fastlane_macos.log)

if [ $EXIT_CODE -ne 0 ]; then
    # ビルド番号重複エラーチェック
    if echo "$OUTPUT" | grep -qE "(redundant binary upload|already exists|This build already exists|has already been uploaded|must be higher than|DUPLICATE|has already been used)"; then
        echo ""
        echo -e "${RED}❌ ビルド番号 ${BUILD_NUMBER} は既にTestFlightにアップロード済みです！${NC}"
        echo ""
        echo -e "${YELLOW}📝 解決方法: pubspec.yaml の version を更新してください。${NC}"
        echo -e "   現在: version: ${VERSION_NAME}+${BUILD_NUMBER}"
        echo -e "   変更例: version: ${VERSION_NAME}+$((BUILD_NUMBER + 1))"
        exit 1
    else
        exit $EXIT_CODE
    fi
fi

echo ""
echo -e "${GREEN}✅ macOS版 TestFlightへのアップロード完了！${NC}"
