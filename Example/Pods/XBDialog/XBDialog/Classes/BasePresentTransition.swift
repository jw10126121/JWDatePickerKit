//
//  BasePresentTransition.swift
//  XBDialog
//
//  Created by xiaobin liu on 2018/2/28.
//  Copyright © 2018年 Sky. All rights reserved.
//

import Foundation
import UIKit


/// MARK - 基础过渡
public class BasePresentTransition: NSObject {
    
    var isPresent = true
    var source: UIViewController?
    
    internal var config: PresentConfig!
    
    convenience init(config: PresentConfig , isPresent: Bool) {
        self.init()
        self.config = config
        self.isPresent = isPresent
    }
    
    func animate(animations: @escaping () -> Void , completion:((Bool) -> Void)?) {
        
        if config.damping == 0.0 {
            UIView.animate(withDuration: config.duration, animations: animations, completion: completion)
        } else {
            UIView.animate(withDuration: config.duration, delay: 0.0, usingSpringWithDamping: config.damping, initialSpringVelocity: config.springVelocity, options: config.animationOption, animations: animations, completion: completion)
        }
    }
}
