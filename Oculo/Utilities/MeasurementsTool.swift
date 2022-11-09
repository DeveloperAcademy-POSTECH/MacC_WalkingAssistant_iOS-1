//
//  MeasurementsTool.swift
//  Oculo
//
//  Created by raymond on 2022/11/04.
//  Copyright © 2022 IntelligentATLAS. All rights reserved.
//

import Foundation
import UIKit

protocol NumericMeasurementsDelegate {
    func updateMeasurementResult(inferenceTime: Double, executionTime: Double, fps: Int)
}


// MARK: AI 모델 퍼포먼스 측정을 위한 클래스 선언
class NumericMeasurements {
    var delegate: NumericMeasurementsDelegate?

    var index: Int = -1
    var numericMeasurements: [Dictionary<String, Double>]

    init() {
        let measuredNumeric = [
            "Start": CACurrentMediaTime(),
            "End": CACurrentMediaTime()
        ]
        numericMeasurements = Array<Dictionary<String,Double>>(repeating: measuredNumeric, count: 30)
    }

    // MARK: 레이블링 메서드 정의
    func didObjectLabeled(with receivedMessage: String? = "") {
        didObjectLabeled(for: index, with: receivedMessage)
    }

    private func didObjectLabeled(for index: Int, with receivedMessage: String? = "") {
        if let message = receivedMessage {
            numericMeasurements[index][message] = CACurrentMediaTime()
        }
    }

    private func getBeforeMeasurment(for index: Int) -> Dictionary<String, Double> {
        return numericMeasurements[(index + 30 - 1) % 30]
    }


    // MARK: 측정 시작 메서드 정의
    func didStartNumericMeasurement() {
        index += 1
        index %= 30
        numericMeasurements[index] = [:]

        didObjectLabeled(for: index, with: "Start")
    }

    // MARK: 측정 종료 메서드 정의
    func didEndNumericMeasurement() {
        didObjectLabeled(for: index, with: "End")

        let beforeMeasurement = getBeforeMeasurment(for: index)
        let currentMeasurement = numericMeasurements[index]

        if let startTime = currentMeasurement["Start"],
            let endInferenceTime = currentMeasurement["EndInference"],
            let endTime = currentMeasurement["End"],
            let beforeStartTime = beforeMeasurement["Start"] {
            delegate?.updateMeasurementResult(inferenceTime: endInferenceTime - startTime,
                                              executionTime: endTime - startTime,
                                              fps: Int(1/(startTime - beforeStartTime)))
        }

    }

    // 로그 프린트
    func printLogs() {

    }
}


class MeasuredLogDisplayView: UIView {
    let excecutionTimeLabel = UILabel(frame: .zero)
    let fpsLabel = UILabel(frame: .zero)

    required init?(coder aDecoder: NSCoder) {
        fatalError("Cannot implement init(coder:)")
    }
}
