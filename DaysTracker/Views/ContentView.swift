import SwiftUI

struct EditorConfig: Identifiable {
    let id = UUID()
    var eventIndex: Int
    var recordID: UUID? // 新規追加時はnil
    var draftRecord: EventRecord
    var isNewRecord: Bool
}

struct ContentView: View {
    @State private var events: [Event] = [] {
        didSet {
            saveEvents()
        }
    }
    
    @State private var newEventTitle: String = ""
    
    // シート表示管理用の状態変数
    @State private var editingState: EditorConfig?
    
    @State private var searchText: String = ""
    @State private var isEditing: Bool = false
    @State private var showAddEventSheet: Bool = false
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                // Liquid Glass animated background
                LiquidGlassBackground()
                
                VStack(spacing: 0) {
                    // Header with title and controls
                    headerView
                    
                    // Search bar (when in edit mode)
                    if isEditing {
                        searchBarView
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                    
                    // Events list or empty state
                    if events.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { _, event in
                                    EventGlassCard(
                                        event: event,
                                        isExpanded: event.isExpanded,
                                        onToggleExpand: { toggleExpand(for: event.id) },
                                        onQuickAdd: {
                                            if let eventIndex = events.firstIndex(where: { $0.id == event.id }) {
                                                let newRecord = EventRecord(date: Date(), note: "")
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    events[eventIndex].records.append(newRecord)
                                                }
                                                provideHapticFeedback(.success)
                                            }
                                        },
                                        onAddRecord: {
                                            if let eventIndex = events.firstIndex(where: { $0.id == event.id }) {
                                                editingState = EditorConfig(
                                                    eventIndex: eventIndex,
                                                    recordID: nil,
                                                    draftRecord: EventRecord(date: Date(), note: ""),
                                                    isNewRecord: true
                                                )
                                            }
                                        },
                                        onEditRecord: { recordID in
                                            if let eventIndex = events.firstIndex(where: { $0.id == event.id }),
                                               let recordIndex = events[eventIndex].records.firstIndex(where: { $0.id == recordID }) {
                                                editingState = EditorConfig(
                                                    eventIndex: eventIndex,
                                                    recordID: recordID,
                                                    draftRecord: events[eventIndex].records[recordIndex],
                                                    isNewRecord: false
                                                )
                                            }
                                        },
                                        sortedRecords: sortedRecords(for: event),
                                        daysFromPrevious: { record in
                                            if let eventIndex = events.firstIndex(where: { $0.id == event.id }) {
                                                return daysFromPreviousRecord(eventIndex: eventIndex, record: record)
                                            }
                                            return 0
                                        },
                                        onDeleteRecord: { recordID in
                                            deleteRecord(eventID: event.id, recordID: recordID)
                                        },
                                        onDeleteEvent: {
                                            if let eventIndex = events.firstIndex(where: { $0.id == event.id }) {
                                                _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    events.remove(at: eventIndex)
                                                }
                                                provideHapticFeedback(.warning)
                                            }
                                        },
                                        isEditMode: isEditing
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 100)
                        }
                    }
                }
                
                // Floating action button to add new event
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addEventButton
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
        // シート表示ロジックを item ベースに変更（データ安全性の向上）
        .sheet(item: $editingState) { config in
            RecordEditorView(
                record: Binding(
                    get: { config.draftRecord },
                    set: { 
                        if var state = editingState {
                            state.draftRecord = $0
                            editingState = state
                        }
                    }
                ),
                isEditing: !config.isNewRecord,
                onSave: {
                    if let index = events.indices.contains(config.eventIndex) ? config.eventIndex : nil {
                        if config.isNewRecord {
                            // 新規追加
                            events[index].records.append(config.draftRecord)
                        } else if let recordID = config.recordID,
                                  let recordIndex = events[index].records.firstIndex(where: { $0.id == recordID }) {
                            // 既存更新
                            events[index].records[recordIndex] = config.draftRecord
                        }
                        provideHapticFeedback(.success)
                    }
                    editingState = nil
                },
                onCancel: {
                    editingState = nil
                },
                onDelete: config.isNewRecord ? nil : {
                    // 削除機能
                    if let index = events.indices.contains(config.eventIndex) ? config.eventIndex : nil,
                       let recordID = config.recordID,
                       let recordIndex = events[index].records.firstIndex(where: { $0.id == recordID }) {
                        _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            events[index].records.remove(at: recordIndex)
                        }
                        provideHapticFeedback(.warning)
                    }
                    editingState = nil
                }
            )
        }
        .sheet(isPresented: $showAddEventSheet) {
            AddEventSheet(
                newEventTitle: $newEventTitle,
                onAdd: {
                    addNewEvent()
                    showAddEventSheet = false
                    provideHapticFeedback(.success)
                },
                onCancel: {
                    newEventTitle = ""
                    showAddEventSheet = false
                }
            )
        }
        .onAppear {
            loadEvents()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEditing)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DaysTracker")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(currentDateString)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit mode toggle button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isEditing.toggle()
                }
                provideHapticFeedback(.light)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                        .font(.system(size: 18, weight: .medium))
                    Text(isEditing ? "完了" : "編集")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(isEditing ? .white : (colorScheme == .dark ? .white : .primary))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if isEditing {
                            Capsule()
                                .fill(Color.liquidGlassAccent)
                        } else {
                            Capsule()
                                .fill(.ultraThinMaterial)
                            Capsule()
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3), lineWidth: 1)
                        }
                    }
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.liquidGlassAccent, Color.liquidGlassSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("イベントがありません")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text("右下の「+」ボタンから\n追跡したいイベントを追加してください")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("イベントを検索...", text: $searchText)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25), lineWidth: 1)
                }
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Add Event FAB
    private var addEventButton: some View {
        Button(action: {
            showAddEventSheet = true
            provideHapticFeedback(.medium)
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.liquidGlassAccent, Color.liquidGlassAccent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.liquidGlassAccent.opacity(0.4), radius: 15, x: 0, y: 8)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Properties
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日 (E)"
        return formatter.string(from: Date())
    }
    
    // MARK: - Haptic Feedback
    private func provideHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    private func provideHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // MARK: - Functions
    private func addNewEvent() {
        let trimmed = newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            events.append(Event(title: trimmed))
        }
        newEventTitle = ""
    }
    
    private func toggleExpand(for eventID: UUID) {
        if let idx = events.firstIndex(where: { $0.id == eventID }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                events[idx].isExpanded.toggle()
            }
            provideHapticFeedback(.light)
        }
    }
    
    private func sortedRecords(for event: Event) -> [EventRecord] {
        return event.records.sorted { $0.date > $1.date }
    }
    
    private func daysFromPreviousRecord(eventIndex: Int, record: EventRecord) -> Int {
        guard eventIndex < events.count else { return 0 }
        let sortedList = sortedRecords(for: events[eventIndex])
        guard let currentIdx = sortedList.firstIndex(where: { $0.id == record.id }) else { return 0 }
        if currentIdx < sortedList.count - 1 {
            let previousRecord = sortedList[currentIdx + 1]
            return daysBetween(start: previousRecord.date, end: record.date)
        }
        return 0
    }
    
    private func daysBetween(start: Date, end: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
    
    private func deleteRecord(eventID: UUID, recordID: UUID) {
        if let eventIndex = events.firstIndex(where: { $0.id == eventID }),
           let recordIndex = events[eventIndex].records.firstIndex(where: { $0.id == recordID }) {
            _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                events[eventIndex].records.remove(at: recordIndex)
            }
            provideHapticFeedback(.warning)
        }
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "events")
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "events"),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
    }
    
    private var filteredEvents: [Event] {
        if searchText.isEmpty {
            return events
        }
        return events.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Event Glass Card
struct EventGlassCard: View {
    let event: Event
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onQuickAdd: () -> Void  // 新規: クイック追加
    let onAddRecord: () -> Void
    let onEditRecord: (UUID) -> Void
    let sortedRecords: [EventRecord]
    let daysFromPrevious: (EventRecord) -> Int
    let onDeleteRecord: (UUID) -> Void
    let onDeleteEvent: () -> Void
    let isEditMode: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State private var showDeleteConfirmation: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with quick add button
            HStack(spacing: 12) {
                // Main content area - tap to expand
                Button(action: onToggleExpand) {
                    HStack(spacing: 14) {
                        // Event title
                        Text(event.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Days since badge
                        if let latestRecord = sortedRecords.first {
                            DaysBadge(days: daysSince(date: latestRecord.date), label: "日前")
                        } else {
                            Text("記録なし")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        
                        // Expand chevron
                        AnimatedChevron(isExpanded: isExpanded)
                    }
                }
                .buttonStyle(.plain)
                
                // Quick add button - always visible
                Button(action: onQuickAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.liquidGlassAccent, Color.liquidGlassSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.liquidGlassAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2))
                        .padding(.horizontal, 18)
                    
                    if sortedRecords.isEmpty {
                        // Empty records state
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("まだ記録がありません")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        // Records list
                        ForEach(sortedRecords) { record in
                            RecordRow(
                                record: record,
                                daysFromPrevious: daysFromPrevious(record),
                                onEdit: { onEditRecord(record.id) },
                                onDelete: { onDeleteRecord(record.id) }
                            )
                        }
                    }
                    
                    // Add record button with date picker option
                    Button(action: onAddRecord) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 16))
                            Text("日付を選んで記録")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.liquidGlassAccent)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    // Delete event button (only in edit mode)
                    if isEditMode {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                Text("このイベントを削除")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                            Button("削除", role: .destructive) {
                                onDeleteEvent()
                            }
                            Button("キャンセル", role: .cancel) {}
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .glassCard(cornerRadius: 20)
    }
    
    private func daysSince(date: Date) -> Int {
        let calendar = Calendar.current
        let startOfRecordDay = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: startOfRecordDay, to: startOfToday)
        return components.day ?? 0
    }
}

