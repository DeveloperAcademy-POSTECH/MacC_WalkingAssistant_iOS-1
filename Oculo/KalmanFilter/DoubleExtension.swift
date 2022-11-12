//
//  DoubleExtension.swift
//  DeepSORT
//
//  Created by Kim, Raymond on 2022/11/11.
//

import Foundation

// MARK: Double as Kalman input
extension Double: KalmanInput {
    public var transposed: Double {
        return self
    }

    public var inversed: Double {
        return 1 / self
    }

    public var additionToUnit: Double {
        return 1 - self
    }
}
