//
//  MenuConfig.swift
//  XBDialog
//
//  Created by xiaobin liu on 2018/2/28.
//  Copyright © 2018年 Sky. All rights reserved.
//

import Foundation
import UIKit

/// MARK - 菜单类型
public enum MenuType {
    
    /// 左边宽度
    case leftWidth(w: CGFloat)
    /// 左边的占整个比例
    case leftWidthFromViewRate(rate: CGFloat)
    
    /// 右边宽度
    case rightWidth(w: CGFloat)
    /// 右边的占整个比例
    case rightWidthFromViewRate(rate: CGFloat)
    
    /// 底部高度
    case bottomHeight(h: CGFloat)
    /// 底部高度占整个比例
    case bottomHeightFromViewRate(rate: CGFloat)
    
    case leftFullScreen
    case rightFullScreen
}


/// 菜单框配置
public class MenuConfig: PresentConfig  {
    
    /// 呈现规模
    public var presentingScale: CGFloat = 1.0
    
    /// 阻尼大小
    public var damping: CGFloat = 0.0
    
    /// 动画选项
    public var animationOption: UIView.AnimationOptions = .curveLinear
    
    /// SpringVelocity则表示初始的速度，数值越大一开始移动越快。在usingSpringWithDamping为1.0f时，initialSpringVelocity分别取5.0f，15.0f和25.0f的情况。值得注意的是，初始速度取值较高而时间较短时，也会出现反弹)
    public var springVelocity: CGFloat = 0.0
    
    /// 动画时间
    public var duration: TimeInterval = 0.3
    
    /// 菜单类型
    public var menuType: MenuType = .bottomHeight(h: 100)
    
    /// 背景手势
    public var gestureRecognizer: UIGestureRecognizer?
    
    /// 背景毛玻璃效果(如果nil的话,默认一般的)
    public var blurEffectStyle: UIBlurEffect.Style?
    
    /// 是否遮照
    public var isShowMask: Bool = true
    
    /// 是否支持拖拽
    public var isDraggable = false
    
    /// 推动互动过渡
    public var drivenInteractive: UIPercentDrivenInteractiveTransition?
    
    /// 拖拽完成阀值
    public var draggableCompletedPrecent: CGFloat = 0.5
}





