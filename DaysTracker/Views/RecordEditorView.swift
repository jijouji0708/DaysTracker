import SwiftUI

struct RecordEditorView: View {
    @Binding var record: EventRecord
    var isEditing: Bool
    
    var onSave: () -> Void
    var onCancel: () -> Void
    var onDelete: (() -> Void)? // 削除用コールバック（オプショナル）
    
    @Environment(\.colorScheme) var colorScheme
    @State private var animateIn: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid Glass Background
                LiquidGlassBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header icon
                        headerIcon
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                        
                        // Date picker section
                        datePickerSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                        
                        // Note section
                        noteSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            
                        // Delete Button (Only for existing records)
                        if isEditing, let onDelete = onDelete {
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("この記録を削除")
                                }
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.top, 20)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        Text("キャンセル")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color.liquidGlassAccent)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(isEditing ? "記録を編集" : "新しい記録")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onSave) {
                        Text("保存")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.liquidGlassAccent)
                            )
                    }
                }
            }
            // Delete Confirmation Dialog
            .confirmationDialog("この記録を削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    onDelete?()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Header Icon
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 90, height: 90)
            
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4),
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 90, height: 90)
            
            Image(systemName: isEditing ? "pencil.and.outline" : "calendar.badge.plus")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.liquidGlassAccent, Color.liquidGlassSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .shadow(color: Color.liquidGlassAccent.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Date Picker Section
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.liquidGlassAccent)
                
                Text("実施日")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
            }
            .padding(.leading, 4)
            
            // Date picker card
            VStack {
                DatePicker("", selection: $record.date, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                    .tint(Color.liquidGlassAccent)
            }
            .padding(16)
            .glassCard(cornerRadius: 18)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: record.date)
    }
    
    // MARK: - Note Section
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.liquidGlassAccent)
                
                Text("メモ")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                
                Text("(任意)")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.leading, 4)
            
            // Note text editor
            ZStack(alignment: .topLeading) {
                if record.note.isEmpty {
                    Text("メモを入力...")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $record.note)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 100, maxHeight: 200)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .glassCard(cornerRadius: 18)
        }
    }
}

struct RecordEditorView_Previews: PreviewProvider {
    @State static var tempRecord = EventRecord(date: Date(), note: "")
    static var previews: some View {
        RecordEditorView(
            record: $tempRecord,
            isEditing: false,
            onSave: {},
            onCancel: {}
        )
        .preferredColorScheme(.dark)
    }
}
