//
//  InsightsPage.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/25/26.
//

import SwiftUI
import CoreData

struct InsightsPage: View {
    let context: NSManagedObjectContext
    @StateObject private var applyHistoryStore: ApplyHistoryStore
    @StateObject private var resumeVersionStore: ResumeVersionStore
    @StateObject private var insightReportStore: InsightReportStore
    @StateObject private var tokenUsageStore: TokenUsageStore
    
    @State private var isAnalyzing = false
    @State private var analysisProgress: Double = 0.0
    @State private var analysisError: String? = nil
    
    // 네비게이션 경로 관리를 위한 상태
    @State private var navigationPath: [InsightNavigationTarget] = []
    
    enum InsightNavigationTarget: Hashable {
        case result(UUID) // 리포트 ID
    }
    
    @State private var isShowingSetup = false
    
    init(context: NSManagedObjectContext) {
        self.context = context
        _applyHistoryStore = StateObject(
            wrappedValue: ApplyHistoryStore(context: context)
        )
        _resumeVersionStore = StateObject(
            wrappedValue: ResumeVersionStore(context: context)
        )
        _insightReportStore = StateObject(
            wrappedValue: InsightReportStore(context: context)
        )
        _tokenUsageStore = StateObject(
            wrappedValue: TokenUsageStore(context: context)
        )
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            historyListView
                .navigationTitle("인사이트")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isShowingSetup = true
                        } label: {
                            Label("새 분석", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .navigationDestination(for: InsightNavigationTarget.self) { target in
                    switch target {
                    case .result(let id):
                        if let history = insightReportStore.reports.first(where: { $0.id == id }) {
                            reportDetailView(history.report)
                                .navigationTitle("분석 리포트 상세")
                        } else {
                            Text("리포트를 찾을 수 없습니다.")
                        }
                    }
                }
                .sheet(isPresented: $isShowingSetup) {
                    NavigationStack {
                        analysisSetupView
                            .navigationTitle("인사이트 분석 설정")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("취소") {
                                        isShowingSetup = false
                                    }
                                }
                            }
                    }
                    .frame(width: 600, height: 700) // 팝업 크기 지정
                }
        }
        .onAppear {
            applyHistoryStore.fetch()
            resumeVersionStore.fetch()
            insightReportStore.fetch()
        }
    }
    
    private func reportDetailView(_ report: InsightReport) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 100) {
                // 1. 리포트 헤더
                reportHeader(report)
                
                // 2. 종합 성과 요약
                overallPerformanceSection(report)
                
                // 3. 합격/불합격 심층 패턴 분석
                patternsInDepthSection(report)
                
                // 4. 이력서 버전 및 전략 분석
                resumeStrategySection(report)
                
                // 5. 이력서 레벨 및 JD 적합도
                resumeLevelAndJDSection(report)
                
                // 6. 기술 스택 최적화 제안
                techStackOptimizationSection(report)
                
                // 7. 전략적 액션 아이템
                finalActionPlanSection(report)
                
                // 8. 푸터 및 주의사항
                reportFooter
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 100)
            .frame(maxWidth: 1000, alignment: .leading)
        }
    }
    
    // MARK: - 히스토리 리스트 화면
    private var historyListView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if insightReportStore.reports.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("저장된 인사이트가 없습니다")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Button("새 분석 시작") {
                            isShowingSetup = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(insightReportStore.reports) { history in
                        historyCard(history)
                            .onTapGesture {
                                navigationPath.append(.result(history.id))
                            }
                    }
                }
            }
            .padding(40)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func historyCard(_ history: InsightReportHistory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16, weight: .bold))
                        Text("취업 전략 분석 리포트")
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    HStack(spacing: 8) {
                        Text(formatDate(history.generatedAt))
                        Text("•")
                        Text(formatTime(history.generatedAt))
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    do {
                        try insightReportStore.delete(id: history.id)
                    } catch {
                        analysisError = "삭제 실패: \(error.localizedDescription)"
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            HStack(spacing: 24) {
                statBadge(
                    icon: "tray.fill",
                    label: "총 지원",
                    value: "\(history.totalApplications)건"
                )
                
                statBadge(
                    icon: "checkmark.circle.fill",
                    label: "합격",
                    value: "\(history.acceptedCount)건"
                )
                
                statBadge(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "합격률",
                    value: String(format: "%.1f%%", history.acceptanceRate)
                )
            }
            
            if !history.report.overallPerformance.keyFindings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("핵심 발견사항")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    ForEach(history.report.overallPerformance.keyFindings.prefix(2), id: \.self) { finding in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(finding)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func statBadge(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - 분석 설정 화면
    private var analysisSetupView: some View {
        VStack(spacing: 40) {
            // 상단 헤더 섹션
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Color.accentColor)
                }
                
                VStack(spacing: 8) {
                    Text("인사이트 리포트 생성")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.5)
                    
                    Text("AI가 당신의 지원 패턴과 이력서를 분석하여\n최적의 취업 전략을 도출합니다.")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 20)
            
            // 설정 카드
            VStack(alignment: .leading, spacing: 24) {
                Text("분석 범위 설정")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 16) {
                    // 데이터 소스 요약
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "tray.full.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("지원 내역 데이터")
                                .font(.system(size: 14, weight: .semibold))
                            Text("총 \(acceptedCount + rejectedCount)건의 기록 분석")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 사용된 이력서 정보
                    if !usedResumeVersions.isEmpty {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 36, height: 36)
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("사용된 이력서 버전")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("\(usedResumeVersions.count)개 버전이 지원 내역에 사용됨")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.secondary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // 실행 버튼
                Button(action: startAnalysis) {
                    HStack(spacing: 10) {
                        if isAnalyzing {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "wand.and.stars")
                            Text("리포트 생성 시작")
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        SettingsStore.shared.isAIConfigured ? Color.accentColor : Color.secondary.opacity(0.3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.accentColor.opacity(0.2), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(isAnalyzing || !SettingsStore.shared.isAIConfigured)
                
                if !SettingsStore.shared.isAIConfigured {
                    Text("설정에서 AI API 키를 먼저 등록해주세요.")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: .black.opacity(0.03), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.03), lineWidth: 1)
            )
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - 1. 리포트 헤더
    private func reportHeader(_ report: InsightReport) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("AI INSIGHT REPORT")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.accentColor)
                
                Spacer()
                
                Text("CONFIDENTIAL")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(
                        Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundStyle(.secondary)
            }
            
            Text("데이터 기반 취업 전략 분석 보고서")
                .font(.system(size: 56, weight: .bold))
                .tracking(-1)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 24) {
                    Label("발행일: \(formatDate(report.generatedAt))", systemImage: "calendar")
                    Label("분석 데이터: 지원 내역 \(report.overallPerformance.totalCount)건", systemImage: "database.fill")
                    Label("분석 모델: Claude 4.5 Vision", systemImage: "cpu.fill")
                }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            }
            
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1)
                .padding(.top, 20)
        }
    }
    
    // MARK: - 2. 종합 성과 요약
    private func overallPerformanceSection(_ report: InsightReport) -> some View {
        VStack(alignment: .leading, spacing: 40) {
            sectionHeader(title: "01. 종합 성과 요약", subtitle: "현재까지의 지원 데이터로 도출된 핵심 지표입니다.")
            
            HStack(spacing: 100) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("전체 합격률")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(String(format: "%.0f", report.overallPerformance.acceptanceRate))%")
                            .font(.system(size: 80, weight: .bold))
                        Text("\(report.overallPerformance.acceptedCount) / \(report.overallPerformance.totalCount)")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("주요 성과 요약")
                        .font(.system(size: 18, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(report.overallPerformance.keyFindings, id: \.self) { finding in
                            bulletItem(text: finding)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 3. 합격/불합격 심층 패턴 분석
    private func patternsInDepthSection(_ report: InsightReport) -> some View {
        VStack(alignment: .leading, spacing: 48) {
            sectionHeader(title: "02. 합격/불합격 심층 패턴 분석", subtitle: "성공과 실패 케이스의 환경적, 기술적 공통점을 대조 분석합니다.")
            
            HStack(alignment: .top, spacing: 60) {
                VStack(alignment: .leading, spacing: 32) {
                    Label("합격 케이스의 공통점", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.green)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(report.patterns.acceptedPatterns.enumerated()), id: \.offset) { index, pattern in
                            detailPatternItem(title: pattern.category, content: pattern.value, desc: pattern.description)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 32) {
                    Label("불합격 케이스의 공통점", systemImage: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(report.patterns.rejectedPatterns.enumerated()), id: \.offset) { index, pattern in
                            detailPatternItem(title: pattern.category, content: pattern.value, desc: pattern.description)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - 4. 이력서 버전 및 전략 분석
    private func resumeStrategySection(_ report: InsightReport) -> some View {
        VStack(alignment: .leading, spacing: 48) {
            sectionHeader(title: "03. 이력서 버전 및 스타일 전략", subtitle: "작성 스타일과 버전별 성과를 분석하여 최적의 구성을 제안합니다.")
            
            VStack(alignment: .leading, spacing: 40) {
                // 버전별 통계
                if !report.resumeStrategy.versionPerformance.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("버전별 성과 분석")
                            .font(.system(size: 20, weight: .bold))
                        
                        HStack(spacing: 32) {
                            ForEach(report.resumeStrategy.versionPerformance, id: \.versionName) { perf in
                                let color: Color = perf.status == "BEST" ? .green : perf.status == "NEEDS_IMPROVEMENT" ? .red : .secondary
                                performanceCard(
                                    version: perf.versionName,
                                    document: "\(String(format: "%.0f", perf.documentPassRate))%",
                                    interview: "\(String(format: "%.0f", perf.interviewEntryRate))%",
                                    status: perf.status,
                                    color: color
                                )
                            }
                        }
                    }
                }
                
                // 스타일 분석
                if !report.resumeStrategy.styleEffectiveness.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("콘텐츠 스타일 유효성")
                            .font(.system(size: 20, weight: .bold))
                        
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(report.resumeStrategy.styleEffectiveness, id: \.style) { style in
                                styleEffectRow(title: style.style, effectiveness: style.effectiveness, desc: style.description)
                            }
                        }
                    }
                }
                
                // 그룹별 취약점
                if !report.resumeStrategy.companyGroupFit.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("회사군별 이력서 적합도")
                            .font(.system(size: 20, weight: .bold))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(report.resumeStrategy.companyGroupFit, id: \.companyGroup) { fit in
                                Text("• \(fit.companyGroup): \(fit.description)")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 5. 이력서 레벨 및 JD 적합도
    private func resumeLevelAndJDSection(_ report: InsightReport) -> some View {
        VStack(alignment: .leading, spacing: 48) {
            sectionHeader(title: "04. 시장 인지 레벨 및 JD 적합도", subtitle: "이력서가 시장에 어떻게 비춰지는지, 그리고 JD와의 정렬 상태를 분석합니다.")
            
            HStack(alignment: .top, spacing: 60) {
                VStack(alignment: .leading, spacing: 32) {
                    Text("페르소나 레벨 평가")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 20) {
                            levelLabel(title: "이력서 인지 레벨", value: report.resumeLevelAndJD.personaLevel.perceivedLevel)
                            Image(systemName: "arrow.right").foregroundStyle(.secondary)
                            levelLabel(title: "지원 포지션군", value: report.resumeLevelAndJD.personaLevel.targetPosition)
                        }
                        
                        Text(report.resumeLevelAndJD.personaLevel.description)
                            .font(.system(size: 16))
                            .lineSpacing(6)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 32) {
                    Text("JD 정렬 (Alignment) 상태")
                        .font(.system(size: 20, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(report.resumeLevelAndJD.jdAlignment, id: \.type) { alignment in
                            alignmentItem(type: alignment.type, count: alignment.count, desc: alignment.description)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - 6. 기술 스택 최적화 제안
    private func techStackOptimizationSection(_ report: InsightReport) -> some View {
        VStack(alignment: .leading, spacing: 48) {
            sectionHeader(title: "05. 기술 스택 최적화 제안", subtitle: "평가에 도움이 되지 않거나 방해가 되는 요소를 제거하여 가독성을 높입니다.")
            
            VStack(alignment: .leading, spacing: 40) {
                HStack(alignment: .top, spacing: 40) {
                    optimizationBox(title: "실제 평가에 도움 안 되는 기술", items: report.techStackOptimization.unhelpfulTechs, color: .secondary)
                    optimizationBox(title: "기술적 허영으로 오해될 요소", items: report.techStackOptimization.vanityTechs, color: .orange)
                    optimizationBox(title: "빠졌을 때 더 좋아질 항목", items: report.techStackOptimization.shouldRemove, color: .blue)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("💡 Expert Tip")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                    Text(report.techStackOptimization.expertTip)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .background(Color.accentColor.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - 7. 전략적 액션 아이템
    private func finalActionPlanSection(_ report: InsightReport) -> some View {
        VStack(alignment: .leading, spacing: 48) {
            sectionHeader(title: "06. 전략적 액션 아이템", subtitle: "성공률을 2배 이상 높이기 위한 단계별 실행 계획입니다.")
            
            VStack(alignment: .leading, spacing: 32) {
                ForEach(report.actionPlan.phases, id: \.phase) { phase in
                    actionStepRow(step: phase.phase, title: phase.title, tasks: phase.tasks)
                }
            }
        }
    }
    
    // MARK: - 8. 푸터 및 주의사항
    private var reportFooter: some View {
        VStack(alignment: .leading, spacing: 24) {
            Divider()
            
            Text("데이터 해석 시 유의사항")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.secondary)
            
            Text("본 리포트는 인공지능이 과거의 통계적 패턴을 분석한 결과입니다. 실제 채용은 면접관의 주관적 취향, 회사의 시급한 상황, 당일의 컨디션 등 비결정적인 요소가 복합적으로 작용합니다. 따라서 이 리포트를 절대적 기준으로 삼기보다 전략 수립을 위한 참고 자료로 활용하시기 바랍니다.")
                .font(.system(size: 14))
                .lineSpacing(6)
                .foregroundStyle(.tertiary)
            
            HStack {
                Text("Dreamhigh Insight Engine v1.0")
                Spacer()
                Text("Generated for Archan")
            }
            .font(.system(size: 12))
            .foregroundStyle(.quaternary)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Helper Components
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
            Text(subtitle)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        }
    }
    
    private func bulletItem(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•").foregroundStyle(Color.accentColor)
            Text(text.replacingOccurrences(of: "**", with: "")) // Simple plain text for now, can be styled with AttributedString
                .font(.system(size: 18))
                .foregroundStyle(.primary.opacity(0.8))
        }
    }
    
    private func detailPatternItem(title: String, content: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
            Text(content)
                .font(.system(size: 20, weight: .semibold))
            Text(desc)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
    }
    
    private func performanceCard(version: String, document: String, interview: String, status: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(version).font(.system(size: 18, weight: .bold))
                Spacer()
                Text(status)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 32) {
                VStack(alignment: .leading) {
                    Text("서류 통과").font(.system(size: 12)).foregroundStyle(.secondary)
                    Text(document).font(.system(size: 24, weight: .bold))
                }
                VStack(alignment: .leading) {
                    Text("면접 진입").font(.system(size: 12)).foregroundStyle(.secondary)
                    Text(interview).font(.system(size: 24, weight: .bold))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func styleEffectRow(title: String, effectiveness: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.system(size: 18, weight: .semibold))
                Spacer()
                Text(effectiveness)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(effectiveness == "매우 높음" ? .green : .orange)
            }
            Text(desc)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 12)
    }
    
    private func levelLabel(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 18, weight: .bold))
        }
    }
    
    private func alignmentItem(type: String, count: Int, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(type).font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(count)건").font(.system(size: 14)).foregroundStyle(.secondary)
            }
            Text(desc).font(.system(size: 14)).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func optimizationBox(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func actionStepRow(step: String, title: String, tasks: [String]) -> some View {
        HStack(alignment: .top, spacing: 32) {
            Text(step)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.system(size: 20, weight: .bold))
                ForEach(tasks, id: \.self) { task in
                    HStack(spacing: 12) {
                        Image(systemName: "circle.fill").font(.system(size: 6)).foregroundStyle(.secondary)
                        Text(task).font(.system(size: 16))
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var acceptedCount: Int {
        applyHistoryStore.items.filter { $0.documentStatus.lowercased().contains("합격") || 
                                         $0.documentStatus.lowercased().contains("pass") ||
                                         $0.documentStatus.lowercased().contains("accept") }.count
    }
    
    private var rejectedCount: Int {
        applyHistoryStore.items.filter { $0.documentStatus.lowercased().contains("불합격") || 
                                         $0.documentStatus.lowercased().contains("fail") ||
                                         $0.documentStatus.lowercased().contains("reject") }.count
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy. MM. dd"
        return dateFormatter.string(from: date)
    }
    
    private var usedResumeVersions: [ResumeVersion] {
        let usedVersionIds = Set(applyHistoryStore.items.compactMap { $0.resumeVersionId })
        return resumeVersionStore.versions.filter { usedVersionIds.contains($0.id) }
    }
    
    private func startAnalysis() {
        guard SettingsStore.shared.isAIConfigured,
              let aiService = AIServiceFactory.createServiceFromSettings(tokenUsageStore: tokenUsageStore) else {
            analysisError = "AI 서비스를 설정해주세요."
            return
        }
        
        guard !applyHistoryStore.items.isEmpty else {
            analysisError = "분석할 지원 내역이 없습니다."
            return
        }
        
        isAnalyzing = true
        analysisError = nil
        
        Task {
            do {
                // 지원 내역에 실제로 사용된 이력서 버전만 전달
                let report = try await aiService.generateInsightReport(
                    applyHistories: applyHistoryStore.items,
                    resumeVersions: usedResumeVersions,
                    targetResumeVersionId: nil // 항상 전체 종합 분석
                )
                
                await MainActor.run {
                    // 리포트 저장
                    do {
                        let newHistory = try insightReportStore.saveAndReturn(report: report)
                        
                        isAnalyzing = false
                        isShowingSetup = false // 팝업 닫기
                        
                        // 결과 화면으로 이동
                        navigationPath.append(.result(newHistory.id))
                    } catch {
                        print("리포트 저장 실패: \(error)")
                        isAnalyzing = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.analysisError = "분석 중 오류가 발생했습니다: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
}

#Preview {
    InsightsPage(context: PersistenceController.shared.container.viewContext)
}
