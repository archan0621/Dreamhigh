# Dreamhigh 개발 완료 내역

## 📋 완료된 기능

### 1. 지원 내역 관리 개선

#### 채용공고 링크 추가 ✅
- `ApplyHistory` 모델에 `jobPostingURL: String?` 필드 추가
- `ApplicationDetailSidebar`에 채용공고 링크 입력 필드 추가
- CoreData 엔티티에 `jobPostingURL` 속성 추가
- 링크 저장 및 표시 기능 구현
- `AddApplicationSheet`에 채용공고 링크 입력 필드 추가
- 링크 열기 버튼 추가 (브라우저에서 열기)

#### UI/UX 개선 ✅
- 필수 필드에 빨간 별표(*) 표시 추가 (회사명, 지원일자)
- 면접 상태 기본값을 "대기"로 설정
- 이력서 버전 선택 기능 추가 (지원 내역 추가/수정 시)
- 편집 버튼 위치 개선 (내용 섹션 헤더)
- PDF 썸네일 클릭 가능하도록 수정

#### 채용공고 크롤링 및 정보 정리 ✅
- URL 입력 시 자동으로 채용공고 사이트 크롤링 (전체 내용)
- 크롤링된 원문을 AI로 구조화하여 정보 추출
  - `StructuredJobPosting` 모델 정의
  - 회사명, 포지션, 요구사항, 우대사항, 근무지, 설명 등 기본 정보 추출
  - 채용 형태, 경력 요구사항, 기술 스택, 근무 형태, 마감일 등 추가 정보 추출
  - 급여 정보 제거 (보통 없음)
  - 복리후생 필드 제거
  - 원문은 저장하지 않고 구조화된 데이터만 저장
  - 공통 프롬프트 관리 (`AIPrompts`)
- 추출된 정보를 `ApplyHistory`에 저장 (CoreData `structuredJobPostingData` 필드)
- 크롤링 실패 시 에러 처리 및 사용자 친화적 메시지 표시
- 분석 결과 UI 표시 (항상 표시, 비어있으면 안내 메시지)
- 분석 완료 시 분석 버튼 비활성화
- 네트워크 권한 설정 (macOS App Sandbox)

### 2. AI 설정 및 인증 ✅
- 설정 팝업 UI 구현 (왼쪽 위 메뉴 - macOS Settings Scene)
- AI 제공자 선택 기능 (Claude만 활성화, ChatGPT/Gemini는 주석 처리)
- 토큰 입력 및 저장 기능
- 토큰 검증 및 상태 표시
- 토큰 없을 시 AI 기능 비활성화 처리 (`SettingsStore.shared.isAIConfigured` 전역 값 사용)
- 토큰 보안 저장 (Keychain)
- 토큰 보기/숨기기 기능
- 포커스 관리 (다른 여백 클릭 시 포커스 해제)

### 3. AI 아키텍처 설계 ✅
- AI 서비스 인터페이스 프로토콜 선언
  - 공통 메서드 정의 (채용공고 구조화)
  - `StructuredJobPosting` 모델 정의 (급여 제거, 복리후생 제거, 추가 정보 필드 포함)
- Claude 구현체 (`ClaudeAIService`)
  - Claude API 호출 구현
  - 최신 Claude 4.5 모델 지원
  - 에러 핸들링 (invalidAPIKey, networkError, invalidResponse)
- 팩토리 패턴으로 구현체 선택 및 생성 (`AIServiceFactory`)
- 공통 프롬프트 관리 (`AIPrompts`)
- 모델 선택 기능 (`AIModel` enum, SettingsStore 연동)

### 4. 데이터 모델 확장 ✅
- CoreData 모델 업데이트 (jobPostingURL 추가)
- CoreData 모델 업데이트 (structuredJobPostingData 추가 - JSON 저장)
- `ApplyHistory` 모델에 `structuredJobPosting` 필드 추가
- 분석 결과 저장/로드 로직 구현 (`ApplyHistoryStore.updateStructuredJobPosting`)

### 5. 이력서 AI 피드백 기능 ✅
- CoreData에 AI 피드백 저장 필드 추가 (`aiFeedbackData`)
- `ResumeFeedback` 도메인 모델 구현
  - 종합 점수 (0-100)
  - 첫인상 (3-5줄 요약)
  - 강점 목록 (기술적 강점, 사고방식/태도, 차별점)
  - 개선점 및 약점 목록
  - 면접 예상 질문 목록
  - 섹션별 상세 피드백 (경력, 프로젝트 등)
  - 총평 (CTO 관점)
  - 생성 일시
- AI 프롬프트 작성 (시니어 면접관 관점)
  - 첫인상, 구조/레이아웃, 인간미/태도, 성과/문제해결력, 대외활동, 면접관 판단 기준
  - JSON 출력 형식 명시
- `ClaudeAIService`에 이력서 분석 구현
  - PDF Vision API 사용 (base64 인코딩)
  - 타임아웃 120초 (PDF 분석용)
  - `analyzeResume(pdfPath:)` 메서드
- `ResumeVersionDetailView`에 피드백 UI 구현
  - "피드백 받기" 버튼 (로딩 상태 표시)
  - 피드백 결과 표시 뷰 (`ResumeFeedbackView`)
  - 점수별 색상 표시 (80+ 초록, 60-79 파랑, 40-59 주황, 40 미만 빨강)
  - 강점/개선점 아이콘 및 리스트
  - 면접 질문 번호 매김
  - 섹션별 평가 카드
- AI 토큰 없을 시 기능 비활성화 및 안내 메시지
- CoreData 재조회 로직으로 영속성 보장

### 6. UI/UX 전반 개선 ✅
- App Store 스타일 사이드바 구현
  - 메뉴 아이콘 및 텍스트 크기 증가
  - 간격 조정 (spacing: 8, padding: 4)
  - 깔끔한 레이아웃
- 이력서 버전 목록 페이지 개선
  - NavigationStack 기반 네비게이션
  - 카드 형태 그리드 레이아웃
  - PDF 썸네일 미리보기
  - App Store 스타일 상세보기 전환

## 🔧 기술적 개선사항

### 크롤링 인프라
- 기본 HTML 크롤링 구현 (script, style 태그 제거, HTML 태그 제거)
- 네트워크 에러 핸들링 (DNS 조회 실패, 타임아웃 등)
- macOS App Sandbox 네트워크 권한 설정

## 📝 참고사항

- 모든 AI 기능은 사용자 프라이버시를 고려하여 데이터 처리
- 크롤링 시 robots.txt 및 이용약관 준수
- API 사용량 및 비용 관리 필요
- 오프라인 모드 지원 고려 (로컬 AI 모델)
