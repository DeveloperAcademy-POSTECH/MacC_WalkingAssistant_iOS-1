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
    var hideView = UIView()

    /// Test Flight에서 실제 사용 방법을 안내하는 Label
    var informTextLabel = UILabel()

    /// LiveText의 구성 요소
    let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()
    
    let textReadetTTS = TTSTool()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(arView)
        self.view.insertSubview(hideView, belowSubview: arView) /// Test Flight용 앱에서는 화면을 보여줘야 하기 때문에 가리는 뷰를 ARView 뒤로 숨깁니다.
        self.view.insertSubview(informTextLabel, aboveSubview: arView)

        createHideView()
        createInformTextLabel()

        addConstraints()

        addGestures()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.textReadetTTS.stopSpeak()
        arView.session.pause()
    }

    /// hideView의 배경색 지정
    func createHideView() {
        hideView.backgroundColor = .black
    }

    /// 안내 문구 label 생성
    func createInformTextLabel() {
        informTextLabel.text = """
        터치: 글자 읽기
        아래로 드래그: 종료
        """
        informTextLabel.backgroundColor = .blue
        informTextLabel.textColor = .white
        informTextLabel.numberOfLines = 0
    }

    /// 요소별 Constraints 추가
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

    /// 화면을 탭할 경우 수행할 동작 추가
    func addGestures() {
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(analyzeCurrentImageAndSpeak))
        self.view.addGestureRecognizer(tapGesture)
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
                            self.textReadetTTS.speak(analysis.transcript)
                        } else {
                            self.textReadetTTS.speak("글자가 인식되지 않았습니다.")
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
