import SwiftUI

struct RecordEditorView: View {
    @Binding var record: EventRecord
    var isEditing: Bool
    
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("実施日")) {
                    DatePicker("日付を選択", selection: $record.date, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                Section(header: Text("メモ (任意)")) {
                    TextField("メモを入力 (任意)", text: $record.note)
                }
            }
            .navigationTitle(isEditing ? "記録を編集" : "新しい記録")
            .navigationBarItems(
                leading: Button("キャンセル", action: onCancel),
                trailing: Button("保存", action: onSave)
            )
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
    }
}
