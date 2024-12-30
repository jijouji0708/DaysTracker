import SwiftUI

struct ContentView: View {
    @State private var events: [Event] = [] {
        didSet {
            saveEvents()
        }
    }
    
    @State private var newEventTitle: String = ""
    @State private var selectedEventIndex: Int? = nil
    @State private var selectedRecordIndex: Int? = nil
    @State private var showRecordEditor: Bool = false
    @State private var draftRecord: EventRecord = EventRecord(date: Date(), note: "")
    @State private var isEditingRecord: Bool = false
    @State private var searchText: String = ""
    
    // 編集状態を管理する変数
    @State private var isEditing: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 検索バーと新規イベント追加
                if isEditing {
                    VStack(spacing: 10) {
                        // 検索バー
                        HStack {
                            TextField("イベントを検索", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 8)
                            
                            Button(action: searchEvents) {
                                Text("検索")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 新規イベント追加
                        HStack {
                            TextField("新しいイベント名", text: $newEventTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 8)
                            
                            Button(action: addNewEvent) {
                                Text("追加")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                
                // イベントリスト
                List {
                    ForEach(filteredEvents.indices, id: \.self) { index in
                        EventSectionView(
                            event: filteredEvents[index],
                            isExpanded: isExpanded(filteredEvents[index]),
                            onToggleExpand: { toggleExpand(for: filteredEvents[index].id) },
                            onAddRecord: {
                                selectedEventIndex = events.firstIndex(where: { $0.id == filteredEvents[index].id })
                                draftRecord = EventRecord(date: Date(), note: "")
                                isEditingRecord = false
                                showRecordEditor = true
                            },
                            onEditRecord: { recordIndex in
                                let actualEventIndex = events.firstIndex(where: { $0.id == filteredEvents[index].id })!
                                selectedEventIndex = actualEventIndex
                                selectedRecordIndex = recordIndex
                                draftRecord = events[actualEventIndex].records[recordIndex]
                                isEditingRecord = true
                                showRecordEditor = true // 編集モードで表示
                            },
                            sortedRecords: sortedRecords(for: events[events.firstIndex(where: { $0.id == filteredEvents[index].id })!]),
                            daysFromPrevious: { record in
                                let actualEventIndex = events.firstIndex(where: { $0.id == filteredEvents[index].id })!
                                return daysFromPreviousRecord(eventIndex: actualEventIndex, record: record)
                            },
                            onDeleteRecord: { recordIndex in
                                deleteRecord(eventIndex: index, recordIndex: recordIndex)
                            }
                        )
                    }
                    .onDelete { offsets in
                        deleteEvents(at: offsets)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("DaysTracker")
            .toolbar {
                // Editボタン
                Button(action: { isEditing.toggle() }) {
                    Text(isEditing ? "完了" : "編集")
                }
            }
        }
        .sheet(isPresented: $showRecordEditor) {
            if let eventIndex = selectedEventIndex {
                RecordEditorView(
                    record: $draftRecord,
                    isEditing: isEditingRecord,
                    onSave: {
                        if isEditingRecord, let recordIndex = selectedRecordIndex {
                            // 編集モード: 記録を更新
                            events[eventIndex].records[recordIndex] = draftRecord
                        } else {
                            // 新規追加モード: 記録を追加
                            events[eventIndex].records.append(draftRecord)
                        }
                        showRecordEditor = false
                    },
                    onCancel: {
                        showRecordEditor = false
                    }
                )
            }
        }
        .onAppear {
            loadEvents()
        }
    }

    // MARK: - 関数群
    
    private func addNewEvent() {
        let trimmed = newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        events.append(Event(title: trimmed))
        newEventTitle = ""
    }
    
    private func searchEvents() {
        // 検索イベントロジックをここに追加
    }
    
    private func toggleExpand(for eventID: UUID) {
        if let idx = events.firstIndex(where: { $0.id == eventID }) {
            events[idx].isExpanded.toggle()
        }
    }
    
    private func isExpanded(_ event: Event) -> Bool {
        return event.isExpanded
    }
    
    private func sortedRecords(for event: Event) -> [EventRecord] {
        return event.records.sorted { $0.date > $1.date }
    }
    
    private func daysFromPreviousRecord(eventIndex: Int, record: EventRecord) -> Int {
        let sortedList = sortedRecords(for: events[eventIndex])
        guard let currentIdx = sortedList.firstIndex(where: { $0.id == record.id }) else { return 0 }
        if currentIdx < sortedList.count - 1 {
            let previousRecord = sortedList[currentIdx + 1]
            return daysBetween(start: previousRecord.date, end: record.date)
        }
        return 0
    }
    
    private func daysSince(date: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: date, to: Date())
        return components.day ?? 0
    }
    
    private func daysBetween(start: Date, end: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
    
    private func deleteEvents(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
    }
    
    private func deleteRecord(eventIndex: Int, recordIndex: Int) {
        events[eventIndex].records.remove(at: recordIndex)
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
