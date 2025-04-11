import SwiftUI

struct CustomerModeView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool // TopBarなどで使う可能性を考慮 (一旦維持)

    var body: some View {
        VStack {
            // TopBar は一旦コメントアウト (後で必要か判断)
            // TopBarView(viewModel: viewModel, showingCalendar: $showingCalendar)

            // サブモードに応じてビューを切り替え (MVPでは ShoppingListView のみ)
            switch viewModel.customerSubMode {
            case .shoppingList:
                ShoppingListView(viewModel: viewModel)
            case .budgetChallenge:
                Text("予算チャレンジモード (実装中)") // 将来用プレースホルダー
            }

            Spacer() // 仮
        }
        .onAppear {
            // CustomerMode が表示されたときの初期化処理があればここに追加
            // ViewModel側で実施済みのため、通常は不要かも
        }
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