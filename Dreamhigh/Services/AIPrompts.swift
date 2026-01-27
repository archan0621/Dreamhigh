//
//  AIPrompts.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation

enum AIPrompts {
    /// 채용공고 구조화 프롬프트
    static func structureJobPosting(_ jobPostingText: String) -> String {
        """
        다음 채용공고 텍스트를 구조화된 JSON 형식으로 변환해주세요.
        다음 필드들을 추출해주세요:
        - companyName: 회사명
        - position: 포지션/직무명
        - requirements: 필수 요구사항 (배열)
        - preferredQualifications: 우대사항 (배열)
        - location: 근무지
        - description: 상세 설명
        - employmentType: 채용 형태 (정규직, 계약직, 인턴, 파트타임 등)
        - experienceLevel: 경력 요구사항 (신입, 경력, 경력 무관, N년차 이상 등)
        - techStack: 기술 스택 (배열, 예: ["Swift", "SwiftUI", "iOS"] 등)
        - workType: 근무 형태 (재택근무, 출근근무, 하이브리드 등)
        - deadline: 마감일 (있는 경우)
        
        각 필드는 해당 정보가 없으면 null로 설정하세요.
        JSON 형식으로만 응답해주세요. 다른 설명은 포함하지 마세요.
        
        채용공고 텍스트:
        \(jobPostingText)
        """
    }
    
    /// 이력서 피드백 프롬프트
    static let reviewResume = """
        너는 다음 조건을 만족하는 시니어 면접관이다.
        
        - 스타트업부터 대기업까지 모두 경험한 CTO 또는 Tech Lead
        - 연간 수십~수백 장의 이력서를 검토하며, 
          "이 사람이 실제로 같이 일하고 싶은 사람인가"를 기준으로 판단한다
        - 기술적 깊이뿐 아니라 판단력, 문제 정의 능력, 인간미, 성장 가능성을 중요하게 본다
        - 기술적 허영심, 과도한 포장, 의미 없는 프로젝트를 매우 빠르게 걸러낸다
        - 면접에서 실제로 물어볼 질문까지 염두에 두고 이력서를 평가한다
        
        아래에 제공되는 pdf는 한 명의 지원자가 제출한 이력서이다.
        형식은 자유롭고, 구직 사이트에서 자동 생성된 형식일 수도 있고,
        지원자가 직접 구조를 설계해 정리한 것일 수도 있다.
        
        이력서의 문구, 구성, 레이아웃 묘사, 표현 방식만을 바탕으로
        면접관의 관점에서 종합적인 평가를 수행하라.
        
        다음 관점들을 반드시 모두 고려해서 평가하라.
        
        1. 첫인상
        - 이력서가 '구직 사이트 자동 생성'처럼 보이는지, 
          아니면 지원자가 직접 고민해서 정리한 흔적이 보이는지
        - 전체 가독성, 정보 밀도, 읽는 피로도
        - "읽고 싶게 만드는가, 아니면 스킵하고 싶어지는가"
        
        2. 구조와 레이아웃
        - 핵심 정보가 빠르게 눈에 들어오는지
        - 문단 구성, 불필요한 중복, 정리 수준
        - 기술 나열형 이력서인지, 문제 해결 중심 구조인지
        
        3. 내용의 인간미와 태도
        - 단순한 기술 스택 나열인지, 
          아니면 왜 그런 선택을 했는지가 드러나는지
        - 너무 화려한 기술 위주로 기술적 허영심이 느껴지지는 않는지
        - 반대로 "CRUD 구현", "기본 기능 개발" 같은 설명만 반복되어
          실력이 얕아 보이지는 않는지
        - 이 사람이 '독종으로 끝까지 파고드는 타입인지',
          아니면 '지시받은 것만 하는 타입인지'
        
        4. 성과와 문제 해결력
        - STAR 기법(Situation, Task, Action, Result)이 자연스럽게 녹아 있는지
        - 수치, 지표, 전후 비교가 있는지
        - 결과가 모호한 서술("기여함", "개선함")에 그치지 않는지
        
        5. 대외 활동 및 확장성
        - 블로그, GitHub, 오픈소스 기여, 사이드 프로젝트 유무
        - 단순한 토이 프로젝트(예: 투두 앱, 클론 코딩)에 그치지 않는지
        - 실제 생활이나 현실 문제를 해결하려는 시도가 보이는지
        - 남들과 다른 관점이나 문제 설정이 드러나는지
        
        6. 면접관의 본능적 판단
        - 이 사람을 실제로 면접에서 불러보고 싶은지
        - 함께 일했을 때 성장할 가능성이 있는지
        - 팀에 긍정적인 긴장감이나 기준을 만들어줄 사람인지
        
        다음 JSON 형식으로만 응답하라. 다른 설명은 포함하지 마라.
        
        {
          "overallScore": 0-100 사이의 정수,
          "firstImpression": "3-5줄의 첫인상 요약",
          "strengths": [
            "기술적 강점 1",
            "기술적 강점 2",
            "사고방식/태도 강점 1",
            "차별점"
          ],
          "improvements": [
            "약점/리스크 1",
            "개선 제안 1 (구체적으로, Before → After 형식 포함 가능)",
            "개선 제안 2"
          ],
          "interviewQuestions": [
            "검증 질문 1",
            "검증 질문 2",
            "의심 질문 1"
          ],
          "sectionFeedback": [
            {
              "sectionName": "경력",
              "score": 0-100,
              "feedback": "해당 섹션에 대한 구체적 피드백"
            },
            {
              "sectionName": "프로젝트",
              "score": 0-100,
              "feedback": "해당 섹션에 대한 구체적 피드백"
            }
          ],
          "summary": "1-2줄의 총평 (CTO가 내부 공유용으로 남길 법한 문장)"
        }
        """
    
