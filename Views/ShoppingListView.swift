import SwiftUI

struct ShoppingListView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 15) {
            // 1. 買い物リスト表示エリア (仮)
            ShoppingListDisplayView(shoppingList: viewModel.currentShoppingList, language: viewModel.currentLanguage, getProduct: viewModel.getProduct)
                .padding(.horizontal)

            // 2. 商品グリッド (既存のものを流用)
            // ★ viewModelのメソッドを直接呼び出すように変更
            ProductGridView(viewModel: viewModel)

            // 3. カート内容表示エリア (仮)
            CustomerCartView(cart: viewModel.customerCart, language: viewModel.currentLanguage, getProduct: viewModel.getProduct, removeFromCartAction: viewModel.removeFromCustomerCart)
                .padding(.horizontal)

            // 4. レジに進むボタン (仮)
            Button {
                // TODO: レジ画面 (CheckoutView) へ遷移する処理
                print("Proceed to Checkout tapped")
                // viewModel.customerSubMode = .checkout のような状態遷移？
                // → CustomerModeView側で状態を持つ方が良いかも (例: @State private var isCheckingOut = false)
            } label: {
                Label(viewModel.currentLanguage == "ja" ? "レジにすすむ" : "Checkout", systemImage: "chevron.right.circle.fill")
                    .font(.title2.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding()
            // カートが空の時はボタンを無効化 (任意)
            .disabled(viewModel.customerCart.isEmpty)

        }
    }
}

// --- 仮のサブビュー ---

// 買い物リスト表示
struct ShoppingListDisplayView: View {
    let shoppingList: [OrderItem]?
    let language: String
    let getProduct: (String) -> Product? // Product取得用クロージャ

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(language == "ja" ? "お買い物リスト" : "Shopping List")
                .font(.headline).padding(.bottom, 3)
            if let list = shoppingList, !list.isEmpty {
                ForEach(list) { item in
                    if let product = getProduct(item.productKey) {
                        HStack {
                            Text("・")
                            Text(language == "ja" ? product.nameJA : product.nameEN)
                            Text("x \(item.quantity)")
                        }
                    }
                }
            } else {
                Text(language == "ja" ? "(リストがありません)" : "(No list)")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.thin)
        .cornerRadius(10)
    }
}

// カート内容表示
struct CustomerCartView: View {
    let cart: [OrderItem]
    let language: String
    let getProduct: (String) -> Product?
    let removeFromCartAction: (Product) -> Void // 削除アクションを追加

    var body: some View {
         VStack(alignment: .leading, spacing: 5) {
            Text(language == "ja" ? "カートの中身" : "Your Cart")
                 .font(.headline).padding(.bottom, 3)
             if !cart.isEmpty {
                 ForEach(cart.sorted(by: { $0.productKey < $1.productKey })) { item in
                     if let product = getProduct(item.productKey) {
                         HStack {
                             Text("・")
                             Text(language == "ja" ? product.nameJA : product.nameEN)
                             Text("x \(item.quantity)")
                             Spacer()
                             Text("¥\(product.price * item.quantity)")
                             // 削除ボタンを追加
                             Button {
                                 removeFromCartAction(product)
                             } label: {
                                 Image(systemName: "minus.circle.fill")
                                     .foregroundColor(.red)
                             }
                         }
                         .font(.subheadline) // 少し小さく
                     }
                 }
                 // 合計金額表示 (変更なし)
                 let total = cart.reduce(0) { sum, item in
                      if let product = getProduct(item.productKey) {
                          return sum + (product.price * item.quantity)
                      }
                     return sum
                 }
                 Divider().padding(.vertical, 2)
                 HStack {
                     Spacer()
                     Text(language == "ja" ? "合計:" : "Total:")
                         .fontWeight(.bold)
                     Text("¥\(total)")
                         .fontWeight(.bold)
                 }
             } else {
                 Text(language == "ja" ? "(カートは空です)" : "(Cart is empty)")
             }
         }
         .padding()
         .frame(maxWidth: .infinity, alignment: .leading)
         .background(Material.regular)
         .cornerRadius(10)
    }
}


// --- Preview ---
struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        // ViewModelの準備を previews の外で行うか、別の方法を使う
        // 例: ヘルパー関数や別のstruct内で準備
        // ShoppingListView(viewModel: createPreviewViewModel())
        
        // または、View自体に直接ダミーデータを渡すように ShoppingListView を変更する
        // (今回はViewModelを使う前提のため、上記のViewModel準備方法が推奨)
        
        // とりあえず、単純なプレビュー表示
        ShoppingListView(viewModel: GameViewModel()) // これだとリストやカートは空になる
        
        // データが入った状態のプレビューを見たい場合は、以下のようにする
        // let previewViewModel = GameViewModel()
        // setupPreviewData(for: previewViewModel)
        // return ShoppingListView(viewModel: previewViewModel)
    }

    // プレビュー用ViewModel準備ヘルパー (例)
    /*
    static func setupPreviewData(for viewModel: GameViewModel) {
        if let product1 = viewModel.products.first, let product2 = viewModel.products.dropFirst().first {
            viewModel.currentShoppingList = [OrderItem(productKey: product1.key, quantity: 1), OrderItem(productKey: product2.key, quantity: 2)]
            viewModel.customerCart = [
                OrderItem(productKey: product1.key, quantity: 1),
                OrderItem(productKey: product2.key, quantity: 1)
            ]
        }
    }
    */
} 