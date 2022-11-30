//
//  ObjectDetectionViewController.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/11/04.
//

import UIKit
import Vision
import CoreMedia
import ARKit
import SceneKit

class ObjectDetectionViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    var soundManager = SoundManager()
    var healthKitManager = HealthKitManager()
    let maxWidth: Double = 191.0
    let maxHeight: Double = 255.0
    // MARK: UI 프로퍼티
    lazy var videoPreview: ARSCNView = {
        let videoPreview = ARSCNView(frame: self.view.frame)
        videoPreview.clipsToBounds = true
        videoPreview.translatesAutoresizingMaskIntoConstraints = false

        return videoPreview
    }()

    lazy var labelsTableView: UITableView = {
        let labelsTableView = UITableView(frame: .zero, style: .insetGrouped)
        labelsTableView.alwaysBounceVertical = true
        labelsTableView.clipsToBounds = true
        labelsTableView.translatesAutoresizingMaskIntoConstraints = false

        return labelsTableView
    }()

    lazy var customView: UIView = {
        let customView = UIView()
        customView.translatesAutoresizingMaskIntoConstraints = false

        return customView
    }()

    lazy var inferenceLabel: UILabel = {
        let inferenceLabel = UILabel()
        inferenceLabel.contentMode = .left
        inferenceLabel.font = UIFont.systemFont(ofSize: 10)
        inferenceLabel.textColor = UIColor.green
        inferenceLabel.translatesAutoresizingMaskIntoConstraints = false

        return inferenceLabel
    }()

    lazy var executionTimeLabel: UILabel = {
        let executionTimeLabel = UILabel()
        executionTimeLabel.contentMode = .left
        executionTimeLabel.font = UIFont.systemFont(ofSize: 10)
        executionTimeLabel.textColor = UIColor.green
        executionTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        return executionTimeLabel
    }()

    lazy var FPSLabel: UILabel = {
        let FPSLabel = UILabel()
        FPSLabel.contentMode = .left
        FPSLabel.font = UIFont.systemFont(ofSize: 10)
        FPSLabel.textColor = UIColor.green
        FPSLabel.translatesAutoresizingMaskIntoConstraints = false

        return FPSLabel
    }()

    lazy var boundingBoxView: BoundingBoxDisplayView = {
        let boundingBoxView = BoundingBoxDisplayView()
        boundingBoxView.backgroundColor = .clear
        boundingBoxView.translatesAutoresizingMaskIntoConstraints = false

        return boundingBoxView
    }()

    var objectRecognitionModel: yolov5s {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            return try yolov5s(configuration: config)
        } catch {
            print(error)
            fatalError("Cannot create YOLOv5s")
        }
    }

    // MARK: Vision 프레임워크 프로퍼티
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    var didInference = false

    // MARK: AV 프레임워크 프로퍼티
    let semaphore = DispatchSemaphore(value: 1)
    var lastExecution = Date()

    // MARK: 예측값을 나타내기 위한 TableView에 들어가는 데이터
    var predictions: [VNRecognizedObjectObservation] = []

    // MARK: 모델 퍼포먼스 측정을 위한 프로퍼티
    private let performanceMeasurement = NumericMeasurements()

    // MARK: 이동 평균 필터(MAF; moving average filter) 정의 - 바운딩 박스 렌더링 및 경로 트래킹시 Noise 제거용
        /// 참고: https://www.analog.com/media/en/technical-documentation/dsp-book/dsp_book_ch15.pdf
    let movingAverageFilter1 = MovingAverageFilter()
    let movingAverageFilter2 = MovingAverageFilter()
    let movingAverageFilter3 = MovingAverageFilter()

    // MARK: CoreML 설정
    func setupCoreMLModel() {
        if let visionModel = try? VNCoreMLModel(for: objectRecognitionModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel,
                                      completionHandler: didCompleteVisionRequest)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("Fail to create vision model")
        }
    }

    // MARK: ARSession 시작 정지 함수 정의
    func startARSession() {
        guard ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth]) else { return }

        /// Enable both the `sceneDepth` and `smoothedSceneDepth` frame semantics.
        let config = ARWorldTrackingConfiguration()

        config.frameSemantics = [.sceneDepth]
        videoPreview.session.run(config)
    }

    func pauseARSession() {
        videoPreview.session.pause()
    }

    // MARK: ARSession 기능 정의
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let depth = frame.sceneDepth?.depthMap else { return }
        guard let confidence = frame.sceneDepth?.confidenceMap else { return }
        let depthWidth = CVPixelBufferGetWidth(depth)   // 256
        let depthHeight = CVPixelBufferGetHeight(depth)     // 192

        CVPixelBufferLockBaseAddress(depth, .readOnly)
        CVPixelBufferLockBaseAddress(confidence, .readOnly)

        guard let depthBaseAddress = CVPixelBufferGetBaseAddress(depth) else { return }
        guard let confidenceBaseAddress = CVPixelBufferGetBaseAddress(confidence) else { return }

        /// UnsafeMutableRawPointer -> UnsafeBufferPointer
        let bindDepthPtr = depthBaseAddress.bindMemory(to: Float32.self, capacity: depthWidth * depthHeight)
        let bindConfidencePtr = confidenceBaseAddress.bindMemory(to: Int8.self, capacity: depthWidth * depthHeight)

        /// UnsafeMutablePointer -> UnsafeBufferPointer
        let depthBufPtr = UnsafeBufferPointer(start: bindDepthPtr, count: depthWidth * depthHeight)
        let confidenceBufPtr = UnsafeBufferPointer(start: bindConfidencePtr, count: depthWidth * depthHeight)

        let depthArray = Array(depthBufPtr)
        let confidenceArray = Array(confidenceBufPtr)

        /// 이차원 배열로 변환
        let patternArray: [[Float32]] = Array(repeating: Array(repeating: 0, count: depthWidth), count: depthHeight)
        var iter = depthArray.makeIterator()
        let newDepthArray = patternArray.map { $0.compactMap { _ in iter.next() }}

        // MARK: ARSCNView의 이미지 캡쳐 및 CVPixelBuffer로 변환 후 인공지능 예측
        guard let frame = session.currentFrame else { return }
        let imageBuffer = frame.capturedImage

        let imageSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))
        let viewPort = videoPreview.bounds
        let viewPortSize = videoPreview.bounds.size
        let interfaceOrientation = self.videoPreview.window!.windowScene!.interfaceOrientation
        let image = CIImage(cvImageBuffer: imageBuffer)
        let normalizeTransform = CGAffineTransform(scaleX: 1.0/imageSize.width, y: 1.0/imageSize.height)

        /// 세로 모드시 Y축 변환 필요
        let flipTransform = (interfaceOrientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity

        /// 렌더링에 적합한 좌표 설정
        let displayTransform = frame.displayTransform(for: interfaceOrientation, viewportSize: viewPortSize)
        let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
        let transformedImage = image.transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)).cropped(to: viewPort)

        guard let img = UIImage(ciImage: transformedImage).convertToBuffer() else { return }

        if !self.didInference {
            self.didInference = true

            // MARK: 측정 시작
            self.performanceMeasurement.didStartNumericMeasurement()

            // MARK: 예측
            self.predictUsingVision(pixelBuffer: img)
        }

        /// 최솟값 넣을 딕셔너리 생성
        var minValueDictionary: [Float32 : [String]] = [:]

        for prediction in predictions {
            let detectedBoundingBox = prediction.boundingBox
            let depthBounds = VNImageRectForNormalizedRect(detectedBoundingBox, depthHeight, depthWidth)  /// 1 * 1 의 박스 좌표를 256 * 192 로 변환
            var boundingBoxCoordinate: Array<Int> = []

            boundingBoxCoordinate += [Int(round(depthBounds.minX)), Int(round(depthBounds.minY)), Int(round(depthBounds.maxX)), Int(round(depthBounds.maxY))]
            boundingBoxCoordinate = boundingBoxCoordinate.map{ $0 < 0 ? 0 : $0 }  /// 이상치 수정

            var convertedDepth = convertToDepthCoordinate(coordinate: boundingBoxCoordinate)  /// YOLO 좌표 -> depthMap 좌표 변환

            convertedDepth = convertedDepth.map{ $0 < 0 ? 0 : $0 }
            var minDepth: Float32 = 10.0
            var minDepthCoordinate: String = ""

            for y in convertedDepth[1]...convertedDepth[3] {
                let slice = newDepthArray[y][convertedDepth[0]...convertedDepth[2]]
                guard let minData = slice.min() else { return }
                if minData < minDepth {
                    minDepth = minData
                    minDepthCoordinate = "\(String(slice.firstIndex(of: minData)!)), \(String(y))"  /// 최솟값이 새로 생길 때마다 좌표 정보 업데이트
                }
            }
            minValueDictionary[minDepth] = [minDepthCoordinate, String(prediction.label!)]  /// depth 최솟값을 좌표:깊이 쌍으로 딕셔너리에 추가
        }

        if !minValueDictionary.isEmpty && !soundManager.synthesizer.isSpeaking {

            let sorted = minValueDictionary.keys.sorted()
            let firstKey = sorted[0]
            let firstItem = minValueDictionary[firstKey]
            let splited = firstItem![0].split(separator: ", ")
            
            let y = Int(String(splited[0]))!
            let x = Int(String(splited[1]))!
            
            let xRatio = Int((Double(x) / maxWidth * 100.0 ))
            let yRatio = Int((Double(y) / maxHeight * 100.0 ))
            
            var coordinatorString = ""
            if xRatio < 33 {
                coordinatorString += "우측"
            } else if xRatio < 67 {
                coordinatorString += "정면"
            } else {
                coordinatorString += "좌측"
            }
            
            if yRatio < 33 {
                coordinatorString += "상단"
            } else if yRatio < 67 {
                if !(coordinatorString == "정면") {
                    coordinatorString += "가운데"
                }
            } else {
                coordinatorString += "하단"
            }
                    
            var steps = healthKitManager.calToStepCount(meter: Double(firstKey))
            var stepsString = ""
            switch steps
            {
            case 0:
                stepsString = "근처에 있습니다"
            case 1:
                stepsString = "약 한 걸음 떨어져 있습니다"
            case 2:
                stepsString = "약 두 걸음 떨어져 있습니다"
            case 3:
                stepsString = "약 세 걸음 떨어져 있습니다"
            case 4:
                stepsString = "약 네 걸음 떨어져 있습니다"
            case 5:
                stepsString = "약 다섯 걸음 떨어져 있습니다"
            case 6:
                stepsString = "약 여섯 걸음 떨어져 있습니다"
            case 7:
                stepsString = "약 일곱 걸음 떨어져 있습니다"
            case 8:
                stepsString = "약 여덟 걸음 떨어져 있습니다"
            case 9:
                stepsString = "약 아홉 걸음 떨어져 있습니다"
            default:
                stepsString = "멀리 떨어져 있습니다."
            }
            let TTS = "\(coordinatorString)에 \(firstItem![1])가 " + stepsString
            soundManager.speak(TTS)
            print(TTS)
            
        }

        CVPixelBufferUnlockBaseAddress(depth, .readOnly)
        CVPixelBufferUnlockBaseAddress(confidence, .readOnly)
    }

    private func convertToDepthCoordinate(coordinate: Array<Int>) -> Array<Int> {
        var convertedCoordinate: Array<Int> = []
        convertedCoordinate.append(255 - coordinate[3])
        convertedCoordinate.append(191 - coordinate[2])
        convertedCoordinate.append(255 - coordinate[1])
        convertedCoordinate.append(191 - coordinate[0])

        return convertedCoordinate
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseARSession()
    }

    // MARK: 뷰 컨트롤러 라이프사이클 정의
    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidth = self.view.frame.width

        /// ARSession 델리게이트 호출
        videoPreview.delegate = self
        videoPreview.session.delegate = self

        /// 모델 클래스 호출
        setupCoreMLModel()

        /// 퍼포먼스 측정 클래스 호출
        performanceMeasurement.delegate = self

        self.view.addSubview(videoPreview)
        self.view.addSubview(boundingBoxView)
        self.view.addSubview(labelsTableView)
        self.view.addSubview(customView)
        customView.addSubview(inferenceLabel)
        customView.addSubview(executionTimeLabel)
        customView.addSubview(FPSLabel)

        setVideoPreviewConstraints(width: screenWidth)
        setCustomViewConstraints()
        setInferenceLabelConstraints()
        setEtimeLabelConstraints()
        setFPSLabelConstraints()
        setBoundingBoxViewConstraints()
        setLablesTableViewConstraints()

        registerTableView()
        let navigationRotor = self.navigationRotor()
        self.accessibilityCustomRotors = [navigationRotor]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    func setVideoPreviewConstraints(width: CGFloat) {
        videoPreview.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 18).isActive = true
        videoPreview.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        videoPreview.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        videoPreview.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: width * 1.333).isActive = true
    }

    func setCustomViewConstraints() {
        customView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        customView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        customView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        customView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true
    }

    func setInferenceLabelConstraints() {
        inferenceLabel.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        inferenceLabel.leadingAnchor.constraint(equalTo: customView.leadingAnchor, constant: 16).isActive = true
        inferenceLabel.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true
    }

    func setEtimeLabelConstraints() {
        executionTimeLabel.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        executionTimeLabel.leadingAnchor.constraint(equalTo: customView.leadingAnchor, constant: 184).isActive = true
        executionTimeLabel.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true
    }

    func setFPSLabelConstraints() {
        FPSLabel.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        FPSLabel.leadingAnchor.constraint(equalTo: customView.leadingAnchor, constant: 352).isActive = true
        FPSLabel.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true
    }

    func setBoundingBoxViewConstraints() {
        boundingBoxView.topAnchor.constraint(equalTo: videoPreview.topAnchor).isActive = true
        boundingBoxView.leadingAnchor.constraint(equalTo: videoPreview.leadingAnchor).isActive = true
        boundingBoxView.trailingAnchor.constraint(equalTo: videoPreview.trailingAnchor).isActive = true
        boundingBoxView.bottomAnchor.constraint(equalTo: videoPreview.bottomAnchor).isActive = true
    }

    func setLablesTableViewConstraints() {
        labelsTableView.topAnchor.constraint(equalTo: videoPreview.bottomAnchor).isActive = true
        labelsTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        labelsTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        labelsTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }

    func registerTableView() {
        labelsTableView.register(LabelsTableViewCell.self, forCellReuseIdentifier: "InformationCell")
        labelsTableView.delegate = self
        labelsTableView.dataSource = self
    }
}