// MARK: - Record Row
struct RecordRow: View {
    let record: EventRecord
    let daysFromPrevious: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(formattedDate(record.date))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .primary)
                    
                    // Show "今日" badge if it's today
                    if isToday(record.date) {
                        Text("今日")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                    }
                }
                
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Days interval badge
            if daysFromPrevious > 0 {
                Text("\(daysFromPrevious)日後")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    )
            }
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.liquidGlassAccent)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("編集", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd (E)"
        return formatter.string(from: date)
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Add Event Sheet
struct AddEventSheet: View {
    @Binding var newEventTitle: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                LiquidGlassBackground()
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(Color.liquidGlassAccent)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("新しいイベント")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text("追跡したいイベントの名前を入力してください")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Text field
                    TextField("イベント名", text: $newEventTitle)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .glassTextField()
                        .focused($isFocused)
                        .padding(.horizontal, 24)
                        .submitLabel(.done)
                        .onSubmit {
                            if !newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                                onAdd()
                            }
                        }
                    
                    Spacer()
                    
                    // Add button
                    Button(action: onAdd) {
                        Text("追加")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                            ? Color.gray.opacity(0.5)
                                            : Color.liquidGlassAccent
                                    )
                            )
                    }
                    .disabled(newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                    .foregroundColor(Color.liquidGlassAccent)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
