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
    lazy var footerLableView = UILabel()
    lazy var logoImageStackView = UIStackView()
    
    //let data = [["Membership", "Agreement on sending recorded video"], ["Terms of arrangement", "Privacy", "License", "Contact Us"]]
    let data = [["License"]]
     
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.logoImageStackView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.footerLableView)

        self.logoImageView.contentMode = .scaleAspectFit

        self.logoImageStackView.addArrangedSubview(logoImageView)
        self.logoImageStackView.distribution = .fillEqually
        self.logoImageStackView.axis = .vertical
        self.logoImageStackView.backgroundColor = .systemBackground

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.footerLableView.text = """
        Copyright(c) 2022. IntelligentATLAS.
        All Rights Reserved.
        """
        self.footerLableView.lineBreakMode = .byWordWrapping
        self.footerLableView.numberOfLines = 0
        self.footerLableView.textAlignment = .center

        self.logoImageView.translatesAutoresizingMaskIntoConstraints = false
        self.logoImageStackView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.footerLableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
        [
            self.logoImageStackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            self.logoImageStackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.logoImageStackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.logoImageStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            //self.logoImageView.topAnchor.constraint(equalTo: self.logoImageStackView.topAnchor, constant: 10),
           
            self.tableView.topAnchor.constraint(equalTo: self.logoImageStackView.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            
            self.footerLableView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.footerLableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
        self.view.backgroundColor = .systemBackground
        
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
//        cell.textLabel?.text = Language(rawValue: data[indexPath.section][indexPath.row])?.localized
        cell.textLabel?.text = Language(rawValue: data[indexPath.section][indexPath.row])?.localized
        return cell
    }
    
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        present(LicenseViewController(), animated: true)
    }
}
