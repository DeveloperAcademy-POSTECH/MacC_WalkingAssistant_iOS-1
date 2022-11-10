//
//  VideoCaptureTool.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/11/04.
//  Copyright © 2022 IntelligentATLAS. All rights reserved.
//

import UIKit
import AVFoundation
import CoreVideo

public protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime)
}

public class VideoCapture: NSObject {
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VideoCaptureDelegate?
    public var fps = 15

    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let dispatchQueue = DispatchQueue(label: "")

    var lastTimestamp = CMTime()

    public func sessionSetup(sessionPreset: AVCaptureSession.Preset = .vga640x480, completion: @escaping (Bool) -> Void) {
        self.setupCamera(sessionPreset: sessionPreset, completion: { success in
            completion(success)
        })
    }

    func setupCamera(sessionPreset: AVCaptureSession.Preset, completion: @escaping (_ success: Bool) -> Void) {

        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset

        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: .video,
                                                          position: .back) else {
            print("Error: No video devices available")
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Error: Cannot create AVCaptureDeviceInput")
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer

        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
        ]

        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: dispatchQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // MARK: 픽셀 버퍼 방향 설정
        /// 설정하지 않으면 90도 돌아감. addOutput() 이후 설정해야 한다.
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait

        captureSession.commitConfiguration()

        let success = true
        completion(success)
    }

    public func start() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        /// 디바이스 캡쳐의 FPS를 낮추면 뚝뚝 끊겨 보이므로 일단 최고 FPS로 캡쳐하지만 덷리게이트 패턴 호출은 설정한 프레임 레이트에 맞춰 이루어짐
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - lastTimestamp

        if deltaTime >= CMTimeMake(value: 1, timescale: Int32(fps)) {
            lastTimestamp = timestamp
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            delegate?.videoCapture(self, didCaptureVideoFrame: imageBuffer, timestamp: timestamp)
        }
    }

    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print("dropped frame")
    }
}

