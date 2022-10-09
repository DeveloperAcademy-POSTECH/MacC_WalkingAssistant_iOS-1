//
//  MainViewController.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/10/07.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        overrideUserInterfaceStyle = .dark
        
        createNavigateButton()
        createEnvironmentReaderButton()
        createTextReadingButton()
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

}
