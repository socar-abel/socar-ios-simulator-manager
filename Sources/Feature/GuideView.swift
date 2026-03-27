import SwiftUI

public struct GuideView: View {

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                titleSection
                quickStartSection
                tabGuideSection
                faqSection
            }
            .padding(32)
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)
                Text("사용 가이드")
                    .font(.largeTitle).fontWeight(.bold)
            }
            Text("SOCAR iOS 앱을 시뮬레이터에서 실행하기 위한 안내서입니다.")
                .font(.body).foregroundStyle(.secondary)
        }
    }

    // MARK: - Quick Start

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("빠른 시작", icon: "bolt.fill", color: .orange)

            stepCard(
                step: 1,
                title: "Xcode 설치",
                description: "App Store에서 Xcode를 설치한 후 한 번 실행해주세요.\n(라이선스 동의 및 추가 컴포넌트 설치가 진행됩니다)"
            )
            stepCard(
                step: 2,
                title: "iOS 버전 확인",
                description: "'iOS 버전' 탭에서 설치된 버전을 확인하세요.\n버전이 없다면 '다운로드 가능한 iOS 버전'에서 원하는 버전을 다운로드합니다."
            )
            stepCard(
                step: 3,
                title: "디바이스 선택 및 부팅",
                description: "'디바이스' 탭에서 원하는 기기를 선택하고 '부팅' 버튼을 누르세요.\n시뮬레이터 화면이 자동으로 나타납니다."
            )
            stepCard(
                step: 4,
                title: "SOCAR 앱 설치",
                description: "'빌드 관리' 탭에서 Google Drive 링크를 통해 .app 파일을 다운로드하세요.\n다운로드한 파일을 드래그하거나 '파일 추가' 버튼으로 등록한 후, '설치' 버튼을 누르면 됩니다."
            )
            stepCard(
                step: 5,
                title: "앱 실행 및 테스트",
                description: "설치가 완료되면 시뮬레이터에서 SOCAR 앱 아이콘을 탭하여 실행합니다.\n딥링크 테스트는 '디바이스' 탭의 딥링크 섹션을 활용하세요."
            )
        }
    }

    // MARK: - Tab Guide

    private var tabGuideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("탭별 기능 안내", icon: "rectangle.3.group", color: .blue)

            featureCard(
                icon: "iphone",
                title: "디바이스",
                features: [
                    "시뮬레이터 디바이스 목록 조회",
                    "디바이스 부팅 / 종료 / 삭제",
                    "다중 선택 후 일괄 삭제",
                    "딥링크 실행 (socar-v2://...)",
                    ".app 파일 직접 설치",
                    "이름순, iOS 버전순, 화면 크기순 정렬",
                    "노치 유무로 필터링"
                ]
            )
            featureCard(
                icon: "shippingbox",
                title: "빌드 관리",
                features: [
                    "Google Drive에서 빌드 파일 다운로드",
                    ".app 또는 .zip 파일 드래그앤드롭으로 추가",
                    "앱 이름, 버전, 아이콘 자동 표시",
                    "특정 디바이스에 앱 설치"
                ]
            )
            featureCard(
                icon: "cpu",
                title: "iOS 버전",
                features: [
                    "설치된 iOS 버전 확인 및 삭제",
                    "다운로드 가능한 버전 목록 (Apple CDN 조회)",
                    "디스크 사용량 모니터링",
                    "사용 불가능한 디바이스 일괄 정리"
                ]
            )
        }
    }

    // MARK: - FAQ

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("자주 묻는 질문", icon: "questionmark.circle.fill", color: .purple)

            faqItem(
                question: "\"확인되지 않은 개발자\" 경고가 뜹니다",
                answer: "앱을 우클릭(또는 Control+클릭)한 후 '열기'를 선택하세요.\n또는 터미널에서 아래 명령어를 실행해주세요:\nxattr -cr /Applications/SOCARSimulatorManager.app"
            )
            faqItem(
                question: "디바이스 목록이 비어있습니다",
                answer: "Xcode가 설치되어 있는지 확인해주세요.\nXcode 설치 후 한 번은 실행하여 초기 설정을 완료해야 합니다."
            )
            faqItem(
                question: "iOS 버전이 하나도 없습니다",
                answer: "'iOS 버전' 탭에서 원하는 버전을 다운로드하세요.\n다운로드에는 7~10GB의 저장 공간과 수십 분의 시간이 소요됩니다."
            )
            faqItem(
                question: "앱 설치 후 시뮬레이터에 아이콘이 안 보입니다",
                answer: "시뮬레이터의 홈 화면을 좌우로 스와이프하면 다른 페이지에 있을 수 있습니다.\n또는 시뮬레이터 상단의 검색바에서 'SOCAR'를 검색해보세요."
            )
            faqItem(
                question: "Google Drive 빌드 폴더에 접근 권한이 없습니다",
                answer: "모바일팀에 문의하여 Google Drive 폴더 접근 권한을 요청해주세요."
            )
        }
    }

    // MARK: - Components

    private func sectionTitle(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.title2).fontWeight(.bold)
        }
    }

    private func stepCard(step: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(step)")
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.blue))

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(description)
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func featureCard(icon: String, title: String, features: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(.blue)
                Text(title).font(.headline)
            }
            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundStyle(.secondary)
                    Text(feature).font(.callout).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Q. \(question)")
                .font(.callout).fontWeight(.semibold)
            Text(answer)
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
