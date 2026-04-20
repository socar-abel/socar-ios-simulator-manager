# SOCAR Simulator Manager

비개발자(QA, 디자이너, Android 개발자 등)도 iOS 시뮬레이터를 쉽게 관리할 수 있는 macOS 앱입니다.

## 설치

터미널에 아래 한 줄을 붙여넣으세요:

```bash
curl -sL https://github.com/socar-abel/socar-ios-simulator-manager/releases/latest/download/SOCARSimulatorManager.zip -o /tmp/ssm.zip && unzip -oq /tmp/ssm.zip -d /tmp/ssm && xattr -cr /tmp/ssm/SOCARSimulatorManager.app && cp -r /tmp/ssm/SOCARSimulatorManager.app /Applications/ && open /Applications/SOCARSimulatorManager.app
```

### 사전 요구사항

- **macOS 14.0 이상**
- **Xcode 설치 + 한 번 실행 필수**
  - Xcode를 설치한 뒤 반드시 한 번 실행하여 라이선스 동의 + 추가 컴포넌트 설치를 완료해야 합니다
  - Xcode가 없으면 앱 실행 시 온보딩 화면에서 설치를 안내합니다
  - Command Line Tools만으로는 사용할 수 없습니다

> Xcode를 설치했는데 시뮬레이터가 동작하지 않는다면, 앱이 자동으로 `DEVELOPER_DIR` 환경변수를 설정하여 해결합니다. 별도 터미널 명령어 실행이 필요 없습니다.

## 주요 기능

### 디바이스 관리
- 시뮬레이터 디바이스 생성 / 부팅 / 종료 / 삭제 / 이름 변경
- 디바이스 목록 정렬 및 필터링
- 멀티 선택 후 일괄 삭제
- 화면 보기 (Simulator 앱 활성화)
- 기기 흔들기 (Shake Gesture)

### 앱 설치
- 등록된 .app 파일 목록에서 원클릭 설치
- 파일 선택 또는 드래그 앤 드롭으로 직접 설치
- Google Drive에서 SOCAR Debug 앱 다운로드 연동

### 위치 설정
- 프리셋 위치: 강남역, 서울숲역, 제주공항, 부산역
- 위도/경도 직접 입력

### 딥링크 테스트
- `socar-v2://` 또는 `https://` URL 입력 후 시뮬레이터에서 실행

### 푸시 알림 테스트
- 타이틀 / 내용 / 딥링크를 입력하면 APNS JSON payload를 자동 생성하여 전송
- `kr.socar.socarapp.debug`와 `kr.socar.socarapp` 두 번들 ID에 동시 전송
- 딥링크는 `land_page` 키로 전송 (SOCAR 앱 호환)

### iOS 버전 관리
- 설치된 iOS 버전 목록 조회 및 삭제
- 다운로드 가능한 iOS 버전 목록 (현재 Xcode 호환 범위 내)
- 인라인 다운로드 진행률 표시 + 취소

### 온보딩
- Xcode 미설치 시 3단계 온보딩 가이드
- xcodereleases.com에서 현재 macOS에 호환되는 Xcode 버전 자동 추천
- "준비 완료! 시작하기" 버튼으로 Xcode 자동 실행 + 설정 완료 대기

## 프로젝트 구조

Swift Package Manager executable 프로젝트입니다. MVVM + Clean Architecture (5개 모듈)로 구성되어 있습니다.

```
Sources/
├── App/                    # 앱 진입점, 온보딩, 메인 화면 라우팅
│   ├── SOCARSimulatorManagerApp.swift   # @main, NSApplication 설정
│   ├── AppContainer.swift               # 환경 체크 + ViewModel 생성
│   ├── AppAssembly.swift                # DI 조립
│   ├── RootView.swift                   # 로딩 / 온보딩 / 메인 분기
│   ├── MainView.swift                   # NavigationSplitView (사이드바 + 디테일)
│   ├── OnboardingView.swift             # 3페이지 온보딩 (이전/다음)
│   └── Resources/AppIcon.png
│
├── Feature/                # SwiftUI 뷰 + ViewModel (@Observable)
│   ├── DeviceListView.swift             # 디바이스 목록 + 멀티 선택
│   ├── DeviceDetailView.swift           # 앱 설치, 제어, 위치, 딥링크, 푸시
│   ├── DeviceListViewModel.swift        # 디바이스 CRUD + 위치/푸시 액션
│   ├── CreateDeviceSheet.swift          # 디바이스 생성 시트
│   ├── BuildListView.swift              # 앱 등록 및 설치 탭
│   ├── BuildListViewModel.swift         # 로컬 빌드 파일 관리
│   ├── IOSVersionView.swift             # iOS 버전 다운로드/삭제
│   ├── IOSVersionViewModel.swift        # 다운로드 진행률 + 폴링
│   └── GuideView.swift                  # 사용 가이드
│
├── Domain/                 # UseCase, Entity, Interface (비즈니스 로직)
│   ├── SimulatorDevice.swift            # 디바이스 엔티티
│   ├── SimulatorUseCaseInterface.swift  # UseCase 프로토콜
│   ├── SimulatorUseCase.swift           # UseCase 구현
│   ├── EnvironmentCheckUseCase.swift    # 환경 체크 (Xcode, simctl)
│   ├── EnvironmentStatus.swift          # 환경 상태 + isReady 판단
│   ├── LocationPreset.swift             # 위치 프리셋 (강남역 등)
│   ├── DownloadProgress.swift           # 다운로드 진행률 파싱
│   └── ...
│
├── Data/                   # Repository 구현, DTO, Shell 명령 실행
│   ├── SimulatorRepository.swift        # xcrun simctl 래핑
│   ├── EnvironmentRepository.swift      # xcode-select, simctl 체크
│   ├── FileRepository.swift             # 로컬 빌드 파일 관리
│   └── SimctlDTO.swift                  # simctl JSON 파싱 모델
│
└── Core/                   # 공통 유틸, UI 컴포넌트
    ├── ShellService.swift               # 프로세스 실행 (actor 기반)
    ├── Constants.swift                  # 타임아웃, URL, 디자인 상수
    ├── ToastOverlay.swift               # 에러/성공 토스트
    └── ActionButton.swift               # 재사용 버튼 컴포넌트
```

## 기술 스택

| 항목 | 기술 |
|------|------|
| 언어 | Swift 5.10 |
| UI | SwiftUI (macOS 14+) |
| 아키텍처 | MVVM + Clean Architecture |
| 상태 관리 | @Observable (Observation 프레임워크) |
| 동시성 | Swift Concurrency (async/await, actor) |
| 패키지 관리 | Swift Package Manager |
| 시뮬레이터 제어 | xcrun simctl |
| 배포 | GitHub Release + ad-hoc codesign |

## 개발

```bash
# 빌드
swift build

# 실행
swift run

# Release 빌드
swift build -c release
```

## iOS 버전 호환 범위

iOS 버전 탭에 표시되는 다운로드 가능 목록은 **설치된 Xcode의 iOS SDK 버전**에 의해 결정됩니다.

| Xcode | 최소 macOS | iOS 시뮬레이터 다운로드 범위 |
|-------|-----------|--------------------------|
| 26.3+ | macOS 15.6 | iOS 16.0 ~ 26.x |
| 16.3 ~ 16.4 | macOS 15.2+ | iOS 16.0 ~ 18.x |
| 16.0 ~ 16.2 | macOS 14.5+ | iOS 16.0 ~ 18.x |
