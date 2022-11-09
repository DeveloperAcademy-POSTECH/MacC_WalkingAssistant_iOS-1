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
import AVFoundation


let synthesizer = AVSpeechSynthesizer()

func speak(_ string: String) {
    let utterance = AVSpeechUtterance(string: string)
    utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
    if (synthesizer.isSpeaking) {
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    synthesizer.speak(utterance)
}

class TextReaderViewController: UIViewController, ImageAnalysisInteractionDelegate, UIGestureRecognizerDelegate {
    
    var arView = ARView()
    var hideView = UIView()
    var informTextLabel = UILabel()
    
    let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(arView)
        self.view.insertSubview(hideView, belowSubview: arView)
        self.view.insertSubview(informTextLabel, aboveSubview: arView)
        
        createHideView()
        createInformTextLabel()
        
        addConstraints()
        
        addGestures()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        arView.session.pause()
    }
    
    func createHideView() {
        hideView.backgroundColor = .black
    }
    
    func createInformTextLabel() {
        informTextLabel.text = """
        터치: 글자 읽기
        아래로 드래그: 종료
        """
        informTextLabel.backgroundColor = .blue
        informTextLabel.textColor = .white
        informTextLabel.numberOfLines = 0
    }
    
    func addConstraints() {
        arView.translatesAutoresizingMaskIntoConstraints = false
        hideView.translatesAutoresizingMaskIntoConstraints = false
        informTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let arViewConstraints = [
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        let hideViewConstraints = [
            hideView.topAnchor.constraint(equalTo: view.topAnchor),
            hideView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hideView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hideView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        let informTextLabelConstraints = [
            informTextLabel.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            informTextLabel.centerYAnchor.constraint(equalTo: arView.centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(arViewConstraints)
        NSLayoutConstraint.activate(hideViewConstraints)
        NSLayoutConstraint.activate(informTextLabelConstraints)
    }
    
    func addGestures() {
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(analyzeCurrentImage))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func analyzeCurrentImage() {
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
                            speak(analysis.transcript)
                        } else {
                            speak("글자가 인식되지 않았습니다.")
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
