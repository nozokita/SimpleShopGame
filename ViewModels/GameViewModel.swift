import SwiftUI
import AVFoundation // AVFoundationをインポート
import Combine // TimerのためにCombineをインポート（なくても動くことが多いが念のため）

// ゲームの状態を表すEnum
enum GameState {
    case initialSelection // 追加: 最初のモード選択画面
    case modeSelection    // 既存: お店屋さんモードの詳細選択
    case playing          // 既存: お店屋さんモードプレイ中
    case playingCustomer  // 追加: お客さんモードプレイ中
    case animalCare       // 追加: どうぶつのおへや
    case result
}

// ★ 追加: お客さんモード内のサブ状態
enum CustomerSubMode {
    case shoppingList    // 買い物リストモード
    case budgetChallenge // 予算チャレンジモード (将来用)
    // 必要なら他のモードも追加 (例: .checkout - 支払い画面)
}

// ゲームモードを表すEnum
enum GameMode: CaseIterable {
    case shopping // 通常のお買い物モード
    case calculationQuiz // 簡単な計算モード
    case priceQuiz // 金額計算モード
    case listeningQuiz // リスニングクイズモード (追加)
}

// 効果音の種類を表すEnum
enum SoundEffect {
    case correct
    case incorrect
    case itemSelect
    case orderNew
    
    // サウンドファイル名を返す
    var fileName: String {
        switch self {
        case .correct:
            return "success"
        case .incorrect:
            return "failure"
        case .itemSelect:
            return "success" // success.mp3を流用
        case .orderNew:
            return "success" // success.mp3を流用
        }
    }
}

// 時間制限の選択肢 (追加)
enum TimeLimitOption: Double, CaseIterable, Identifiable {
    case short = 30.0
    case medium = 60.0
    case long = 90.0

    var id: Double { self.rawValue }

    var displayName: String {
        switch self {
        case .short: return "30秒"
        case .medium: return "60秒"
        case .long: return "90秒"
        }
    }
}

// UserDefaults のキー
private let clearedDatesKey = "clearedDates"
private let highScoresKey = "highScores" // ハイスコア保存用キー (追加)

// ゲームの状態とロジックを管理するViewModel
// @Observable マクロを削除し、ObservableObjectに準拠
class GameViewModel: ObservableObject {
    // MARK: - Speech Synthesis (★ 追加)
    private let speechSynthesizer = AVSpeechSynthesizer()

    // MARK: - Game Mode
    @Published var currentGameMode: GameMode = .shopping
    @Published var currentShopType: ShopType = .fruitStand // 現在の店タイプ (初期値を修正)

    // MARK: - Animal Care Properties
    @Published var puppyHunger: Double = 80
    @Published var puppyHappiness: Double = 80
    @Published var lastAnimalCareTime: Date = Date()

    // MARK: - Customer Mode Properties (追加)
    @Published var customerSubMode: CustomerSubMode = .shoppingList
    @Published var currentShoppingList: [OrderItem]? = nil // 購入目標リスト
    @Published var customerCart: [OrderItem] = []       // プレイヤーのカート
    @Published var paymentAmount: Int = 0               // プレイヤーの支払い額

    // MARK: - Game Constants
    let maxMistakes: Int = 3    // 最大許容間違い回数

    // MARK: - Properties (状態変数)
    // Viewに更新を通知したいプロパティに @Published を追加
    @Published var selectedTimeLimitOption: TimeLimitOption = .medium // 時間選択 (追加)
    @Published var products: [Product] = []
    @Published var currentOrder: Order? = nil // 構造が変わったので注意
    @Published var userSelection: [String: Int] = [:]
    @Published var calculationInput: String = "" // 計算モードでのユーザー入力
    @Published var priceInput: String = "" // 価格クイズモードでのユーザー入力 (追加)
    @Published var currentScore: Int = 0 // 現在のスコア (追加)
    @Published var mistakeCount: Int = 0 // 間違い回数
    @Published var currentLanguage: String = "ja" { // didSet を追加
        didSet {
            // 言語が日本語に変更され、かつリスニングモードだったらモード選択に戻す
            if currentLanguage == "ja" && currentGameMode == .listeningQuiz {
                print("Language changed to Japanese during Listening Quiz. Returning to mode selection.")
                returnToModeSelection()
            }
        }
    }
    @Published var gameState: GameState = .initialSelection // 現在のゲーム状態
    @Published var remainingTime: Double = 60.0 // 初期値は selectedTimeLimitOption に合わせる

    // アニメーション & フィードバック用フラグ
    @Published var showFeedbackOverlay: Bool = false
    @Published var feedbackIsCorrect: Bool = true // true: Correct, false: Incorrect
    @Published var paymentSuccessful: Bool = false // ★ 支払い成功フラグを追加
    @Published var tappedProductKey: String? = nil // タップされたアイコンのキー
    @Published var isNewHighScore: Bool = false // ハイスコア更新フラグ (追加)

    // 効果音プレイヤー
    private var correctSoundPlayer: AVAudioPlayer? // 正解（注文完了）時の音
    private var incorrectSoundPlayer: AVAudioPlayer? // 不正解時の音
    // private var itemSelectSoundPlayer: AVAudioPlayer? // <<< 削除

    // タイマー
    private var timer: Timer?
    private var cancellable: AnyCancellable? // TimerをCombineで扱う場合の代替 (今回は未使用)

    // MARK: - Customer Selection (追加)
    @Published var currentCustomerImageName: String = "customer1" // 現在のお客様画像名 (追加)

    // 利用可能なお客様画像名のリスト (追加)
    private let customerImageNames = ["customer1", "customer2", "customer3"]

    // MARK: - Computed Properties for Views (追加)

    /// 計算クイズで表示する商品と個数のリスト (新設)
    var calculationProductsToDisplay: [(product: Product, quantity: Int)] {
        // 現在の注文アイテムを取得し、回答用アイテムを除外
        let items = currentOrder?.items.filter { $0.productKey != "total_quantity_answer" } ?? []
        
        // OrderItem を (Product, Int) のタプルに変換
        let productsAndQuantities = items.compactMap { item -> (Product, Int)? in
            // getProduct(byId:) を self で呼び出す
            if let product = self.getProduct(byId: item.productKey) {
                return (product: product, quantity: item.quantity)
            } else {
                print("Warning: Product not found for key \(item.productKey) in calculationProductsToDisplay")
                return nil
            }
        }
        return productsAndQuantities
    }

