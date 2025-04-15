import SwiftUI

struct AnimalCareView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack {
            // ヘッダー (ホームボタンなど)
            HStack {
                Button {
                    viewModel.returnToModeSelection()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.8)))
                        .shadow(radius: 2)
                }
                Spacer()
                // 必要に応じて他のヘッダー要素 (スコアなど)
            }
            .padding()

            Spacer() // 子犬を中央に寄せる

            // 子犬の画像
            Image("puppy") // アセット名が "puppy" の場合
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200) // 仮のサイズ
                .padding()

            // 仮の「お世話する」ボタン
            Button {
                // TODO: ViewModelのアクションを呼ぶ
                print("お世話ボタンが押されました")
            } label: {
                Text("お世話する")
                    .font(.title2.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding()

            Spacer() // 下にもスペース
        }
        .background(Color.green.opacity(0.1).ignoresSafeArea()) // 仮の背景色
    }
}

// Preview Provider (オプション)
struct AnimalCareView_Previews: PreviewProvider {
    static var previews: some View {
        AnimalCareView(viewModel: GameViewModel())
    }
} 