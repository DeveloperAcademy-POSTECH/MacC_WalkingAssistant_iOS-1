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
    
    // Variable for UI Button
    lazy var navigationButton = UIButton()
    lazy var environmentReaderButton = UIButton()
    lazy var textReaderButton = UIButton()
    lazy var settingButton = UIButton()

    // Variable for object detection camera view
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil

    // @IBOutlet weak private var previewView: UIView!  // MARK: Storyboard component
    private var previewView: UIView!
    
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
        
        UIDevice.current.isProximityMonitoringEnabled = true
        
        if UIDevice.current.isProximityMonitoringEnabled {
            NotificationCenter.default.addObserver(self, selector: #selector(proximityStateDidChange), name: UIDevice.proximityStateDidChangeNotification, object: nil)
        }
        
        self.view.addSubview(navigationButton)
        self.view.addSubview(environmentReaderButton)
        self.view.addSubview(textReaderButton)
        self.view.addSubview(settingButton)
        
        createNavigateButton()
        createEnvironmentReaderButton()
        createTextReaderButton()
        createSettingButton()
        
        addConstraints()
    }
    
    func createNavigateButton() {
        navigationButton.backgroundColor = UIColor.black
        navigationButton.setTitle("Navigation", for: .normal)
        navigationButton.layer.cornerRadius = 10.0
        navigationButton.tag = 1
        navigationButton.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        navigationButton.layer.cornerRadius = 10.0
        navigationButton.layer.borderWidth = 10
        navigationButton.layer.borderColor = UIColor.red.cgColor
    }

    func createEnvironmentReaderButton() {
        environmentReaderButton.backgroundColor = UIColor.black
        environmentReaderButton.setTitle("Environment Reader", for: .normal)
        environmentReaderButton.layer.cornerRadius = 10.0
        environmentReaderButton.tag = 2
        environmentReaderButton.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        environmentReaderButton.layer.cornerRadius = 10.0
        environmentReaderButton.layer.borderWidth = 10
        environmentReaderButton.layer.borderColor = UIColor.yellow.cgColor
    }

    func createTextReaderButton() {
        textReaderButton.backgroundColor = UIColor.black
        textReaderButton.setTitle("Text Reader", for: .normal)
        textReaderButton.layer.cornerRadius = 10.0
        textReaderButton.tag = 3
        textReaderButton.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        textReaderButton.layer.cornerRadius = 10.0
        textReaderButton.layer.borderWidth = 10
        textReaderButton.layer.borderColor = UIColor.blue.cgColor
    }
    
    func createSettingButton() {
        settingButton.backgroundColor = UIColor.black
        settingButton.setTitle("Settings", for: .normal)
        settingButton.addTarget(self, action: #selector(openSettingView), for: .touchUpInside)
    }
    
    func addConstraints() {
        navigationButton.translatesAutoresizingMaskIntoConstraints = false
        environmentReaderButton.translatesAutoresizingMaskIntoConstraints = false
        textReaderButton.translatesAutoresizingMaskIntoConstraints = false
        settingButton.translatesAutoresizingMaskIntoConstraints = false
        
        let navigationButtonConstraints = [
            navigationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            navigationButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            navigationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            navigationButton.bottomAnchor.constraint(equalTo: navigationButton.topAnchor, constant: self.view.frame.height * 0.25)
        ]
        
        let environMentReaderButtonConstraints = [
            environmentReaderButton.topAnchor.constraint(equalTo: navigationButton.bottomAnchor, constant: 16),
            environmentReaderButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            environmentReaderButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            environmentReaderButton.bottomAnchor.constraint(equalTo: environmentReaderButton.topAnchor, constant: self.view.frame.height * 0.25)
        ]
        
        let textReaderButtonConstraints = [
            textReaderButton.topAnchor.constraint(equalTo: environmentReaderButton.bottomAnchor, constant: 16),
            textReaderButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textReaderButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textReaderButton.bottomAnchor.constraint(equalTo: textReaderButton.topAnchor, constant: self.view.frame.height * 0.25)
        ]
        
        let settingButtonConstraints = [
            settingButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            settingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
            
        ]
        
        NSLayoutConstraint.activate(navigationButtonConstraints)
        NSLayoutConstraint.activate(environMentReaderButtonConstraints)
        NSLayoutConstraint.activate(textReaderButtonConstraints)
        NSLayoutConstraint.activate(settingButtonConstraints)
    }
    
    @objc func onTouchButton(_ sender: UIButton) {
        self.selected = sender.tag
        if(selected == 1) {
            self.navigationButton.backgroundColor = .red
            self.environmentReaderButton.backgroundColor = .black
            self.textReaderButton.backgroundColor = .black
        } else if (self.selected == 2) {
            self.navigationButton.backgroundColor = .black
            self.environmentReaderButton.backgroundColor = .yellow
            self.textReaderButton.backgroundColor = .black
        } else if (self.selected == 3) {
            self.navigationButton.backgroundColor = .black
            self.environmentReaderButton.backgroundColor = .black
            self.textReaderButton.backgroundColor = .blue
            present(TextReaderViewController(), animated: true)
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

