//
//  ViewController.swift
//  JWDatePickerKit
//
//  Created by 10126121@qq.com on 04/09/2019.
//  Copyright (c) 2019 10126121@qq.com. All rights reserved.
//

import UIKit
import PGDatePicker
import SnapKit
import JWDatePickerKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    /// 列表
    lazy var tableView: UITableView = {
        let temTable = UITableView(frame: CGRect.zero, style: .plain)
        temTable.delegate = self
        temTable.dataSource = self
        temTable.backgroundView = nil
        temTable.backgroundColor = UIColor.white
        temTable.separatorInset = .zero
        temTable.tableFooterView = UIView()
        temTable.register(UITableViewCell.self, forCellReuseIdentifier: "1")
        return temTable
    }()
    
    private lazy var data = [PGDatePickerMode.year,
                        PGDatePickerMode.yearAndMonth,
                        PGDatePickerMode.date,
                        PGDatePickerMode.dateHour,
                        PGDatePickerMode.dateHourMinute,
                        PGDatePickerMode.dateHourMinuteSecond,
                        PGDatePickerMode.monthDay,
                        PGDatePickerMode.monthDayHour,
                        PGDatePickerMode.monthDayHourMinute,
                        PGDatePickerMode.monthDayHourMinuteSecond,
                        PGDatePickerMode.time,
                        PGDatePickerMode.timeAndSecond,
                        PGDatePickerMode.minuteAndSecond,
                        PGDatePickerMode.dateAndTime]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "1")
        cell?.textLabel?.text = self.data[indexPath.row].name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        let dateVC = JWDatePickerViewController()
        dateVC.datePickerMode = self.data[indexPath.row]
        //        dateVC.defaultDate = Date()
        //        dateVC.maximumDate = Date()
        //        dateVC.minimumDate = Date()
        
        dateVC.cancelHandler = {
            dateVC.dismiss(animated: true, completion: nil)
        }
        dateVC.confirmHandler = { date in
            debugPrint(date)
            dateVC.dismiss(animated: true, completion: nil)
        }
        self.present(dateVC, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension PGDatePickerMode {
    
    public var name: String {
        switch self {
        case .year:
            return "年"
        case .yearAndMonth:
            return "年月"
        case .date:
            return "年月日"
        case .dateHour:
            return "年月日时"
        case .dateHourMinute:
            return "年月日时分"
        case .dateHourMinuteSecond:
            return "年月日时分秒"
        case .monthDay:
            return "月日"
        case .monthDayHour:
            return "月日时"
        case .monthDayHourMinute:
            return "月日时分"
        case .monthDayHourMinuteSecond:
            return "月日时分秒"
        case .time:
            return "时分"
        case .timeAndSecond:
            return "时分秒"
        case .minuteAndSecond:
            return "分秒"
        case .dateAndTime:
            return "月日周 时分"
        }
    }
}

