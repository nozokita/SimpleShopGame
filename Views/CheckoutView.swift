import SwiftUI

struct CheckoutView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var isPresented: Bool // CustomerModeViewのisCheckingOutと連動

    var body: some View {
        VStack(spacing: 20) {
            // 閉じるボタン（ShoppingListViewに戻る）
            HStack {
                Spacer()
                Button {
                    isPresented = false // このビューを閉じる
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
            .padding()

            // ★ タイトルをローカライズ
            Text(viewModel.currentLanguage == "ja" ? "お支払い" : "Checkout") 
                .font(.largeTitle.bold())

            // ★ 合計金額表示をローカライズ
            Text("\(viewModel.currentLanguage == "ja" ? "合計金額" : "Total Amount"): ¥\(calculateCorrectTotal())")
                .font(.title)

            // お金入力UI (仮)
            MoneyInputView(viewModel: viewModel) // viewModelを渡す

            // リセットボタン
            Button {
                viewModel.paymentAmount = 0
            } label: {
                // ★ ラベルをローカライズ
                 Label(viewModel.currentLanguage == "ja" ? "ぜんぶもどす" : "Reset All", systemImage: "arrow.counterclockwise.circle.fill")
                     .font(.title3)
                     .padding(8)
                     .foregroundColor(.white)
                     .background(Color.orange)
                     .cornerRadius(10)
                     .shadow(radius: 1)
            }
            .disabled(viewModel.paymentAmount == 0)
            .padding(.bottom)

            // 支払い確定ボタン (仮)
            Button {
                viewModel.confirmPayment() // ViewModelの支払い確定メソッドを呼ぶ
                // 正解なら isPresented が false になって戻る想定 (ViewModel側で制御)
            } label: {
                // ★ ラベルをローカライズ
                Label(viewModel.currentLanguage == "ja" ? "これで払う" : "Pay Now", systemImage: "checkmark.circle.fill")
                    .font(.title2.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding()
            .disabled(viewModel.paymentAmount == 0)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.yellow.opacity(0.1).ignoresSafeArea()) // 背景色 (仮)
        .onAppear {
             // 支払い画面が表示されたときに支払い額をリセット
             viewModel.paymentAmount = 0
        }
        // ★ 支払い成功フラグを監視して画面を閉じる
        .onChange(of: viewModel.paymentSuccessful) { newValue in
            if newValue {
                isPresented = false // 支払い成功時に画面を閉じる
            }
        }
    }

    // ★ 合計金額を計算するヘルパー関数
    private func calculateCorrectTotal() -> Int {
        guard let shoppingList = viewModel.currentShoppingList else { return 0 }
        return shoppingList.reduce(0) { total, item in
            if let product = viewModel.getProduct(byId: item.productKey) {
                return total + (product.price * item.quantity)
            }
            return total
        }
    }
}

// --- Preview ---
struct CheckoutView_Previews: PreviewProvider {
    @State static var isPresentedPreview = true

    // プレビュー用に設定済みのViewModelを生成するヘルパー
    static var configuredViewModel: GameViewModel {
        let vm = GameViewModel()
        // プレビュー用のデータをViewModelに設定
        if let product1 = vm.products.first, let product2 = vm.products.dropFirst().first {
            vm.currentShoppingList = [OrderItem(productKey: product1.key, quantity: 1), OrderItem(productKey: product2.key, quantity: 2)]
        }
        return vm
    }

    static var previews: some View {
        // ヘルパーを使ってViewModelを取得し、CheckoutViewを返す
        CheckoutView(
            viewModel: configuredViewModel,
            isPresented: $isPresentedPreview
        )
    }
} 