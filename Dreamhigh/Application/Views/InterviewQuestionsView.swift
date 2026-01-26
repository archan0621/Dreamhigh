//
//  InterviewQuestionsView.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/25/26.
//

import SwiftUI

// MARK: - 지원 내역 상세 페이지에 들어갈 섹션
struct InterviewQuestionsSection: View {
    let applicationId: UUID
    
    @State private var selectedTab: InterviewTab = .codingOrAssignment
    @State private var questions: [InterviewQuestion] = []
    @State private var isAddingQuestion = false
    @State private var reflectionText: String = ""
    @State private var isEditingReflection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 탭 선택
            Picker("면접 유형", selection: $selectedTab) {
                ForEach(InterviewTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            
            // 회고/생각 정리
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(selectedTab.rawValue) 회고")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(action: { isEditingReflection.toggle() }) {
                        Label(isEditingReflection ? "저장" : "편집", systemImage: isEditingReflection ? "checkmark" : "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                ZStack(alignment: .topLeading) {
                    if isEditingReflection {
                        TextField("전형을 마친 후 들었던 생각, 느낀 점, 개선할 점 등을 자유롭게 작성하세요", text: $reflectionText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .lineLimit(5...15)
                    } else {
                        if reflectionText.isEmpty {
                            Text("전형을 마친 후 들었던 생각, 느낀 점, 개선할 점 등을 자유롭게 작성하세요")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    isEditingReflection = true
                                }
                        } else {
                            Text(reflectionText)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            
            // 질문 목록
            VStack(spacing: 12) {
                if questions.isEmpty {
                    // 빈 상태
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.bubble")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        
                        Text("아직 \(selectedTab.rawValue) 질문이 없습니다")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button(action: { isAddingQuestion = true }) {
                            Label("질문 추가", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // 질문 카드
                    ForEach(questions) { question in
                        InterviewQuestionCard(question: question)
                    }
                    
                    // 추가 버튼
                    Button(action: { isAddingQuestion = true }) {
                        Label("질문 추가", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $isAddingQuestion) {
            AddInterviewQuestionSheet(
                interviewType: selectedTab,
                onSave: { question in
                    // TODO: 실제 저장 로직
                    questions.append(question)
                }
            )
        }
    }
}

// MARK: - 전체 화면 (필요시 사용)
struct InterviewQuestionsView: View {
    let applicationId: UUID
    
    @State private var selectedTab: InterviewTab = .technical
    @State private var questions: [InterviewQuestion] = []
    @State private var isAddingQuestion = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 탭 선택
            Picker("면접 유형", selection: $selectedTab) {
                ForEach(InterviewTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // 질문 목록
            ScrollView {
                VStack(spacing: 16) {
                    if questions.isEmpty {
                        // 빈 상태
                        VStack(spacing: 16) {
                            Image(systemName: "questionmark.bubble")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Text("아직 \(selectedTab.rawValue) 질문이 없습니다")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("아래 버튼을 눌러 질문을 추가해보세요")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    } else {
                        // 질문 카드
                        ForEach(questions) { question in
                            InterviewQuestionCard(question: question)
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // 하단 버튼
            HStack {
                Spacer()
                
                Button(action: { isAddingQuestion = true }) {
                    Label("질문 추가", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .sheet(isPresented: $isAddingQuestion) {
            AddInterviewQuestionSheet(
                interviewType: selectedTab,
                onSave: { question in
                    // TODO: 실제 저장 로직
                    questions.append(question)
                }
            )
        }
    }
}

struct InterviewQuestionCard: View {
    let question: InterviewQuestion
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.question)
                        .font(.headline)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    HStack(spacing: 8) {
                        ForEach(question.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Divider()
                
                // 답변
                VStack(alignment: .leading, spacing: 8) {
                    Text("답변")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    if let answer = question.answer, !answer.isEmpty {
                        Text(answer)
                            .font(.body)
                            .foregroundStyle(.primary)
                    } else {
                        Text("답변을 작성해주세요")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                }
                
                // 메모
                if let notes = question.notes, !notes.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("메모")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 하단 액션
                HStack {
                    Spacer()
                    
                    Button(action: {}) {
                        Label("수정", systemImage: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {}) {
                        Label("삭제", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AddInterviewQuestionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let interviewType: InterviewTab
    let onSave: (InterviewQuestion) -> Void
    
    @State private var question = ""
    @State private var answer = ""
    @State private var notes = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("질문 추가")
                    .font(.headline)
                
                Spacer()
                
                Button("취소") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // 폼
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 면접 유형 표시
                    VStack(alignment: .leading, spacing: 8) {
                        Text("면접 유형")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(interviewType.rawValue)
                            .font(.body)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // 질문
                    VStack(alignment: .leading, spacing: 8) {
                        Text("질문 *")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("면접에서 받은 질문을 입력하세요", text: $question, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .lineLimit(3...10)
                    }
                    
                    // 답변
                    VStack(alignment: .leading, spacing: 8) {
                        Text("답변")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("면접 때 한 답변 또는 준비한 답변을 입력하세요", text: $answer, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .lineLimit(5...15)
                    }
                    
                    // 태그
                    VStack(alignment: .leading, spacing: 8) {
                        Text("태그")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            TextField("태그 입력 후 Enter", text: $tagInput)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onSubmit {
                                    if !tagInput.isEmpty {
                                        tags.append(tagInput)
                                        tagInput = ""
                                    }
                                }
                        }
                        
                        if !tags.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                        
                                        Button(action: { tags.removeAll { $0 == tag } }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    // 메모
                    VStack(alignment: .leading, spacing: 8) {
                        Text("메모")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("추가 메모나 개선점을 입력하세요", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .lineLimit(3...8)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // 하단 버튼
            HStack {
                Spacer()
                
                Button("취소") {
                    dismiss()
                }
                
                Button("저장") {
                    let newQuestion = InterviewQuestion(
                        id: UUID(),
                        question: question,
                        answer: answer.isEmpty ? nil : answer,
                        interviewType: interviewType,
                        tags: tags,
                        notes: notes.isEmpty ? nil : notes,
                        createdAt: Date()
                    )
                    onSave(newQuestion)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(question.isEmpty)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }
}

// MARK: - Models (임시)

enum InterviewTab: String, CaseIterable {
    case codingOrAssignment = "코딩테스트 / 과제"
    case technical = "기술 면접"
    case personality = "인성 면접"
}

struct InterviewQuestion: Identifiable {
    let id: UUID
    let question: String
    let answer: String?
    let interviewType: InterviewTab
    let tags: [String]
    let notes: String?
    let createdAt: Date
}

#Preview {
    InterviewQuestionsView(applicationId: UUID())
}
