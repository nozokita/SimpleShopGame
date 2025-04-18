import SwiftUI

struct AnimalCareView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showStatusMessage: Bool = false
    @State private var statusMessage: String = ""
    @State private var showMiniGame: Bool = false
    
    // 画面サイズ取得用
    @State private var containerSize: CGSize = .zero
    
    // 背景切り替え用のデバッグボタンを表示するかどうか（開発時のみtrue）
    private let showDebugToggle = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色（画像がカバーしきれない部分用）
                Color(hex: viewModel.isDaytime ? 0xE1F5FE : 0x263238)
                    .ignoresSafeArea()
                
                // 背景画像
                Image(viewModel.isDaytime ? "bg_room_day_portrait" : "bg_room_night_portrait")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: max(geometry.size.width, geometry.size.height * 0.5625), // 16:9のアスペクト比を考慮
                        height: geometry.size.height
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .clipped()
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.0), value: viewModel.isDaytime)
                
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
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(22)
                                .shadow(radius: 2)
                        }
                        
                        Spacer()
                        
                        Text("どうぶつのおへや")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: 0x4E342E))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        
                        Spacer()
                        
                        // 時計アイコン
                        Text(formattedLastCareTime)
                            .font(.caption)
                            .foregroundColor(Color(hex: 0x795548))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(22)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // デバッグ用時間切り替えボタン（開発用）
                    if showDebugToggle {
                        Button(action: {
                            viewModel.toggleTimeOfDay()
                        }) {
                            Text(viewModel.isDaytime ? "🌞 昼間 → 🌙 夜に切替" : "🌙 夜 → 🌞 昼間に切替")
                                .font(.caption)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                    
                    // ステータスパネル
                    VStack(spacing: 8) {
                        // パネルヘッダー
                        HStack {
                            Text("ステータス")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x5D4037))
                            Spacer()
                            // 自動更新インジケーター
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                Text("自動更新")
                                    .font(.caption2)
                            }
                            .foregroundColor(Color(hex: 0x9E9E9E))
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                        
                        Divider()
                            .background(Color(hex: 0xE0E0E0))
                            .padding(.horizontal, 8)
                        
                        // 満腹度
                        HStack {
                            Image(systemName: statusIcon(for: viewModel.puppyHunger, type: "hunger"))
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(statusColor(for: viewModel.puppyHunger))
                                .cornerRadius(6)
                                .shadow(radius: 1)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("おなか")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: 0x5D4037))
                                
                                ProgressBar(value: viewModel.puppyHunger, color: statusColor(for: viewModel.puppyHunger))
                                    .frame(height: 7)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        
                        // 機嫌
                        HStack {
                            Image(systemName: statusIcon(for: viewModel.puppyHappiness, type: "happiness"))
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(statusColor(for: viewModel.puppyHappiness))
                                .cornerRadius(6)
                                .shadow(radius: 1)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("きげん")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: 0x5D4037))
                                
                                ProgressBar(value: viewModel.puppyHappiness, color: statusColor(for: viewModel.puppyHappiness))
                                    .frame(height: 7)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8) // パディングを縮小して縦スペースを確保
                    
                    // アニメーション表示エリア
                    ZStack {
                        // 床の影 - 下部に配置して床に接地しているように見せる
                        Ellipse()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 200, height: 50)
                            .offset(y: geometry.size.height * 0.18)
                        
                        // 子犬のアニメーション表示
                        PuppyAnimationView(viewModel: viewModel, size: CGSize(width: geometry.size.width, height: geometry.size.height * 0.4))
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                        
                        // ステータスメッセージ
                        if showStatusMessage {
                            VStack {
                                Text(statusMessage)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: 0x5D4037))
                                    .padding(12)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.9))
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white, lineWidth: 1.5)
                                        }
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        // 吹き出しの矢印
                                        Triangle()
                                            .fill(Color.white.opacity(0.9))
                                            .frame(width: 20, height: 10)
                                            .rotationEffect(.degrees(180))
                                            .offset(y: 12),
                                        alignment: .bottom
                                    )
                            }
                            .offset(y: -120)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6)),
                                    removal: .opacity.animation(.easeOut(duration: 0.2))
                                )
                            )
                        }
                    }
                    .frame(height: geometry.size.height * 0.4) // 表示エリアを少し小さく
                    
                    // スペーサーを増やしてアクションパネルを下げる
                    Spacer(minLength: 30)
                    
                    // アクションパネル
                    VStack(spacing: 4) {
                        // パネルヘッダー
                        HStack {
                            Text("アクション")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x5D4037))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        Divider()
                            .background(Color(hex: 0xE0E0E0))
                            .padding(.horizontal, 8)
                            .padding(.bottom, 2)
                        
                        // アクションボタングリッド
                        HStack(spacing: 20) {
                            // 餌やりボタン
                            ActionButton(
                                action: { feedAction() },
                                imageName: "icon_feed",
                                color: Color(hex: 0xFF9800),
                                isDisabled: viewModel.puppyHunger >= 90
                            )
                            
                            // 遊ぶボタン
                            ActionButton(
                                action: { playAction() },
                                imageName: "icon_play",
                                color: Color(hex: 0x4CAF50),
                                isDisabled: viewModel.puppyHappiness >= 90
                            )
                            
                            // 撫でるボタン
                            ActionButton(
                                action: { petAction() },
                                imageName: "icon_pet",
                                color: Color(hex: 0x9C27B0),
                                isDisabled: false
                            )
                            
                            // トイレボタン
                            ActionButton(
                                action: { cleanToiletAction() },
                                imageName: "icon_clean",
                                color: Color(hex: 0x2196F3),
                                isDisabled: viewModel.poopCount == 0
                            )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom + 5, 20)) // 下部のパディングを少し減らす
                }
            }
            .onAppear {
                // 画面表示時に子犬のステータスを更新
                viewModel.updatePuppyStatus()
                // うんちの数も計算
                viewModel.calculatePoops()
                // 時間帯の更新タイマーを開始
                viewModel.startTimeOfDayTimer()
                
                // うんちが3つ以上ある場合はメッセージを表示
                if viewModel.poopCount >= 3 {
                    withAnimation {
                        showStatusMessage = true
                        statusMessage = "トイレを掃除してね..."
                    }
                    
                    // 3秒後にメッセージを非表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            showStatusMessage = false
                        }
                    }
                }
            }
            .onDisappear {
                // 画面を離れる時にタイマーを停止
                viewModel.stopTimeOfDayTimer()
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
        
        // 撫でるアニメーションを表示
        viewModel.showPettingAnimation = true
        
        // 少し経ったらリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.showPettingAnimation = false
        }
        
        // 音を鳴らす
        viewModel.playSoundEffect(.correct)
        
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
    
    // トイレ掃除アクション
    private func cleanToiletAction() {
        // うんちがない場合は無効
        guard viewModel.poopCount > 0 else { return }
        
        // アニメーション
        withAnimation {
            showStatusMessage = true
            statusMessage = "きれいになった！"
        }
        
        // ViewModel更新
        viewModel.cleanPoops()
        
        // メッセージ非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showStatusMessage = false
            }
        }
    }
}

// アクションボタンコンポーネント（新しいカスタムアイコン用に修正）
struct ActionButton: View {
    var action: () -> Void
    var imageName: String
    var color: Color
    var isDisabled: Bool
    
    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .opacity(isDisabled ? 0.5 : 1.0)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .scaleEffect(isDisabled ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDisabled)
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

// 三角形の描画（吹き出しの矢印用）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// プレビュー用
struct AnimalCareView_Previews: PreviewProvider {
    static var previews: some View {
        AnimalCareView(viewModel: GameViewModel())
    }
} 