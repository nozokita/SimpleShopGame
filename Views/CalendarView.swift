import SwiftUI

// --- Identifiable なスコア記録用構造体 (追加) ---
struct ScoreRecord: Identifiable {
    let id = UUID()
    let mode: GameMode
    let time: TimeLimitOption
    let score: Int
}

// カレンダー表示用のビュー
struct CalendarView: View {
    @Environment(\.dismiss) var dismiss // シートを閉じるための環境変数
    @EnvironmentObject var viewModel: GameViewModel // ViewModel を参照 (追加)
    
    // let clearedDates: [Date] // ← GameViewModelから直接読み込むので削除
    @State private var datePickerSelection: Date = Date() // DatePicker用の非オプショナル選択日付 (追加)
    @State private var displayedDate: Date? = Date() // 実際に表示/ロジックで使うオプショナルな日付 (変更: selectedDate -> displayedDate)
    @State private var scoresForSelectedDate: [(mode: GameMode, time: TimeLimitOption, score: Int)] = [] // 選択日のスコア (変更なし)
    @State private var allScoresByDate: [Date: [(mode: GameMode, time: TimeLimitOption, score: Int)]] = [:] // 全スコアデータ (変更なし)

    var body: some View {
        NavigationView { // NavigationViewを追加してタイトルを表示
            VStack {
                // --- カレンダー本体 --- 
                DatePicker(
                    "Start Date", // ラベルは非表示にするので何でも良い
                    selection: $datePickerSelection, // 非オプショナルの $datePickerSelection を使用 (変更)
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical) // グラフィカルスタイルを使用
                .padding()
                // .accentColor(.purple) // アクセントカラー
                // .environment(\.calendar, Calendar(identifier: .japanese)) // 日本の暦にする場合
                // .environment(\.locale, Locale(identifier: "ja_JP")) // ロケールを日本語に
                .onChange(of: datePickerSelection) { _, newDate in // datePickerSelection の変更を監視 (変更)
                    displayedDate = newDate // 表示用日付を更新
                    updateScoresForSelectedDate(newDate) // スコアも更新
                }

                // --- 選択日のスコア表示部分をサブビューに切り出す --- (変更)
                SelectedDateScoresView(
                    displayedDate: displayedDate, 
                    scores: scoresForSelectedDate.map { ScoreRecord(mode: $0.mode, time: $0.time, score: $0.score) }, 
                    viewModel: viewModel
                )

            }
            .navigationTitle(viewModel.currentLanguage == "ja" ? "ハイスコア記録" : "High Scores") // タイトル
            .navigationBarItems(trailing: Button(viewModel.currentLanguage == "ja" ? "閉じる" : "Close") { dismiss() } ) // 閉じるボタン
            .onAppear {
                // ビューが表示されたらスコアデータを読み込む (追加)
                allScoresByDate = viewModel.loadScoresByDate()
                // 初期表示日のスコアも更新 (displayedDateを使用)
                updateScoresForSelectedDate(displayedDate)
            }
        }
    }
    
    // --- ヘルパー関数 --- 
    /// 選択された日付に対応するスコアを更新する
    private func updateScoresForSelectedDate(_ date: Date?) {
        guard let date = date else {
            scoresForSelectedDate = []
            return
        }
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        guard let dayKey = calendar.date(from: dateComponents) else {
            scoresForSelectedDate = []
            return
        }
        scoresForSelectedDate = allScoresByDate[dayKey] ?? []
        print("Updated scores for \(dayKey): \(scoresForSelectedDate.count) records")
    }
}

// --- 選択日のスコア表示用サブビュー (新規追加) ---
struct SelectedDateScoresView: View {
    let displayedDate: Date?
    let scores: [ScoreRecord] // 型を [ScoreRecord] に変更
    @ObservedObject var viewModel: GameViewModel // viewModelも渡す

    var body: some View {
        if let date = displayedDate {
            List {
                Section(header: Text("\(date, style: .date) の記録")) {
                    if scores.isEmpty {
                        Text("この日の記録はありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(scores.sorted(by: { $0.score > $1.score }), id: \.id) { record in 
                            ScoreRowView(record: record, viewModel: viewModel)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        } else {
            Spacer() 
            Text("日付を選択して記録を確認")
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

// --- スコア表示用の行ビュー (変更なし) ---
struct ScoreRowView: View {
    let record: ScoreRecord // 型を ScoreRecord に変更
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack {
            Image(systemName: modeIcon(record.mode)) // モードアイコン表示
                .foregroundColor(modeColor(record.mode))
                .frame(width: 25, alignment: .center) // アイコン幅を固定
            VStack(alignment: .leading) {
                Text(modeDisplayName(record.mode)) // モード名表示
                    .font(.headline)
                Text("(\(record.time.displayName))") // 時間表示
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("スコア: \(record.score)")
                .fontWeight(.bold)
        }
    }

    private func modeDisplayName(_ mode: GameMode) -> String {
        switch mode {
        case .shopping: return viewModel.currentLanguage == "ja" ? "おかいもの" : "Shopping"
        case .calculationQuiz: return viewModel.currentLanguage == "ja" ? "けいさん" : "Calculation"
        case .priceQuiz: return viewModel.currentLanguage == "ja" ? "おかねクイズ" : "Price Quiz"
        case .listeningQuiz: return viewModel.currentLanguage == "ja" ? "リスニング" : "Listening Quiz"
        }
    }
    
    private func modeIcon(_ mode: GameMode) -> String {
        switch mode {
        case .shopping: return "cart.fill"
        case .calculationQuiz: return "plus.forwardslash.minus"
        case .priceQuiz: return "yensign.circle.fill"
        case .listeningQuiz: return "ear.and.waveform"
        }
    }
    
    private func modeColor(_ mode: GameMode) -> Color {
         switch mode {
         case .shopping: return .green
         case .calculationQuiz: return .purple
         case .priceQuiz: return .pink
         case .listeningQuiz: return .teal
         }
     }
}

// --- ContentView側の修正 --- (CalendarView呼び出し部分)
// この修正は ContentView.swift に適用する必要があります (前回のEditで適用されているはず)
// struct ContentView: View {
// ...
//        .sheet(isPresented: $showingCalendar) {
//            CalendarView()
//                .environmentObject(viewModel)
//        }
// ...
// }

#Preview { // PreviewProvider も修正
    CalendarView()
        .environmentObject(GameViewModel()) // Preview用にViewModelインスタンスを提供
} 
