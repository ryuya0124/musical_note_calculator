#!/bin/bash
# ============================================================
# マルチプラットフォームリリースビルドスクリプト
# Linux (x64/ARM64), Android, Windows (x64/ARM) のリリースバイナリをビルド
# macOS/Windows/Linux 環境で動作
# ============================================================

set -e

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== マルチプラットフォームリリースビルドスクリプト ===${NC}"

# OS検出
OS_TYPE="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS_TYPE="windows"
fi

echo -e "${GREEN}検出されたOS: $OS_TYPE${NC}"

# プロジェクトのルートディレクトリに移動
cd "$(dirname "$0")"
PROJECT_ROOT=$(pwd)
echo -e "${GREEN}プロジェクトルート: $PROJECT_ROOT${NC}"

# distフォルダを作成
DIST_DIR="$PROJECT_ROOT/dist"
mkdir -p "$DIST_DIR"
echo -e "${GREEN}出力先: $DIST_DIR${NC}"

# Flutterの依存関係をインストール
echo -e "${YELLOW}Flutterの依存関係をインストール中...${NC}"
flutter pub get

# 言語ファイルを生成
echo -e "${YELLOW}言語ファイルを生成中...${NC}"
flutter gen-l10n

# ============================================================
# 1. Linux ビルド (x64 / ARM64)
# ============================================================
if [ "$OS_TYPE" = "linux" ]; then
    echo -e "${GREEN}=== Linux ビルド開始 ===${NC}"

    # Linux x64
    echo -e "${YELLOW}Linux x64 ビルド中...${NC}"
    flutter build linux --release
    LINUX_X64_BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
    if [ -d "$LINUX_X64_BUILD_DIR" ]; then
        echo -e "${YELLOW}Linux x64 バイナリをdistにコピー中...${NC}"
        cp -r "$LINUX_X64_BUILD_DIR" "$DIST_DIR/rytmica-linux-x64"
        echo -e "${GREEN}✅ Linux x64 ビルド完了: $DIST_DIR/rytmica-linux-x64${NC}"
    else
        echo -e "${RED}❌ Linux x64 ビルドが見つかりません${NC}"
    fi

    # Linux ARM64
    echo -e "${YELLOW}Linux ARM64 ビルド中...${NC}"
    flutter build linux --release --target-platform linux-arm64 2>/dev/null || echo -e "${YELLOW}⚠️  Linux ARM64 ビルドはこの環境ではサポートされていません${NC}"
    LINUX_ARM64_BUILD_DIR="$PROJECT_ROOT/build/linux/arm64/release/bundle"
    if [ -d "$LINUX_ARM64_BUILD_DIR" ]; then
        echo -e "${YELLOW}Linux ARM64 バイナリをdistにコピー中...${NC}"
        cp -r "$LINUX_ARM64_BUILD_DIR" "$DIST_DIR/rytmica-linux-arm64"
        echo -e "${GREEN}✅ Linux ARM64 ビルド完了: $DIST_DIR/rytmica-linux-arm64${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Linuxビルドは Linux ホストでのみサポートされています (現在のOS: $OS_TYPE)${NC}"
fi

# ============================================================
# 2. Android (APK) ビルド
# ============================================================
echo -e "${GREEN}=== Android (APK) ビルド開始 ===${NC}"
flutter build apk --release --split-per-abi

# APKをdistにコピー
ANDROID_BUILD_DIR="$PROJECT_ROOT/build/app/outputs/flutter-apk"
if [ -d "$ANDROID_BUILD_DIR" ]; then
    echo -e "${YELLOW}APKをdistにコピー中...${NC}"
    cp "$ANDROID_BUILD_DIR"/*.apk "$DIST_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✅ Android ビルド完了: $DIST_DIR/*.apk${NC}"
else
    echo -e "${RED}❌ Androidビルドが見つかりません${NC}"
fi

# ============================================================
# 3. Windows ビルド (x64 / ARM - EXE分離、MSIXユニバーサル)
# ============================================================
if [ "$OS_TYPE" = "macos" ] || [ "$OS_TYPE" = "windows" ]; then
    echo -e "${GREEN}=== Windows ビルド開始 ===${NC}"

    # Windows x64 EXE
    echo -e "${YELLOW}Windows x64 EXE ビルド中...${NC}"
    flutter build windows --release
    WINDOWS_X64_BUILD_DIR="$PROJECT_ROOT/build/windows/x64/runner/Release"
    if [ -d "$WINDOWS_X64_BUILD_DIR" ]; then
        echo -e "${YELLOW}Windows x64 バイナリをdistにコピー中...${NC}"
        mkdir -p "$DIST_DIR/rytmica-windows-x64"
        cp -r "$WINDOWS_X64_BUILD_DIR"/* "$DIST_DIR/rytmica-windows-x64/"
        echo -e "${GREEN}✅ Windows x64 EXE ビルド完了: $DIST_DIR/rytmica-windows-x64${NC}"
    else
        echo -e "${RED}❌ Windows x64 ビルドが見つかりません${NC}"
    fi

    # Windows ARM64 EXE
    echo -e "${YELLOW}Windows ARM64 EXE ビルド中...${NC}"
    flutter build windows --release --target-platform windows-arm64 2>/dev/null || echo -e "${YELLOW}⚠️  Windows ARM64 ビルドはこの環境ではサポートされていません${NC}"
    WINDOWS_ARM64_BUILD_DIR="$PROJECT_ROOT/build/windows/arm64/runner/Release"
    if [ -d "$WINDOWS_ARM64_BUILD_DIR" ]; then
        echo -e "${YELLOW}Windows ARM64 バイナリをdistにコピー中...${NC}"
        mkdir -p "$DIST_DIR/rytmica-windows-arm64"
        cp -r "$WINDOWS_ARM64_BUILD_DIR"/* "$DIST_DIR/rytmica-windows-arm64/"
        echo -e "${GREEN}✅ Windows ARM64 EXE ビルド完了: $DIST_DIR/rytmica-windows-arm64${NC}"
    fi

    # Windows MSIX (ユニバーサル)
    echo -e "${YELLOW}Windows MSIX (ユニバーサル) パッケージを作成中...${NC}"
    if command -v dart &> /dev/null; then
        dart run msix:create --build-windows false 2>/dev/null || echo -e "${YELLOW}⚠️  MSIX作成に失敗しました。pubspec.yamlにmsix設定があるか確認してください${NC}"
        
        # MSIXをdistにコピー
        MSIX_FILE=$(find "$PROJECT_ROOT/build/windows" -name "*.msix" 2>/dev/null | head -n 1)
        if [ -n "$MSIX_FILE" ]; then
            echo -e "${YELLOW}MSIXをdistにコピー中...${NC}"
            cp "$MSIX_FILE" "$DIST_DIR/"
            echo -e "${GREEN}✅ Windows MSIX ビルド完了: $DIST_DIR/$(basename "$MSIX_FILE")${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Dartコマンドが見つかりません。MSIXビルドをスキップします${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Windowsビルドは macOS/Windows ホストでのみサポートされています (現在のOS: $OS_TYPE)${NC}"
fi

# ============================================================
# 完了
# ============================================================
echo ""
echo -e "${GREEN}=== すべてのビルドが完了しました ===${NC}"
echo -e "${GREEN}出力先: $DIST_DIR${NC}"
echo ""
echo "ビルドされたファイル:"
ls -lh "$DIST_DIR" 2>/dev/null || dir "$DIST_DIR"
