#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$SCRIPT_DIR/SOCARSimulatorManager.app"
DEFAULT_BUILDS="$SCRIPT_DIR/DefaultBuilds"
BUILDS_DIR="$HOME/Library/Application Support/SOCARSimulatorManager/Builds"
MAC_VERSION=$(sw_vers -productVersion)

echo ""
echo "=================================="
echo "  SOCAR Simulator Manager 설치"
echo "=================================="
echo ""
echo "초기 세팅 프로세스를 진행합니다."
echo "환경을 확인하고 필요한 설정을 자동으로 처리합니다."
echo ""

# 1. 앱 파일 존재 확인
echo "[1/4] 앱 파일 확인 중..."
if [ ! -d "$APP_PATH" ]; then
    echo "  ❌ SOCARSimulatorManager.app을 찾을 수 없습니다."
    echo "     이 파일과 같은 폴더에 앱이 있어야 합니다."
    echo ""
    read -p "아무 키나 누르면 종료합니다..."
    exit 1
fi
echo "  ✅ 앱 파일 확인 완료"
echo ""

# 2. Xcode 설치 여부 확인
echo "[2/4] Xcode 설치 여부 확인 중..."
if ! xcode-select -p &>/dev/null; then
    echo "  ⚠️  Xcode가 설치되어 있지 않습니다."
    echo ""
    echo "  이 앱을 사용하려면 Xcode가 필요합니다."
    echo "  현재 macOS 버전: $MAC_VERSION"
    echo ""
    echo "  📌 설치 방법:"
    echo "     1. 아래에서 '예'를 선택하면 Xcode 다운로드 사이트가 열립니다."
    echo "     2. macOS $MAC_VERSION 에 호환되는 버전을 찾아서 다운로드합니다."
    echo "     3. 다운로드한 .xip 파일을 더블클릭하면 Xcode가 설치됩니다."
    echo "     4. 설치된 Xcode를 한 번 실행합니다."
    echo "        → 라이선스 동의 화면이 나오면 'Agree'를 클릭합니다."
    echo "        → 추가 컴포넌트 설치가 시작되면 완료될 때까지 기다립니다."
    echo "     5. 이 스크립트를 다시 실행합니다."
    echo ""
    echo "  Xcode 설치 페이지로 이동하시겠습니까?"
    echo "    1) 예"
    echo "    2) 아니오 - 나중에 설치합니다"
    echo ""
    read -p "  선택 (1 또는 2): " choice
    if [ "$choice" = "1" ]; then
        echo ""
        echo "  🌐 xcodereleases.com을 열고 있습니다..."
        open "https://xcodereleases.com"
    fi
    echo ""
    read -p "아무 키나 누르면 종료합니다..."
    exit 0
fi
echo "  ✅ Xcode 확인 완료"
echo ""

# 3. simctl 사용 가능 여부 확인
echo "[3/4] Xcode 초기 설정 확인 중..."
if ! xcrun simctl help &>/dev/null; then
    echo "  ⚠️  Xcode 초기 설정이 완료되지 않았습니다."
    echo ""
    echo "  📌 해결 방법:"
    echo "     1. Xcode를 실행합니다. (Launchpad 또는 /Applications 에서 찾을 수 있습니다)"
    echo "     2. 라이선스 동의 화면이 나오면 'Agree'를 클릭합니다."
    echo "     3. 추가 컴포넌트 설치가 시작되면 완료될 때까지 기다립니다."
    echo "     4. 설치가 끝나면 Xcode를 닫고, 이 스크립트를 다시 실행합니다."
    echo ""
    echo "  그래도 안 되면 터미널에서 아래 명령어를 실행해주세요:"
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo ""
    read -p "아무 키나 누르면 종료합니다..."
    exit 0
fi
echo "  ✅ Xcode 설정 확인 완료"
echo ""

# 4. 앱 설치 및 실행
echo "[4/4] 앱 설치 중..."

# 보안 속성 제거
xattr -cr "$APP_PATH" 2>/dev/null
echo "  ✅ 보안 설정 완료"

# 기본 빌드 복사
if [ -d "$DEFAULT_BUILDS" ]; then
    mkdir -p "$BUILDS_DIR"
    for app in "$DEFAULT_BUILDS"/*.app; do
        [ ! -d "$app" ] && continue
        APP_NAME=$(basename "$app")
        if [ ! -d "$BUILDS_DIR/$APP_NAME" ]; then
            echo "  📦 기본 앱 복사 중: $APP_NAME"
            cp -r "$app" "$BUILDS_DIR/"
        else
            echo "  ✅ 이미 존재: $APP_NAME"
        fi
    done
fi

echo ""
echo "🚀 앱을 실행합니다..."
open "$APP_PATH"

echo ""
echo "✅ 모든 설정이 완료되었습니다!"
echo "   이 창은 닫아도 됩니다."
echo "   다음부터는 SOCARSimulatorManager.app을 직접 실행하면 됩니다."
