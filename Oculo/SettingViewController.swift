//
//  SettingViewController.swift
//  Oculo
//
//  Created by Dongjin Jeon on 2022/10/27.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {
    
    lazy var logoImageView = UIImageView(image: UIImage(named: "settingViewLogo"))
    lazy var tableView = UITableView(frame: .zero, style: .insetGrouped)
    lazy var lastLableView = UILabel()
    
    let data = [["멤버십", "보행정보 제공 동의"], ["이용 약관 (Terms of arrangement", "개인정보 보호 (Privacy)", "사용권 조항 (License)", "고객센터 (Contact Us)"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        
        self.view.addSubview(self.logoImageView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.lastLableView)
        
        self.tableView.dataSource = self
        self.lastLableView.text = """
        Copyright(c) 2022. IntelligentATLAS.
        All Rights Reserved.
        """
        self.lastLableView.lineBreakMode = .byWordWrapping
        self.lastLableView.numberOfLines = 0
        self.lastLableView.textAlignment = .center
        
        self.logoImageView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.lastLableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate(
        [
            self.logoImageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            self.logoImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.logoImageView.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.lastLableView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.lastLableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

}

extension SettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: .none)
        cell.textLabel?.text = data[indexPath.section][indexPath.row]
        return cell
    }
}
