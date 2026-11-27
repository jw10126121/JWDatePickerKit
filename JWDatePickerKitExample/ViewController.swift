//
//  ViewController.swift
//  JWDatePickerKit
//
//  Created by 10126121@qq.com on 04/09/2019.
//  Copyright (c) 2019 10126121@qq.com. All rights reserved.
//

import UIKit
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
    
    private lazy var data = [JWDatePickerType.year,
                        JWDatePickerType.yearAndMonth,
                        JWDatePickerType.date,
                        JWDatePickerType.dateHour,
                        JWDatePickerType.dateHourMinute,
                        JWDatePickerType.dateHourMinuteSecond,
                        JWDatePickerType.monthDay,
                        JWDatePickerType.monthDayHour,
                        JWDatePickerType.monthDayHourMinute,
                        JWDatePickerType.monthDayHourMinuteSecond,
                        JWDatePickerType.time,
                        JWDatePickerType.timeAndSecond,
                        JWDatePickerType.minuteAndSecond,
                        JWDatePickerType.dateAndTime]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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

