import SwiftUI

struct MoneyInputView: View {
    @ObservedObject var viewModel: GameViewModel

    // 日本の硬貨・紙幣の額面とアイコン名 (カスタム画像に変更)
    let moneyTypes: [(value: Int, icon: String)] = [
        (value: 10000, icon: "yen_10000"), // 10000円
        (value: 5000, icon: "yen_5000"), // 5000円
        (value: 1000, icon: "yen_1000"), // 1000円
        (value: 500, icon: "yen_500"),   // 500円
        (value: 100, icon: "yen_100"),   // 100円
        (value: 50, icon: "yen_50"),    // 50円
        (value: 10, icon: "yen_10"),    // 10円
        (value: 5, icon: "yen_5"),     // 5円
        (value: 1, icon: "yen_1")      // 1円
    ]

    // グリッドレイアウト定義
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3) // 3列表示

    var body: some View {
        VStack {
            Text("\(viewModel.currentLanguage == "ja" ? "支払う金額" : "Paying Amount"): ¥\(viewModel.paymentAmount)")
                .font(.title2.bold())
                .padding(.bottom, 10)

            LazyVGrid(columns: columns, spacing: 15) { // spacing調整
                ForEach(moneyTypes, id: \.value) { money in
                    Button {
                        viewModel.addPayment(amount: money.value)
                    } label: {
                        VStack(spacing: 4) { // spacing調整
                            Image(money.icon) // Image(systemName:) から変更
                                .resizable() // 画像をリサイズ可能に
                                .scaledToFit() // アスペクト比を維持してフィット
                                // --- ★ ここからサイズ調整 --- 
                                .frame(height: 40) // 高さを基準にサイズ調整
                                // --- ★ ここまでサイズ調整 ---
                            Text(viewModel.currentLanguage == "ja" ? "\(money.value) 円" : "¥\(money.value)")
                                .font(.caption) // フォント調整
                        }
                        .frame(maxWidth: .infinity, minHeight: 70) // ボタンサイズ調整
                        .padding(5)
                        .background(Material.regularMaterial) // Material変更
                        .cornerRadius(10)
                        .foregroundColor(.primary)
                        .shadow(color: .gray.opacity(0.2), radius: 2, y: 1) // 影調整
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// --- Preview ---
struct MoneyInputView_Previews: PreviewProvider {
    static var previews: some View {
        MoneyInputView(viewModel: GameViewModel())
            .padding()
    }
} 