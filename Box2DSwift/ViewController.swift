//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update()
    }
}

class ViewController: GLKViewController {
    
    
    private var context: EAGLContext?
    private var glesRenderer: Renderer!
    
    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = self.view as? GLKView, let context = context {
            view.context = context
            delegate = self as GLKViewControllerDelegate
            glesRenderer = Renderer()
            glesRenderer.setup(view)
            glesRenderer.loadModels()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGL()
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.doSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        view.addGestureRecognizer(singleTap)
        
        let singlePan = UIPanGestureRecognizer(target: self, action: #selector(self.doSingleFingerPan(_:)))
        singlePan.minimumNumberOfTouches = 1
        singlePan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(singlePan)

    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glesRenderer.draw(rect)
        let player_score = glesRenderer.box2d.getPlayerScore()
        let AI_score = glesRenderer.box2d.getAIScore()
        
        let player_label = UILabel(frame: CGRect(x: 50, y: 480, width: 250, height: 100))
        player_label.textColor = .white
        player_label.text = ("Player: \(player_score)")
        player_label.tag = 1;
        view.addSubview(player_label)
        
        let AI_label = UILabel(frame: CGRect(x: 50, y: 0, width: 250, height: 100))
        AI_label.textColor = .white
        AI_label.text = ("AI: \(AI_score)")
        AI_label.tag = 2;
        view.addSubview(AI_label)
        
        view.viewWithTag(1)?.removeFromSuperview()
        view.addSubview(player_label)
        
        view.viewWithTag(2)?.removeFromSuperview()
        view.addSubview(AI_label)
        
    }
    
    @objc func doSingleTap(_ sender: UITapGestureRecognizer) {
        glesRenderer.box2d.launchBall()
    }
    
    @objc func doSingleFingerPan(_ sender: UIPanGestureRecognizer) {
        
        glesRenderer.box2d.movePlayer(Float(sender.translation(in: view).x))
        
    }

}
