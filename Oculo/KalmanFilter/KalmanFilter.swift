//
//  KalmanFilter.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/11/11.
//  Copyright © 2022 IntelligentATLAS. All rights reserved.
//

// Source: https://github.com/wearereasonablepeople/KalmanFilter
// 참고: Cocoapods로 해당 패키지를 더 이상 설치할 수 없음.

import Foundation

/**
 Conventional Kalman Filter
 */
public struct KalmanFilter<Type: KalmanInput>: KalmanFilterType {

    // x̂_k|k-1
    public let stateEstimatePrior: Type

    // P_k|k-1
    public let errorCovariancePrior: Type

    public init(stateEstimatePrior: Type, errorCovariancePrior: Type) {
        self.stateEstimatePrior = stateEstimatePrior
        self.errorCovariancePrior = errorCovariancePrior
    }

    /**
     칼만 필터의 예측 단계

     - parameter stateTransitionModel: F_k
     - parameter controlInputModel: B_k
     - parameter controlVector: u_k
     - parameter covarianceOfProcessNoise: Q_k

     - returns: 예측된(predicted) x̂_k 및 P_k가 있는 칼만 필터의 또 다른 인스턴스
     */
    public func predict(stateTransitionModel: Type, controlInputModel: Type, controlVector: Type, covarianceOfProcessNoise: Type) -> KalmanFilter {

        // x̂_k|k-1 = F_k * x̂_k-1|k-1 + B_k * u_k
        let predictedStateEstimate = stateTransitionModel * stateEstimatePrior + controlInputModel * controlVector

        // P_k|k-1 = F_k * P_k-1|k-1 * F_k^t + Q_k
        let predictedEstimateCovariance = stateTransitionModel * errorCovariancePrior * stateTransitionModel.transposed + covarianceOfProcessNoise

        return KalmanFilter(stateEstimatePrior: predictedStateEstimate, errorCovariancePrior: predictedEstimateCovariance)
    }

    /**
     칼만 필터의 업데이트 단계.
     측정 값으로 예측을 업데이트함.

     - parameter measurement: z_k
     - parameter observationModel: H_k
     - parameter covarienceOfObservationNoise: R_k

     - returns: 새로운 x̂_k 와 P_k 값으로 칼만 필터의 측정 버전 업데이트
     */
    public func update(measurement: Type, observationModel: Type, covarienceOfObservationNoise: Type) -> KalmanFilter {

        // H_k^t 전치. 이걸 캐싱(cache)해서 모델 성능을 향상시킴
        let observationModelTransposed = observationModel.transposed

        // ỹ_k = z_k - H_k * x̂_k|k-1
        let measurementResidual = measurement - observationModel * stateEstimatePrior

        // S_k = H_k * P_k|k-1 * H_k^t + R_k
        let residualCovariance = observationModel * errorCovariancePrior * observationModelTransposed + covarienceOfObservationNoise

        // K_k = P_k|k-1 * H_k^t * S_k^-1
        let kalmanGain = errorCovariancePrior * observationModelTransposed * residualCovariance.inversed

        // x̂_k|k = x̂_k|k-1 + K_k * ỹ_k
        let posterioriStateEstimate = stateEstimatePrior + kalmanGain * measurementResidual

        // P_k|k = (I - K_k * H_k) * P_k|k-1
        let posterioriEstimateCovariance = (kalmanGain * observationModel).additionToUnit * errorCovariancePrior

        return KalmanFilter(stateEstimatePrior: posterioriStateEstimate, errorCovariancePrior: posterioriEstimateCovariance)
    }
}
