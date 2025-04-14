import SwiftUI

struct CustomerModeView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool // TopBarなどで使う可能性を考慮 (一旦維持)

    // ★ 支払い画面表示用の状態変数
    @State private var isCheckingOut = false

    var body: some View {
        // ★ ZStack を NavigationStack で囲む
        NavigationStack {
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

                    // ★ Spacer を ProductGridView の前に移動
                    Spacer()
                    ProductGridView(viewModel: viewModel)

                    // ★ カート表示とレジボタンをVStackで囲み、間隔を狭める
                    VStack(spacing: 8) { // ← spacing を 8 に設定
                        customerCartView
                        NavigationLink {
                            // 遷移先のビュー
                            CheckoutView(viewModel: viewModel)
                        } label: {
                            // ボタンと同じ見た目のラベル
                            Label(viewModel.currentLanguage == "ja" ? "レジにすすむ" : "Checkout", systemImage: "chevron.right.circle.fill")
                                .font(.title2.bold())
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal) // 横パディングを追加
                        .disabled(viewModel.customerCart.isEmpty) // カートが空なら無効
                    } // ★ 新しいVStackの閉じ括弧

                    Divider()

                    // ★ Spacer をここから削除
                    // Spacer()
                }
                .padding() // VStack全体にパディングを追加
            } // ZStack の終わり
        } // NavigationStack の終わり
        .onAppear {
            // CustomerMode が表示されたときの初期化処理があればここに追加
            // ViewModel側で実施済みのため、通常は不要かも
            // isCheckingOut は NavigationLink で不要になったため削除
        }
        // CustomerMode 全体に背景色などを設定しても良いかも
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ★ カート表示ビュー (ボタンとSpacerを削除)
    private var customerCartView: some View {
        VStack(alignment: .leading) {
            Text("カート") // ローカライズ対応推奨
                .font(.headline)
                .padding(.bottom, 2)

            if viewModel.customerCart.isEmpty {
                Text("カートは空です") // ローカライズ対応推奨
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100) // 高さを確保
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.customerCart) { item in
                            HStack {
                                if let product = viewModel.getProduct(byId: item.productKey) {
                                    Text(product.nameJA) // 日本語名
                                    Spacer()
                                    Text("\(item.quantity) 個") // 個数
                                    Text("¥\(product.price * item.quantity)") // 合計金額
                                } else {
                                    Text("商品不明") // エラーケース
                                }
                                // 削除ボタン
                                Button {
                                    viewModel.removeFromCustomerCart(item)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain) // ボタンのデフォルトスタイルを無効化
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                }
                .frame(maxHeight: 150) // 表示する高さに制限

                // 合計金額
                HStack {
                    Spacer()
                    Text("カート合計:")
                        .font(.headline)
                    Text("¥\(calculateCartTotal())")
                        .font(.title2.weight(.semibold))
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
        .frame(minHeight: 120) // カートが空でも最低限の高さを確保
    }

    // ★ カート合計計算ヘルパー (変更なし)
    private func calculateCartTotal() -> Int {
        viewModel.customerCart.reduce(0) { total, item in
            if let product = viewModel.getProduct(byId: item.productKey) {
                return total + (product.price * item.quantity)
            }
            return total
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