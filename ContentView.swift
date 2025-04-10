// Test comment added by AI assistant
//
//  ContentView.swift
//  SimpleShopGame
//
//  Created by Nozomu Kitamura on 4/5/25.
//

import SwiftUI

// --- 仮のビュー定義 (GameplayView より前に移動) --- 

struct UserSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    var body: some View {
        // TODO: ユーザー選択内容の表示を実装
        Text("選択: " + viewModel.displayUserSelectionText()) // 仮表示
            .padding(.horizontal)
            .frame(height: 50)
            .background(Material.thin)
            .cornerRadius(10)
    }
}

struct UserCalculationInputView: View {
    @ObservedObject var viewModel: GameViewModel
    var inputText: String

    var body: some View {
        // プレースホルダーかどうかでテキストの色を変更
        Text(inputText.isEmpty ? (viewModel.currentGameMode == .calculationQuiz ? "答えを入力" : "金額を入力") : inputText)
            .font(.title) // 少しフォントサイズ調整
            .fontWeight(inputText.isEmpty ? .regular : .bold) // 入力中は太字に
            .foregroundColor(inputText.isEmpty ? .gray : .primary) // プレースホルダーはグレー
            .padding() // パディングを調整
            .frame(maxWidth: .infinity, minHeight: 70) // 横幅いっぱい、最低高さを設定
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.7))) // 背景を角丸白に
            .overlay( // 枠線を追加
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal) // 左右にも少しパディング
    }
}

struct SubmitButton: View {
    @ObservedObject var viewModel: GameViewModel
    var body: some View {
        // TODO: ボタンの見た目と有効/無効状態を実装
        Button {
            viewModel.submitUserSelection()
        } label: {
            Text(viewModel.currentLanguage == "ja" ? "OK!" : "Submit")
                .font(.title2.bold())
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(15)
        }
        .padding(.horizontal)
    }
}

// ------------------------------------

struct ContentView: View {
    // ViewModelのインスタンスを作成
    @StateObject private var viewModel = GameViewModel()
    @State private var showingCalendar = false // カレンダー表示用の状態変数

    var body: some View {
        ZStack { 
            // 全体の背景色 (グラデーション)
            LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // --- ゲーム状態に応じて表示を切り替え (★ 修正) ---
            switch viewModel.gameState {
            case .initialSelection:
                InitialModeSelectionView(viewModel: viewModel, showingCalendar: $showingCalendar)
                    .transition(.opacity.animation(.easeInOut))
            case .modeSelection:
                ModeSelectionView(viewModel: viewModel, showingCalendar: $showingCalendar)
                    .transition(.opacity.animation(.easeInOut))
            case .playing:
                GameplayView(viewModel: viewModel, showingCalendar: $showingCalendar)
                    .transition(.opacity.animation(.easeInOut))
            case .playingCustomer:
                // ★ 新しいお客さんモードビュー (プレースホルダー)
                CustomerModeView(viewModel: viewModel, showingCalendar: $showingCalendar) // 仮のビュー名
                    .transition(.opacity.animation(.easeInOut))
            case .animalCare:
                // ★ 新しい動物のおへやビュー (プレースホルダー)
                AnimalCareView(viewModel: viewModel, showingCalendar: $showingCalendar) // 仮のビュー名
                    .transition(.opacity.animation(.easeInOut))
            case .result:
                ResultView(viewModel: viewModel)
            }

            // --- 正解/不正解フィードバック表示 (オーバーレイ) ---
            if viewModel.showFeedbackOverlay {
                FeedbackOverlayView(isCorrect: viewModel.feedbackIsCorrect, language: viewModel.currentLanguage)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        // --- カレンダーをシート表示する --- 
        .sheet(isPresented: $showingCalendar) {
            CalendarView()
                 .environmentObject(viewModel)
        }
    }
}

// --- Gameplay View (Extracted from ContentView's .playing case) ---
struct GameplayView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool

    var body: some View {
        VStack(spacing: 10) {
            TopBarView(viewModel: viewModel, showingCalendar: $showingCalendar)

            VStack(spacing: 10) { 
                Image(viewModel.currentCustomerImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .padding(.bottom, 5)
                
                Text(viewModel.displayOrderText())
                    .font(viewModel.currentLanguage == "ja" ? .title2 : .title3)
                    .fontWeight(.medium)
                    .padding(.horizontal)
                    .minimumScaleFactor(0.8)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 100)
            }
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.7)))
            .padding(.horizontal)

