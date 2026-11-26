//
//  PresentConfig.swift
//  XBDialog
//
//  Created by xiaobin liu on 2018/2/28.
//  Copyright © 2018年 Sky. All rights reserved.
//

import Foundation
import UIKit


/// MARK - 配置
public protocol Config {
    
    /// 是否遮照
    var isShowMask: Bool { get set }
    
    /// 阻尼
    var damping : CGFloat { get set }
    
    /// 初始速度
    var springVelocity : CGFloat { get set }
    
    /// 动画选项
    var animationOption: UIView.AnimationOptions { get set }
    
    /// 动画时间
    var duration : TimeInterval { get set }
    
    /// 手势
    var gestureRecognizer: UIGestureRecognizer?  { get set }
    
    /// 毛玻璃背景效果
    var blurEffectStyle: UIBlurEffect.Style? { get set }
}

/// MARK - PresentConfig
public protocol PresentConfig: Config {
    var presentingScale: CGFloat  { get set }
}
