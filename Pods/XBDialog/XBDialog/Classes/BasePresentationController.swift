//
//  BasePresentationController.swift
//  XBDialog
//
//  Created by xiaobin liu on 2018/2/28.
//  Copyright © 2018年 Sky. All rights reserved.
//

import UIKit


/// MARK - 基类BasePresentation
public class BasePresentationController: UIPresentationController {

    /// 配置
    internal var config: PresentConfig!
    
    /// 初始化
    public convenience init(presentedViewController: UIViewController, presenting
        presentingViewController: UIViewController? ,
                            config:PresentConfig) {
        
        self.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.config = config
    }
    
    
    /// 遮罩View
    public var maskView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        return view
    }()
    
    
    /// 在呈现过渡即将开始的时候被调用的,(在这里面加入遮罩,以及遮罩显示的动画)
    public override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        if let c = containerView, maskView.superview == nil {
            c.insertSubview(maskView, at: 0)
        }
        
        /// 如果手势存在的话
        if let gusture = config.gestureRecognizer {
            maskView.addGestureRecognizer(gusture)
        }
        
        if self.config.isShowMask {
            
            /// 如果有毛玻璃的设置
            if let effect = config.blurEffectStyle {
                
                maskView.alpha = 1.0
                maskView.effect = UIBlurEffect(style: effect)
                
            } else {
                
                maskView.alpha = 0.0
                maskView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
            }
        }
        
        self.presentingViewController.transitionCoordinator?.animate(alongsideTransition: { (context) in
            self.presentingViewController.view.transform = CGAffineTransform(scaleX: self.config.presentingScale, y: self.config.presentingScale)
        }, completion: nil)
    }
    
    
    /// 在退出过渡即将开始的时候被调用的,(在这里把遮罩给过渡去掉)
    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            UIView.animate(withDuration: config.duration) {
                self.presentingViewController.view.transform = .identity
            }
        }
    }
    
    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let c = containerView {
            maskView.frame = c.bounds
        }
    }
    
    /// 是否全屏
    public override var shouldPresentInFullscreen: Bool {
        return false
    }
    
    /// shouldRemovePresentersView
    public override var shouldRemovePresentersView: Bool {
        return false
    }
    
    /// 视图将过渡
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (context) in
            // Prevent Scale error
            if let c = self.containerView {
                self.presentingViewController.view.transform = .identity
                self.presentingViewController.view.frame = c.bounds
                self.presentingViewController.view.transform = CGAffineTransform(scaleX: self.config.presentingScale, y: self.config.presentingScale)
            }
            self.presentedViewController.view.frame = self.frameOfPresentedViewInContainerView
        }) { (context) in
        }
    }
}
