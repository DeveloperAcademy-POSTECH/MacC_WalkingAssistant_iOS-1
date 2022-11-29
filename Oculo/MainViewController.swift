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
    var healthKitManager = HealthKitManager()
    
    /// Variable for UI changing
    var selected = 0

    /// Variable for UI Button
    lazy var navigationButton = UIButton()
    lazy var environmentReaderButton = UIButton()
    lazy var textReaderButton = UIButton()
    lazy var settingButton = UIButton()

    /// Variable for object detection camera view
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil

    /// Varibale for Custom Rotor
    var rotorPropertyValueLabel: UILabel!
    
    private var previewView: UIView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // set
        UIDevice.current.isProximityMonitoringEnabled = true
        // 처음 앱을 작동시켰을때 healthKit Manager에서 사용자의 보폭 정보를 불러오기 위한 시험 코드입니다.
        print(healthKitManager.calToStepCount(meter: 10))
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
        
        let navigationButtonRotor = self.navigationButtonRotor()
        let textReaderButtonRotor = self.textReaderButtonRotor()
        let environmentReaderButton = self.environmentReaderButtonRotor()
        self.accessibilityCustomRotors = [navigationButtonRotor, textReaderButtonRotor, environmentReaderButton]

        createNavigateButton()
        createEnvironmentReaderButton()
        createTextReaderButton()
        createSettingButton()

        addConstraints()
    }

    func createNavigateButton() {
        navigationButton.backgroundColor = UIColor.black
        navigationButton.setTitle(Language(rawValue: "Navigation")?.localized, for: .normal)
        navigationButton.layer.cornerRadius = 10.0
        navigationButton.tag = 1
        navigationButton.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        navigationButton.layer.cornerRadius = 10.0
        navigationButton.layer.borderWidth = 10
        navigationButton.layer.borderColor = UIColor.red.cgColor
    }

    func createEnvironmentReaderButton() {
        environmentReaderButton.backgroundColor = UIColor.black
        environmentReaderButton.setTitle(Language(rawValue: "Environment Reader")?.localized, for: .normal)
        environmentReaderButton.layer.cornerRadius = 10.0
        environmentReaderButton.tag = 2
        environmentReaderButton.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        environmentReaderButton.layer.cornerRadius = 10.0
        environmentReaderButton.layer.borderWidth = 10
        environmentReaderButton.layer.borderColor = UIColor.yellow.cgColor
    }

    func createTextReaderButton() {
        textReaderButton.backgroundColor = UIColor.black
        textReaderButton.setTitle(Language(rawValue: "Text Reader")?.localized, for: .normal)
        textReaderButton.layer.cornerRadius = 10.0
        textReaderButton.tag = 3
        textReaderButton.addTarget(self, action: #selector(onTouchButton), for: .touchUpInside)
        textReaderButton.layer.cornerRadius = 10.0
        textReaderButton.layer.borderWidth = 10
        textReaderButton.layer.borderColor = UIColor.blue.cgColor
    }

    func createSettingButton() {
        settingButton.backgroundColor = UIColor.black
        settingButton.setTitle(Language(rawValue: "Settings")?.localized, for: .normal)
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

    // MARK: Switching Button Custom Rotor
    public func navigationButtonRotor() -> UIAccessibilityCustomRotor {
           
           // Create a custor Rotor option, it has a name that will be read by voice over, and
           // a action that is a action called when this rotor option is interacted with.
           // The predicate gives you info about the state of this interaction
           let propertyRotorOption = UIAccessibilityCustomRotor.init(name: "내비게이션") { (predicate) -> UIAccessibilityCustomRotorItemResult? in
               
               // Get the direction of the movement when this rotor option is enablade
               let forward = predicate.searchDirection == UIAccessibilityCustomRotor.Direction.next
               
               // You can do any kind of business logic processing here
               if forward {
                   self.selected = 1
                   self.onTouchButton(self.navigationButton)
               }
               
               // Return the selection of voice over to the element rotorPropertyValueLabel
               // Use this return to select the desired selection that fills the purpose of its logic
               return UIAccessibilityCustomRotorItemResult.init()
           }
           
           return propertyRotorOption
       }
    
    public func environmentReaderButtonRotor() -> UIAccessibilityCustomRotor {
        
        // Create a custor Rotor option, it has a name that will be read by voice over, and
        // a action that is a action called when this rotor option is interacted with.
        // The predicate gives you info about the state of this interaction
        let propertyRotorOption = UIAccessibilityCustomRotor.init(name: "주변 환경 읽기") { (predicate) -> UIAccessibilityCustomRotorItemResult? in
            
            // Get the direction of the movement when this rotor option is enablade
            let forward = predicate.searchDirection == UIAccessibilityCustomRotor.Direction.next
            
            // You can do any kind of business logic processing here
            if forward {
                self.selected = 2
                self.onTouchButton(self.environmentReaderButton)
            }

            // Return the selection of voice over to the element rotorPropertyValueLabel
            // Use this return to select the desired selection that fills the purpose of its logic
            return UIAccessibilityCustomRotorItemResult.init()
        }
        
        return propertyRotorOption
    }
    public func textReaderButtonRotor() -> UIAccessibilityCustomRotor {
        
        // Create a custor Rotor option, it has a name that will be read by voice over, and
        // a action that is a action called when this rotor option is interacted with.
        // The predicate gives you info about the state of this interaction
        let propertyRotorOption = UIAccessibilityCustomRotor.init(name: "글자 읽기") { (predicate) -> UIAccessibilityCustomRotorItemResult? in
            
            // Get the direction of the movement when this rotor option is enablade
            let forward = predicate.searchDirection == UIAccessibilityCustomRotor.Direction.next
            
            // You can do any kind of business logic processing here
            if forward {
                self.selected = 3
                self.onTouchButton(self.textReaderButton)
            }

            // Return the selection of voice over to the element rotorPropertyValueLabel
            // Use this return to select the desired selection that fills the purpose of its logic
            return UIAccessibilityCustomRotorItemResult.init()
        }
        
        return propertyRotorOption
    }

    @objc func onTouchButton(_ sender: UIButton) {
        self.selected = sender.tag
        if(selected == 1) {
            self.navigationButton.backgroundColor = .red
            self.environmentReaderButton.backgroundColor = .black
            self.textReaderButton.backgroundColor = .black
            present(ObjectDetectionViewController(), animated: true)
        } else if (self.selected == 2) {
            self.navigationButton.backgroundColor = .black
            self.environmentReaderButton.backgroundColor = .yellow
            self.textReaderButton.backgroundColor = .black
            present(EnvironmentReaderViewController(), animated: true)
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

