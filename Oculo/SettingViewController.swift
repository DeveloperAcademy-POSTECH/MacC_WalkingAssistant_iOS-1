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
    let data = [["License"],["SPEAKING RATE"]]
    let sectionNames = ["","SPEAKING RATE"]
    
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
//https://feelsodev.tistory.com/7
class CustomCell: UITableViewCell {
    static let cellId = "speakingRate"
    var soundManger = SoundManager()
    
    let turtleImage = UIImageView(
        image: UIImage(
            systemName: "tortoise",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .medium))?.withTintColor(.white, renderingMode: .alwaysOriginal)
    )
    
    let rabbitImage = UIImageView(
        image: UIImage(
            systemName: "hare",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .medium))?.withTintColor(.white, renderingMode: .alwaysOriginal)
    )
    
    lazy var slider : UISlider = {
        let slider = UISlider()
        slider.maximumValue = 1.0  // 슬라이더 최댓값
        slider.minimumValue = 0.5  // 슬라이더 최솟값
        slider.value = soundManger.speakingRate  // soundManager의 speakingRate를 받아옴
        slider.addTarget(self, action: #selector(onChangeValueSlider(sender: )), for: UIControl.Event.valueChanged)
        return slider
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
        self.selectionStyle = .none  // 커스텀셀이 터치되어도 변화 없게
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layout() {
        let imageMargin:CGFloat = 24 // 이미지 와 셀간의 간격 ( [ 여기 이미지 슬라이더 이미지 여기 ] )
        let sliderMargin:CGFloat = 10 // 슬라이더 와 이미지 사이의 간격 ( [ 이미지 여기 슬라이더 여기 이미지 ] )
        self.contentView.addSubview(turtleImage)
        self.contentView.addSubview(rabbitImage)
        self.contentView.addSubview(slider)
        
        turtleImage.translatesAutoresizingMaskIntoConstraints = false
        turtleImage.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: imageMargin).isActive = true
        turtleImage.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        
        rabbitImage.translatesAutoresizingMaskIntoConstraints = false
        rabbitImage.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -imageMargin).isActive = true
        rabbitImage.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.leftAnchor.constraint(equalTo: turtleImage.rightAnchor, constant: sliderMargin).isActive = true
        slider.rightAnchor.constraint(equalTo: rabbitImage.leftAnchor, constant: -sliderMargin).isActive = true
        slider.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
    }
    
    @objc func onChangeValueSlider(sender: UISlider) { // 슬라이더가 변경되었을때
        UserDefaults.standard.setValue(sender.value, forKey: "speakingRate") // speakingRate 유저디폴트에 저장
    }
}

extension SettingViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {  // 섹션 갯수
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {  // 섹션당 row 갯수
        return data[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {  // 섹션 title
        return Language(rawValue: sectionNames[section])?.localized
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {  // cell 높이
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case 0 : // 0번째 섹션일때 (라이선스 부분)
            cell = UITableViewCell(style: .default, reuseIdentifier: .none)
            cell.textLabel?.text = Language(rawValue: data[indexPath.section][indexPath.row])?.localized
        case 1 : // 1번째 섹션일때 (speakingRate 조절하는 슬라이더가 있는 부분)
            let customCell: CustomCell
            customCell = CustomCell(style: .default, reuseIdentifier: .none)
            return customCell
        default :  // 여기로오면 에러 ㅎㅎ...
            cell = UITableViewCell(style: .default, reuseIdentifier: .none)
            cell.textLabel?.text = Language(rawValue: "error")?.localized  // error(에러입니다) 라고 적힌 cell을 반환
        }
        return cell
    }
    
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case [0,0] : // 라이선스셀이 터치 되었을때
            present(LicenseViewController(), animated: true)  // 라이선스 페이지를 띄움
        default: // 라이선스셀 외에 다른부분이 터치 되었을때 (에러상황)
            print("error")
        }
    }
}
