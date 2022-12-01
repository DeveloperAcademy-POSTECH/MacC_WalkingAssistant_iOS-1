//
//  TextReaderViewController.swift
//  Oculo
//
//  Created by Dongjin Jeon on 2022/11/08.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import UIKit
import RealityKit
import VisionKit

class TextReaderViewController: UIViewController, ImageAnalysisInteractionDelegate, UIGestureRecognizerDelegate {

    /// 카메라 역할을 수행할 ARView
    var arView = ARView()

    /// 실제 사용시에 카메라 화면을 가리기 위한 View
    var textReadButton = UIButton()

    /// LiveText의 구성 요소
    let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()
    
    let soundManager = SoundManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(textReadButton)
        self.view.insertSubview(arView, belowSubview: textReadButton)

        createTextReadButton()

        addConstraints()

        addGestures()
        let textReaderRotor = self.textReaderRotor()
        self.accessibilityCustomRotors = [textReaderRotor]
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.soundManager.stopSpeak()
        arView.session.pause()
        
    }

    /// hideView의 배경색 지정
    func createTextReadButton() {
        textReadButton.setTitle(Language(rawValue: "Text recognition")?.localized, for: .normal)
        textReadButton.setTitle("", for: .selected)
        textReadButton.addTarget(self, action: #selector(analyzeCurrentImageAndSpeak), for: .touchUpInside)
    }

    /// 요소별 Constraints 추가
    func addConstraints() {
        arView.translatesAutoresizingMaskIntoConstraints = false
        textReadButton.translatesAutoresizingMaskIntoConstraints = false

        let arViewConstraints = [
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]

        let hideViewConstraints = [
            textReadButton.topAnchor.constraint(equalTo: view.topAnchor),
            textReadButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textReadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textReadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        NSLayoutConstraint.activate(arViewConstraints)
        NSLayoutConstraint.activate(hideViewConstraints)
    }

    /// 화면을 탭할 경우 수행할 동작 추가
    func addGestures() {
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(analyzeCurrentImageAndSpeak))
        self.view.addGestureRecognizer(tapGesture)
    }

    
    private func textReaderRotor () -> UIAccessibilityCustomRotor {
        // Create a custor Rotor option, it has a name that will be read by voice over, and
        // a action that is a action called when this rotor option is interacted with.
        // The predicate gives you info about the state of this interaction
        let propertyRotor = UIAccessibilityCustomRotor.init(name: "메인 화면으로") { (predicate) -> UIAccessibilityCustomRotorItemResult? in
            
            // Get the direction of the movement when this rotor option is enablade
            let forward = predicate.searchDirection == UIAccessibilityCustomRotor.Direction.next
            
            // You can do any kind of business logic processing here
            if forward {
                // 홈 화면으로 돌아감
                self.dismiss(animated: true)
               // self.present(TextReaderViewController(), animated: true)
            }
            // Return the selection of voice over to the element rotorPropertyValueLabel
            // Use this return to select the desired selection that fills the purpose of its logic
            return UIAccessibilityCustomRotorItemResult.init()
        }
        return propertyRotor
    }
    
    /// ARView에 그려진 영상을 LiveText로 분석 후 TTS 수행
    @objc func analyzeCurrentImageAndSpeak() {
        if let imgBuffer = self.arView.session.currentFrame?.capturedImage {
            let ciimg = CIImage(cvImageBuffer: imgBuffer)
            let image = UIImage(ciImage: ciimg)

            Task {
                let configuration = ImageAnalyzer.Configuration([.text])
                do {
                    let analysis = try await analyzer.analyze(image, configuration: configuration)
                    DispatchQueue.main.async {
                        self.interaction.preferredInteractionTypes = []
                        self.interaction.analysis = nil
                        
                        self.interaction.analysis = analysis;
                        self.interaction.preferredInteractionTypes = .dataDetectors
                        self.interaction.selectableItemsHighlighted = true
                        
                        if (analysis.hasResults(for: .text)) {
                            print(analysis.transcript)
                            self.soundManager.speak(analysis.transcript)
                        } else {
                            self.soundManager.speak(translate("글자가 인식되지 않았습니다."))
                        }
                    }
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

}
