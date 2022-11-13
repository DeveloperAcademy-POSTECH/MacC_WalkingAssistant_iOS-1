//
//  DoubleExtension.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/11/11.
//  Copyright © 2022 IntelligentATLAS. All rights reserved.
//

// Source: https://github.com/wearereasonablepeople/KalmanFilter
// 참고: Cocoapods로 해당 패키지를 더 이상 설치할 수 없음.

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
