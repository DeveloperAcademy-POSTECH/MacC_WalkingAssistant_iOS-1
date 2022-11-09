//
//  ObjectDetectionViewController.swift
//  objDetectorTest
//
//  Created by raymond on 2022/11/04.
//

import UIKit
import Vision
import CoreMedia

class ObjectDetectionViewController: UIViewController {

    // MARK: UI 프로퍼티
    lazy var videoPreview: UIView = {
        let videoPreview = UIView(frame: self.view.frame)
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
        inferenceLabel.translatesAutoresizingMaskIntoConstraints = false

        return inferenceLabel
    }()

    lazy var etimeLabel: UILabel = {
        let etimeLabel = UILabel()
        etimeLabel.contentMode = .left
        etimeLabel.font = UIFont.systemFont(ofSize: 10)
        etimeLabel.translatesAutoresizingMaskIntoConstraints = false

        return etimeLabel
    }()

    lazy var fpsLabel: UILabel = {
        let fpsLabel = UILabel()
        fpsLabel.contentMode = .left
        fpsLabel.font = UIFont.systemFont(ofSize: 10)
        fpsLabel.translatesAutoresizingMaskIntoConstraints = false

        return fpsLabel
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
    var videoCapture: VideoCapture!
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

    // MARK: 카메라/비디오 캡쳐 설정
    func setupCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.sessionSetup(sessionPreset: .vga640x480) { success in

            if success {
                // 레이어에 프리뷰 뷰 추가
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }

                // 세션 셋업 후 비디오 프리뷰 시작
                self.videoCapture.start()
            }
        }
    }

    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }

    // MARK: 뷰 컨트롤러 라이프사이클 정의
    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidth = self.view.frame.width

        /// 모델 클래스 호출
        setupCoreMLModel()

        /// 카메라 클래스 호출
        setupCamera()

        /// 퍼포먼스 측정 클래스 호출
        performanceMeasurement.delegate = self

        self.view.addSubview(videoPreview)
        self.view.addSubview(boundingBoxView)
        self.view.addSubview(labelsTableView)
        self.view.addSubview(customView)
        customView.addSubview(inferenceLabel)
        customView.addSubview(etimeLabel)
        customView.addSubview(fpsLabel)

        setVideoPreviewConstraints(width: screenWidth)
        setCustomViewConstraints()
        setInferenceLabelConstraints()
        setEtimeLabelConstraints()
        setFpsLabelConstraints()
        setBoundingBoxViewConstraints()
        setLablesTableViewConstraints()

        registerTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
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
        etimeLabel.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        etimeLabel.leadingAnchor.constraint(equalTo: customView.leadingAnchor, constant: 184).isActive = true
        etimeLabel.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true
    }

    func setFpsLabelConstraints() {
        fpsLabel.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
        fpsLabel.leadingAnchor.constraint(equalTo: customView.leadingAnchor, constant: 352).isActive = true
        fpsLabel.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true
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


extension ObjectDetectionViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime)  {
        // 카메라로 캡쳐한 이미지를 픽셀 버퍼로 보냄
        if !self.didInference, let pixelBuffer = didCaptureVideoFrame {
            self.didInference = true

            // 측정 시작
            self.performanceMeasurement.didStartNumericMeasurement()

            // 추론 시작
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
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

                // 측정 종료
                self.performanceMeasurement.didEndNumericMeasurement()

                self.didInference = false
            }
        } else {
            // 측정 종료
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = labelsTableView.dequeueReusableCell(withIdentifier: "InformationCell", for: indexPath) as! LabelsTableViewCell

        let rectString = predictions[indexPath.row].boundingBox.toString(digit: 3)
        let confidence = predictions[indexPath.row].labels.first?.confidence ?? -1
        let confidenceString = String(format: "%.3f", confidence)  // MARK: confidence: Math.sigmoid(confidence)

        cell.predictedLabel.text = predictions[indexPath.row].label ?? "N/A"
        cell.informationLabel.text = "\(rectString), \(confidenceString)"

        return cell
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
            self.etimeLabel.text = "Execution: \(self.movingAverageFilter2.averageValue) ms"
            self.fpsLabel.text = "FPS: \(self.movingAverageFilter3.averageValue)"
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
