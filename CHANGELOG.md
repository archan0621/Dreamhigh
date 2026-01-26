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

### 7. 면접 질문/답변 기록 ✅
- 지원 내역 상세 페이지에 면접 질문/답변 섹션 추가
- 전형별 탭 구성
  - 코딩테스트 / 과제
  - 기술 면접
  - 인성 면접
- 전형별 회고 작성 기능
  - 편집/보기 모드 전환
  - 클릭하여 편집 모드 진입
  - 플레이스홀더: "전형을 마친 후 들었던 생각, 느낀 점, 개선할 점 등을 자유롭게 작성하세요"
  - 편집 전후 동일한 박스 크기 (minHeight: 120)
  - 자동 저장 (편집 완료 시)
- 질문 카드 UI
  - 접기/펼치기 기능
  - 질문, 답변, 태그, 메모 표시
  - 수정/삭제 버튼
- 질문 추가 시트
  - 질문 입력 (필수)
  - 답변 입력 (선택)
  - 태그 추가/제거
  - 메모 입력
- 빈 상태 UI (질문이 없을 때)
- CoreData 연동
  - `ApplyHistoryEntity`에 `interviewQuestionsData` 필드 추가 (JSON 문자열)
  - `InterviewData`, `InterviewTypeData`, `InterviewQuestion` 도메인 모델 구현
  - `ApplyHistory`에 `interviewData` 필드 추가
  - `ApplyHistoryStore.updateInterviewData()` 메서드 구현
  - 자동 저장/로드 (질문 추가, 회고 작성, 탭 전환 시)

### 8. AI 취업 인사이트 리포트 ✅
- **합격/불합격 패턴 분석 및 전략 도출**
  - 지원자의 과거 지원 내역과 이력서 피드백을 결합한 심층 분석
  - 이력서에 작성된 실제 내용(강점/약점)을 기반으로 한 정확한 인사이트 제공
  - 회사 유형별(대기업, 스타트업 등) 적합도 및 성과 분석
  - 이력서 레벨(주니어/중급/시니어) 및 JD 정합성 평가
  - 기술적 허영 요소 및 제거 시 가점 항목 등 기술 스택 최적화 제안
  - Phase 1~3 단계별 전략적 액션 아이템 제시
- **데이터 저장 및 히스토리 관리**
  - `InsightReportEntity` CoreData 추가
  - `InsightReportStore`를 통한 분석 결과의 영구 저장 및 관리
  - 생성 일자별 히스토리 목록 UI 구현 (삭제 기능 포함)
  - 분석 완료 시 자동 저장 및 상세 화면 전환
- **UI/UX 개선**
  - 가독성을 최우선으로 한 비즈니스 보고서 스타일의 단일 페이지 레이아웃
  - 분석 설정 화면을 팝업(Sheet) 형태로 개선하여 문맥 유지
  - 표준 네비게이션 적용 (뒤로 가기 버튼 지원)
  - 히스토리 카드에 명확한 제목과 요약 정보 표시
- **프롬프트 엔지니어링 최적화**
  - AI가 채용공고 정보와 이력서 내용을 혼동하지 않도록 프롬프트 구조화
  - 출력 형식을 JSON으로 고정하여 안정적인 데이터 파싱 보장
  - 이력서의 실제 피드백 데이터를 주입하여 분석 정확도 향상

### 9. AI 토큰 사용량 추적 ✅
- **자동 토큰 사용량 기록**
  - Claude API 응답에서 `usage` 객체 자동 파싱 및 저장
  - Input/Output 토큰, 캐시 생성/읽기 토큰 세부 추적
  - 서비스별 분류 (채용공고 분석, 이력서 피드백, 인사이트 리포트)
- **CoreData 기반 영구 저장**
  - `TokenUsageEntity` 추가
  - `TokenUsageStore`를 통한 통계 집계 및 관리
- **Settings 화면 통계 UI**
  - 총 토큰 사용량 및 예상 비용 (USD) 표시
  - Input/Output 토큰 세부 분석
  - 서비스별 사용량 및 호출 횟수 표시
  - Claude Sonnet 4.5 기준 비용 계산 (Input: $3/M, Output: $15/M)
- **실시간 추적**
  - 모든 AI 호출 시 자동으로 토큰 사용량 기록
  - Settings 화면 진입 시 최신 통계 자동 조회

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
