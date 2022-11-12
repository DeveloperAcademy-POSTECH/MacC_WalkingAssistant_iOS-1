//
//  KalmanFilterType.swift
//  DeepSORT
//
//  Created by Kim, Raymond on 2022/11/11.
//

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