extension ObjectDetectionViewController {
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }

        /// 참고: 모델의 입력 구성에 따라 비전 프레임워크가 이미지의 입력 크기를 자동으로 구성함.
        self.semaphore.wait()  /// wait(): -1, signal(): +1 반환
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([request])
    }

    // MARK: 포스트 프로세싱
    func didCompleteVisionRequest(request: VNRequest, error: Error?) {
        self.performanceMeasurement.didObjectLabeled(with: "EndInference")

        if let predictions = request.results as? [VNRecognizedObjectObservation] {
//            print(predictions.first?.labels.first?.identifier ?? "nil")
//            print(predictions.first?.labels.first?.confidence ?? -1)

            self.predictions = predictions

            DispatchQueue.main.async {
                self.boundingBoxView.predictedObjects = predictions
                self.labelsTableView.reloadData()

                /// 측정 종료
                self.performanceMeasurement.didEndNumericMeasurement()

                self.didInference = false
            }
        } else {
            /// 측정 종료
            self.performanceMeasurement.didEndNumericMeasurement()

            self.didInference = false
        }
        self.semaphore.signal()
    }
    
    private func navigationRotor () -> UIAccessibilityCustomRotor {
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
                // self.present(ObjectDetectionViewController(), animated: true)
            }
            // Return the selection of voice over to the element rotorPropertyValueLabel
            // Use this return to select the desired selection that fills the purpose of its logic
            return UIAccessibilityCustomRotorItemResult.init()
        }
        return propertyRotor
    }
}



