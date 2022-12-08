//
//  KalmanFilter.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/11/17.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation

// MARK: Kalman Filter 구조체 정의
/// 원본 소스코드: https://github.com/rlabbe/Kalman-and-Bayesian-Filters-in-Python

/**
 칼만 필터의 뿌리는 베이즈 필터이다. 즉, 칼만 필터는 베이지안 확률을 이용한 필터이다.
 특히, 베이즈 필터의 문제점인 적분 계산을 개선하기 위해 칼만 필터가 도입된 것이므로 칼만 필터를 이해하려면 베이즈 필터를 먼저 공부하는 것이 좋다.

 칼만 필터는 입력과 출력이 하나씩인 구조로, 측정값(z_k)이 주어지면 알고리즘 내부에서 그 측정값을 처리한 다음 추정값(x̂_k)을 출력한다.

 칼만 필터 내부 계산은 초깃값 선정 이후 총 4단계의 연산 과정을 거친다.
 이때 _k는 k번째 측정값에 대한 계산이라는 뜻이며, 이는 곧 알고리즘이 반복적으로 수행됨을 의미한다(recursion).
 칼만 필터의 전체 구조가 이전 스텝 (k-1)의 값을 이용하여 현재 스텝 (k)의 값을 업데이트 하는 것이므로 k 라는 인덱스를 추가한 것이다.

 ※ 위 첨자(-)는 매우 중요한 기호이니 유의해서 봐야 한다.

 칼만 필터의 전체 연산 플로우는 다음과 같다.

 0. 초깃값 선정
 1. 추정값과 오차 공분산 예측
   ※ 공분산(covariance)은 두 변수 간의 선형적인 관계를 나타내는 통계량임
 2. 칼만 이득(Kalman gain) 계산
   ※ 칼만 이득은 다음 단계의 추정값 계산에 사용되는 가중치이다. 칼만 이득은 반복적으로 연산되고, 계속 업데이트된다.
 3. 추정값 계산
 4. 오차 공분산 계산
 */

public struct KalmanFilter<Type: KalmanInput>: KalmanFilterType {
    /**
     Kalman Filter 구조체는 주로 행렬에 값 할당시 행렬의 사이즈를 측정하기 위해 사용한다.
     먼저 상태 벡터(state vector)의 크기를 dim_x 로, 측정 벡터(measurement vector)의 크기를 dim_z 로 정의한다.
     예컨대 dim_z=2 로 지정했는데 측정 노이즈 행렬인 R에 3x3 으로 값을 지정하면 R의 크기는 2x2여야 하기 때문에 할당 예외(assert exception)가 발생한다.
     원본 소스코드의 작성자는 "어떤 이유로든 중간 스트림(midstream)의 크기를 변경시켜야 하는 경우 행렬 이름에 밑줄을 넣어서 직접 할당" 하는 것을 권장하고 있다.
        i.e.) your_filter._R = a_3x3_matrix
     */

    // x̂_k|k-1
    /// | 기호는 "given"을 의미함. 즉, k-1 시점의 상태 벡터를 k 시점의 상태 벡터에 대입한다는 의미이다.
    /// x̂_k: 추정값. 측정값인 z_k를 받아 알고리즘 내부에서 처리하여 x̂_k를 출력함.
    /// k-1: 현재 스텝의 한 단계 전 스텝. k-1 값을 이용하여 현재 스텝인 k 값을 계산함.
    public let stateEstimatePrior: Type

    // P_k|k-1
    /// P_k: 오차 공분산 행렬. 추정값인 x̂_k와 실제값(측정값)인 x_k 사이의 오차를 나타내는 행렬.
    public let errorCovariancePrior: Type

    // MARK: Kalman Filter의 상태 천이 행렬(state transition matrix)
    /// stateEstimatePrior: 상태값에 대한 사전 추정치
    /// errorCovariancePrior: 상태값에 대한 사전 오차 공분산 행렬
    public init(stateEstimatePrior: Type, errorCovariancePrior: Type) {
        self.stateEstimatePrior = stateEstimatePrior
        self.errorCovariancePrior = errorCovariancePrior
    }

    /**
     칼만 필터의 스텝 예측.

     - parameter stateTransitionModel: F_k  --> 상태 천이 모델
     - parameter controlInputModel: B_k  --> 제어 입력 모델
     - parameter controlVector: u_k  --> 제어 벡터
     - parameter covarianceOfProcessNoise: Q_k  --> 처리 과정의 노이즈 공분산 행렬

     - returns: 예측된 x̂_k와 P_k를 갖는 칼만 필터 인스턴스
     */
    public func predict(stateTransitionModel: Type, controlInputModel: Type, controlVector: Type, covarianceOfProcessNoise: Type) -> KalmanFilter {

        // x̂_k|k-1 = F_k * x̂_k-1|k-1 + B_k * u_k
        let predictedStateEstimate = stateTransitionModel * stateEstimatePrior + controlInputModel * controlVector

        // P_k|k-1 = F_k * P_k-1|k-1 * F_k^t + Q_k
        let predictedEstimateCovariance = stateTransitionModel * errorCovariancePrior * stateTransitionModel.transposed + covarianceOfProcessNoise

        return KalmanFilter(stateEstimatePrior: predictedStateEstimate, errorCovariancePrior: predictedEstimateCovariance)
    }

    /**
     칼만 필터 스텝 업데이트. 측정값을 이용하여 예측값(prediction)을 업데이트한다.

     - parameter measurement: z_k --> 측정값
     - parameter observationModel: H_k --> 관측 모델
     - parameter covarienceOfObservationNoise: R_k --> 측정 노이즈 공분산 행렬

     - returns: 측정값으로 업데이트된 버전의 칼만 필터. 새로운 x̂_k와 P_k를 갖는다.
     */
    public func update(measurement: Type, observationModel: Type, covarienceOfObservationNoise: Type) -> KalmanFilter {
        /// H_k^t: H_k의 전치 행렬. 성능 향상을 위해 캐싱한다.
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

// MARK: 칼만 인풋 요구사항 정의
public protocol KalmanInput {
    var transposed: Self { get }
    var inversed: Self { get }
    var additionToUnit: Self { get }

    /// 칼만 인풋에 사용할 추가 연산자 정의: +, -, *
    /// lhs: left hand side(왼쪽 element), rhs: right hand side(오른쪽 element)
    /// static func로 상속이 불가능하도록 선언: 연산자를 중복하여 선언하는 것을 방지하기 위함
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
}

// MARK: 칼만 필터 타입의 요구사항 정의
public protocol KalmanFilterType {
    associatedtype Input: KalmanInput  /// associatedtype: 연관 타입. 프로토콜에서 사용할 타입을 지정한다.

    var stateEstimatePrior: Input { get }  /// { get }: 읽기 전용 프로퍼티
    var errorCovariancePrior: Input { get }

    func predict(stateTransitionModel: Input, controlInputModel: Input, controlVector: Input, covarianceOfProcessNoise: Input) -> Self
    func update(measurement: Input, observationModel: Input, covarienceOfObservationNoise: Input) -> Self
}

// MARK: 칼만 인풋을 위한 Double(실수) 익스텐션
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
