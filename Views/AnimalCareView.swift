import SwiftUI

// Color型の拡張（16進数カラーコード対応）
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct AnimalCareView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var puppyScale: CGFloat = 1.0
    @State private var showStatusMessage: Bool = false
    @State private var statusMessage: String = ""
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: 0xFFF8E1)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // ヘッダー
                HStack {
                    Button(action: {
                        viewModel.gameState = .initialSelection
                    }) {
                        Image(systemName: "house.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: 0x795548))
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text("どうぶつのおへや")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: 0x4E342E))
                    
                    Spacer()
                    
                    // バランスを取るための空のスペース
                    Color.clear
                        .frame(width: 60, height: 10)
                }
                .padding(.horizontal)
                
                // ステータスバー
                VStack(spacing: 15) {
                    // 満腹度
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(Color(hex: 0xFF9800))
                        Text("おなか:")
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: 0x5D4037))
                        
                        ProgressBar(value: viewModel.puppyHunger, color: Color(hex: 0xFF9800))
                    }
                    .padding(.horizontal)
                    
                    // 機嫌
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color(hex: 0xE91E63))
                        Text("きげん:")
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: 0x5D4037))
                        
                        ProgressBar(value: viewModel.puppyHappiness, color: Color(hex: 0xE91E63))
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.7))
                )
                .padding(.horizontal)
                
                Spacer()
                
                // 子犬の画像
                ZStack {
                    // 子犬
                    Image("puppy")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .scaleEffect(puppyScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: puppyScale)
                    
                    // ステータスメッセージ
                    if showStatusMessage {
                        Text(statusMessage)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0xE91E63))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.8))
                            )
                            .offset(y: -120)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // アクションボタン
                HStack(spacing: 30) {
                    // 餌やりボタン
                    Button(action: {
                        feedAction()
                    }) {
                        VStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color(hex: 0xFF9800))
                                )
                            
                            Text("ごはん")
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: 0x5D4037))
                        }
                    }
                    
                    // 遊ぶボタン
                    Button(action: {
                        playAction()
                    }) {
                        VStack {
                            Image(systemName: "figure.play")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color(hex: 0x4CAF50))
                                )
                            
                            Text("あそぶ")
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: 0x5D4037))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 画面表示時に子犬のステータスを更新
            viewModel.updatePuppyStatus()
        }
    }
    
    // 餌やりアクション
    private func feedAction() {
        // アニメーション
        withAnimation {
            puppyScale = 1.2
            showStatusMessage = true
            statusMessage = "もぐもぐ♪"
        }
        
        // ViewModel更新
        viewModel.feedPuppy()
        
        // アニメーションリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                puppyScale = 1.0
            }
        }
        
        // メッセージ非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showStatusMessage = false
            }
        }
    }
    
    // 遊ぶアクション
    private func playAction() {
        // アニメーション
        withAnimation {
            puppyScale = 1.3
            showStatusMessage = true
            statusMessage = "わーい！"
        }
        
        // ViewModel更新
        viewModel.playWithPuppy()
        
        // アニメーションリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                puppyScale = 1.0
            }
        }
        
        // メッセージ非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showStatusMessage = false
            }
        }
    }
}

// ステータスバーコンポーネント
struct ProgressBar: View {
    var value: Double // 0-100
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // ベース
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                
                // プログレス
                Rectangle()
                    .fill(color)
                    .cornerRadius(5)
                    .frame(width: min(CGFloat(value) / 100 * geometry.size.width, geometry.size.width))
            }
        }
        .frame(height: 15)
    }
}

// プレビュー用
struct AnimalCareView_Previews: PreviewProvider {
    static var previews: some View {
        AnimalCareView(viewModel: GameViewModel())
    }
} 