            Spacer()

            // --- 下部のUI（モードによって切り替え） ---
            VStack {
                switch viewModel.currentGameMode {
                case .shopping, .listeningQuiz:
                    ProductGridView(viewModel: viewModel)
                    UserSelectionView(viewModel: viewModel)
                    SubmitButton(viewModel: viewModel)
                case .calculationQuiz, .priceQuiz:
                    UserCalculationInputView(viewModel: viewModel, inputText: viewModel.currentGameMode == .calculationQuiz ? viewModel.calculationInput : viewModel.priceInput)
                    NumberPadView(inputText: viewModel.currentGameMode == .calculationQuiz ? $viewModel.calculationInput : $viewModel.priceInput)
                    
                    SubmitButton(viewModel: viewModel)
                }
            }
            .padding(.bottom)
        }
    }
}

// --- Product Grid View (Extracted from GameplayView) ---
struct ProductGridView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ScrollView { // アイコンが多い場合にスクロール可能に
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 20) {
                 ForEach(viewModel.products) { product in
                     // --- Product Cell --- (個々の商品表示)
                     VStack(spacing: 8) {
                         Image(product.imageName)
                             .resizable().scaledToFit().frame(width: 70, height: 70) // アイコン少し大きく
                             .background(Color.white.opacity(0.8)).cornerRadius(15).shadow(radius: 2)
                         Text(viewModel.currentLanguage == "ja" ? product.nameJA : product.nameEN)
                             .font(.caption).fontWeight(.medium).lineLimit(1)
                     }
                     .padding(12)
                     .background(Material.thin)
                     .cornerRadius(18)
                     .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                     .scaleEffect(viewModel.tappedProductKey == product.key ? 1.1 : 1.0) // 少し控えめに
                     .animation(.spring(response: 0.2, dampingFraction: 0.6), value: viewModel.tappedProductKey == product.key)
                     .onTapGesture { viewModel.productTapped(product) }
                     // --- End Product Cell ---
                 }
             }.padding()
        }
    }
}

// --- フィードバック表示用の新しいビュー定義 ---
struct FeedbackOverlayView: View {
    let isCorrect: Bool
    let language: String

    var body: some View {
        ZStack {
            // 背景を完全に不透明にする
            (isCorrect ? Color.yellow : Color.blue) // opacity を削除
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // 画像名を feedbackIsCorrect で固定に変更
                Image(isCorrect ? "character_happy" : "character_sad")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.top, 50)

                // メッセージ
                Text(isCorrect ? (language == "ja" ? "やったね！" : "Great!") : (language == "ja" ? "ざんねん..." : "Oops..."))
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(isCorrect ? .orange : .white)
                    .shadow(radius: 2)

                Spacer() // コンテンツを上部に寄せる
            }
        }
        // このビュー自体はタップを透過させる
        .allowsHitTesting(false)
    }
}

// --- モード選択用の新しいビュー定義 ---
struct ModeSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool

    var body: some View {
        // ZStackを調整して左上にボタンを配置可能にする
        ZStack(alignment: .topLeading) { // alignment を .topLeading に変更
            LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // 中央のコンテンツ（変更なし）
            VStack(spacing: 15) {
                Image("character_happy")
                    .resizable().scaledToFit().frame(width: 130, height: 130).padding(.top, 50)
                Text(viewModel.currentLanguage == "ja" ? "ハッピーショッピング" : "Happy Shopping")
                    .font(.largeTitle.bold())
                    .foregroundColor(.orange)
                
                // --- お店タイプ選択UI (サブビューに切り出し) ---
                ShopTypeSelectionView(viewModel: viewModel)
                    .padding(.bottom, 15)
                
                Text(viewModel.currentLanguage == "ja" ? "どのモードで遊ぶ？" : "Choose a Mode")
                    .font(.title2).foregroundColor(.gray).padding(.bottom, 10)

                // --- モード選択ボタン (サブビューに切り出し) --- 
                ModeSelectionButtonsView(viewModel: viewModel)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // --- 左上のホームボタンを追加 --- 
            Button { 
                viewModel.returnToModeSelection() // ViewModelのメソッドを呼び出す
            } label: { 
                Image(systemName: "house.fill")
                    .font(.title2) // アイコンサイズ調整
                    .padding(12) // パディングを追加
                    .background(Material.thin) // 背景
                    .clipShape(Circle()) // 円形にクリップ
                    .foregroundColor(.gray) // アイコンの色
                    .shadow(radius: 2) // 影を追加
            }
            .padding() // 画面端からの余白

            // --- 右上の言語切り替えボタン (変更なし) --- 
            HStack {
                Spacer() // 右に寄せるためのスペーサー
                Button { viewModel.currentLanguage = (viewModel.currentLanguage == "ja" ? "en" : "ja") } label: { 
                    Text(viewModel.currentLanguage == "ja" ? "English" : "日本語")
                        .font(.body).padding(10).background(Material.thin).foregroundColor(.primary).cornerRadius(10).shadow(radius: 1)
                }
            }
            .padding() // 画面端からの余白
        }
        .onAppear {
            viewModel.loadProducts()
        }
    }
}