    // MARK: - Initialization
    init() {
        remainingTime = selectedTimeLimitOption.rawValue // 初期値を設定
        loadProducts() // 商品データは最初にロードしておく
        loadSounds()
        initializePuppyInfo() // 子犬の情報を初期化
    }

    deinit { // ViewModelが破棄されるときにタイマーを停止
        invalidateTimer()
    }

    // MARK: - Game Setup & Reset
    /// ゲームの初期設定またはリセットを行う（モード選択後に呼ぶ想定）
    func setupGame(mode: GameMode) {
        // リスニングクイズは英語のみ
        if mode == .listeningQuiz && currentLanguage != "en" {
            print("Listening Quiz requires English. Switching to Shopping mode.")
            currentGameMode = .shopping // 強制的にショッピングモードに
        } else {
            currentGameMode = mode
        }

        currentScore = 0 // スコアをリセット (追加)
        mistakeCount = 0
        gameState = .playing
        userSelection = [:]
        calculationInput = "" // 入力もリセット
        priceInput = "" // 価格入力もリセット (追加)
        showFeedbackOverlay = false
        remainingTime = selectedTimeLimitOption.rawValue // 選択された時間でリセット (追加)
        invalidateTimer()
        loadProducts()
        selectRandomCustomer() // 最初の顧客を選ぶ
        generateNewOrder()     // 最初の注文を生成
        startTimer()           // タイマーを開始 (追加)
    }

    /// ゲームをモード選択状態に戻す
    func returnToModeSelection() {
        invalidateTimer() // タイマーを止める
        gameState = .initialSelection
        // その他の状態もリセット（任意）
        currentOrder = nil
        userSelection = [:]
        calculationInput = "" // 入力もリセット
        priceInput = "" // 価格入力もリセット (追加)
        currentScore = 0 // スコアもリセット
        isNewHighScore = false // ハイスコアフラグもリセット
    }

    /// ゲームをリセットする（現在はモード選択に戻る）
    func resetGame() {
        // setupGame() // 以前は直接リセットしていた
        returnToModeSelection() // モード選択画面に戻るように変更
    }

    // MARK: - Sound Loading
    private func loadSounds() {
        correctSoundPlayer = loadSound(fileName: "success")
        incorrectSoundPlayer = loadSound(fileName: "failure")
        // itemSelectSoundPlayer = loadSound(fileName: "success") // <<< 削除
    }

    /// 効果音を再生するメソッド
    func playSoundEffect(_ effect: SoundEffect) {
        switch effect {
        case .correct:
            correctSoundPlayer?.stop()
            correctSoundPlayer?.currentTime = 0
            correctSoundPlayer?.play()
            print("Playing correct sound")
        case .incorrect:
            incorrectSoundPlayer?.stop()
            incorrectSoundPlayer?.currentTime = 0
            incorrectSoundPlayer?.play()
            print("Playing incorrect sound")
        default:
            // 他の効果音の場合は既存の方法で再生
            let soundFileName = effect.fileName
            let player = loadSound(fileName: soundFileName)
            player?.currentTime = 0
            player?.play()
        }
    }

    /// 注文を音声で読み上げるメソッド
    func speakPrompt() {
        // currentOrderがnilの場合は何もしない
        guard let order = currentOrder else { return }
        
        // 読み上げる言語と内容を選択
        let textToSpeak: String
        
        // 現在のゲームモードによって適切なテキストを準備
        switch currentGameMode {
        case .shopping, .listeningQuiz:
            // ショッピングモードとリスニングモードは注文テキストを読み上げる
            if currentGameMode == .listeningQuiz && currentLanguage == "en" {
                // リスニングモードでは生成したテキストを使用
                textToSpeak = generateShoppingOrderText(order: order)
            } else {
                // 通常のショッピングモードではdisplayOrderTextを使用
                textToSpeak = displayOrderText()
            }
            
        case .calculationQuiz:
            // 計算モードでは計算問題を読み上げる
            if currentLanguage == "ja" {
                textToSpeak = "いくつですか？"
            } else {
                textToSpeak = "How many items in total?"
            }
            
        case .priceQuiz:
            // 価格クイズモードでは価格問題を読み上げる
            if currentLanguage == "ja" {
                textToSpeak = "いくらですか？"
            } else {
                textToSpeak = "How much is it?"
            }
        }
        
        // 音声合成を使用して読み上げる
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.voice = AVSpeechSynthesisVoice(language: currentLanguage == "ja" ? "ja-JP" : "en-US")
        utterance.rate = currentLanguage == "ja" ? 0.43 : 0.5 // 日本語の場合は少し遅めに
        utterance.pitchMultiplier = 1.1 // 声の高さ
        utterance.volume = 1.0 // 音量（0.0-1.0）
        
        // 既存の読み上げを中止
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        // 音声合成を実行
        speechSynthesizer.speak(utterance)
    }

