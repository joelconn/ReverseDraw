import SpriteKit
import SwiftUI

#if os(macOS)
struct ConfettiView: NSViewRepresentable {
    var intensity: Intensity = .normal
    var loop: Bool = false
    enum Intensity { case normal, dramatic }

    func makeNSView(context: Context) -> SKView {
        let skView = SKView(frame: .zero)
        skView.allowsTransparency = true
        skView.wantsLayer = true
        skView.layer?.backgroundColor = .clear
        skView.ignoresSiblingOrder = true
        skView.presentScene(makeScene())
        return skView
    }
    func updateNSView(_ nsView: SKView, context: Context) {}
    private func makeScene() -> ConfettiScene {
        let s = ConfettiScene()
        s.intensity = intensity
        s.loop = loop
        s.scaleMode = .resizeFill
        s.backgroundColor = .clear
        return s
    }
}
#else
struct ConfettiView: UIViewRepresentable {
    var intensity: Intensity = .normal
    var loop: Bool = false
    enum Intensity { case normal, dramatic }

    func makeUIView(context: Context) -> SKView {
        let skView = SKView(frame: .zero)
        skView.isOpaque = false
        skView.backgroundColor = .clear
        skView.ignoresSiblingOrder = true
        skView.presentScene(makeScene())
        return skView
    }
    func updateUIView(_ uiView: SKView, context: Context) {}
    private func makeScene() -> ConfettiScene {
        let s = ConfettiScene()
        s.intensity = intensity
        s.loop = loop
        s.scaleMode = .resizeFill
        s.backgroundColor = .clear
        return s
    }
}
#endif

final class ConfettiScene: SKScene {
    var intensity: ConfettiView.Intensity = .normal
    var loop: Bool = false
    private var launched = false

    override func didMove(to view: SKView) {
        guard !launched else { return }
        launched = true

        // Set scene size to match the view's bounds so particles spawn across full screen
        if view.bounds.width > 0, view.bounds.height > 0 {
            size = view.bounds.size
        }

        backgroundColor = SKColor.clear
        scaleMode = .resizeFill

        if loop {
            run(SKAction.repeatForever(SKAction.sequence([
                SKAction.run { [weak self] in self?.launchConfetti() },
                SKAction.wait(forDuration: 2.5)
            ])))
        } else {
            launchConfetti()
        }
    }

    private func launchConfetti() {
        let count = intensity == .dramatic ? 320 : 160
        let colors: [SKColor] = [
            .systemYellow,
            .systemTeal,
            .white,
            SKColor(red: 1.0, green: 0.38, blue: 0.38, alpha: 1),
            SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1),
            SKColor(red: 0.2, green: 0.85, blue: 0.75, alpha: 1)
        ]

        for i in 0..<count {
            let color = colors.randomElement()!
            let w = CGFloat.random(in: 8...18)
            let h = CGFloat.random(in: 4...12)
            let node = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 1)
            node.fillColor = color
            node.strokeColor = .clear
            node.zRotation = CGFloat.random(in: 0...(2 * .pi))
            node.alpha = CGFloat.random(in: 0.7...1.0)

            let startX = CGFloat.random(in: 0...size.width)
            node.position = CGPoint(x: startX, y: size.height + 30)
            addChild(node)

            let delay = Double(i) / Double(count) * 2.0
            let duration = Double.random(in: 2.5...4.5)
            let drift = CGFloat.random(in: -250...250)
            let endY = CGFloat.random(in: -100...size.height * 0.2)

            let move = SKAction.moveBy(
                x: drift,
                y: endY - node.position.y,
                duration: duration
            )
            move.timingMode = .easeIn

            let rotate = SKAction.rotate(
                byAngle: CGFloat.random(in: -.pi * 6...(.pi * 6)),
                duration: duration
            )

            let fadeStart = duration * 0.65
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: fadeStart),
                SKAction.fadeOut(withDuration: duration - fadeStart)
            ])

            let anim = SKAction.group([move, rotate, fade])
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                anim,
                SKAction.removeFromParent()
            ]))
        }
    }
}
