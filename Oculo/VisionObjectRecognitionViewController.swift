//
//  VisionObjectRecognitionViewController.swift
//  Oculo
//
//  Created by raymond on 2022/11/01.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Vision

class VisionObjectRecognitionViewController: ObjectRecognitionViewController {

    // 오브젝트 인식 결과를 표현하기 위한 오버레이 정의
    private var objectRecognitionOverlay: CALayer! = nil

    // 비전 프레임워크 부분
    private var requests = [VNRequest]()

    // @discardableResult: 에러 메시지 송출을 막기 위한 옵션
    @discardableResult
    func setupVision() -> NSError? {
        // 비전 프레임워크 설정
        let error: NSError! = nil

        guard let modelURL = Bundle.main.url(
            forResource: "yolov7tiny",
            withExtension: "mlmodelc"
        ) else {
            return NSError(
                domain: "VisionObjectRecognitionViewController",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Model file is missing"]
            )
        }

        do {
            /// VNCoreModel은 CoreML 기반 모델을 사용하며, CoreML 모델이 VNCoreMLRequest를 사용할 수 있도록 함.
            /// VNCoreModel로 모델을 불러옴.
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))

            // MARK: VNCoreMLRequest
            /// VMCoreMLRequest는 CoreML의 MLModel 객체(object)를 기반으로 하는 VNCoreMLModel을 활용하여 예측을 실행한다.
            ///     관찰: 분류기 모델 - VNClassificationObservation
            ///     이미지 대 이미지 모델 - VNPixelBufferObservation
            ///     객체 인식 모델 - VNRecognizedObjectObservation
            ///     기타 다른 MLModel -  VNCoreMLFeatureValueObservation
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {

                    // 메인 큐에서 모든 UI 업데이트를 수행하도록 함.
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }

