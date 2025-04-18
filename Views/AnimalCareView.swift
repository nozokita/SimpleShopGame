import SwiftUI

struct AnimalCareView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showStatusMessage: Bool = false
    @State private var statusMessage: String = ""
    @State private var showMiniGame: Bool = false
    
    // 画面サイズ取得用
    @State private var containerSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景 - 部屋風の背景
                VStack(spacing: 0) {
                    // 壁（上部）
                    Rectangle()
                        .fill(Color(hex: 0xE0F7FA))
                        .frame(height: geometry.size.height * 0.65)
                    
                    // 床（下部）
                    Rectangle()
                        .fill(Color(hex: 0xFFECB3))
                        .frame(height: geometry.size.height * 0.35)
                }
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // ヘッダー
                    HStack {
                        // ホームボタン
                        Button(action: {
                            // 音を鳴らす
                            viewModel.playSoundEffect(.correct)
                            viewModel.gameState = .initialSelection
                        }) {
                            Image(systemName: "house.fill")
                                .font(.title2)
                                .foregroundColor(Color(hex: 0x795548))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(22)
                                .shadow(radius: 2)
                        }
                        
                        Spacer()
                        
                        Text("どうぶつのおへや")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x4E342E))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        
                        Spacer()
                        
                        // 時計アイコン
                        Text(formattedLastCareTime)
                            .font(.caption)
                            .foregroundColor(Color(hex: 0x795548))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(22)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                    
                    // ステータスパネル
                    VStack(spacing: 12) {
                        // 満腹度
                        HStack {
                            Image(systemName: statusIcon(for: viewModel.puppyHunger, type: "hunger"))
                                .foregroundColor(statusColor(for: viewModel.puppyHunger))
                            Text("おなか")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: 0x5D4037))
                            
                            ProgressBar(value: viewModel.puppyHunger, color: statusColor(for: viewModel.puppyHunger))
                        }
                        .padding(.horizontal)
                        
                        // 機嫌
                        HStack {
                            Image(systemName: statusIcon(for: viewModel.puppyHappiness, type: "happiness"))
                                .foregroundColor(statusColor(for: viewModel.puppyHappiness))
                            Text("きげん")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: 0x5D4037))
                            
                            ProgressBar(value: viewModel.puppyHappiness, color: statusColor(for: viewModel.puppyHappiness))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.7))
                            .shadow(radius: 2)
                    )
                    .padding(.horizontal)
                    
                    // アニメーション表示エリア
                    ZStack {
                        // 床の影
                        Ellipse()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 200, height: 50)
                            .offset(y: geometry.size.height * 0.25)
                        
                        // 子犬のアニメーション表示
                        PuppyAnimationView(viewModel: viewModel, size: CGSize(width: geometry.size.width, height: geometry.size.height * 0.5))
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                        
                        // ステータスメッセージ
                        if showStatusMessage {
                            Text(statusMessage)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0xE91E63))
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.8))
                                        .shadow(radius: 3)
                                )
                                .offset(y: -120)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .frame(height: geometry.size.height * 0.5)
                    
                    Spacer()
                    
                    // アクションボタン
                    HStack(spacing: 20) {
                        // 餌やりボタン
                        ActionButton(
                            action: { feedAction() },
                            iconName: "cup.and.saucer.fill",
                            label: "ごはん",
                            color: Color(hex: 0xFF9800),
                            isDisabled: viewModel.puppyHunger >= 90
                        )
                        
                        // 遊ぶボタン
                        ActionButton(
                            action: { playAction() },
                            iconName: "figure.play",
                            label: "あそぶ",
                            color: Color(hex: 0x4CAF50),
                            isDisabled: viewModel.puppyHappiness >= 90
                        )
                        
                        // 撫でるボタン
                        ActionButton(
                            action: { petAction() },
                            iconName: "hand.raised.fill",
                            label: "なでる",
                            color: Color(hex: 0x9C27B0),
                            isDisabled: false
                        )
                        
                        // ミニゲームボタン
                        ActionButton(
                            action: { miniGameAction() },
                            iconName: "gamecontroller.fill",
                            label: "ゲーム",
                            color: Color(hex: 0x2196F3),
                            isDisabled: false
                        )
                    }
                    .padding(.bottom, 30)
                }
            }
            .onAppear {
                // 画面表示時に子犬のステータスを更新
                viewModel.updatePuppyStatus()
            }
        }
    }
    
    // 最終ケア時刻のフォーマット
    var formattedLastCareTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: viewModel.lastAnimalCareTime)
    }
    
    // ステータスに応じたアイコンを取得
    func statusIcon(for value: Double, type: String) -> String {
        if type == "hunger" {
            if value < 30 { return "exclamationmark.triangle.fill" }
            if value < 70 { return "fork.knife" }
            return "fork.knife.circle.fill"
        } else {
            if value < 30 { return "heart.slash.fill" }
            if value < 70 { return "heart" }
            return "heart.fill"
        }
    }
    
    // ステータスに応じた色を取得
    func statusColor(for value: Double) -> Color {
        if value < 30 { return Color(hex: 0xF44336) }
        if value < 70 { return Color(hex: 0xFF9800) }
        return Color(hex: 0x4CAF50)
    }
    
    // 餌やりアクション
    private func feedAction() {
        guard viewModel.puppyHunger < 90 else { return }
        
        // アニメーション
        withAnimation {
            showStatusMessage = true
            statusMessage = "もぐもぐ♪"
        }
        
        // ViewModel更新（ViewModelのメソッドでアニメーション制御も行う）
        viewModel.feedPuppy()
        
        // メッセージ非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showStatusMessage = false
            }
        }
    }
    
    // 遊ぶアクション
    private func playAction() {
        guard viewModel.puppyHappiness < 90 else { return }
        
        // アニメーション
        withAnimation {
            showStatusMessage = true
            statusMessage = "わーい！"
        }
        
        // ViewModel更新
        viewModel.playWithPuppy()
        
        // メッセージ非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showStatusMessage = false
            }
        }
    }
    
    // 撫でるアクション
    private func petAction() {
        // アニメーション
        withAnimation {
            showStatusMessage = true
            statusMessage = "すりすり～"
        }
        
        // ViewModel更新 - 少し機嫌をアップ
        viewModel.puppyHappiness = min(viewModel.puppyHappiness + 5, 100)
        viewModel.lastAnimalCareTime = Date()
        
        // ハプティックフィードバック
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // メッセージ非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showStatusMessage = false
            }
        }
    }
    
    // ミニゲームアクション
    private func miniGameAction() {
        // ミニゲーム表示（今後実装）
        withAnimation {
            showStatusMessage = true
            statusMessage = "また今度ね！"
        }
        
        // ハプティックフィードバック
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // メッセージ非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showStatusMessage = false
            }
        }
    }
}

// アクションボタンコンポーネント
struct ActionButton: View {
    var action: () -> Void
    var iconName: String
    var label: String
    var color: Color
    var isDisabled: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(isDisabled ? Color.gray.opacity(0.5) : color)
                            .shadow(radius: 2)
                    )
                
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: 0x5D4037))
            }
        }
        .disabled(isDisabled)
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
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                
                // プログレス
                Capsule()
                    .fill(color)
                    .frame(width: min(CGFloat(value) / 100 * geometry.size.width, geometry.size.width))
            }
        }
        .frame(height: 12)
    }
}

// プレビュー用
struct AnimalCareView_Previews: PreviewProvider {
    static var previews: some View {
        AnimalCareView(viewModel: GameViewModel())
    }
} 