    /// 指定されたファイル名の音声ファイルをロードしてAVAudioPlayerを生成する
    private func loadSound(fileName: String) -> AVAudioPlayer? {
        // mp3形式を想定
        guard let soundURL = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Error: Sound file \(fileName).mp3 not found in main bundle.")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay() // 再生前にバッファリングしておく
            return player
        } catch {
            print("Error loading sound file \(fileName).mp3: \(error)")
            return nil
        }
    }

    // MARK: - Timer Control
    /// タイマーを開始する
    private func startTimer() {
        // 念のため既存タイマーを停止
        invalidateTimer()
        // 残り時間をリセットしないように変更 (setupGameで設定されるため)
        // remainingTime = selectedTimeLimitOption.rawValue
        // タイマーを開始 (1秒ごとに timerTick を呼ぶ)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }

    /// タイマーを停止・無効化する
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// タイマーが1秒進むごとに呼ばれる処理
    private func timerTick() {
        guard gameState == .playing else {
            invalidateTimer() // プレイ中でなければタイマー停止
            return
        }

        remainingTime -= 1
        print("Remaining Time: \(remainingTime)")

        if remainingTime <= 0 {
            handleTimeUp()
        }
    }

    // MARK: - Customer Selection (追加)
    /// ランダムにお客様を選択して画像名を更新する
    private func selectRandomCustomer() {
        currentCustomerImageName = customerImageNames.randomElement() ?? "customer1"
        print("Selected customer: \(currentCustomerImageName)")
    }

    // MARK: - Game Logic Methods

    /// 商品データをロードする（お店の種類によって切り替え）
    func loadProducts() {
        switch currentShopType {
        case .fruitStand:
            products = fruitProducts
        case .bakery:
            products = bakeryProducts
        case .cakeShop:
            products = cakeProducts
        case .restaurant: // レストランのケースを追加
            products = restaurantProducts
        }
        print("Loaded products for shop type: \(currentShopType)")
        // シャッフルして毎回順序を変える (任意)
        products.shuffle()
    }

    /// 新しい注文を生成する
    func generateNewOrder() {
        // タイマーを開始 (setupGame からここに移動？ → いや、初回だけ setupGame で開始し、2問目以降は不要)
        // startTimer() // ここでタイマーを開始しない

        userSelection = [:] // ユーザー選択をリセット
        calculationInput = "" // 計算入力もリセット
        priceInput = "" // 価格入力もリセット (追加)
        tappedProductKey = nil // タップ状態もリセット
        selectRandomCustomer() // 新しいお客さんを選ぶ

        switch currentGameMode {
        case .shopping:
            currentOrder = generateShoppingOrder()
        case .calculationQuiz:
            currentOrder = generateCalculationQuizOrder()
        case .priceQuiz:
            currentOrder = generatePriceQuizOrder()
        case .listeningQuiz:
            // リスニングクイズ用の注文生成（ショッピングと同じ形式）
            currentOrder = generateShoppingOrder()
        }
        print("Generated new order: \(currentOrder?.items ?? [])")
        playSoundEffect(.orderNew) // 注文生成時の効果音を再生
        speakPrompt() // 注文生成後に読み上げ
    }

    /// 通常のお買い物注文を生成する
    private func generateShoppingOrder() -> Order {
        // --- 難易度調整ロジック (coinCount -> currentScore) ---
        let difficultyLevel = currentScore
        let maxItemTypes: Int
        let maxQuantityPerItem: Int
        if difficultyLevel < 2 { maxItemTypes = 1; maxQuantityPerItem = 1 }
        else if difficultyLevel < 5 { maxItemTypes = min(2, products.count); maxQuantityPerItem = 2 }
        else if difficultyLevel < 8 { maxItemTypes = min(3, products.count); maxQuantityPerItem = 2 }
        else { maxItemTypes = min(3, products.count); maxQuantityPerItem = 3 }

        var orderItems: [OrderItem] = []
        let numberOfItemTypes = Int.random(in: 1...maxItemTypes)
        let availableProducts = products.shuffled()
        for i in 0..<numberOfItemTypes {
            let product = availableProducts[i]
            let quantity = Int.random(in: 1...maxQuantityPerItem)
            orderItems.append(OrderItem(productKey: product.key, quantity: quantity))
        }
        return Order(items: orderItems)
    }

    /// 計算モードの注文 (問題) を生成する
    private func generateCalculationQuizOrder() -> Order {
        // 現在のお店の商品からランダムに2種類選ぶ (最低2種類必要)
        guard products.count >= 2 else {
            print("Error: Need at least 2 products for calculation quiz. Switching to shopping.")
            currentGameMode = .shopping
            return generateShoppingOrder()
        }
        let selectedProducts = products.shuffled().prefix(2)
        let product1 = selectedProducts[0]
        let product2 = selectedProducts[1]
        
        // それぞれの個数を決定 (1〜3個程度)
        let quantity1 = Int.random(in: 1...3)
        let quantity2 = Int.random(in: 1...3)
        
        // 合計個数を計算
        let totalQuantity = quantity1 + quantity2
        
        // 表示用の注文アイテム (これが視覚的表示に使われる)
        let item1 = OrderItem(productKey: product1.key, quantity: quantity1)
        let item2 = OrderItem(productKey: product2.key, quantity: quantity2)
        
        // 答え用のアイテム
        let answerItem = OrderItem(productKey: "total_quantity_answer", quantity: totalQuantity)
        
        return Order(items: [item1, item2, answerItem])
    }

    /// 金額計算注文を生成する
    private func generatePriceQuizOrder() -> Order {
        // --- 難易度調整 (coinCount -> currentScore) ---
        let difficultyLevel = currentScore
        let numItems: Int
        let maxQuantity: Int
        let isChangeQuiz: Bool = difficultyLevel >= 9 // 9コイン以上でおつり問題

        if isChangeQuiz {
            // おつり問題: 2〜3品、各1〜2個
            numItems = Int.random(in: 2...3)
            maxQuantity = 2
        } else if difficultyLevel >= 6 {
            // 上級: 3品、各1〜2個
            numItems = 3
            maxQuantity = 2
        } else if difficultyLevel >= 3 {
            // 中級: 2品、各1〜2個
            numItems = 2
            maxQuantity = 2
        } else {
            // 初級: 2品、各1個
            numItems = 2
            maxQuantity = 1
        }
        // --------------------

        guard products.count >= numItems else {
            print("Error: Not enough products for price quiz difficulty. Switching to shopping.")
            currentGameMode = .shopping
            return generateShoppingOrder()
        }

        // ランダムに商品を選ぶ
        let selectedProducts = products.shuffled().prefix(numItems)
        var orderItems: [OrderItem] = []
        var totalPrice: Int = 0

        for product in selectedProducts {
            let quantity = Int.random(in: 1...maxQuantity)
            orderItems.append(OrderItem(productKey: product.key, quantity: quantity))
            totalPrice += product.price * quantity
        }

        if isChangeQuiz {
            // おつり計算問題の場合
            // キリの良い支払金額を決定 (合計より大きく、次の100円単位または500円単位など)
            // 例: 合計が430円なら500円、870円なら1000円
            let paymentAmount: Int
            if totalPrice < 100 {
                paymentAmount = 100
            } else if totalPrice < 500 {
                 // 100円単位で切り上げ
                paymentAmount = Int(ceil(Double(totalPrice) / 100.0)) * 100
            } else {
                // 500円単位で切り上げ (ただし合計+100円以上になるように調整)
                let basePayment = Int(ceil(Double(totalPrice) / 500.0)) * 500
                paymentAmount = max(basePayment, Int(ceil(Double(totalPrice) / 100.0)) * 100) // 100円単位切り上げより小さくならないように
            }
             // 稀に合計と支払いが同額になるケースを避ける（必ずおつりが出るように）
            let finalPaymentAmount = (paymentAmount <= totalPrice) ? paymentAmount + (paymentAmount < 500 ? 100 : 500) : paymentAmount


            let change = finalPaymentAmount - totalPrice

            // 支払金額と答え（おつり）をダミーアイテムとして追加
            let paymentItem = OrderItem(productKey: "payment_amount", quantity: finalPaymentAmount)
            let answerItem = OrderItem(productKey: "change_answer", quantity: change)
            return Order(items: orderItems + [paymentItem, answerItem])
        } else {
            // 合計金額問題の場合
            // 合計金額を答えとしてダミーアイテムに格納
            let answerItem = OrderItem(productKey: "price_answer", quantity: totalPrice)
            return Order(items: orderItems + [answerItem])
        }
    }

    /// 商品がタップされたときの処理 (ユーザー選択を更新)
    func productTapped(_ product: Product) {
        guard gameState == .playing else { return }

        // ユーザー選択に商品を追加/カウントアップ
        let currentCount = userSelection[product.key, default: 0]
        userSelection[product.key] = currentCount + 1
        print("User selected: \(product.key), new count: \(userSelection[product.key]!)")

        // アイテム選択時の効果音を再生
        playSoundEffect(.itemSelect)

        // --- タッチフィードバック用 --- 
        tappedProductKey = product.key // タップされたキーを記録
        // 少し遅れて解除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 他のアイコンがタップされていなければ解除
            if self.tappedProductKey == product.key {
                self.tappedProductKey = nil
            }
        }
        // --------------------------

        // TODO: タップした商品アイコンへのフィードバックアニメーション
    }

    /// ユーザーの選択を確定し、正誤判定を行う
    func submitUserSelection() {
        guard let order = currentOrder else { return }
        var isCorrect = false

        switch currentGameMode {
        case .shopping, .listeningQuiz:
            let correctSelection = order.items.reduce(into: [String: Int]()) { result, item in
                result[item.productKey] = item.quantity
            }
            isCorrect = (userSelection == correctSelection)

        case .calculationQuiz:
            if let userAnswer = Int(calculationInput),
               let correctAnswerItem = order.items.first(where: { $0.productKey == "total_quantity_answer" }) {
                isCorrect = (userAnswer == correctAnswerItem.quantity)
            } else {
                isCorrect = false // 入力が数値でない場合は不正解
            }
            
        case .priceQuiz:
            // 価格クイズの正誤判定 (追加)
            let correctTotalPrice = order.items.reduce(0) { total, item in
                if let product = getProduct(byId: item.productKey) {
                    return total + (product.price * item.quantity)
                } else {
                    print("Warning: Product not found for key \(item.productKey) in price quiz submission.")
                    return total
                }
            }
            
            if let userAnswer = Int(priceInput) {
                isCorrect = (userAnswer == correctTotalPrice)
            } else {
                isCorrect = false // 入力が数値でない場合は不正解
            }
        }

        if isCorrect {
            handleCorrectSubmission()
        } else {
            handleIncorrectSubmission()
        }
    }

    /// 正しい選択が提出されたときの処理
    private func handleCorrectSubmission() {
        print("Submission Correct! Score: \(currentScore + 1)")
        currentScore += 1 // スコアをインクリメント (追加)
        playSoundEffect(.correct)

        feedbackIsCorrect = true
        showFeedbackOverlay = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showFeedbackOverlay = false

            // 時間切れでない限り、次の注文へ
            if self.gameState == .playing {
                self.generateNewOrder()
            }
        }
    }

    /// 間違った選択が提出されたときの処理
    private func handleIncorrectSubmission() {
        print("Submission Incorrect! Mistakes: \(mistakeCount + 1)")
        mistakeCount += 1
        playSoundEffect(.incorrect)
        feedbackIsCorrect = false
        showFeedbackOverlay = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showFeedbackOverlay = false
            self.userSelection = [:]
            self.calculationInput = ""
            self.priceInput = ""
            if self.mistakeCount >= self.maxMistakes {
                self.handleTimeUp()
            }
        }
    }

    /// 時間切れ時の処理 (または間違い上限到達時)
    private func handleTimeUp() {
        guard gameState == .playing else { return } // 既に結果表示などに遷移していたら何もしない

        print("Time Up or Max Mistakes Reached! Final Score: \(currentScore)")
        invalidateTimer() // タイマー停止
        gameState = .result // 結果表示状態へ (変更)

        // ハイスコアをチェック・保存
        let previousHighScore = loadHighScore(for: currentGameMode, timeLimit: selectedTimeLimitOption)
        if currentScore > previousHighScore {
            print("New High Score! \(currentScore) (Previous: \(previousHighScore))")
            isNewHighScore = true
            saveHighScore(currentScore, for: currentGameMode, timeLimit: selectedTimeLimitOption)
        } else {
            print("Score \(currentScore), High Score \(previousHighScore)")
            isNewHighScore = false
        }

        // 結果表示画面へ遷移する (ContentView側で gameState を見て表示を切り替える)
        // 必要なら効果音など
        // correctSoundPlayer?.play() // 例: 終了音
    }

    // MARK: - Data Persistence (UserDefaults)
    /// クリアした日付をUserDefaultsに保存する
    private func saveClearedDate(_ date: Date) {
        let defaults = UserDefaults.standard
        // 既存のクリア日付リストを読み込む (なければ空の配列)
        var clearedDates = defaults.object(forKey: clearedDatesKey) as? [Date] ?? []

        // 日付の「年月日」部分だけを比較して、同じ日の記録がなければ追加
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let todayStart = calendar.date(from: dateComponents)!

        if !clearedDates.contains(where: { calendar.isDate($0, inSameDayAs: todayStart) }) {
            clearedDates.append(todayStart) // 同じ日の重複を避けて追加
            defaults.set(clearedDates, forKey: clearedDatesKey)
            print("Saved cleared date: \(todayStart)")
        } else {
            print("Date already saved for today: \(todayStart)")
        }
    }

    /// UserDefaultsからクリア日付リストを読み込む (カレンダー表示用)
    func loadClearedDates() -> [Date] {
        return UserDefaults.standard.object(forKey: clearedDatesKey) as? [Date] ?? []
    }

    // --- ハイスコア保存・読み込み --- (変更)
    private func highScoreKey(for mode: GameMode, timeLimit: TimeLimitOption) -> String {
        return "\(highScoresKey)_\(mode)_\(timeLimit.rawValue)"
    }

    /// ハイスコアを保存する (スコアと日付を一緒に保存)
    func saveHighScore(_ score: Int, for mode: GameMode, timeLimit: TimeLimitOption) {
        let key = highScoreKey(for: mode, timeLimit: timeLimit)
        // 現在の日付も一緒に保存する
        let scoreData: [String: Any] = ["score": score, "date": Date()]
        UserDefaults.standard.set(scoreData, forKey: key)
        print("Saved high score data for \(mode) (\(timeLimit.displayName)): Score \(score), Date \(Date())")
    }

    /// 指定されたモード・時間のハイスコア(スコアのみ)を読み込む
    func loadHighScore(for mode: GameMode, timeLimit: TimeLimitOption) -> Int {
        let key = highScoreKey(for: mode, timeLimit: timeLimit)
        // 保存されている辞書を読み込む
        guard let scoreData = UserDefaults.standard.dictionary(forKey: key),
              let score = scoreData["score"] as? Int else {
            return 0 // データがない、または形式が違う場合は0を返す
        }
        return score
    }

    /// 日付ごとにグループ化されたハイスコア記録を読み込む (カレンダー用 - 追加)
    func loadScoresByDate() -> [Date: [(mode: GameMode, time: TimeLimitOption, score: Int)]] {
        var scoresDict: [Date: [(mode: GameMode, time: TimeLimitOption, score: Int)]] = [:]
        let defaults = UserDefaults.standard
        let calendar = Calendar.current

        // 全てのモードと時間の組み合わせを試す
        for mode in GameMode.allCases { // GameModeにallCasesを追加する必要あり
            for timeLimit in TimeLimitOption.allCases {
                let key = highScoreKey(for: mode, timeLimit: timeLimit)
                if let scoreData = defaults.dictionary(forKey: key),
                   let score = scoreData["score"] as? Int,
                   let date = scoreData["date"] as? Date {
                    
                    // 日付の「年月日」部分を取得してキーにする
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    guard let dayKey = calendar.date(from: dateComponents) else { continue }

                    let record = (mode: mode, time: timeLimit, score: score)

                    if scoresDict[dayKey] != nil {
                        scoresDict[dayKey]?.append(record)
                    } else {
                        scoresDict[dayKey] = [record]
                    }
                }
            }
        }
        print("Loaded scores grouped by date: \(scoresDict.count) days")
        return scoresDict
    }

    // MARK: - Helper Methods (表示用)
    /// 現在の言語設定に応じた注文テキストを生成して返す (モード別)
    func displayOrderText() -> String {
        // リスニングモードではテキストを表示しない (指示のみ)
        if currentGameMode == .listeningQuiz {
            return currentLanguage == "ja" ? "よく聞いてね！" : "Listen carefully!"
        }
        
        guard let order = currentOrder, !order.items.isEmpty else { return "..." }

        switch currentGameMode {
        case .shopping:
            return generateShoppingOrderText(order: order)
        case .calculationQuiz:
            return generateCalculationQuizOrderText(order: order)
        case .priceQuiz:
            return generatePriceQuizOrderText(order: order)
        case .listeningQuiz: // このケースを追加
            break // 冒頭で return しているので、ここには到達しないはず
        }
        // switch文の外に到達することは理論上ないが、コンパイラ警告を避けるために空文字列を返す
        print("Warning: displayOrderText reached unexpected end.")
        return ""
    }
    
    /// 通常の買い物注文テキストを生成
    private func generateShoppingOrderText(order: Order) -> String {
        guard !order.items.isEmpty else { return "..." }

        let itemStrings = order.items.compactMap { item -> String? in
            guard let product = products.first(where: { $0.key == item.productKey }) else { return nil }
            
            if currentLanguage == "ja" {
                let name = product.nameJA
                let quantityString = "\(item.quantity)個"
                return "\(name) \(quantityString)"
            } else {
                // --- English Text Generation Logic (Modified) ---
                let quantity = item.quantity
                let name = product.nameEN
                var formattedName = name

                if quantity == 1 {
                    // Quantity 1: Use "one" explicitly for clarity
                    formattedName = "one \(name)"
                } else {
                    // Quantity > 1: Handle pluralization
                    if name == "Gyoza" || name == "Curry Rice" { // These don't usually take 's'
                         formattedName = "\(quantity) \(name)"
                    } else if name.hasSuffix("s") { // Already ends in 's'
                         formattedName = "\(quantity) \(name)"
                    } else {
                        // Add 's' for plural
                         formattedName = "\(quantity) \(name)s"
                    }
                }
                return formattedName
                // --- End of Modification ---
            }
        }

        if currentLanguage == "ja" {
            let joinedItems = itemStrings.joined(separator: " と ")
            return "\(joinedItems) ください"
        } else {
            // Format the final sentence for English
            var joinedItems = ""
            if itemStrings.count == 1 {
                joinedItems = itemStrings[0]
            } else if itemStrings.count > 1 {
                // Join with commas and 'and' before the last item
                let allButLast = itemStrings.dropLast().joined(separator: ", ")
                if let last = itemStrings.last {
                    joinedItems = "\(allButLast) and \(last)"
                } else {
                    joinedItems = allButLast // Should not happen if count > 1
                }
            } else {
                joinedItems = "something" // Should not happen with the guard at the top
            }
            
            return "Can I have \(joinedItems) please?"
        }
    }

    /// 計算モードの注文テキストを生成
    private func generateCalculationQuizOrderText(order: Order) -> String {
        // 答え用アイテムを除いた、表示用の商品アイテムを取得
        let displayItems = order.items.filter { $0.productKey != "total_quantity_answer" }
        
        // 商品名と個数を文字列に変換
        let itemStrings = displayItems.compactMap { item -> String? in
            guard let product = products.first(where: { $0.key == item.productKey }) else { return nil }
            let name = currentLanguage == "ja" ? product.nameJA : product.nameEN
            let quantityString = "\(item.quantity)"
            
            if currentLanguage == "ja" { 
                return "\(name) \(quantityString)こ"
            } else {
                // 英語の複数形対応 (generateShoppingOrderTextから流用)
                var formattedName = name
                 if item.quantity > 1 {
                     if name != "Gyoza" && name != "Curry Rice" && !name.hasSuffix("s") { 
                          formattedName = "\(name)s"
                     } 
                 }
                return "\(quantityString) \(formattedName)"
            }
        }

        guard !itemStrings.isEmpty else { return "ぜんぶで なんこ？" } // 安全策
        
        // 問題文を組み立て
        let joinedItems = itemStrings.joined(separator: currentLanguage == "ja" ? " と " : " and ")
        return currentLanguage == "ja" ? "\(joinedItems) で ぜんぶで なんこ？" : "How many \(joinedItems) in total?"
    }

    /// 金額計算注文テキストを生成
    private func generatePriceQuizOrderText(order: Order) -> String {
        // 表示用の商品アイテムのみフィルタリング
         let displayItems = order.items.filter { !["price_answer", "payment_amount", "change_answer"].contains($0.productKey) }

        guard !displayItems.isEmpty else { return "..." }

        let itemStrings = displayItems.compactMap { item -> String? in
            guard let product = products.first(where: { $0.key == item.productKey }) else { return nil }
            let name = currentLanguage == "ja" ? product.nameJA : product.nameEN
            let quantityString = "\(item.quantity)"
            let priceString = "(¥\(product.price))"

            if currentLanguage == "ja" {
                return "\(name)\(priceString) \(quantityString)個"
            } else {
                return "\(quantityString) \(name)\(priceString)"
            }
        }

        let joinedItems = itemStrings.joined(separator: currentLanguage == "ja" ? " と " : " and ")

        // おつり問題かどうかを判定 (payment_amount があるか)
        if let paymentItem = order.items.first(where: { $0.productKey == "payment_amount" }) {
            let paymentAmount = paymentItem.quantity
            if currentLanguage == "ja" {
                 return "\(joinedItems) で \(paymentAmount)円 はらったら おつりは いくら？"
            } else {
                // Consider phrasing like "If you pay ¥[amount] for [items], how much change do you get?"
                return "You bought \(joinedItems). If you pay ¥\(paymentAmount), how much change?"
            }
        } else {
            // 合計金額問題の場合
            return currentLanguage == "ja" ? "\(joinedItems) で おかね は いくら？" : "How much is \(joinedItems) in total?"
        }
    }

    /// ユーザーの選択内容を表示用のテキストに変換する
    func displayUserSelectionText() -> String {
        guard !userSelection.isEmpty else {
            return currentLanguage == "ja" ? "(まだ選んでいません)" : "(Nothing selected yet)"
        }

        let itemStrings = userSelection.sorted(by: { $0.key < $1.key }).compactMap { key, quantity -> String? in
            guard let product = products.first(where: { $0.key == key }) else { return nil }
            let name = currentLanguage == "ja" ? product.nameJA : product.nameEN
            if currentLanguage == "ja" {
                return "\(name) \(quantity)つ"
            } else {
                return "\(quantity) \(name)\(quantity > 1 ? "s" : "")"
            }
        }

        return itemStrings.joined(separator: ", ")
    }

    // MARK: - Product Retrieval (変更なし)
    /// 商品キーを使って商品を取得する
    func getProduct(byId key: String) -> Product? {
        return products.first(where: { $0.key == key })
    }

    // MARK: - Navigation Methods (追加)

    /// お店屋さんモード（モード選択）へ遷移する
    func goToShopModeSelection() {
        print("Navigating to Shop Mode Selection")
        gameState = .modeSelection
        // 必要に応じて追加のリセット処理
    }

    /// お客さんモードを開始する (★ 修正)
    func startCustomerMode() {
        print("Starting Customer Mode - Shopping List")
        gameState = .playingCustomer
        customerSubMode = .shoppingList // サブモードを設定
        // 必要に応じてモード開始時の初期化処理
        invalidateTimer() // タイマーは一旦止める
        currentScore = 0 // スコアリセット
        mistakeCount = 0
        loadProducts() // 商品データをロード (お店タイプは currentShopType に依存)
        generateShoppingListMission() // 最初のミッションを生成
    }

    /// どうぶつのおへやモードを開始する
    func startAnimalCareMode() {
        print("Starting Animal Care Mode")
        gameState = .animalCare
        // 必要に応じてモード開始時の初期化処理
        invalidateTimer() // タイマーは一旦止めるなど
        currentScore = 0 // スコアリセットなど
        mistakeCount = 0
    }

    // MARK: - Customer Mode Methods (追加)
    func generateShoppingListMission() {
        // TODO: 買い物リストを生成するロジック
        print("Generating new shopping list mission...")
        // ダミーデータ設定 (後で実装)
        // よりランダム性を持たせる
        let shuffledProducts = products.shuffled()
        guard shuffledProducts.count >= 2 else {
            print("Not enough products to generate a shopping list.")
            currentShoppingList = []
            return
        }
        let product1 = shuffledProducts[0]
        let product2 = shuffledProducts[1]
        let quantity1 = Int.random(in: 1...2) // 個数を1〜2に
        let quantity2 = Int.random(in: 1...2)

        currentShoppingList = [
            OrderItem(productKey: product1.key, quantity: quantity1),
            OrderItem(productKey: product2.key, quantity: quantity2)
        ]

        resetCustomerCartAndPayment() // 新しいミッション開始時にカートと支払いをリセット
    }

    func addToCustomerCart(_ product: Product) {
        // どのサブモードでもカートには追加できるようにしても良いかも？
        // guard customerSubMode == .shoppingList else { return }

        // カート内の既存アイテムを探す
        if let index = customerCart.firstIndex(where: { $0.productKey == product.key }) {
            customerCart[index].quantity += 1
        } else {
            customerCart.append(OrderItem(productKey: product.key, quantity: 1))
        }
        print("Added \(product.nameEN) to customer cart. Cart: \(customerCart)")
    }

    // カートから商品を減らす、または削除するメソッド (任意で追加)
    func removeFromCustomerCart(_ itemToRemove: OrderItem) {
        // guard customerSubMode == .shoppingList else { return }
        if let index = customerCart.firstIndex(where: { $0.id == itemToRemove.id }) {
            if customerCart[index].quantity > 1 {
                customerCart[index].quantity -= 1
            } else {
                customerCart.remove(at: index)
            }
            print("Removed \(itemToRemove.productKey) from customer cart. Cart: \(customerCart)")
        }
    }

    func addPayment(amount: Int) {
        paymentAmount += amount
        print("Payment amount: \(paymentAmount)")
    }

    func confirmPayment() {
        // TODO: 正誤判定ロジック
        print("Confirming payment...")
        // ★ shoppingList ではなく customerCart を使うように変更
        // guard let shoppingList = currentShoppingList else { 
        //     print("Error: Shopping list is nil.")
        //     return
        // }

        // 正しい合計金額を計算 (★ customerCart を使う)
        let correctTotal = customerCart.reduce(0) { total, item in // shoppingList を customerCart に変更
            if let product = getProduct(byId: item.productKey) {
                return total + (product.price * item.quantity)
            }
            // ★ 警告メッセージも修正
            print("Warning: Product not found for key \(item.productKey) in customer cart.")
            return total
        }

        let isCorrect = (paymentAmount == correctTotal)

        if isCorrect {
            print("Payment correct!")
            // ★ 正解フラグを立てる
            paymentSuccessful = true
            showFeedbackAndGenerateNextMission() // フィードバック表示
        } else {
            print("Payment incorrect! Expected: \(correctTotal), Paid: \(paymentAmount)")
            // TODO: 不正解時の処理 (フィードバック表示、支払いリセットなど)
            showIncorrectFeedbackAndResetPayment()
        }
    }

    // カートと支払いをリセットするヘルパーメソッド
    func resetCustomerCartAndPayment() {
        customerCart = []
        paymentAmount = 0
        paymentSuccessful = false
        objectWillChange.send() // UI更新のために通知
    }

    // 正解フィードバック表示と次のミッション生成 (仮) -> (★ 修正: 次のミッション生成は削除)
    private func showFeedbackAndGenerateNextMission() {
        feedbackIsCorrect = true
        showFeedbackOverlay = true
        // 正解音？
         correctSoundPlayer?.play()
         // ★ スコアを加算する
         currentScore += 1
         print("Score increased to: \(currentScore)") // デバッグ用ログ

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showFeedbackOverlay = false
            // 画面は paymentSuccessful フラグで閉じるのでここでは何もしない
            print("Payment successful feedback shown.") 
        }
    }

    // 不正解フィードバック表示と支払いリセット (仮)
    private func showIncorrectFeedbackAndResetPayment() {
         feedbackIsCorrect = false
         showFeedbackOverlay = true
         // 間違いカウントは別途考慮が必要かも
         // mistakeCount += 1
         incorrectSoundPlayer?.play()
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
             self.showFeedbackOverlay = false
             self.paymentAmount = 0 // 支払いだけリセット
             // if self.mistakeCount >= self.maxMistakes { self.handleTimeUp() }
         }
     }

    // MARK: - Animal Care Methods
    /// 子犬に餌をあげる - 満腹度と機嫌が上がる
    func feedPuppy() {
        // お腹と機嫌を増加させる（最大100まで）
        puppyHunger = min(puppyHunger + 20, 100)
        puppyHappiness = min(puppyHappiness + 10, 100)
        lastAnimalCareTime = Date()
        
        // アニメーション指示
        showEatingAnimation = true
        
        // 3秒後にリセット（もっと長い時間表示するため）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showEatingAnimation = false
        }
        
        // 操作時間を更新
        updateLastInteraction()
    }
    
    /// 子犬と遊ぶ
    func playWithPuppy() {
        // 機嫌が大幅上昇（最大100）
        puppyHappiness = min(puppyHappiness + 25, 100)
        
        // 満腹度が少し減少（最小0）
        puppyHunger = max(puppyHunger - 5, 0)
        
        // ケア時間を更新
        lastAnimalCareTime = Date()
        
        // アニメーション指示
        showPlayingAnimation = true
        
        // 3秒後にリセット（長めに表示）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showPlayingAnimation = false
        }
        
        // 操作時間を更新
        updateLastInteraction()
    }
    
    /// 子犬の状態を時間経過に応じて更新する
    func updatePuppyStatus() {
        // 前回のお世話からの経過時間に基づいてステータスを更新
        let elapsedSeconds = Date().timeIntervalSince(lastAnimalCareTime)
        let hoursElapsed = elapsedSeconds / 3600
        
        // 1時間ごとにお腹と機嫌が減少する（減少率は調整可能）
        let hungerDecrease = min(hoursElapsed * 5, puppyHunger)
        let happinessDecrease = min(hoursElapsed * 10, puppyHappiness)
        
        puppyHunger = max(puppyHunger - hungerDecrease, 0)
        puppyHappiness = max(puppyHappiness - happinessDecrease, 0)
        
        // うんちの数も計算
        calculatePoops()
    }

    // 子犬アニメーションの状態管理
    @Published var showEatingAnimation: Bool = false
    @Published var showPlayingAnimation: Bool = false
    @Published var showPettingAnimation: Bool = false
    
    // うんち関連の状態管理
    @Published var poopCount: Int = 0
    @Published var lastPoopTime: Date = Date().addingTimeInterval(-3600) // 1時間前
    @Published var showCleaningAnimation: Bool = false
    
    // 子犬の名前と飼育日数関連
    @Published var puppyName: String = "まだ名前がありません"
    @Published var puppyAdoptionDate: Date = Date()
    @Published var isPuppyMissing: Bool = false
    @Published var lastInteractionDate: Date = Date()
    private let missingTimeThreshold: TimeInterval = 60 * 60 * 24 * 3 // 3日間

    // 時間帯関連の状態管理
    @Published var isDaytime: Bool = true
    private var timeOfDayTimer: Timer?
    
    /// 現在の時間帯を更新する
    func updateTimeOfDay() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // 6時〜18時を昼間、それ以外を夜とする
        isDaytime = (6...18).contains(hour)
    }
    
    /// 時間帯更新タイマーを開始する
    func startTimeOfDayTimer() {
        // 初期状態を設定
        updateTimeOfDay()
        
        // すでにタイマーがある場合は無効化
        timeOfDayTimer?.invalidate()
        
        // 1分ごとに時間帯をチェック
        timeOfDayTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeOfDay()
        }
    }
    
    /// 時間帯更新タイマーを停止する
    func stopTimeOfDayTimer() {
        timeOfDayTimer?.invalidate()
        timeOfDayTimer = nil
    }
    
    /// デモ用に時間帯を切り替える（開発用）
    func toggleTimeOfDay() {
        isDaytime.toggle()
    }
    
    /// うんちの数を計算する - 一定時間経過ごとにうんちが増える
    func calculatePoops() {
        // 前回のお掃除からの経過時間に基づいてうんちの数を計算
        let elapsedSeconds = Date().timeIntervalSince(lastPoopTime)
        // 30分ごとにうんちが1つ増える（お腹が空いている場合より増える）
        let basePoopInterval: TimeInterval = 30 * 60 // 30分
        let hungerFactor = max(1.0, 2.0 - (Double(puppyHunger) / 100.0)) // お腹が空いているほど頻度が上がる
        let intervalAdjusted = basePoopInterval / hungerFactor
        
        let newPoops = Int(elapsedSeconds / intervalAdjusted)
        if newPoops > 0 {
            // 最大10個まで
            poopCount = min(poopCount + newPoops, 10)
            // 最後のうんち時間を更新（未来にならないように現在時刻を基準）
            lastPoopTime = Date()
        }
    }
    
    /// うんちを掃除する
    func cleanPoops() {
        // うんちがない場合は何もしない
        guard poopCount > 0 else { return }
        
        // うんちを0にする
        poopCount = 0
        // 最後の掃除時間を更新
        lastPoopTime = Date()
        
        // 掃除アニメーション指示
        showCleaningAnimation = true
        
        // 2秒後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showCleaningAnimation = false
        }
        
        // 掃除すると機嫌が上がる
        puppyHappiness = min(puppyHappiness + 5, 100)
        
        // 操作時間を更新
        updateLastInteraction()
    }

    // MARK: - Pet Name & Adoption Management
    
    /// 子犬の名前を保存する
    func savePuppyName(_ name: String) {
        puppyName = name
        UserDefaults.standard.set(name, forKey: "puppyName")
        updateLastInteraction() // 名前を付けたときに操作時間を更新
    }
    
    /// 子犬の名前を読み込む
    func loadPuppyName() {
        if let savedName = UserDefaults.standard.string(forKey: "puppyName") {
            puppyName = savedName
        }
    }
    
    /// 飼育開始日を保存する
    func savePuppyAdoptionDate(_ date: Date) {
        puppyAdoptionDate = date
        UserDefaults.standard.set(date, forKey: "puppyAdoptionDate")
        updateLastInteraction() // 飼育開始日を設定したときに操作時間を更新
    }
    
    /// 飼育開始日を読み込む
    func loadPuppyAdoptionDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "puppyAdoptionDate") as? Date {
            puppyAdoptionDate = savedDate
        } else {
            // 初めて開く場合は現在日時を設定
            puppyAdoptionDate = Date()
            savePuppyAdoptionDate(puppyAdoptionDate)
        }
    }
    
    /// 最後の操作日時を保存する
    private func saveLastInteractionDate(_ date: Date) {
        lastInteractionDate = date
        UserDefaults.standard.set(date, forKey: "lastInteractionDate")
    }
    
    /// 最後の操作日時を読み込む
    private func loadLastInteractionDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "lastInteractionDate") as? Date {
            lastInteractionDate = savedDate
        } else {
            // 初めての場合は現在日時を設定
            lastInteractionDate = Date()
            saveLastInteractionDate(lastInteractionDate)
        }
    }
    
    /// 子犬との最後の操作時間を更新する
    func updateLastInteraction() {
        let now = Date()
        saveLastInteractionDate(now)
        
        // 操作があったので子犬が去った状態をリセット
        if isPuppyMissing {
            isPuppyMissing = false
        }
    }
    
    /// 子犬が去ったかどうかをチェックする
    func checkPuppyMissing() {
        let now = Date()
        let timeSinceLastInteraction = now.timeIntervalSince(lastInteractionDate)
        
        // 一定時間操作がない場合、子犬が去った状態にする
        if timeSinceLastInteraction > missingTimeThreshold && !isPuppyMissing {
            isPuppyMissing = true
        }
    }
    
    /// 子犬の飼育をリセットする
    func resetPuppyAdoption() {
        // 新しい飼育開始日を設定
        savePuppyAdoptionDate(Date())
        
        // 子犬が去った状態をリセット
        isPuppyMissing = false
        
        // 操作時間を更新
        updateLastInteraction()
        
        // 子犬の状態をリセット
        puppyHunger = 100
        puppyHappiness = 100
        poopCount = 0
    }
    
    /// 飼育日数を計算して返す
    var puppyDaysWithYou: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: puppyAdoptionDate, to: Date())
        return max(components.day ?? 0, 0) // nilや負の値の場合は0を返す
    }
    
    /// 子犬の情報を初期化する
    func initializePuppyInfo() {
        // 既存の情報を読み込む
        loadPuppyName()
        loadPuppyAdoptionDate()
        loadLastInteractionDate()
        
        // 子犬が去ったかどうかをチェック
        checkPuppyMissing()
    }
} 