        return error
    }

    // 비전 프레임워크의 연산 결과물을 표시하기 위한 메서드
    func drawVisionRequestResults(_ results: [Any]) {

        // MARK: CATransaction - 참고: CATransaction.h
        /**
         트랜잭션은 CoreAnimation의 메커니즘으로, 다중 레이어-트리 작업을 렌더 트리에 대한 원자 업데이트(atomic update) 방식으로 일괄(batch) 처리하기 위해 사용함.
         레이어 트리를 수정할 때마다 항상 트랜잭션이 포함돼야 함.

         CoreAnimation은 "명시적" 트랜잭션과 "암묵적" 트랜잭션의 두 가지 종류의 트랜잭션을 지원함.
         - 명시적 트랜잭션(Explicit transactions)
           명시적 트랜잭션은 레이어 트리를 수정하기 전 '[CATransaction begin]'을 호출하고, 수정 이후 '[CATransaction commit]'을 호출하는 방식의 트랜잭션임.

         - 암시적(암묵적) 트랜잭션(Implicit transactions)
           암묵적 트랜잭션은 레이어 트리가 수정될 때 CoreAnimation에 의해 자동으로 생성된다(이때 수동으로 활성화되는 트랜잭션은 없음).
           암묵적 트랜잭션은 스레드의 런 루프(run-loop)가 반복될 때 자동으로 커밋된다.

           어떤 특정한 경우(예컨대 런 루프가 없거나 막혀(block) 있는 경우 등)라면 적정 시점에서 렌더 트리가 업데이트 되도록 하기 위해 명시적 트랜잭션을 사용하여야 할 수도 있다.
         */
        CATransaction.begin()

        // MARK: kCFBooleanTrue, kCFBooleanFalse
        /**
         kCFBooleanTrue과 kCFBooleanFalse는 불리언 true, false 값(value)으로, CFBoolean 타입의 값이다.

         CFBoolean 타입의 객체는 Core Foundation의 프로퍼티 리스트 및 컬렉션 자료형에서 불리언 값을 사용하기 위해 불리언 값을 래핑하는 데 사용된다.
         */

        // MARK: Transaction의 프로퍼티 아이디
        /// 트랜잭션 프로퍼티 아이디: 총 4 개가 있음.
        ///     - kCATransactionAnimationDuration: String
        ///     - kCATransactionDisableActions: String
        ///     - kCATransactionAnimationTimingFunction: String
        ///     - kCATransactionCompletionBlock: String
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

        objectRecognitionOverlay.sublayers = nil  // MARK: 예전에 인식된 오브젝트를 삭제함.

        // MARK: VNRecognizedObjectObservation
        /**
         @class VNRecognizedObjectObservation
         @superclass VNDetectedObjectObservation

         VNRecognizedObjectObservation은 인식된 개체를 분류하는 분류 배열이 있는 VNDetectedObjectObservation의 서브클래스이다.
         분류의 신뢰도 합계는 1.0으로,  분류 신뢰도에 VNRecognizedObjectObservation의 관측값 신뢰도를 곱해서 사용하는 것이 일반적임.
         */

        // MARK: object observation 파싱
        /**
         object observation 파싱의 결과물의 속성은 관측 결과에 대한 어레이이다.
         이 어레이에는 레이블과 바운딩 박스의 값이 포함된다.
         다음과 같이 배열을 반복시키면 관측 결과에 대한 구분을 분석할 수 있다.
         */
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }

            // 신뢰도(confidence)가 가장 높은 레이블만 선택
            let topLabelObservation = objectObservation.labels[0]

            // MARK: VNImageRectForNormalizedRect
            /**
             정규화된 좌표 공간(normalized coordinate space) 내부의 사각형으로부터 투영된(projected) 이미지의 좌표를 사각형을 반환한다.
             - 사각형은 픽셀 단위로 반환됨.

             - 이미지의 좌표는 정수가 아닐 수도 있음.
                * '정규화된(normalized)' 이라는 키워드가 붙은 만큼, [0..1] 의 범위를 갖기 때문.

             - 파라미터
                - normalizedRect: [0..1] 범위의 정규화된 좌표 공간에 있는 사각형
                - imageWidth: 픽셀 단위로 나타낸 이미지의 너비
                - imageHeight: 픽셀 단위로 나타낸 이미지의 높이
            */

            /// 바운딩 박스의 좌표는 이미지의 크기로 정규화된다.
            /// 바운딩 박스의 원점은 이미지의 좌측 하단 모서리이다.
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox,
                                                            Int(bufferSize.width),
                                                            Int(bufferSize.height))

            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)

            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            objectRecognitionOverlay.addSublayer(shapeLayer)
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }

    override func captureOutput(_ output: AVCaptureOutput,
                                didOutput sampleBuffer: CMSampleBuffer,
                                from connection: AVCaptureConnection) {

        // MARK: CMSampleBufferGetImageBuffer
        /**
         @function    CMSampleBufferGetImageBuffer

         미디어 데이터의 CMSampleBuffer의 CVImageBuffer를 반환한다.  * CVImageBuffer: 코어비디오(CoreVideo) 이미지 버퍼의 기본형(base type).
         호출자(calle)는 반환된 dataBuffer를 소유하지 않으며, 호출자가 참조를 유지해야 하는 경우 명시적으로 유지해야 함.

         다음 경우, 결괏값은 NULL이 된다.
            - CMSampleBuffer에 CVImageBuffer가 포함되어 있지 않을 때
            - CMSampleBuffer에는 CMBlockBuffer가 포함되어 있는 경우
                - CMBlockBuffer: 시스템이 사용하는 CFType 객체로, 메모리
                - 참고: https://developer.apple.com/documentation/coremedia/cmblockbuffer-u9i
            - 그 밖에 다른 오류가 있는 경우
         */
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // MARK: exif = exchangable image file format(교환 이미지 파일 형식).
        /// 디지털 카메라 등에서 사용되는 이미지 파일 메타데이터 포맷이다.
        ///     * 참고 1: 꺼무위키 https://namu.wiki/w/EXIF
        ///     * 참고 2: 영문 위키피디아 https://en.wikipedia.org/wiki/Exif (꺼무위키보다는 이걸 보시는 걸 추천 드림)
        let exifOrientation = exifOrientationFromDeviceOrientation()

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                        orientation: exifOrientation,
                                                        options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }

    /// ObjectRecognitionViewController 내에 정의된 set
    override func setupAVCapture() {
        super.setupAVCapture()

        // 비전 프레임워크 설정
        setupLayers()
        updateLayerGeometry()
        setupVision()

        // 캡쳐 시작
        startCaptureSession()
    }

    func setupLayers() {
        objectRecognitionOverlay = CALayer()  // 관찰한 이전 오브젝트를 렌더링하는 컨테이너 레이어
        objectRecognitionOverlay.name = "ObservationOverlay"
        objectRecognitionOverlay.bounds = CGRect(x: 0.0,
                                                 y: 0.0,
                                                 width: bufferSize.width,
                                                 height: bufferSize.height)

        /// objectRecognitionOverlay를 화면(루트 레이어; AIModelInferenceDisplayLayer) 가운데에 배치.
        objectRecognitionOverlay.position = CGPoint(x: AIModelInferenceDisplayLayer.bounds.midX,
                                                    y: AIModelInferenceDisplayLayer.bounds.midY)

        /// 화면 가운데에 배치한 objectRecognitionOverlay를 루트 레이어에 서브레이어로 더해 줌.
        AIModelInferenceDisplayLayer.addSublayer(objectRecognitionOverlay)
    }

    func updateLayerGeometry() {
        let bounds = AIModelInferenceDisplayLayer.bounds
        var scale: CGFloat

        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width

        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

        /// 화면 방향으로 레이어 회전, 크기 조절, 미러링
        ///     * 아핀 변환을 활용한다.  ** 참고: https://en.wikipedia.org/wiki/Affine_transformation
        objectRecognitionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))

        // 레이어: 중앙 포지션
        objectRecognitionOverlay.position = CGPoint(x: bounds.midX,
                                                    y: bounds.midY)

        /// 현재 트랜잭션 동안 이루어진 모든 변경 사항을 커밋한다(현재 트랜잭션이 없으면 예외를 발생시킴).
        CATransaction.commit()
    }

    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont],
                                      range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(),
                                            components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0  // MARK: 레티나 디스플레이용 렌더링 옵션

        // 화면 방향으로 레이어 회전, 크기 조정, 미러링
        /// 아핀 변환으로 회전각을 돌리는데, 파이를 2로 나눈 값을 scale 하는 이유를 모르겠음
        /// 아핀 변환 자체를 공부해 봐야 할 듯
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }

    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(),
                                             components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 5
        return shapeLayer
    }

}
