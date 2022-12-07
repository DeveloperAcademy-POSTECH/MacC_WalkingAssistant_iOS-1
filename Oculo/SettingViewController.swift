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
//https://feelsodev.tistory.com/7
class CustomCell: UITableViewCell {
    static let cellId = "speakingRate"
    
    var speakingRate = 3
    
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
    
    let slider : UISlider = {
        let slider = UISlider()
        slider.maximumValue = 1.5
        slider.minimumValue = 0.5
        slider.value = 0.8
        slider.addTarget(self, action: #selector(onChangeValueSlider(sender: )), for: UIControl.Event.valueChanged)
        return slider
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
        self.selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layout() {
        let leftAndRightConstant:CGFloat = 24
        
        self.contentView.addSubview(turtleImage)
        self.contentView.addSubview(rabbitImage)
        self.contentView.addSubview(slider)
        turtleImage.translatesAutoresizingMaskIntoConstraints = false
        turtleImage.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: leftAndRightConstant).isActive = true
        turtleImage.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        
        rabbitImage.translatesAutoresizingMaskIntoConstraints = false
        rabbitImage.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -leftAndRightConstant).isActive = true
        rabbitImage.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.leftAnchor.constraint(equalTo: turtleImage.rightAnchor, constant: 10).isActive = true
        slider.rightAnchor.constraint(equalTo: rabbitImage.leftAnchor, constant: -10).isActive = true
        slider.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
    }
    @objc func onChangeValueSlider(sender: UISlider) {
        
        //            // Change the green value of the background of the view according to the value of Slider.
        //            self.view.backgroundColor = UIColor(red: 0, green: CGFloat(sender.value), blue: 0, alpha: 1)
        //
        //            // Instantiate CIFilter with color effect specified.
        //            let colorFilter = CIFilter(name: "CIColorCrossPolynomial")
        //
        //            // Set the image.
        //            colorFilter!.setValue(self.inputImage, forKey: kCIInputImageKey)
        //
        //            // Create converted value of RGB.
        //            let r: [CGFloat] = [0.0, CGFloat(sender.value), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        //            let g: [CGFloat] = [0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        //            let b: [CGFloat] = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        //
        //            // Adjust the value.
        //            colorFilter!.setValue(CIVector(values: r, count: 10), forKey: "inputRedCoefficients")
        //            colorFilter!.setValue(CIVector(values: g, count: 10), forKey: "inputGreenCoefficients")
        //            colorFilter!.setValue(CIVector(values: b, count: 10), forKey: "inputBlueCoefficients")
        //
        //            // Output the image processed by the filter.
        //            let outputImage : CIImage = colorFilter!.outputImage!
        //
        //            // Set the UIView processed image again.
        //            self.imageView.image = UIImage(ciImage: outputImage)
        //
        //            // Perform redrawing.
        //            self.imageView.setNeedsDisplay()
        print(sender.value)
    }
}

extension SettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Language(rawValue: sectionNames[section])?.localized
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case 0 :
            cell = UITableViewCell(style: .default, reuseIdentifier: .none)
            //        cell.textLabel?.text = Language(rawValue: data[indexPath.section][indexPath.row])?.localized
            cell.textLabel?.text = Language(rawValue: data[indexPath.section][indexPath.row])?.localized
        case 1 :
            let customCell: CustomCell
            customCell = CustomCell(style: .default, reuseIdentifier: .none)
            return customCell
        default :
            cell = UITableViewCell(style: .default, reuseIdentifier: .none)
            //        cell.textLabel?.text = Language(rawValue: data[indexPath.section][indexPath.row])?.localized
            cell.textLabel?.text = Language(rawValue: "error")?.localized
        }
        return cell
    }
    
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case [0,0] :
            present(LicenseViewController(), animated: true)
        default:
            print("error")
        }
    }
}
