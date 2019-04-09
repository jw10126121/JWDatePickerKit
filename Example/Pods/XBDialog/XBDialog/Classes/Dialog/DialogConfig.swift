//
//  DialogConfig.swift
//  XBDialog
//
//  Created by xiaobin liu on 2017/6/7.
//  Copyright © 2017年 Sky. All rights reserved.
//

import Foundation
import UIKit



/// 对话框类型
public enum DialogType {
    case preferSize //preferredContentSize
    case size(s: CGSize) //Custom Size
}

/// 方向类型
public enum DirectionType {
    case left
    case right
    case top
    case bottom
}

/// 对话框动画类型
public enum DialogAnimateType {
    case alpha(from: CGFloat , to: CGFloat)
    case scale(from: CGFloat , to: CGFloat)
    case direction(type: DirectionType)
}


/// 弹出框配置
public class DialogConfig: PresentConfig  {
    
    /// 呈现规模
    public var presentingScale: CGFloat = 1.0
    
    /// 阻尼大小
    public var damping: CGFloat = 0.0
    
    /// 动画选项
    public var animationOption: UIView.AnimationOptions = UIView.AnimationOptions.curveLinear
    
    /// SpringVelocity则表示初始的速度，数值越大一开始移动越快。在usingSpringWithDamping为1.0f时，initialSpringVelocity分别取5.0f，15.0f和25.0f的情况。值得注意的是，初始速度取值较高而时间较短时，也会出现反弹)
    public var springVelocity: CGFloat = 0.0
    
    /// 动画时间
    public var duration: TimeInterval = 0.3
    
    /// 对话框类型
    public var dialogType: DialogType = DialogType.preferSize
    
    /// 动画类型
    public var animateType: DialogAnimateType = .alpha(from: 0, to: 1)
    
    /// 背景手势
    public var gestureRecognizer: UIGestureRecognizer?
    
    /// 背景毛玻璃效果(如果nil的话,默认一般的)
    public var blurEffectStyle: UIBlurEffect.Style?
    
    /// 是否遮照
    public var isShowMask: Bool = true
}
