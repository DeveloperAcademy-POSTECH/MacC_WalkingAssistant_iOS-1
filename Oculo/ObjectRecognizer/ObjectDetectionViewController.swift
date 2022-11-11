//
//  ObjectDetectionViewController.swift
//  objDetectorTest
//
//  Created by Kim, Raymond on 2022/11/04.
//

import UIKit
import Vision
import CoreMedia
import ARKit
import SceneKit

class ObjectDetectionViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {

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

    var objectRecognitionModel: yolov5x6 {
        do {
            let config = MLModelConfiguration()
            return try yolov5x6(configuration: config)
        } catch {
            print(error)
            fatalError("Cannot create YOLOv5x6")
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
        // Enable both the `sceneDepth` and `smoothedSceneDepth` frame semantics.
        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.sceneDepth]
        videoPreview.session.run(config)
    }
    
    func pauseARSession() {
        videoPreview.session.pause()
    }
    
// MARK: ARSession의 기능 정의
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let depth = frame.sceneDepth?.depthMap else { return }
        guard let confidence = frame.sceneDepth?.confidenceMap else { return }
        let depthWidth = CVPixelBufferGetWidth(depth)   // 256
        let depthHeight = CVPixelBufferGetHeight(depth)     // 192
        
        CVPixelBufferLockBaseAddress(depth, .readOnly)
        CVPixelBufferLockBaseAddress(confidence, .readOnly)
        
        guard let depthBaseAddress = CVPixelBufferGetBaseAddress(depth) else { return }
        guard let confidecneBaseAddress = CVPixelBufferGetBaseAddress(confidence) else { return }
        
        // UnsafeMutabelRawPointer -> UnsafeBufferPointer
        let bindDepthPtr = depthBaseAddress.bindMemory(to: Float32.self, capacity: depthWidth * depthHeight)
        let bindConfidencePtr = confidecneBaseAddress.bindMemory(to: Int8.self, capacity: depthWidth * depthHeight)
        
        //UnsafeMutablePointer -> UnsafeBufferPointer
        let depthBufPtr = UnsafeBufferPointer(start: bindDepthPtr, count: depthWidth * depthHeight)
        let confidenceBufPtr = UnsafeBufferPointer(start: bindConfidencePtr, count: depthWidth * depthHeight)
        
        let depthArray = Array(depthBufPtr)
        let confidenceArray = Array(confidenceBufPtr)
        
//        print(depthArray[0])
//        print(confidenceArray[0])

        CVPixelBufferUnlockBaseAddress(depth, .readOnly)
        CVPixelBufferUnlockBaseAddress(confidence, .readOnly)
        
        // MARK: ARSCNView의 이미지 캡쳐 및 CVPixelBuffer로 변환 후 인공지능 예측
        guard let image = videoPreview.snapshot().convertToBuffer() else { return }
        
        if !self.didInference {
            self.didInference = true

            // start of measure
            self.performanceMeasurement.didStartNumericMeasurement()

            // predict!
            self.predictUsingVision(pixelBuffer: image)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        // 15 14
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
        self.semaphore.wait()  // wait(): -1, signal(): +1 반환
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
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
}

extension ObjectDetectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictions.count
    }

    /// predcition의 정보가 업데이트 되기전에 indexPath에서 호출하는 문제를 해결하기위해 조건을 걸어 빈 셀을 호출
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