extension ObjectDetectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictions.count
    }

    /// prediction 정보가 업데이트 되기 전에 indexPath에서 호출하는 문제를 해결하기 위해 조건을 걸어 빈 셀을 호출
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.row > predictions.count-1) {
            return UITableViewCell()
        } else {
            let cell = labelsTableView.dequeueReusableCell(withIdentifier: "InformationCell", for: indexPath) as! LabelsTableViewCell

            let rectString = predictions[indexPath.row].boundingBox.toString(digit: 3)
            let confidence = predictions[indexPath.row].labels.first?.confidence ?? -1
            let confidenceString = String(format: "%.3f", confidence)  // MARK: confidence: Math.sigmoid(confidence)

            cell.predictedLabel.text = predictions[indexPath.row].label ?? "N/A"
            cell.informationLabel.text = "\(rectString), \(confidenceString)"

            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20
    }
}

extension ObjectDetectionViewController: NumericMeasurementsDelegate {
    func updateMeasurementResult(inferenceTime: Double, executionTime: Double, fps: Int) {
//        print(executionTime, fps)
        DispatchQueue.main.async {
            self.movingAverageFilter1.appendElement(element: Int(inferenceTime * 1000.0))
            self.movingAverageFilter2.appendElement(element: Int(executionTime * 1000.0))
            self.movingAverageFilter3.appendElement(element: fps)

            self.inferenceLabel.text = "Inference: \(self.movingAverageFilter1.averageValue) ms"
            self.executionTimeLabel.text = "Execution: \(self.movingAverageFilter2.averageValue) ms"
            self.FPSLabel.text = "FPS: \(self.movingAverageFilter3.averageValue)"
        }
    }
}

class MovingAverageFilter {
    private var arr: [Int] = []
    private let maxCount = 10

    public func appendElement(element: Int) {
        arr.append(element)
        if arr.count > maxCount {
            arr.removeFirst()
        }
    }

    public var averageValue: Int {
        guard !arr.isEmpty else { return 0 }
        let sum = arr.reduce(0) { $0 + $1 }
        return Int(sum/arr.count)
    }
}

extension UIImage {
    func convertToBuffer() -> CVPixelBuffer? {

        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer)

        guard (status == kCVReturnSuccess) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()

        let context = CGContext(
            data: pixelData,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
}
