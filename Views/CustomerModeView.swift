import SwiftUI

struct CustomerModeView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool // TopBarなどで使う可能性を考慮 (一旦維持)

    // ★ 支払い画面表示用の状態変数
    @State private var isCheckingOut = false

    var body: some View {
        ZStack {
            // 背景色などを設定 (任意)
            Color.blue.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 15) {
                // MARK: - Header (★ Home Button Added)
                HStack {
                    // 左上にホームに戻るボタンを追加
                    Button {
                        viewModel.returnToModeSelection() // ホーム画面に戻る
                    } label: {
                        Image(systemName: "house.fill")
                            .font(.title2)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.8)))
                            .shadow(radius: 2)
                    }
                    
                    Spacer() // スペーサーで左右に要素を分ける

                    // ★ スコア表示を右上に追加 (星アイコンに変更)
                    HStack(spacing: 4) { // アイコンと数字の間隔を調整
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(viewModel.currentScore)")
                    }
                    .font(.title2)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.8)))
                    .shadow(radius: 2)

                    // (既存の言語切り替えボタンなどがあればここ)
                }
                .padding(.horizontal)
                .padding(.top, 5)

                // ★ isCheckingOut の状態に応じてビューを切り替え
                if isCheckingOut {
                    // TODO: CheckoutView を表示 (まだ作成していない)
                    CheckoutView(viewModel: viewModel, isPresented: $isCheckingOut) // 仮
                } else {
                    // ★ ShoppingListView に isCheckingOut の Binding を渡す
                    ShoppingListView(viewModel: viewModel, isCheckingOut: $isCheckingOut)
                }

                Spacer() // 仮
            }
        }
        .onAppear {
            // CustomerMode が表示されたときの初期化処理があればここに追加
            // ViewModel側で実施済みのため、通常は不要かも
            // 画面が表示されたときに isCheckingOut をリセットする (任意)
            isCheckingOut = false
        }
        // CustomerMode 全体に背景色などを設定しても良いかも
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// --- Preview ---
struct CustomerModeView_Previews: PreviewProvider {
    static var previews: some View {
        CustomerModeView(
            viewModel: GameViewModel(), // 実際のViewModelインスタンス
            showingCalendar: .constant(false) // ダミーのBinding
        )
    }
} 