import SwiftUI

struct ContentView: View {
    @State private var events: [Event] = [] {
        didSet {
            saveEvents()
        }
    }
    
    @State private var newEventTitle: String = ""
    @State private var selectedEventIndex: Int? = nil
    @State private var selectedRecordID: UUID? = nil
    @State private var showRecordEditor: Bool = false
    @State private var draftRecord: EventRecord = EventRecord(date: Date(), note: "")
    @State private var isEditingRecord: Bool = false
    @State private var searchText: String = ""
    @State private var isEditing: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーションを追加
                LinearGradient(gradient: Gradient(colors: [Color.white, Color(.systemGray6)]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if isEditing {
                        VStack(spacing: 10) {
                            // 検索バー
                            HStack {
                                TextField("イベントを検索", text: $searchText)
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .padding(.horizontal, 8)
                                
                                Button(action: addNewEvent) {
                                    Text("追加")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
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
                                    if let actualEventIndex = events.firstIndex(where: { $0.id == filteredEvents[index].id }) {
                                        selectedEventIndex = actualEventIndex
                                        draftRecord = EventRecord(date: Date(), note: "")
                                        isEditingRecord = false
                                        showRecordEditor = true
                                    }
                                },
                                onEditRecord: { recordID in
                                    if let actualEventIndex = events.firstIndex(where: { $0.id == filteredEvents[index].id }),
                                       let recordIndex = events[actualEventIndex].records.firstIndex(where: { $0.id == recordID }) {
                                        selectedEventIndex = actualEventIndex
                                        selectedRecordID = recordID
                                        draftRecord = events[actualEventIndex].records[recordIndex]
                                        isEditingRecord = true
                                        showRecordEditor = true
                                    }
                                },
                                sortedRecords: sortedRecords(for: events[index]),
                                daysFromPrevious: { record in
                                    if let actualEventIndex = events.firstIndex(where: { $0.id == filteredEvents[index].id }) {
                                        return daysFromPreviousRecord(eventIndex: actualEventIndex, record: record)
                                    }
                                    return 0
                                },
                                onDeleteRecord: { recordID in
                                    if let actualEventIndex = events.firstIndex(where: { $0.id == filteredEvents[index].id }),
                                       let recordIndex = events[actualEventIndex].records.firstIndex(where: { $0.id == recordID }) {
                                        deleteRecord(eventIndex: actualEventIndex, recordIndex: recordIndex)
                                    }
                                }
                            )
                            .listRowBackground(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .onDelete { offsets in
                            deleteEvents(at: offsets)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("DaysTracker")
            .toolbar {
                // 編集モードの切替ボタン
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
                        if isEditingRecord, let recordID = selectedRecordID,
                           let recordIndex = events[eventIndex].records.firstIndex(where: { $0.id == recordID }) {
                            events[eventIndex].records[recordIndex] = draftRecord
                        } else {
                            events[eventIndex].records.append(draftRecord)
                        }
                        showRecordEditor = false
                        selectedRecordID = nil
                    },
                    onCancel: {
                        showRecordEditor = false
                        selectedRecordID = nil
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
        // 検索イベントロジック（必要に応じて実装）
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
