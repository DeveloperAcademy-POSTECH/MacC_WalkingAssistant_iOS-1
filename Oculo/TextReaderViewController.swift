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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.soundManager.stopSpeak()
        arView.session.pause()
    }

    /// hideView의 배경색 지정
    func createTextReadButton() {
        textReadButton.setTitle("글자 인식", for: .normal)
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
                            self.soundManager.speak("글자가 인식되지 않았습니다.")
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
