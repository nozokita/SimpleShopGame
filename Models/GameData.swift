import Foundation
import SwiftUI

// 商品データを表す構造体
struct Product: Identifiable, Hashable {
    let id = UUID() // 一意なID
    let key: String // 識別キー (例: "apple")
    let nameJA: String // 日本語名
    let nameEN: String // 英語名
    let imageName: String // アセットカタログ内の画像名
    let colorKey: String // 色を表すキー (例: "red", "yellow", "purple")
    let price: Int // 価格 (追加)
}

// 注文内の個々のアイテムを表す構造体
struct OrderItem: Identifiable, Hashable {
    let id = UUID()
    let productKey: String // 商品のキー
    var quantity: Int      // 個数
}

// 注文データを表す構造体 (複数アイテム対応)
struct Order: Identifiable, Hashable {
    let id = UUID()
    var items: [OrderItem] // 注文アイテムのリスト (辞書から配列に変更)
    // 注文テキストは動的に生成するため、ここでは保持しない
}

// お店の種類を表すEnum
enum ShopType: String, CaseIterable, Identifiable {
    case fruitStand = "くだものや"
    case bakery = "パンや"
    case cakeShop = "ケーキや"
    case restaurant = "レストラン"

    var id: String { self.rawValue }
    
    // アイコン画像名を返す計算プロパティ
    var imageName: String {
        switch self {
        case .fruitStand:
            return "shop_icon_fruit" // アセット名に合わせて変更
        case .bakery:
            return "shop_icon_bakery"  // アセット名に合わせて変更
        case .cakeShop:
            return "shop_icon_cake"    // アセット名に合わせて変更
        case .restaurant:
            return "shop_icon_restaurant" // アセット名に合わせて変更
        }
    }

    // 日本語名を取得
    var nameJA: String {
        return self.rawValue
    }

    // 英語名を取得
    var nameEN: String {
        switch self {
        case .fruitStand: return "Fruit Stand"
        case .bakery: return "Bakery"
        case .cakeShop: return "Cake Shop"
        case .restaurant: return "Restaurant"
        }
    }

    // 言語に応じた名前を取得
    func localizedName(language: String) -> String {
        return language == "ja" ? nameJA : nameEN
    }
}

// ゲームの状態を表すEnum
// ... GameState ...

// ゲームモードを表すEnum
// ... GameMode ...

// UserDefaults のキー
// ...

// 商品データを表現する構造体
// ... Product struct ...
// ... Order struct ...
// ... OrderItem struct ...

// --- 商品リスト定義 ---

// 果物屋の商品
let fruitProducts: [Product] = [
    Product(key: "apple", nameJA: "りんご", nameEN: "Apple", imageName: "apple", colorKey: "red", price: 100),
    Product(key: "banana", nameJA: "バナナ", nameEN: "Banana", imageName: "banana", colorKey: "yellow", price: 150),
    Product(key: "orange", nameJA: "オレンジ", nameEN: "Orange", imageName: "orange", colorKey: "orange", price: 120),
    Product(key: "grape", nameJA: "ぶどう", nameEN: "Grape", imageName: "grape", colorKey: "purple", price: 300),
    Product(key: "peach", nameJA: "もも", nameEN: "Peach", imageName: "peach", colorKey: "pink", price: 500),
    Product(key: "strawberry", nameJA: "いちご", nameEN: "Strawberry", imageName: "strawberry", colorKey: "red", price: 250)
]

// パン屋の商品
let bakeryProducts: [Product] = [
    Product(key: "bread", nameJA: "しょくパン", nameEN: "White Bread", imageName: "bread", colorKey: "white", price: 200),
    Product(key: "melonpan", nameJA: "メロンパン", nameEN: "Melon Bread", imageName: "melonpan", colorKey: "green", price: 180),
    Product(key: "currypan", nameJA: "カレーパン", nameEN: "Curry Bread", imageName: "currypan", colorKey: "brown", price: 220),
    Product(key: "croissant", nameJA: "クロワッサン", nameEN: "Croissant", imageName: "croissant", colorKey: "brown", price: 150),
    Product(key: "sandwich", nameJA: "サンドイッチ", nameEN: "Sandwich", imageName: "sandwich", colorKey: "white", price: 350),
    Product(key: "donut", nameJA: "ドーナツ", nameEN: "Donut", imageName: "donut", colorKey: "brown", price: 160)
]

// ケーキ屋の商品
let cakeProducts: [Product] = [
    Product(key: "shortcake", nameJA: "ショートケーキ", nameEN: "Shortcake", imageName: "shortcake", colorKey: "white", price: 450),
    Product(key: "chocolatecake", nameJA: "チョコケーキ", nameEN: "Chocolate Cake", imageName: "chocolate_cake", colorKey: "brown", price: 480),
    Product(key: "cheesecake", nameJA: "チーズケーキ", nameEN: "Cheesecake", imageName: "cheesecake", colorKey: "yellow", price: 420),
    Product(key: "montblanc", nameJA: "モンブラン", nameEN: "Mont Blanc", imageName: "mont_blanc", colorKey: "brown", price: 500),
    Product(key: "roll_cake", nameJA: "ロールケーキ", nameEN: "Roll Cake", imageName: "roll_cake", colorKey: "white", price: 380),
    Product(key: "pudding", nameJA: "タルト", nameEN: "tart", imageName: "tart", colorKey: "yellow", price: 300)
]

// レストランの商品 (新規追加)
let restaurantProducts: [Product] = [
    Product(key: "hamburg_steak", nameJA: "ハンバーグ", nameEN: "Hamburg Steak", imageName: "hamburg_steak", colorKey: "brown", price: 850),
    Product(key: "gyoza", nameJA: "ギョーザ", nameEN: "Gyoza", imageName: "gyoza", colorKey: "white", price: 450),
    Product(key: "hamburger", nameJA: "ハンバーガー", nameEN: "Hamburger", imageName: "hamburger", colorKey: "brown", price: 600),
    Product(key: "curry", nameJA: "カレーライス", nameEN: "Curry Rice", imageName: "curry", colorKey: "brown", price: 700),
    Product(key: "beer", nameJA: "ビール", nameEN: "Beer", imageName: "beer", colorKey: "yellow", price: 550),
    Product(key: "wine", nameJA: "ワイン", nameEN: "Wine", imageName: "wine", colorKey: "red", price: 650)
] 