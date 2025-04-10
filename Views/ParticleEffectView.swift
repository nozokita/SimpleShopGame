import SwiftUI

// 個々のパーティクルを表す構造体
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var creationDate = Date() // 生成時刻
}

// パーティクルエフェクトを表示するビュー
struct ParticleEffectView: View {
    @Binding var isVisible: Bool // このビューを表示するかどうかを外部から制御
    @State private var particles: [Particle] = []
    private let particleCount = 30 // 一度に生成するパーティクルの数
    private let duration: TimeInterval = 0.8 // エフェクトの継続時間

    var body: some View {
        // isVisible が true になった時にパーティクルを生成・アニメーション
        TimelineView(.animation(minimumInterval: 0.016, paused: !isVisible)) { timeline in
            Canvas { context, size in
                // 現在時刻に基づいて各パーティクルを描画
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let timeAlive = now - particle.creationDate.timeIntervalSinceReferenceDate
                    if timeAlive < duration {
                        // 時間経過で上に移動し、透明になる
                        let progress = timeAlive / duration
                        let currentY = particle.y - (progress * 150) // 上昇距離
                        let currentOpacity = (1.0 - progress) * particle.opacity
                        let currentSize = particle.size * (1.0 - progress * 0.5) // 少し小さくなる

                        // パーティクル（円形）を描画
                        let particleRect = CGRect(x: particle.x - currentSize / 2,
                                                  y: currentY - currentSize / 2,
                                                  width: currentSize,
                                                  height: currentSize)

                        context.fill(Path(ellipseIn: particleRect),
                                     with: .color(randomSparkleColor().opacity(currentOpacity)))
                    }
                }
            }
            // isVisible が変更された時（特に true になった時）に実行
            .onChange(of: isVisible) {
                if isVisible {
                    createParticles()
                    // 指定時間後に isVisible を false に戻す
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        isVisible = false
                        particles.removeAll() // 古いパーティクルを削除
                    }
                }
            }
            // isVisible が false になったらパーティクルを消去
            .onAppear {
                 if !isVisible {
                    particles.removeAll()
                }
            }
        }
        // ビュー自体は透明で、タップを透過する
        .allowsHitTesting(false)
    }

    // パーティクルを初期位置に生成する
    private func createParticles() {
        particles = (0..<particleCount).map { _ in
            // 画面中央付近からランダムに散らばるように生成
            let initialX = CGFloat.random(in: -50...50)
            let initialY = CGFloat.random(in: -30...30)
            let size = CGFloat.random(in: 3...8)
            let opacity = Double.random(in: 0.5...1.0)

            return Particle(x: initialX, y: initialY, size: size, opacity: opacity)
        }
    }

    // キラキラした色をランダムに返すヘルパー関数
    private func randomSparkleColor() -> Color {
        let colors: [Color] = [.yellow, .orange, .pink, .white, Color.yellow.opacity(0.7)]
        return colors.randomElement()!
    }
}

// Preview用
struct ParticleEffectView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue // 背景色
            ParticleEffectView(isVisible: .constant(true)) // 常時表示でプレビュー
                .offset(x: 100, y: 100) // 表示位置を調整
        }
    }
} 