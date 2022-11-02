//
//  MainViewController.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/10/07.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import Vision

class MainViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // Variable for UI changing
    var selected = 0

    // Variable for object detection camera view
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil

    @IBOutlet weak private var previewView: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // set
        UIDevice.current.isProximityMonitoringEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.isProximityMonitoringEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        overrideUserInterfaceStyle = .dark
        
        UIDevice.current.isProximityMonitoringEnabled = true
        
        if UIDevice.current.isProximityMonitoringEnabled {
            NotificationCenter.default.addObserver(self, selector: #selector(proximityStateDidChange), name: UIDevice.proximityStateDidChangeNotification, object: nil)
        }

        // MARK: Marked as an annotation for possible later use -> Swiping UI
//        self.view.addSubview(self.controlSwitch)
//        self.view.addSubview(self.label)

        self.view.addSubview(self.createNavigateButton)
        self.view.addSubview(self.createEnvironmentReaderButton)
        self.view.addSubview(self.createTextReadingButton)
        self.view.addSubview(self.createSettingButton)
    }

    lazy var createNavigateButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: 0,
            y: self.view.frame.height * 0.1,
            width: self.view.frame.width,
            height: self.view.frame.height * 0.25
        )
        button.backgroundColor = UIColor.black
        button.setTitle("Navigation", for: .normal)
        button.layer.cornerRadius = 10.0
        button.tag = 1
        button.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        button.layer.cornerRadius = 10.0
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.red.cgColor

        self.view.addSubview(button)

        return button
    }()

    lazy var createEnvironmentReaderButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: 0,
            y: self.view.frame.height * 0.35 + 20,
            width: self.view.frame.width,
            height: self.view.frame.height * 0.25
        )
        button.backgroundColor = UIColor.black
        button.setTitle("Environment Reader", for: .normal)
        button.layer.cornerRadius = 10.0
        button.tag = 2
        button.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        button.layer.cornerRadius = 10.0
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.yellow.cgColor

        self.view.addSubview(button)

        return button
    }()

    lazy var createTextReadingButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: 0,
            y: self.view.frame.height * 0.6 + 40,
            width: self.view.frame.width,
            height: self.view.frame.height * 0.25
        )
        button.backgroundColor = UIColor.black
        button.setTitle("Text Reader", for: .normal)
        button.layer.cornerRadius = 10.0
        button.tag = 3
        button.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        button.layer.cornerRadius = 10.0
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.blue.cgColor

        self.view.addSubview(button)

        return button
    }()
    
    lazy var createSettingButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: self.view.frame.width - 120,
            y: self.view.frame.height - 80,
            width: 120,
            height: 40
        )
        button.backgroundColor = UIColor.black
        button.setTitle("Settings", for: .normal)
        button.addTarget(self, action: #selector(openSettingView), for: .touchUpInside)

        self.view.addSubview(button)

        return button
    }()

    // MARK: marked as an annotation for possible later use -> Swiping UI
//    lazy var label: UILabel = {
//        let label = UILabel(frame: CGRect(
//            x: 0,
//            y: 0,
//            width: self.view.frame.width,
//            height: self.view.frame.height/17
//        ))
//        label.backgroundColor = UIColor.black
//        label.layer.masksToBounds = true
//        label.textColor = UIColor.white
//        label.textAlignment = NSTextAlignment.center
//        label.layer.position = CGPoint(
//            x: self.view.bounds.width/2,
//            y: self.view.bounds.height/14
//        )
//        label.text = "Button UI"
//
//        return label
//    }()

    // MARK: Marked as an annotation for possible later use -> Swiping UI
//    lazy var controlSwitch: UISwitch = {
//        // Create a Switch.
//        let UIToggleSwitch: UISwitch = UISwitch()
//        UIToggleSwitch.layer.position = CGPoint(
//            x: self.view.frame.width/2,
//            y: self.view.frame.height/1.07
//        )
//
//        // Display the border of switch.
//        UIToggleSwitch.tintColor = UIColor.orange
//
//        // Set Switch to On.
//        UIToggleSwitch.isOn = false
//
//        // Set the event to be called when switching On / Off of Switch.
//        UIToggleSwitch.addTarget(self,
//                action: #selector(onClickSwitch(sender:)),
//                for: UIControl.Event.valueChanged)
//
//        return UIToggleSwitch
//    }()

    @objc func onClickSwitch(sender: UISwitch) {
//        var text: String!  // MARK: Marked as an annotation for possible later use -> Swiping UI

        if sender.isOn {
//            text = "Swipe UI"  // MARK: Marked as an annotation for possible later use -> Swiping UI
            createNavigateButton.removeFromSuperview()
            createTextReadingButton.removeFromSuperview()
            createEnvironmentReaderButton.removeFromSuperview()
        } else {
//            text = "Button UI"  // MARK: Marked as an annotation for possible later use -> Swiping UI
            self.view.addSubview(self.createNavigateButton)
            self.view.addSubview(self.createTextReadingButton)
            self.view.addSubview(self.createEnvironmentReaderButton)
        }

//        self.label.text = text  // MARK: Marked as an annotation for possible later use -> Swiping UI
    }
    
    @objc func onTouchButton(_ sender: UIButton) {
        self.selected = sender.tag
        if(selected == 1) {
            self.createNavigateButton.backgroundColor = .red
            self.createEnvironmentReaderButton.backgroundColor = .black
            self.createTextReadingButton.backgroundColor = .black
        } else if (self.selected == 2) {
            self.createNavigateButton.backgroundColor = .black
            self.createEnvironmentReaderButton.backgroundColor = .yellow
            self.createTextReadingButton.backgroundColor = .black
        } else if (self.selected == 3) {
            self.createNavigateButton.backgroundColor = .black
            self.createEnvironmentReaderButton.backgroundColor = .black
            self.createTextReadingButton.backgroundColor = .blue
        }
    }
    
    @objc func openSettingView() {
        let mainVC = SettingViewController()
        present(mainVC, animated: true, completion: nil)
    }
    
    @objc func proximityStateDidChange() {
        print("\(UIDevice.current.proximityState ? "디바이스가 정상입니다" : "디바이스를 뒤집어 주세요")");
    }
}

