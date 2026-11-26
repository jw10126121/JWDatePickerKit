//
//  DialogPresentationController.swift
//  XBDialog
//
//  Created by xiaobin liu on 2017/6/7.
//  Copyright © 2017年 Sky. All rights reserved.
//

import Foundation
import UIKit


/// 对话框UIPresentationController
public class DialogPresentationController: BasePresentationController {
    
    
    /// dismissalTransitionWillBegin
    public override func dismissalTransitionWillBegin() {
        
        super.dismissalTransitionWillBegin()
        self.presentingViewController.transitionCoordinator?.animate(alongsideTransition: { (context) in
            self.presentingViewController.view.transform = .identity
        }, completion: nil)
    }
    
    
    /// 如果你不希望被呈现的 View 占据了整个屏幕，可以调整它的frame
    public override var frameOfPresentedViewInContainerView: CGRect {
        
        get {
            
            if let frame = containerView?.frame {
                let width = frame.width
                let height = frame.height
                switch (config as! DialogConfig).dialogType {
                case .preferSize:
                    let presentedSize = self.presentedViewController.preferredContentSize
                    return CGRect(x: (width - presentedSize.width) / 2,
                                  y: (height - presentedSize.height) / 2,
                                  width: presentedSize.width,
                                  height: presentedSize.height)
                case .size(let s):
                    
                    return CGRect(x: (width - s.width) / 2,
                                  y: (height - s.height) / 2,
                                  width: s.width,
                                  height: s.height)
                }
            } else if let f = self.presentedView?.frame {
                return f
            }
            
            return CGRect.zero
        } set {}
    }
}