// --- Shop Type Selection Subview --- (アイコン表示に修正)
struct ShopTypeSelectionView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 12) { // 全体の間隔を少し広げる
            Text(viewModel.currentLanguage == "ja" ? "お店を選ぶ" : "Select Shop Type")
                .font(.headline).foregroundColor(.secondary)

            // --- カスタムのショップ選択UI ---
            HStack(alignment: .top, spacing: 15) { // アイコンとテキストを並べるHStack
                ForEach(ShopType.allCases) { shopType in
                    // --- 個々のボタンを ShopTypeButtonView に切り出し ---
                    ShopTypeButtonView(viewModel: viewModel, shopType: shopType)
                }
            }
            .padding(.horizontal) // 左右に余白を追加
            // .pickerStyle(.segmented) // segmented Pickerは削除
            // .onChange はButtonのアクション内で直接実行
        }
    }
}

// --- 個々のショップタイプボタン用ビュー (新規作成) ---
struct ShopTypeButtonView: View {
    @ObservedObject var viewModel: GameViewModel
    let shopType: ShopType

    // 選択されているかどうかを判定するプロパティ
    private var isSelected: Bool {
        viewModel.currentShopType == shopType
    }

    var body: some View {
        Button {
            // タップされたら選択中のショップタイプを更新し、商品を再読み込み
            viewModel.currentShopType = shopType
            viewModel.loadProducts()
        } label: {
            VStack(spacing: 5) { // アイコンとテキストを縦に配置
                Image(shopType.imageName) // ShopTypeから画像名を取得 (要実装)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50) // アイコンサイズ調整
                    .padding(10) // アイコン周りのパディング
                    // 選択中のショップを視覚的に強調 (例: 背景色を変更)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.orange.opacity(0.2) : Color.black.opacity(0.05))
                    )
                    .overlay( // 選択中の枠線 (任意)
                        Circle()
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )

                Text(shopType.localizedName(language: viewModel.currentLanguage))
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular) // 選択中を太字に
                    .foregroundColor(isSelected ? .orange : .primary) // 選択中の色変更
                    .frame(height: 30) // テキストの高さを確保して揃える
            }
            // タップ時のスケールエフェクト
            .scaleEffect(isSelected ? 1.1 : 1.0)
            // 選択変更時のアニメーション
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain) // デフォルトのボタンスタイルを解除してカスタムスタイルを適用
    }
}

// --- Mode Selection Buttons Subview ---
struct ModeSelectionButtonsView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            ModeButton(viewModel: viewModel, mode: .shopping, textJA: "おかいもの", textEN: "Shopping", icon: "cart.fill", color: .green)
            ModeButton(viewModel: viewModel, mode: .calculationQuiz, textJA: "けいさん", textEN: "Calculation", icon: "plus.forwardslash.minus", color: .purple)
            ModeButton(viewModel: viewModel, mode: .priceQuiz, textJA: "おかねクイズ", textEN: "Price Quiz", icon: "yensign.circle.fill", color: .pink)
            
            // --- リスニングクイズボタン (英語モード時のみ表示) ---
            if viewModel.currentLanguage == "en" {
                ModeButton(viewModel: viewModel, mode: .listeningQuiz, textJA: "リスニング", textEN: "Listening Quiz", icon: "ear.and.waveform", color: .teal)
            }
        }
    }
}

