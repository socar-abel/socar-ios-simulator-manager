#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$SCRIPT_DIR/SOCARSimulatorManager.app"
DEFAULT_BUILDS="$SCRIPT_DIR/DefaultBuilds"
BUILDS_DIR="$HOME/Library/Application Support/SOCARSimulatorManager/Builds"

echo ""
echo "=================================="
echo "  SOCAR Simulator Manager 설치"
echo "=================================="
echo ""

# 1. 앱 파일 존재 확인
if [ ! -d "$APP_PATH" ]; then
    echo "❌ SOCARSimulatorManager.app을 찾을 수 없습니다."
    echo "   이 파일과 같은 폴더에 앱이 있어야 합니다."
    echo ""
    read -p "아무 키나 누르면 종료합니다..."
    exit 1
fi

# 2. Xcode 설치 여부 확인
if ! xcode-select -p &>/dev/null; then
    MAC_VERSION=$(sw_vers -productVersion)
    echo "⚠️  Xcode가 설치되어 있지 않습니다."
    echo ""
    echo "이 앱을 사용하려면 Xcode가 필요합니다."
    echo "현재 macOS 버전: $MAC_VERSION"
    echo ""
    echo "Xcode 설치 페이지로 이동하시겠습니까?"
    echo "  1) 예 - 내 macOS에 호환되는 Xcode를 설치합니다"
    echo "  2) 아니오 - 나중에 설치합니다"
    echo ""
    read -p "선택 (1 또는 2): " choice
    if [ "$choice" = "1" ]; then
        echo ""
        echo "🌐 xcodereleases.com을 열고 있습니다..."
        echo "   macOS $MAC_VERSION 에 호환되는 버전을 찾아서 다운로드해주세요."
        open "https://xcodereleases.com"
    fi
    echo ""
    echo "Xcode 설치 완료 후 Xcode를 한 번 실행한 다음, 이 스크립트를 다시 실행해주세요."
    echo ""
    read -p "아무 키나 누르면 종료합니다..."
    exit 0
fi

# 3. simctl 사용 가능 여부 확인
if ! xcrun simctl help &>/dev/null; then
    echo "⚠️  Xcode 초기 설정이 필요합니다."
    echo ""
    echo "Xcode를 한 번 실행해서 라이선스 동의와 추가 컴포넌트 설치를 완료해주세요."
    echo "또는 아래 명령어를 실행해주세요:"
    echo ""
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo ""
    echo "설정 완료 후 이 스크립트를 다시 실행해주세요."
    echo ""
    read -p "아무 키나 누르면 종료합니다..."
    exit 0
fi

# 4. 보안 속성 제거
echo "🔧 보안 속성 제거 중..."
xattr -cr "$APP_PATH"

# 5. 기본 빌드 복사
if [ -d "$DEFAULT_BUILDS" ]; then
    mkdir -p "$BUILDS_DIR"
    for app in "$DEFAULT_BUILDS"/*.app; do
        [ ! -d "$app" ] && continue
        APP_NAME=$(basename "$app")
        if [ ! -d "$BUILDS_DIR/$APP_NAME" ]; then
            echo "📦 기본 빌드 복사 중: $APP_NAME"
            cp -r "$app" "$BUILDS_DIR/"
        else
            echo "✅ 이미 존재: $APP_NAME"
        fi
    done
fi

# 6. 앱 실행
echo ""
echo "🚀 앱을 실행합니다..."
open "$APP_PATH"

echo ""
echo "✅ 완료! 이 창은 닫아도 됩니다."
