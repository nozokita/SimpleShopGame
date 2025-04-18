import SwiftUI
import Combine

// 子犬の状態を表す列挙型
enum PuppyState {
    case idle       // 通常状態
    case walking    // 歩いている
    case eating     // 食事中
    case playing    // 遊んでいる
    case sleeping   // 寝ている
    case happy      // 嬉しい
    case sad        // 悲しい
    case hungry     // お腹が空いている
    case petting    // 撫でられている
}

struct PuppyAnimationView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var currentState: PuppyState = .idle
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: 0)
    @State private var walkingDirection: CGFloat = 1  // 1: 右, -1: 左
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 0.3, on: .main, in: .common)
    @State private var timerCancellable: Cancellable? = nil
    @State private var idleCounter: Int = 0
    @State private var shouldBounce: Bool = false
    @State private var showFood: Bool = false
    @State private var foodPosition: CGPoint = CGPoint(x: 0, y: 0)
    
    // うんち関連の状態管理
    @State private var poopPositions: [CGPoint] = []
    @State private var lastPoopCount: Int = 0
    @State private var showCleaning: Bool = false
    
    // 親ビューから渡されるサイズ
    var size: CGSize
    
    var body: some View {
        ZStack {
            // うんち画像（ある場合に表示）
            ForEach(0..<poopPositions.count, id: \.self) { index in
                if index < poopPositions.count {
                    Image("poop")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .position(poopPositions[index])
                        .opacity(showCleaning ? 0 : 1) // 掃除中は非表示
                        .animation(.easeOut(duration: 0.5), value: showCleaning)
                }
            }
            
            // 掃除効果（キラキラエフェクト）
            if showCleaning {
                ForEach(0..<poopPositions.count, id: \.self) { index in
                    if index < poopPositions.count {
                        Text("✨")
                            .font(.system(size: 30))
                            .position(poopPositions[index])
                    }
                }
            }
            
            // 食べ物画像（条件付きで表示）
            if showFood {
                Image("food")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60)
                    .position(foodPosition)
            }
            
            // 子犬画像
            Image(currentImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .position(position)
                .scaleEffect(shouldBounce ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: shouldBounce)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onTapGesture {
            petPuppy()
        }
        .onAppear {
            startAnimation()
            // 初期うんち生成
            updatePoopDisplay()
        }
        .onDisappear {
            timerCancellable?.cancel()
        }
        .onChange(of: viewModel.showEatingAnimation) { _, isEating in
            if isEating {
                showEatingAnimation()
            }
        }
        .onChange(of: viewModel.showPlayingAnimation) { _, isPlaying in
            if isPlaying {
                showPlayingAnimation()
            }
        }
        .onChange(of: viewModel.showPettingAnimation) { _, isPetting in
            if isPetting {
                showPettingAnimation()
            }
        }
        .onChange(of: viewModel.showCleaningAnimation) { _, isCleaning in
            if isCleaning {
                showCleaningAnimation()
            }
        }
        .onChange(of: viewModel.poopCount) { _, count in
            // うんちの数が変化したら表示を更新
            updatePoopDisplay()
            
            // うんちの数が変わったら状態も再計算
            if count >= 3 && (currentState != .eating && currentState != .playing && currentState != .petting) {
                currentState = determineState()
            }
        }
    }
    
    // 現在の状態に応じた画像名を取得
    private var currentImageName: String {
        get {
            switch currentState {
                case .idle:
                    // 歩行アニメーション：方向に応じた画像を表示（フレーム1のみ）
                    if walkingDirection > 0 {
                        // 右に移動する時は左向きの画像
                        return "puppy_walk_l1"
                    } else {
                        // 左に移動する時は右向きの画像
                        return "puppy_walk_r1"
                    }
                case .eating:
                    return "puppy_eating_1"
                case .playing:
                    // カスタムアニメーションで制御
                    return _customImageName ?? "puppy_playing_1"
                case .sleeping:
                    return "puppy_sleeping_1"
                case .happy:
                    return "puppy_happy_1"
                case .sad:
                    return "puppy_sad_1"
                case .hungry:
                    return "puppy_hungry_1"
                case .petting:
                    return "puppy_pet"
                case .walking:
                    if walkingDirection > 0 {
                        return "puppy_walk_l1"
                    } else {
                        return "puppy_walk_r1"
                    }
            }
        }
        set {
            _customImageName = newValue
        }
    }
    
    // カスタム画像名を保持するプロパティ
    @State private var _customImageName: String? = nil
    
    // 状態決定ロジック
    private func determineState() -> PuppyState {
        // お腹が空いている場合
        if viewModel.puppyHunger < 20 {
            return .hungry
        }
        
        // 機嫌が悪い場合
        if viewModel.puppyHappiness < 20 {
            return .sad
        }
        
        // うんちが3つ以上貯まっている場合
        if viewModel.poopCount >= 3 {
            return .sad
        }
        
        // ランダムに状態を変更
        let randomValue = Int.random(in: 0...100)
        
        if randomValue < 60 {
            return .walking
        } else if randomValue < 70 {
            return .happy
        } else if randomValue < 80 {
            return .idle
        } else if randomValue < 90 && viewModel.puppyHunger < 70 {
            return .hungry
        } else {
            return .idle
        }
    }
    
    // アニメーション開始
    private func startAnimation() {
        // 初期位置を設定 - 床にきちんと接地するよう調整
        position = CGPoint(x: CGFloat.random(in: 50..<size.width-50), y: size.height - 40)
        
        // 初期状態を設定
        currentState = determineState()
        
        // アニメーションタイマーを開始（0.3秒間隔）
        timer = Timer.publish(every: 0.3, on: .main, in: .common)
        timerCancellable = timer.connect()
        
        // タイマーを購読
        timerCancellable = timer.sink { _ in
            updateAnimation()
        }
    }
    
    // アニメーション更新
    private func updateAnimation() {
        // 状態に応じたアニメーション
        switch currentState {
            case .walking, .idle:
                // 歩行アニメーション
                moveAround()
                
                // 一定確率で状態変更
                if Int.random(in: 0...20) == 0 {
                    currentState = determineState()
                }
                
            case .eating:
                // 食事状態は長めに維持（約6秒）
                idleCounter += 1
                if idleCounter > 20 { // 約6秒後
                    idleCounter = 0
                    currentState = determineState()
                    
                    // 食事が終わったら食べ物を非表示
                    showFood = false
                }
                
            case .playing:
                // 遊び状態は長めに維持（約6秒）
                idleCounter += 1
                if idleCounter > 20 { // 約6秒後
                    idleCounter = 0
                    currentState = determineState()
                    _customImageName = nil
                }
                
            case .petting:
                // 撫でられている状態（約3秒）
                idleCounter += 1
                if idleCounter > 10 { // 約3秒後
                    idleCounter = 0
                    currentState = .happy // 撫でた後は嬉しい状態に
                }
                
            case .sleeping, .happy, .sad, .hungry:
                // その他の状態は一定時間経過後に戻る
                idleCounter += 1
                if idleCounter > 10 { // 約3秒後
                    idleCounter = 0
                    currentState = determineState()
                }
        }
    }
    
    // ランダムに移動
    private func moveAround() {
        // 画面端に達したら方向転換
        if position.x < 50 {
            walkingDirection = 1
        } else if position.x > size.width - 50 {
            walkingDirection = -1
        }
        // ランダムで方向転換
        else if Int.random(in: 0...30) == 0 {
            walkingDirection *= -1
        }
        
        // 現在の方向に応じて移動
        let newX = position.x + (walkingDirection * 10)
        position.x = max(50, min(newX, size.width - 50))
        
        // Y座標もわずかに変動させるが、地面から浮かないよう制限
        if Int.random(in: 0...5) == 0 {
            let newY = position.y + CGFloat.random(in: -3...3)
            // 床との接地を維持するため、Y座標の変動を制限
            position.y = max(size.height - 45, min(newY, size.height - 35))
        }
    }
    
    // 子犬を撫でる
    private func petPuppy() {
        // 撫でられた状態にする
        currentState = .petting
        idleCounter = 0
        
        // バウンスアニメーション
        shouldBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shouldBounce = false
        }
        
        // 機嫌アップ（最大100まで）
        viewModel.puppyHappiness = min(viewModel.puppyHappiness + 5, 100)
        
        // ハプティックフィードバック
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // 食事アニメーション
    private func showEatingAnimation() {
        print("🍖 食事アニメーション開始: 食べ物表示")
        // 食べ物を表示
        showFood = true
        
        // 犬の前に食べ物を配置
        foodPosition = CGPoint(x: position.x, y: position.y + 20)
        
        // 食事状態に変更
        currentState = .eating
        idleCounter = 0
        
        // 食事アニメーションが終わった後も食べ物を表示しておく
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            print("🍖 食事アニメーション終了: 食べ物非表示")
            if self.currentState != .eating {
                self.showFood = false
            }
        }
    }
    
    // 遊びアニメーション
    private func showPlayingAnimation() {
        print("🎮 遊びアニメーション開始")
        // 遊び状態に変更
        currentState = .playing
        idleCounter = 0
        
        // 遊びアニメーション - 画像を交互に切り替える
        animatePlayingImages()
    }
    
    // 遊びアニメーション - 画像を交互に切り替える
    private func animatePlayingImages() {
        var counter = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            // 状態が変わったらアニメーション停止
            if self.currentState != .playing {
                timer.invalidate()
                return
            }
            
            // playing_1とplaying_2を交互に表示
            counter += 1
            let suffix = counter % 2 == 0 ? "2" : "1"
            self._customImageName = "puppy_playing_\(suffix)"
            
            // 最大10回（約3秒）で停止
            if counter >= 10 {
                timer.invalidate()
            }
        }
        
        // タイマーを即時起動
        timer.fire()
    }
    
    // 撫でるアニメーション
    private func showPettingAnimation() {
        print("✋ 撫でるアニメーション開始")
        // 撫でられた状態にする
        currentState = .petting
        idleCounter = 0
        
        // バウンスアニメーション
        shouldBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shouldBounce = false
        }
    }
    
    // うんちの表示を更新
    private func updatePoopDisplay() {
        // 現在のうんちの数を取得
        let count = viewModel.poopCount
        
        // うんちが増えた場合は新しいうんちを追加
        if count > poopPositions.count {
            for _ in poopPositions.count..<count {
                // ランダムな位置にうんちを配置（床に接地するよう調整）
                let randomX = CGFloat.random(in: 50..<size.width-50)
                let randomY = CGFloat.random(in: size.height-50..<size.height-30)
                poopPositions.append(CGPoint(x: randomX, y: randomY))
            }
        }
        // うんちが減った場合は配列を切り詰める
        else if count < poopPositions.count {
            poopPositions = Array(poopPositions.prefix(count))
        }
        
        // 現在のうんちの数を記録
        lastPoopCount = count
    }
    
    // 掃除アニメーション
    private func showCleaningAnimation() {
        print("🧹 掃除アニメーション開始")
        showCleaning = true
        
        // 2秒後にエフェクトを消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showCleaning = false
            // うんちの配列をクリア
            self.poopPositions = []
        }
    }
}

// カラー拡張（16進数対応）
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