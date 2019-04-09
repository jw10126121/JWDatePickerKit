//
//  JWDatePickerViewController.swift
//  JWDatePickerKit
//
//  Created by linjw on 2019/4/9.
//

import UIKit
import XBDialog
import SnapKit
import PGDatePicker

/// 时间选择控制器(只支持present弹出)
@objc public class JWDatePickerViewController: UIViewController {
    
    /// 点击背景是否隐藏
    @objc public var backgoundTapDismissEnable = true
    
    /// 取消事件
    @objc public var cancelHandler: (() -> Void)?
    
    /// 确定事件
    @objc public var confirmHandler: ((_ date: Date) -> Void)?
    
    /// 时间选择器模式
    @objc public var datePickerMode: PGDatePickerMode = .date {
        didSet {
            self.datePicker.datePickerMode = datePickerMode
        }
    }
    
    /// 默认时间
    @objc public var defaultDate: Date = Date() {
        didSet {
            self.datePicker.setDate(defaultDate, animated: false)
        }
    }
    
    /// 最小时间
    @objc public var minimumDate: Date? {
        didSet {
            guard let temDate = minimumDate else {
                return
            }
            self.datePicker.minimumDate = temDate
        }
    }
    
    /// 最大时间
    @objc public var maximumDate: Date? {
        didSet {
            guard let temDate = maximumDate else {
                return
            }
            self.datePicker.maximumDate = temDate
        }
    }
    
    /// 线背景颜色
    @objc public dynamic var lineBackgroundColor: UIColor = UIColor.black {
        didSet {
            self.datePicker.lineBackgroundColor = lineBackgroundColor
        }
    }
    
    /// 设置选中行的字体颜色
    @objc public dynamic var textColorOfSelectedRow: UIColor = UIColor.black {
        didSet {
            self.datePicker.textColorOfSelectedRow = textColorOfSelectedRow
        }
    }
    
    /// 设置未选中行的字体颜色
    @objc public dynamic var textColorOfOtherRow: UIColor = UIColor.black {
        didSet {
            self.datePicker.textColorOfOtherRow = textColorOfOtherRow
        }
    }
    
    /// 日期选择器
    private lazy var datePicker: PGDatePicker = {
        let temDatePicker = PGDatePicker()
        temDatePicker.delegate = self
        temDatePicker.backgroundColor = UIColor.white
        return temDatePicker
    }()
    
    /// 头部View
    private lazy var headerView: JWDatePickerMenuHeaderView = {
        let temHeaderView = JWDatePickerMenuHeaderView()
        temHeaderView.backgroundColor = UIColor.white
//        temHeaderView.delegate = self
        return temHeaderView
    }()
    
    /// 选择的日期
    private var selectDate: Date = Date()
    
    /// 默认高度
    private lazy var rowHeight: CGFloat = 50
    
    /// 选择日期高度
    private lazy var datePickerHeight: CGFloat = self.rowHeight * 5
    /// 菜单高度
    private lazy var headerViewHeight: CGFloat = self.rowHeight
    
    /// 转场动画
    private var presentAnimator: XBPresentAnimator!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupData()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupData()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    

}

fileprivate extension JWDatePickerViewController {
    
    func setupData() {
        
        let temHeight = self.datePickerHeight + self.headerViewHeight
        self.presentAnimator = XBPresentAnimator(self)
        self.presentAnimator.menu { (config) in
            config.presentingScale = 1.0
            if #available(iOS 11.0, *) {
                let areaInsetsBottom = UIApplication.shared.keyWindow?.rootViewController?.view.safeAreaInsets.bottom ?? 0.0
                config.menuType = .bottomHeight(h: CGFloat(temHeight + areaInsetsBottom))
            } else {
                config.menuType = .bottomHeight(h: temHeight)
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognizer))
            tap.numberOfTapsRequired = 1
            config.gestureRecognizer = tap
        }
        
    }
    
    func setupUI() {
        
        view.addSubview(headerView)
        view.addSubview(datePicker)
        
        headerView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.datePicker.snp.top)
            make.height.equalTo(self.rowHeight)
        }
        
        self.datePicker.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalTo(self.view)
            }
            make.height.equalTo(self.datePickerHeight)
        }
        
        headerView.cancelHandler = { [weak self] () -> Void in
            guard let self = self else { return }
            self.cancelHandler?()
        }
        headerView.confirmHandler = { [weak self] () -> Void in
            guard let self = self else { return }
            self.confirmHandler?(self.selectDate)
        }
        
    }
    
    /// 手势点击
    @objc func tapGestureRecognizer() {
        
        if backgoundTapDismissEnable {
            self.cancelHandler?()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}

extension JWDatePickerViewController: PGDatePickerDelegate {
    
    public func datePicker(_ datePicker: PGDatePicker!, didSelectDate dateComponents: DateComponents!) {
        self.selectDate = Calendar.current.date(from: dateComponents)!
    }
    
}
