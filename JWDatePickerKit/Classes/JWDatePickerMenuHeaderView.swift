//
//  JWDatePickerHeaderView.swift
//  JWDatePickerKit
//
//  Created by linjw on 2019/4/9.
//

import UIKit


/// 时间选择头部菜单视图
@objc public class JWDatePickerMenuHeaderView: UIView {
    
    /// 取消事件
    @objc public var cancelHandler: (() -> Void)?
    
    /// 确定事件
    @objc public var confirmHandler: (() -> Void)?

    /// 取消标题
    @objc public dynamic var cancelTitle: String = "取消" {
        didSet {
            self.cancelButton.setTitle(cancelTitle, for: .normal)
        }
    }
    
    /// 取消按钮默认颜色
    @objc public dynamic var cancelNormalColor: UIColor = UIColor.red {
        didSet {
            self.cancelButton.setTitleColor(cancelNormalColor, for: .normal)
        }
    }
    
    /// 取消按钮选中状态颜色
    @objc public dynamic var cancelHighlightedColor: UIColor = UIColor.red {
        didSet {
            self.cancelButton.setTitleColor(cancelHighlightedColor, for: .highlighted)
        }
    }
    
    /// 确定标题
    @objc public dynamic var confirmTitle: String = "确定" {
        didSet {
            self.confirmButton.setTitle(confirmTitle, for: .normal)
        }
    }
    
    /// 确定按钮默认状态颜色
    @objc public dynamic var confirmNormalColor: UIColor = UIColor.black {
        didSet {
            self.confirmButton.setTitleColor(confirmNormalColor, for: .normal)
        }
    }
    
    /// 确定按钮选中状态颜色
    @objc public dynamic var confirmHighlightedColor: UIColor = UIColor.black {
        didSet {
            self.confirmButton.setTitleColor(confirmHighlightedColor, for: .highlighted)
        }
    }
    
    /// 线的颜色
    @objc public dynamic var lineColor: UIColor = UIColor(red: 214/255.0, green: 214/255.0, blue: 214/255.0, alpha: 1.0) {
        didSet {
            self.topLine.backgroundColor = lineColor
            self.bottomLine.backgroundColor = lineColor
        }
    }
    
    
    /// 取消按钮
    private lazy var cancelButton: UIButton = {
        
        let temButton = UIButton(type: .custom)
        temButton.setTitle(self.cancelTitle, for: .normal)
        temButton.setTitleColor(self.cancelNormalColor, for: .normal)
        temButton.setTitleColor(self.cancelHighlightedColor, for: .highlighted)
        temButton.addTarget(self, action: #selector(self.eventForCancel), for: .touchUpInside)
        return temButton
    }()
    
    /// 确定按钮
    private lazy var confirmButton: UIButton = {
        
        let temButton = UIButton(type: .custom)
        temButton.setTitle(self.confirmTitle, for: .normal)
        temButton.setTitleColor(self.confirmNormalColor, for: .normal)
        temButton.setTitleColor(self.confirmHighlightedColor, for: .highlighted)
        temButton.addTarget(self, action: #selector(self.eventForConfirm), for: .touchUpInside)
        return temButton
    }()
    
    
    /// 头部线
    private lazy var topLine: UILabel = {
        
        let temLabel = UILabel()
        temLabel.backgroundColor = self.lineColor
        return temLabel
    }()
    
    /// 底部线
    private lazy var bottomLine: UILabel = {
        
        let temLabel = UILabel()
        temLabel.backgroundColor = self.lineColor
        return temLabel
    }()
    
    
    /// 取消事件
    @objc private func eventForCancel() {
        cancelHandler?()
    }
    
    /// 确定事件
    @objc private func eventForConfirm() {
        confirmHandler?()
    }
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    
    

}

fileprivate extension JWDatePickerMenuHeaderView {
    
    func setupUI() {
        
        backgroundColor = UIColor.white
        
        addSubview(topLine)
        addSubview(cancelButton)
        addSubview(confirmButton)
        addSubview(bottomLine)
        
        /// 布局cancelButton
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16.0).isActive = true
        cancelButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16.0).isActive = true
        confirmButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        confirmButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor).isActive = true
        
        topLine.translatesAutoresizingMaskIntoConstraints = false
        topLine.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        topLine.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        topLine.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        topLine.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        topLine.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        bottomLine.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        bottomLine.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        bottomLine.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        bottomLine.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

//        confirmButton.translatesAutoresizingMaskIntoConstraints = false
//        confirmButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
//        confirmButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
//        self.cancelButton.snp.makeConstraints { (make) in
//            make.left.equalTo(16)
//            make.centerY.equalTo(self)
//            make.height.equalTo(30)
//        }
        
//        self.confirmButton.snp.makeConstraints { (make) in
//            make.right.equalTo(-16)
//            make.centerY.equalTo(self)
//            make.height.equalTo(self.cancelButton.snp.height)
//        }
//
//        self.topLine.snp.makeConstraints { (make) in
//            make.left.right.top.equalTo(self)
//            make.height.equalTo(1.0 / UIScreen.main.scale)
//        }
//
//        self.bottomLine.snp.makeConstraints { (make) in
//            make.left.right.bottom.equalTo(self)
//            make.height.equalTo(self.topLine.snp.height)
//        }
        
    }
}








