import SwiftUI

struct CustomerModeView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool // TopBarなどで使う可能性を考慮 (一旦維持)

    // ★ 支払い画面表示用の状態変数
    @State private var isCheckingOut = false

    var body: some View {
        VStack {
            // TopBar は一旦コメントアウト (後で必要か判断)
            // TopBarView(viewModel: viewModel, showingCalendar: $showingCalendar)

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
        .onAppear {
            // CustomerMode が表示されたときの初期化処理があればここに追加
            // ViewModel側で実施済みのため、通常は不要かも
            // 画面が表示されたときに isCheckingOut をリセットする (任意)
            isCheckingOut = false
        }
        // CustomerMode 全体に背景色などを設定しても良いかも
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]), startPoint: .top, endPoint: .bottom).ignoresSafeArea())
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