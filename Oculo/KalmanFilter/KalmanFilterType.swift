//
//  KalmanFilterType.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/11/11.
//  Copyright © 2022 IntelligentATLAS. All rights reserved.
//

// Source: https://github.com/wearereasonablepeople/KalmanFilter
// 참고: Cocoapods로 해당 패키지를 더 이상 설치할 수 없음.

import Foundation

public protocol KalmanInput {
    var transposed: Self { get }
    var inversed: Self { get }
    var additionToUnit: Self { get }

    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
}

public protocol KalmanFilterType {
    associatedtype Input: KalmanInput

    var stateEstimatePrior: Input { get }
    var errorCovariancePrior: Input { get }

    func predict(stateTransitionModel: Input,
                 controlInputModel: Input,
                 controlVector: Input,
                 covarianceOfProcessNoise: Input) -> Self

    func update(measurement: Input,
                observationModel: Input,
                covarienceOfObservationNoise: Input) -> Self
}
