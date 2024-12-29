import SwiftUI

struct Event: Identifiable, Codable {
    let id: UUID
    var title: String
    var records: [EventRecord]
    var isExpanded: Bool = false
    
    init(id: UUID = UUID(), title: String, records: [EventRecord] = [], isExpanded: Bool = false) {
        self.id = id
        self.title = title
        self.records = records
        self.isExpanded = isExpanded
    }
}

struct EventRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var note: String
    
    init(id: UUID = UUID(), date: Date, note: String) {
        self.id = id
        self.date = date
        self.note = note
    }
}