    /// 인사이트 리포트 생성 프롬프트
    static func generateInsightReport(
        applyHistories: [ApplyHistory],
        resumeVersions: [ResumeVersion],
        targetResumeVersionId: UUID?
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 단계별 합격 판단 헬퍼 함수
        func isPassedStatus(_ status: String) -> Bool {
            let lowered = status.lowercased()
            return !lowered.contains("불합격") && !lowered.contains("탈락") && 
                   !lowered.contains("fail") && !lowered.contains("reject") &&
                   (lowered.contains("합격") || lowered.contains("pass") || lowered.contains("accept"))
        }
        
        // 전형 단계별 통과 집계
        let documentPassCount = applyHistories.filter { isPassedStatus($0.documentStatus) }.count
        let techInterviewPassCount = applyHistories.filter { 
            !$0.techInterviewStatus.isEmpty && isPassedStatus($0.techInterviewStatus)
        }.count
        let cultureInterviewPassCount = applyHistories.filter { 
            !$0.cultureInterviewStatus.isEmpty && isPassedStatus($0.cultureInterviewStatus)
        }.count
        
        // 최종 합격 (모든 단계 통과)
        let finalPassCount = applyHistories.filter { history in
            isPassedStatus(history.documentStatus) &&
            (history.techInterviewStatus.isEmpty || isPassedStatus(history.techInterviewStatus)) &&
            (history.cultureInterviewStatus.isEmpty || isPassedStatus(history.cultureInterviewStatus))
        }.count
        
        let totalCount = applyHistories.count
        let acceptanceRate = totalCount > 0 ? Double(finalPassCount) / Double(totalCount) * 100 : 0.0
        
        // 회사 유형별 분류 (CoreData의 category 그대로 사용)
        var companyTypes: [String: [ApplyHistory]] = [:]
        var techStacks: [String: Int] = [:]
        
        for history in applyHistories {
            // category 필드를 그대로 사용 (추정하지 않음)
            let companyType = history.category.isEmpty ? "미분류" : history.category
            
            if companyTypes[companyType] == nil {
                companyTypes[companyType] = []
            }
            companyTypes[companyType]?.append(history)
            
            // 기술 스택 수집
            if let techStack = history.structuredJobPosting?.techStack {
                for tech in techStack {
                    techStacks[tech, default: 0] += 1
                }
            }
        }
        
        // 이력서 버전별 통계
        var versionStats: [String: (documentPass: Int, interviewEntry: Int, total: Int)] = [:]
        for history in applyHistories {
            let versionName = history.resumeVersionId.flatMap { id in
                resumeVersions.first { $0.id == id }?.name
            } ?? "미지정"
            
            var stats = versionStats[versionName] ?? (0, 0, 0)
            stats.total += 1
            
            let status = history.documentStatus.lowercased()
            // "불합격"이 아닌 경우에만 "합격" 키워드 체크
            if !status.contains("불합격") && !status.contains("탈락") && !status.contains("fail") && !status.contains("reject") &&
               (status.contains("합격") || status.contains("pass")) {
                stats.documentPass += 1
            }
            
            if !history.techInterviewStatus.isEmpty || !history.cultureInterviewStatus.isEmpty {
                stats.interviewEntry += 1
            }
            
            versionStats[versionName] = stats
        }
        
        // 지원 내역 상세 정보
        var historyDetails = "지원 내역:\n"
        for (index, history) in applyHistories.enumerated() {
            let versionName = history.resumeVersionId.flatMap { id in
                resumeVersions.first { $0.id == id }?.name
            } ?? "미지정"
            
            historyDetails += """
            \(index + 1). 회사: \(history.companyName)
               - 지원일: \(dateFormatter.string(from: history.appliedAt))
               - 카테고리: \(history.category)
               - 서류 결과: \(history.documentStatus)
               - 기술 면접: \(history.techInterviewStatus.isEmpty ? "없음" : history.techInterviewStatus)
               - 인성 면접: \(history.cultureInterviewStatus.isEmpty ? "없음" : history.cultureInterviewStatus)
               - 사용 이력서: \(versionName)
               - 기술 스택: \(history.structuredJobPosting?.techStack?.joined(separator: ", ") ?? "정보 없음")
            
            """
        }
        
        // 이력서 버전 정보 및 실제 내용
        var resumeDetails = "=== 이력서 실제 내용 분석 ===\n\n"
        for version in resumeVersions {
            resumeDetails += """
            [이력서: \(version.name)] (생성일: \(dateFormatter.string(from: version.createdAt)))
            
            """
            
            // AI 피드백이 있으면 이력서의 실제 강점/약점 포함
            if let feedback = version.aiFeedback {
                resumeDetails += """
                **이 이력서의 실제 강점 (AI 분석 기반):**
                \(feedback.strengths.map { "- \($0)" }.joined(separator: "\n"))
                
                **이 이력서의 개선점:**
                \(feedback.improvements.map { "- \($0)" }.joined(separator: "\n"))
                
                **첫인상:**
                \(feedback.firstImpression)
                
                **종합 평가 (100점 만점):** \(feedback.overallScore)점
                
                """
            } else {
                resumeDetails += "(이력서 내용 분석 없음)\n\n"
            }
        }
        
        return """
        # 역할
        당신은 취업 데이터 분석가입니다. 지원자의 이력서 내용과 지원 결과를 분석하여, 어떤 이력서 요소가 합격/불합격으로 이어졌는지 패턴을 찾아냅니다.
        
        # 분석 규칙
        1. **이력서 강점 섹션에 명시된 내용만 언급할 것**
        2. 채용공고 기술 스택은 참고만 하고, 절대 이력서 내용인 것처럼 언급 금지
        3. 추측하지 말고, 제공된 데이터만 사용할 것
        4. **중요: 아래 제공된 지원 내역은 정확히 \(totalCount)건이며, 이 숫자를 그대로 사용할 것**
        5. **중요: 전형 단계별 통과 현황을 정확히 반영할 것**
        
        # 입력 데이터
        
        
        ## 1. 전체 통계 (반드시 이 숫자를 그대로 사용)
        - 총 지원 건수: \(totalCount)건
        - 서류 통과: \(documentPassCount)건 (\(String(format: "%.1f", totalCount > 0 ? Double(documentPassCount) / Double(totalCount) * 100 : 0))%)
        - 기술 면접 통과: \(techInterviewPassCount)건
        - 인성 면접 통과: \(cultureInterviewPassCount)건
        - 최종 합격: \(finalPassCount)건 (합격률 \(String(format: "%.1f", acceptanceRate))%)
        
        ## 2. 이력서 실제 내용 (분석 기준)
        \(resumeDetails)
        
        ## 3. 회사별 지원 결과
        \(historyDetails)
        
        ## 4. 이력서 버전별 성과
        \(versionStats.map { version, stats in
            let docRate = stats.total > 0 ? Double(stats.documentPass) / Double(stats.total) * 100 : 0
            let interviewRate = stats.total > 0 ? Double(stats.interviewEntry) / Double(stats.total) * 100 : 0
            return "- \(version): 서류 \(String(format: "%.0f", docRate))% / 면접 \(String(format: "%.0f", interviewRate))%"
        }.joined(separator: "\n"))
        
        ## 5. 회사 유형 분포
        \(companyTypes.map { "- \($0.key): \($0.value.count)건" }.joined(separator: "\n"))
        
        # 출력 형식 (JSON만 반환)
        
        
        ```json
        {
          "overallPerformance": {
            "acceptanceRate": \(String(format: "%.1f", acceptanceRate)),
            "acceptedCount": \(finalPassCount),
            "totalCount": \(totalCount),
            "stageStats": {
              "document": {"passed": \(documentPassCount), "rate": \(String(format: "%.1f", totalCount > 0 ? Double(documentPassCount) / Double(totalCount) * 100 : 0))},
              "techInterview": {"passed": \(techInterviewPassCount), "rate": \(String(format: "%.1f", documentPassCount > 0 ? Double(techInterviewPassCount) / Double(documentPassCount) * 100 : 0))},
              "cultureInterview": {"passed": \(cultureInterviewPassCount), "rate": \(String(format: "%.1f", documentPassCount > 0 ? Double(cultureInterviewPassCount) / Double(documentPassCount) * 100 : 0))}
            },
            "keyFindings": ["이력서 기반 핵심 발견 3개"]
          },
          "patterns": {
            "acceptedPatterns": [
              {"category": "이력서 강점", "value": "이력서의 실제 강점", "description": "왜 합격했는지"},
              {"category": "회사 환경", "value": "합격률 높은 회사 유형", "description": "이 환경과 이력서의 매칭"}
            ],
            "rejectedPatterns": [
              {"category": "이력서 약점", "value": "이력서의 실제 약점", "description": "왜 불합격했는지"},
              {"category": "회사 환경", "value": "불합격률 높은 회사 유형", "description": "이 환경에서 이력서 부족한 점"}
            ]
          },
          "resumeStrategy": {
            "versionPerformance": [
              {"versionName": "버전명", "documentPassRate": 0, "interviewEntryRate": 0, "status": "BEST|NORMAL|NEEDS_IMPROVEMENT"}
            ],
            "styleEffectiveness": [
              {"style": "임팩트 중심", "effectiveness": "매우 높음|높음|보통|낮음", "description": "왜 효과적인지"},
              {"style": "기술 중심", "effectiveness": "매우 높음|높음|보통|낮음", "description": "왜 효과적인지"}
            ],
            "companyGroupFit": [
              {"companyGroup": "대기업", "fitLevel": "높음|보통|낮음", "description": "이력서 적합도"}
            ]
          },
          "resumeLevelAndJD": {
            "personaLevel": {
              "perceivedLevel": "시니어|중급|주니어",
              "targetPosition": "타겟 포지션",
              "description": "이력서 레벨 설명"
            },
            "jdAlignment": [
              {"type": "Overqualified", "count": 0, "description": "설명"},
              {"type": "Underqualified", "count": 0, "description": "설명"}
            ]
          },
          "techStackOptimization": {
            "unhelpfulTechs": ["이력서의 도움 안 된 요소"],
            "vanityTechs": ["이력서의 허영 요소"],
            "shouldRemove": ["이력서에서 제거할 항목"],
            "expertTip": "이력서 개선 팁"
          },
          "actionPlan": {
            "phases": [
              {"phase": "Phase 1", "title": "이력서 고도화", "tasks": ["작업1", "작업2"]},
              {"phase": "Phase 2", "title": "지원 타겟 최적화", "tasks": ["작업1", "작업2"]},
              {"phase": "Phase 3", "title": "면접 대비", "tasks": ["작업1", "작업2"]}
            ]
          }
        }
        ```
        """
    }
}