// --- モード選択ボタン用サブビュー --- (新設)
struct ModeButton: View {
    @ObservedObject var viewModel: GameViewModel
    let mode: GameMode
    let textJA: String
    let textEN: String
    let icon: String
    let color: Color

    var body: some View {
        Button { 
            viewModel.setupGame(mode: mode)
        } label: {
            Label(viewModel.currentLanguage == "ja" ? textJA : textEN, systemImage: icon)
                .font(.title.bold()) // 大きく
                .padding(.vertical, 15) // 縦のpadding増やす
                .frame(maxWidth: 320) // 幅を広げる
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(25) // 角丸大きく
                .shadow(radius: 5)
        }
    }
}

// --- 結果表示用の新しいビュー定義 ---
struct ResultView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 30) {
            if viewModel.isNewHighScore {
                // ハイスコア更新時の表示 (新しいメッセージ案)
                Text(viewModel.currentLanguage == "ja" ? "🎉 すごい！新記録！ 🎉" : "🎉 Awesome! New Record! 🎉")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.yellow.opacity(0.2)))
                    .animation(.interpolatingSpring(stiffness: 170, damping: 8), value: viewModel.isNewHighScore)

            } else {
                 Text(viewModel.currentLanguage == "ja" ? "おしまい！" : "Time's Up!")
                    .font(.largeTitle).bold()
            }

            // スコア表示
            VStack {
                Text(viewModel.currentLanguage == "ja" ? "スコア" : "Score")
                    .font(.title2)
                Text("\(viewModel.currentScore)")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.blue)
            }

            // ハイスコア表示 (比較のため)
            VStack {
                 Text(viewModel.currentLanguage == "ja" ? "ハイスコア" : "High Score")
                     .font(.title2)
                 Text("\(viewModel.loadHighScore(for: viewModel.currentGameMode, timeLimit: viewModel.selectedTimeLimitOption))")
                     .font(.system(size: 40, weight: .medium))
                     .foregroundColor(.gray)
            }

            Button { 
                viewModel.returnToModeSelection()
            } label: {
                Text(viewModel.currentLanguage == "ja" ? "モード選択にもどる" : "Back to Mode Selection")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.title2)
            }
            .padding(.horizontal, 40)
        }
    }
}

