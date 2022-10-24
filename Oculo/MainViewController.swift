//
//  MainViewController.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/10/07.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        overrideUserInterfaceStyle = .dark
        
        createNavigateButton()
        createEnvironmentReaderButton()
        createTextReadingButton()

        self.view.addSubview(self.controlSwitch)
        self.view.addSubview(self.label)
    }

    func createNavigateButton() {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: 0,
            y: self.view.frame.height * 0.1,
            width: self.view.frame.width,
            height: self.view.frame.height * 0.25
        )
        button.backgroundColor = UIColor.red
        button.setTitle("Navigation", for: .normal)
        button.layer.cornerRadius = 10.0

        self.view.addSubview(button)
    }


    func createEnvironmentReaderButton() {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: 0,
            y: self.view.frame.height * 0.35 + 20,
            width: self.view.frame.width,
            height: self.view.frame.height * 0.25
        )
        button.backgroundColor = UIColor.yellow
        button.setTitle("Environment Reader", for: .normal)
        button.layer.cornerRadius = 10.0

        self.view.addSubview(button)
    }

    func createTextReadingButton() {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: 0,
            y: self.view.frame.height * 0.6 + 40,
            width: self.view.frame.width,
            height: self.view.frame.height * 0.25
        )
        button.backgroundColor = UIColor.blue
        button.setTitle("Text Reader", for: .normal)
        button.layer.cornerRadius = 10.0

        self.view.addSubview(button)
    }

    lazy var label: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height/17))
        label.backgroundColor = UIColor.black
        label.layer.masksToBounds = true
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.layer.position = CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height/14)
        label.text = "Button UI"

        return label
    }()

    lazy var controlSwitch: UISwitch = {
        // Create a Switch.
        let swicth: UISwitch = UISwitch()
        swicth.layer.position = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/1.07)

        // Display the border of Swicth.
        swicth.tintColor = UIColor.orange

        // Set Switch to On.
        swicth.isOn = false

        // Set the event to be called when switching On / Off of Switch.
        swicth.addTarget(self, action: #selector(onClickSwitch(sender:)), for: UIControl.Event.valueChanged)

        return swicth
    }()

    @objc func onClickSwitch(sender: UISwitch) {
        var text: String!

        if sender.isOn {
            text = "Swipe UI"
        } else {
            text = "Button UI"
        }

        self.label.text = text
    }
}
