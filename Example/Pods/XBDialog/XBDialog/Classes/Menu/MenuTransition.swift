//
//  MenuTransition.swift
//  XBDialog
//
//  Created by xiaobin liu on 2018/2/28.
//  Copyright © 2018年 Sky. All rights reserved.
//

import UIKit


/// MARK - 自定义菜单专场动画
public class MenuTransition: BasePresentTransition, UIViewControllerAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return config.duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let container = transitionContext.containerView
        let height = container.frame.height
        let width = container.frame.width
        switch (config as! MenuConfig).menuType {
        case .bottomHeight(let h):
            self.bottom(context: transitionContext, height: h)
        case .bottomHeightFromViewRate(let rate):
            let rateH = height * rate
            self.bottom(context: transitionContext, height: rateH)
        case .leftWidth(let w):
            self.slide(context: transitionContext, width: w, params: 1)
        case .leftWidthFromViewRate(let rate):
            let rateW = rate * width
            self.slide(context: transitionContext, width: rateW, params: 1)
        case .rightWidth(let w):
            self.slide(context: transitionContext, width: w, params: -1)
        case .rightWidthFromViewRate(let rate):
            let rateW = rate * width
            self.slide(context: transitionContext, width: rateW, params: -1)
        case .leftFullScreen:
            self.slide(context: transitionContext, width: width, params: 1)
        case .rightFullScreen:
            self.slide(context: transitionContext, width: width, params: -1)
        }
    }
    
    func bottom(context:UIViewControllerContextTransitioning , height:CGFloat) {
        let container = context.containerView
        
        if self.isPresent {
            let toVC = context.viewController(forKey: .to)!
            let finalFrame = context.finalFrame(for: toVC)
            toVC.view.frame = finalFrame
            container.addSubview(toVC.view)
            toVC.view.transform = CGAffineTransform(translationX: 0, y: height)
            
            
            ///在使用 Telegram 的过程中，我早就发现它使用起来是非常流畅，而且自带的分享界面和系统原生的分享的呈现动画几乎一模一样。今天我花了几分钟找到了答案，原来 Telegram 使用了一个魔法数字
            /// 它的核心代码是在 UIView.animate 的 options 里，传入了这个魔法选项：
            /// UIView.AnimationOptions(rawValue: 7 << 16 | UIView.AnimationOptions.allowAnimatedContent.rawValue)
            /// 源码参考来自 Telegram 项目：https://github.com/peter-iakovlev/Telegram/blob/public/Share/TGShareController.m#L662
            /// 可能是反向工程系统的库查看到
            let presentationController = toVC.presentationController as? MenuPresentationController
            UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions(rawValue: 7 << 16 | UIView.AnimationOptions.allowAnimatedContent.rawValue), animations: {
                toVC.view.transform = .identity
                presentationController?.maskView.alpha = 1.0
            }) { (finish) in
                context.completeTransition(!context.transitionWasCancelled)
            }
        } else {
            
            let fromVC = context.viewController(forKey: .from)!
            let presentationController = fromVC.presentationController as? MenuPresentationController
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(7 << 16)), animations: {
                fromVC.view.transform = CGAffineTransform(translationX: 0, y: height)
                presentationController?.maskView.alpha = 0.0
            }) { (finish) in
                fromVC.view.transform = .identity
                presentationController?.maskView.removeFromSuperview()
                context.completeTransition(!context.transitionWasCancelled)
            }
        }
    }
    
    func slide(context:UIViewControllerContextTransitioning , width:CGFloat,params:CGFloat) {
        let container = context.containerView
        let x = -width * params
        if self.isPresent {
            let toVC = context.viewController(forKey: .to)!
            let finalFrame = context.finalFrame(for: toVC)
            toVC.view.frame = finalFrame
            container.addSubview(toVC.view)
            
            toVC.view.transform = CGAffineTransform(translationX: x, y: 0)
            let presentationController = toVC.presentationController as? MenuPresentationController
            self.animate(animations: {
                toVC.view.transform = .identity
                presentationController?.maskView.alpha = 1.0
            }, completion: { (finish) in
                context.completeTransition(!context.transitionWasCancelled)
            })
        } else {
            let fromVC = context.viewController(forKey: .from)!
            let presentationController = fromVC.presentationController as? MenuPresentationController
            self.animate(animations: {
                fromVC.view.transform = CGAffineTransform(translationX: x, y: 0)
                presentationController?.maskView.alpha = 0.0
            }, completion: { (finish) in
                fromVC.view.transform = .identity
                presentationController?.maskView.removeFromSuperview()
                context.completeTransition(!context.transitionWasCancelled)
            })
        }
    }
    
}
