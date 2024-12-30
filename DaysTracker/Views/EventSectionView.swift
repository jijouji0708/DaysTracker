import SwiftUI

struct EventSectionView: View {
    let event: Event
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onAddRecord: () -> Void
    let onEditRecord: (UUID) -> Void
    let sortedRecords: [EventRecord]
    let daysFromPrevious: (EventRecord) -> Int
    
    // 追加: 記録削除用のクロージャ
    let onDeleteRecord: (UUID) -> Void

    var body: some View {
        Section {
            // セクションヘッダー
            HStack {
                Text(event.title)
                    .font(.headline)
                Spacer()
                if let latestRecord = sortedRecords.first {
                    // 最新記録がある場合に「何日前」を表示
                    Text("\(daysSince(date: latestRecord.date))日前")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Button(action: onToggleExpand) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            if isExpanded {
                // 記録のリスト表示
                ForEach(sortedRecords) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(formattedDate(record.date)) // 日付をフォーマット
                                .font(.body)
                            Spacer()
                            Text("\(daysFromPrevious(record))日後")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            // 編集ボタン
                            Button(action: { onEditRecord(record.id) }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                            }
                        }
                        if !record.note.isEmpty {
                            Text(record.note)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contextMenu {
                        // 右クリックメニューで削除オプションを追加（macOS向け）
                        Button(role: .destructive) {
                            onDeleteRecord(record.id)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
                // スワイプで削除できるように .onDelete を適用
                .onDelete { offsets in
                    for offset in offsets {
                        let record = sortedRecords[offset]
                        onDeleteRecord(record.id)
                    }
                }
                
                // 記録の追加ボタン
                Button(action: onAddRecord) {
                    HStack {
                        Image(systemName: "plus")
                        Text("記録を追加")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // 日付をフォーマットする関数
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd" // 年/月/日形式
        return formatter.string(from: date)
    }

    // 日付から現在までの日数を計算
    private func daysSince(date: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: date, to: Date())
        return components.day ?? 0
    }
}
