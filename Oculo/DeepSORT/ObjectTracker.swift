////
////  ObjectTracker.swift
////  Oculo
////
////  Created by Kim, Raymond on 2022/11/11.
////  Copyright © 2022 Intelligent ATLAS. All rights reserved.
////
//
//import Foundation
//
//// MARK: Swift translation/implementation of SORT algorithm written in Python
//// MARK: 원본 파이썬 코드 https://github.com/abewley/sort
//
//// MARK: 바운딩 박스 간 IOU 계산
///// [x1, y1, x2, y2] 형태
//public func iou_batch(bb_test: Array<Double>, bb_gt: Array<Double>) -> Double {
//    let xx1 = max(bb_test[0], bb_gt[0])  /// IOU의 좌하단 좌표
//    let yy1 = max(bb_test[1], bb_gt[1])  /// IOU의 우하단 좌표
//    let xx2 = min(bb_test[2], bb_gt[2])  /// IOU의 좌상단 좌표
//    let yy2 = min(bb_test[3], bb_gt[3])  /// IOU의 우상단 좌표
//
//    let w = max(0, xx2 - xx1)
//    let h = max(0, yy2 - yy1)
//
//    let wh = w * h
//
//    /// 교집합 면적 ÷ 합집합 면적
//    let o = Double(wh) / Double(((bb_test[2] - bb_test[0]) * (bb_test[3] - bb_test[1])
//      + (bb_gt[2] - bb_gt[0]) * (bb_gt[3] - bb_gt[1]) - wh))
//
//    return(o)
//}
//
//// MARK: convert_bbox_to_z
///// [x1, y1, x2, y2] 형태의 바운딩 박스를 [x, y, s, r] 형태의 z 값으로 반환
///// x, y: 바운딩 박스 중앙 좌표
///// s: 타겟 바운딩 박스의 면적(scale ÷ area)
///// r: 타겟 바운딩 박스의 종횡비(aspect ratio)
//public func convert_bbox_to_z(bbox_int: Array<Double>) -> Array<Double> {
//  let bbox = bbox_int.map({ Double($0) })
//  let w = bbox[2] - bbox[0]
//  let h = bbox[3] - bbox[1]
//  let x = bbox[0] + w/2
//  let y = bbox[1] + h/2
//  let s = w * h  /// scale = area
//  let r = w / h  /// aspect ratio
//    return [x, y, s, r]
//}
//
//// MARK: convert_x_to_bbox
///// [x, y, s, r] 형 자료로부터 바운딩 박스 가운데 지점의 좌표를 받아 와서 [x1, y1, x2, y2] 형 자료로 반환
///// x1, y1: 바운딩 박스 좌상단 지점
///// x2, y2: 바운딩 박스 우하단 지점
//public func convert_x_to_bbox(x: Array<Double>) -> Array<Double> {
//    let w = sqrt(Double(x[2] * x[3]))
//    let h = x[2] / w
//    return [x[0] - w/2, x[1] - h/2, x[0] + w/2, x[1] + h/2]
//}
//
//var lastId = 0
//
//// MARK: KalmanBoxTracker
///// 바운딩 박스로 관찰된, 추적하고 있는 개별 개체의 내부 상태를 나타냄
//public class KalmanBoxTracker {
//    public var id: Int
//    public var hits: Int  /// 첫 번째 detection을 포함한 총 히트 수. "히트"는 추적기(트래커)가 업데이트된 횟수를 뜻함.
//    public var hit_streak: Int  /// 연속 히트 수. 추적기를 삭제해야 하는지 여부를 결정하는 데 사용됨.
//    public var age: Int  /// 첫번째 detection 이후 경과된 프레임 수
//    public var time_since_update: Int  /// 마지막 업데이트 이후 경과된 시간
//    public var history: Array<Array<Double>>  /// 이전 바운딩 박스의 리스트
//
//    public var x: KalmanMatrix  /// 상태 벡터(state vector). 오브젝트의 상태를 나타냄. dim_x행 1열짜리 영행렬
//    public var P: KalmanMatrix  /// 초기 상태 불확실성(initial state uncertainty). 불확실성에 대한 공분산(uncertainty covariance)
//    public let B: KalmanMatrix  /// 천이(transition) 행렬 컨트롤
//    public let u: KalmanMatrix  /// control vector
//    public let F: KalmanMatrix  /// 상태 천이(state transition) 행렬: 시간 변화에 따라 상태 변화를 야기시킴.
//    public let H: KalmanMatrix  /// 측정함수(measurement function)
//    public var R: KalmanMatrix  /// 불확실성(uncertainty) 측정. 상태 불확실성(state uncertainty)
//    public let Q: KalmanMatrix  /// process의 불확실성. 여기서 프로세스는 시스템의 모델, 즉 시간이 지남에 따라 상태가 어떻게 변화하는지를 뜻하며, Q는 모델의 불확실성을 저장함.
//    public lazy var kalmanFilter = KalmanFilter(stateEstimatePrior: x, errorCovariancePrior: P)
//
//    /// 초기 바운딩 박스로 오브젝트 추적기(트래커) 초기화
//    /// Python 코드의  __init__ 메서드 내부를 따로 구현함
//    public init(bbox: Array<Double>) {
//        self.F = KalmanMatrix(grid: [1,0,0,0,1,0,0, 0,1,0,0,0,1,0, 0,0,1,0,0,0,1, 0,0,0,1,0,0,0, 0,0,0,0,1,0,0, 0,0,0,0,0,1,0, 0,0,0,0,0,0,1], rows: 7, columns: 7)
//        self.x = KalmanMatrix(grid: convert_bbox_to_z(bbox_int: bbox) + [0, 0, 0], rows: 7, columns: 1)  /// x의 0 ~ 3번째에 바운딩 박스를 넣어 준다.
//        self.P = KalmanMatrix(grid: [10,0,0,0,0,0,0, 0,10,0,0,0,0,0, 0,0,10,0,0,0,0, 0,0,0,10,0,0,0, 0,0,0,0,10000,0,0, 0,0,0,0,0,10000,0, 0,0,0,0,0,0,10000], rows: 7, columns: 7)  /// 7 * 7 단위행렬 -> 4행 4열부터 1000 곱하라고 돼 있는데 10000 곱함
//        self.B = KalmanMatrix(identityOfSize: 7)
//        self.u = KalmanMatrix(vector: [0, 0, 0, 0, 0, 0, 0])
//        self.H = KalmanMatrix(grid: [1,0,0,0,0,0,0, 0,1,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0], rows: 4, columns: 7)  /// dim_z * dim_x 사이즈: 4행 7열
//        self.R = KalmanMatrix(grid: [1,0,0,0, 0,1,0,0, 0,0,10,0, 0,0,0,10], rows: 4, columns: 4)
//        self.Q = KalmanMatrix(grid: [1,0,0,0,0,0,0, 0,1,0,0,0,0,0, 0,0,1,0,0,0,0, 0,0,0,1,0,0,0, 0,0,0,0,0.01,0,0, 0,0,0,0,0,0.01,0, 0,0,0,0,0,0,0.0001], rows: 7, columns: 7)  /// 4행 4열부터 0.01을 곱하고, 맨 마지막 행 맨 마지막 열에는 다시 0.01을 더 곱해줌
//        self.id = lastId; lastId += 1
//        self.time_since_update = 0
//        self.hits = 0
//        self.hit_streak = 0
//        self.age = 0
//        self.history = []
//        self.kalmanFilter = KalmanFilter(stateEstimatePrior: self.x, errorCovariancePrior: self.P)
//    }
//
//    public func describe() {
//        print("id:", self.id,
//              "bbox:", self.get_state(),
//              "time_since_update:", self.time_since_update,
//              "hits:", self.hits,
//              "hit_streak:", self.hit_streak,
//              "age:", self.age)
//    }
//
//     /// 관찰된 바운빙 박스로 상태 벡터(state vector) 업데이트
//    public func update(bbox: Array<Double>) {
//        self.time_since_update = 0
//        self.history = []
//        self.hits += 1
//        self.hit_streak += 1
//
//        /// z: kalman_filter.py의 update 메서드의 파라미터. 새 측정값을 칼만 필터에 더해주기 위한 파라미터이다.
//        /// z 값이 0일 때는 아무 것도 계산되지 않지만, x_post 및 P_post는 이전 스텝 값(x_prior, P_prior)으로 업데이트 되고, self.z는 None으로 설정됨.
//        /// 자세한 내용은 KalmanFilter.swift 파일에서 설명
//        let z = KalmanMatrix(grid: convert_bbox_to_z(bbox_int: bbox), rows: 4, columns: 1)
//        self.kalmanFilter = self.kalmanFilter.update(measurement: z, observationModel: H, covarienceOfObservationNoise: R)
//    }
//
//    /// 오브젝트 상태 백터를 전진시키고, 예측된 바운딩 박스의 추정값을 반환함
//    public func predict() -> Array<Double> {
//        self.kalmanFilter = self.kalmanFilter.predict(stateTransitionModel: self.F, controlInputModel: self.B, controlVector: self.u, covarianceOfProcessNoise: self.Q)
//        self.age += 1
//        if self.time_since_update > 0{ self.hit_streak = 0 }
//        self.time_since_update += 1
//        self.history.append(convert_x_to_bbox(x: self.kalmanFilter.stateEstimatePrior.grid))
//        return self.history.last!
//    }
//
//    /// 현재 바운딩 박스에 대한 추정치를 반환
//    public func get_state() -> Array<Double> {
//        return convert_x_to_bbox(x: self.kalmanFilter.stateEstimatePrior.grid)
//    }
//
//}
//
///// 탐지(detection)를 추적된 오브젝트에 할당: 탐지 / 추적된 오브젝트 모두 바운딩 박스로 나타남
///// 3종류의 리스트를 반환함: matches, unmatched_detections, unmatched_trackers
//public func associate_detections_to_trackers(detections: Array<Array<Double>>, trackers: Array<Array<Double>>, iou_threshold: Double = 0.3) -> ([(Int, Int)], [Int], [Int]) {
//    if trackers.count == 0 {
//        return ([], Array(0 ..< detections.count), [])
//    }
//
//    var iou_matrix: [[Double]] = Array(repeating: Array(repeating: 0, count: trackers.count), count: detections.count)
//
//    for (d, det) in detections.enumerated() {
//        for (t, trk) in trackers.enumerated() {
//            iou_matrix[d][t] = iou_batch(bb_test: det, bb_gt: trk)
//        }
//    }
//
//    // TODO: 헝가리안 알고리즘 추가
//    let h = HungarianSolver(matrix: iou_matrix, maxim: true)
//
//    guard let matched_indices = h?.solve() else {  /// matched_indices: 헝가리안 알고리즘으로 계산된 매칭 결과
//        return ([], Array(0 ..< detections.count), Array(0 ..< trackers.count))
//    }
//
//    var unmatched_detections: [Int] = []
//    var unmatched_trackers: [Int] = []
//
//    /// IOU 값이 낮은 항목 제거
//    var matches:[(Int, Int)] = []
//
//    for m in matched_indices.1 {
//        if m.1 >= trackers.count {
//            unmatched_detections.append(m.0)
//        } else if m.0 >= detections.count {
//            unmatched_trackers.append(m.1)
//        } else if iou_matrix[m.0][m.1] < iou_threshold {
//            unmatched_detections.append(m.0)
//            unmatched_trackers.append(m.1)
//        } else {
//            matches.append(m)
//        }
//    }
//
//    return (matches, unmatched_detections, unmatched_trackers)
//}
//
//public class ObjectTracker {
//    public var trackers: Array<KalmanBoxTracker>
//    public var min_hits: Int
//    public var max_age: Int
//    public var frame_count: Int
//    public var more_than_one_active = false
//    public var patience = 0
//    public var creationTime: Date
//    public var iou_threshold: Double
//
//    // MARK: SORT 알고리즘 주요 파라미터 설정
//    public init(max_age: Int = 1, min_hits: Int = 3, iou_threshold: Double = 0.3) {
//        self.trackers = []  /// SORT를 호출하는 위치에 따라 다름
//        self.min_hits = min_hits
//        self.max_age = max_age
//        self.frame_count = 0
//        self.iou_threshold = iou_threshold
//        self.creationTime = Date()
//        lastId = 0
//    }
//
//    /**
//     상태 업데이트 메서드.
//
//     dets: Int형 자료의 어레이. 디텍션 값([x1, y1, x2, y2] 형태)들이 담겨 있음
//     ※ dets: [[x1, y1, x2, y2], [x1, y1, x2, y2], ...] 형태
//
//     각 프레임에서 **반드시** 한 번 호출되어야 함
//     리턴 값의 가장 마지막 열은 추적하는 객체의 ID이다.
//
//     **주의**: 반환되는 객체 수는 제공된 탐지 수와 다를 수 있음. 이상한 거 아니니 걱정 ㄴㄴ
//     */
//    public func update(dets: Array<Array<Double>>) -> Array<Array<Double>> {
//        var ret: Array<Array<Double>> = []
//        self.frame_count += 1
//
//        let trks = self.trackers.map({ $0.predict() })
//        let (matched, unmatched_dets, _) = associate_detections_to_trackers(detections: dets, trackers: trks)
////        print("matches", matched)
//
//        for m in matched {
//            self.trackers[m.1].update(bbox: dets[m.0])  // MARK: 바운딩 박스 업데이트
//        }
//
//        for i in unmatched_dets { self.trackers.append(KalmanBoxTracker(bbox: dets[i])) }
//
//        var i = self.trackers.count
//
//        for trk in self.trackers.reversed() {
//            let d = trk.get_state()
//            if trk.time_since_update < 1 && (trk.hit_streak >= self.min_hits || self.frame_count <= self.min_hits) {
//                ret.append(d + [Double(trk.id + 1)])
//            }
//
//            i -= 1
//
//            // MARK: 트랙 제거 - 추적기가 오랫동안 업데이트 되지 않으면 삭제
//            /// self.max_age: 추적기(트래커)가 업데이트할 수 없는 최대 프레임 수. 즉, 데드 프레임의 수.
//            /// 추적기(트래커)는 매 프레임마다 업데이트되기 때문에 최대 프레임 수는 1로 설정
//            if trk.time_since_update > self.max_age {
//                self.trackers.remove(at: i)
//            }
//        }
////        print("trackers", self.trackers.count)
//
//        if ret.count > 0 {
//            return ret
//        }
//
//        return []
//    }
//
//}