// --- 数字パッド用の新しいビュー定義 ---
struct NumberPadView: View {
    @Binding var inputText: String
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    private let numbers = (1...9).map { String($0) } + ["", "0", ""]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) { // spacing調整
            ForEach(numbers, id: \.self) { number in
                if number.isEmpty {
                    Rectangle().fill(Color.clear)
                } else {
                    Button {
                        if inputText.count < 3 { inputText += number }
                    } label: {
                        Text(number)
                            .font(.largeTitle.bold()) // 数字を大きく
                            .frame(maxWidth: .infinity)
                            .frame(height: 60) // 高さを確保
                            .background(Material.regular)
                            .cornerRadius(15) // 角丸調整
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// --- ゲームプレイ画面の上部UI用ビュー --- (追加)
struct TopBarView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool // ContentView の @State を参照

    var body: some View {
        HStack {
            // 左側: ホーム・カレンダーボタン
            HStack(spacing: 15) {
                Button { viewModel.returnToModeSelection() } label: { Image(systemName: "house.fill").font(.title2).foregroundColor(.gray) }
                Button { showingCalendar = true } label: { Image(systemName: "calendar.badge.clock").font(.title2).foregroundColor(.purple) }
            }
            .padding(.leading)

            Spacer()

            // 中央: 残り時間
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(String(format: "%.0f", viewModel.remainingTime))
                    .font(.title.bold().monospacedDigit())
                    .foregroundColor(.blue)
                    .frame(minWidth: 40)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)

            Spacer()

            // 右側: ライフとスコア (縦並び)
            VStack(alignment: .trailing, spacing: 5) {
                // Mistake Hearts
                HStack(spacing: 2) { ForEach(0..<viewModel.maxMistakes, id: \.self) { index in Image(systemName: index < viewModel.maxMistakes - viewModel.mistakeCount ? "heart.fill" : "heart").foregroundColor(.red).font(.system(size: 20)) } }
                // Score Counter (変更)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").resizable().frame(width: 22, height: 22).foregroundColor(.yellow) // アイコン変更
                    Text("\(viewModel.currentScore)") // スコア表示に変更
                        .font(.headline.bold())
                        .foregroundColor(Color.black.opacity(0.8))
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.trailing)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

// ------------------------------------

// 新しい初期画面ビュー
struct InitialModeSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 15) {
                HStack {
                    Button { showingCalendar = true } label: { Image(systemName: "calendar.badge.clock").font(.title).foregroundColor(.purple).padding(12).background(Material.thin).clipShape(Circle()).shadow(radius: 2) }
                    Spacer()
                    Rectangle().fill(Color.clear).frame(width: 60, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                VStack {
                    Image("character_happy").resizable().scaledToFit().frame(height: 120)
                    Text(viewModel.currentLanguage == "ja" ? "ハッピーショッピング" : "Happy Shopping").font(.system(size: 32, weight: .bold)).foregroundColor(.orange).minimumScaleFactor(0.8).padding(.bottom, 10)
                }
                .padding(.horizontal)
                VStack(spacing: 20) {
                    LargeModeButton(
                        icon: "house.fill",
                        textJA: "おみせやさん",
                        textEN: "Shop Clerk",
                        color: .green,
                        language: viewModel.currentLanguage,
                        action: { [viewModel] in viewModel.goToShopModeSelection() }
                    )
                    LargeModeButton(
                        icon: "cart.fill",
                        textJA: "おきゃくさん",
                        textEN: "Customer",
                        color: .blue,
                        language: viewModel.currentLanguage,
                        action: { [viewModel] in viewModel.startCustomerMode() }
                    )
                    LargeModeButton(
                        icon: "pawprint.fill",
                        textJA: "どうぶつのおへや",
                        textEN: "Animal Room",
                        color: .orange,
                        language: viewModel.currentLanguage,
                        action: { [viewModel] in viewModel.startAnimalCareMode() }
                    )
                }
                .padding(.horizontal, 30)
                Spacer()
            }
            Button {
                viewModel.currentLanguage = (viewModel.currentLanguage == "ja" ? "en" : "ja")
            } label: {
                Text(viewModel.currentLanguage == "ja" ? "English" : "日本語").font(.body).padding(10).background(Material.thin).foregroundColor(.primary).cornerRadius(10).shadow(radius: 1)
            }
            .padding()
        }
        .onAppear {
             viewModel.resetGame()
        }
    }
}

// --- 大きなモード選択ボタン用の共通ビュー --- (★ 修正)
struct LargeModeButton: View {
    let icon: String
    let textJA: String
    let textEN: String
    let color: Color
    let language: String
    let action: () -> Void // 引数名は action のまま

    var body: some View {
        Button(action: action) { // ここで渡された action を直接使う
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .frame(width: 45)
                    .foregroundColor(.white)

                Text(language == "ja" ? textJA : textEN)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                     .font(.title)
                     .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(25)
            .shadow(color: color.opacity(0.6), radius: 6, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(0.98, anchor: .center)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: UUID())
        }
    }
}

// --- ★ 新しいプレースホルダービュー --- 
struct CustomerModeView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool // TopBarなどで使う可能性を考慮

    var body: some View {
        VStack {
            TopBarView(viewModel: viewModel, showingCalendar: $showingCalendar) // TopBarは再利用できるかも
            Spacer()
            Text("お客さんモード (実装中)")
                .font(.largeTitle)
            Spacer()
            // ここにお客さんモードのUIを実装していく
        }
    }
}

struct AnimalCareView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showingCalendar: Bool // TopBarなどで使う可能性を考慮

    var body: some View {
        VStack {
            TopBarView(viewModel: viewModel, showingCalendar: $showingCalendar) // TopBarは再利用できるかも
            Spacer()
            Text("どうぶつのおへや (実装中)")
                .font(.largeTitle)
            Spacer()
            // ここに動物のおへやのUIを実装していく
        }
    }
}

// --- Preview ---
struct InitialModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用にダミーのViewModelとStateを用意
        InitialModeSelectionView(
            viewModel: GameViewModel(), // 実際のViewModelインスタンス
            showingCalendar: .constant(false) // ダミーのBinding
        )
    }
}

#Preview {
    ContentView()
}


