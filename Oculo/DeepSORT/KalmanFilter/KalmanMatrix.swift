//
//  KalmanMatrix.swift
//  Oculo
//
//  Created by raymond on 2022/11/21.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation
import Accelerate

public struct KalmanMatrix: Equatable {

    // MARK: 칼만 행렬 프로퍼티 정의
    public let rows: Int, columns: Int
    public var grid: [Double]  // grid: 행렬의 원소를 저장하는 1차원 배열

    var isSquare: Bool {
        return rows == columns
    }

    // MARK: 칼만 행렬 초기화
    /// rows(행렬의 행 수) × columns(행렬의 열 수) 사이즈의 영행렬로 초기화
    public init(rows: Int, columns: Int) {
        let grid = Array(repeating: 0.0, count: rows * columns)
        self.init(grid: grid, rows: rows, columns: columns)
    }

    /// 행렬의 모든 요소를 주어진 행렬의 크기로 포함하는 그리드로 초기화
    /// parameter grid: 행렬의 요소 어레이. grid의 크기는 rows × column 이어야만 함.
    public init(grid: [Double], rows: Int, columns: Int) {
        assert(rows * columns == grid.count, "grid size should be rows × column size")
        self.rows = rows
        self.columns = columns
        self.grid = grid
    }

    /**
     열 벡터(column vector) 초기화
       ※ 열 벡터는 m × 1 사이즈의 행렬을 의미한다.

     - parameter vector: 벡터의 원소(elements)를 포함하는 어레이
     */
    public init(vector: [Double]) {
        self.init(grid: vector, rows: vector.count, columns: 1)
    }

    /**
     주어진 행 수(rows)로 열 벡터 초기화
     행렬의 모든 원소는 0.0으로 초기화된다.

     - parameter size: 벡터의 열 수
     */
    public init(vectorOf size: Int) {
        self.init(rows: size, columns: 1)
    }

    /**
     주어진 크기로 정사각 행렬 초기화
     배열의 크기는 size × size 이고, 모든 원소는 0.0으로 초기화된다.

     - parameter size: 행렬의 행과 열의 수. 정사각 행렬이므로 동일한 값을 사용한다.
     */
    public init(squareOfSize size: Int) {
        self.init(rows: size, columns: size)
    }

    /**
     주어진 크기로 단위행렬(항등행렬) 초기화.

     - parameter size: 단위행렬의 행과 열의 수.
     */
    public init(identityOfSize size: Int) {
        self.init(squareOfSize: size)
        for i in 0 ..< size {
            self[i, i] = 1
        }
    }

    /**
     2차원 행렬 초기화

     - parameter array2d: 행렬의 2차원 배열 표현
     */
    public init(_ array2d: [[Double]]) {
        /// grid: 행렬의 요소 어레이. array2d를 1차원 어레이로 변환한 것.
        self.init(grid: array2d.flatMap({ $0 }), rows: array2d.count, columns: array2d.first?.count ?? 0)
    }

    // MARK: 전역 메소드
    /**
     행렬의 특정 행, 특정 열에 원소가 존재하는지 여부를 판단하는 함수

     - parameter row: row index of element 원소의 행 인덱스
     - parameter column: column index of element 원소의 열 인덱스
     - returns: 지정된 인덱스가 유효한지(= 원소가 존재하는지) 여부를 나타내는 불리언 값
     */
    public func indexIsValid(forRow row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
        /// row >= 0 && row < rows: 행 인덱스가 유효한지 여부 --> 행 인덱스가 0보다 크거나 같고, 행의 수(rows)보다 작은지 여부
        /// column >= 0 && column < columns: 열 인덱스가 유효한지 여부 --> 열 인덱스가 0보다 크거나 같고, 열의 수(columns)보다 작은지 여부
    }

    public subscript(row: Int, column: Int) -> Double {  /// 연산 프로퍼티(computed property)
        get {
            assert(indexIsValid(forRow: row, column: column), "Out of index error")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValid(forRow: row, column: column), "IOut of index error")
            /// (row * columns) + column: 1차원 어레이의 원소의 인덱스 값
            /// column 값을 (row * columns)에 더하는 이유: 2차원 어레이의 행과 열의 인덱스를 1차원 어레이의 인덱스로 변환하기 위해서
            grid[(row * columns) + column] = newValue
        }
    }

}

// MARK: 행렬의 동등성 판단 연산자 정의
public func == (lhs: KalmanMatrix, rhs: KalmanMatrix) -> Bool {
    return lhs.rows == rhs.rows && lhs.columns == rhs.columns && lhs.grid == rhs.grid
}

// MARK: 행렬을 칼만 인풋 타입으로 사용하기 위한 익스텐션
extension KalmanMatrix: KalmanInput {
    /**
     전치행렬

     시간복잡도: O(n^2)
     */
    public var transposed: KalmanMatrix {
        var resultMatrix = KalmanMatrix(rows: columns, columns: rows)
        let columnLength = resultMatrix.columns
        let rowLength = resultMatrix.rows

        grid.withUnsafeBufferPointer { xp in
            resultMatrix.grid.withUnsafeMutableBufferPointer { rp in
                vDSP_mtransD(xp.baseAddress!, 1, rp.baseAddress!, 1, vDSP_Length(rowLength), vDSP_Length(columnLength))
            }
        }
        return resultMatrix
    }

    /**
     단위에 I - A 형태 추가
       ※ 단, I는 단위 행렬, A는 자기 자신
       ※ 단위 행렬에서 자기 자신을 빼는 이유: 칼만 필터의 수식에서 A를 빼는 것과 동일한 효과를 내기 위해서
       ※ 정사각 행렬의 경우에만 사용 가능하다.

     시간복잡도: O(n ^ 2)
     */
    public var additionToUnit: KalmanMatrix {
        assert(isSquare, "Matrix should be square")
        return KalmanMatrix(identityOfSize: rows) - self
    }

    /**
     역행렬이 가능한 경우 역행렬
     */
    public var inversed: KalmanMatrix {
        assert(isSquare, "Matrix should be square")

        if rows == 1 {
            return KalmanMatrix(grid: [1/self[0, 0]], rows: 1, columns: 1)
        }

        var inMatrix:[Double] = grid

        /// 행렬의 차원을 가져옴.
        /// NxN 행렬은 N^2개의 원소를 가지므로, sqrt(N^2)는 N을 반환하고, 이는 행렬의 차원이다.
        var N: __CLPK_integer = __CLPK_integer(sqrt(Double(grid.count)))  /// 행렬의 차원
        var N2: __CLPK_integer = N  /// 행렬의 차원
        var N3: __CLPK_integer = N  /// 행렬의 차원
        var lwork = __CLPK_integer(grid.count)  /// 작업 공간의 크기. 작업 공간: 행렬의 역행렬을 구하기 위한 작업 공간

        /**
         dgetrf_() 함수와 dgetri_() 함수를 위한 배열 초기화

           ※ dgetrf_() 함수: LU 분해를 수행하는 함수.
              ※ LU분해:  https://ko.wikipedia.org/wiki/LU_%EB%B6%84%ED%95%B4#:~:text=LU%20%EB%B6%84%ED%95%B4(%EC%98%81%EC%96%B4%3A%20LU%20decomposition,%ED%91%9C%ED%98%84%ED%95%9C%20%EA%B2%83%EC%9C%BC%EB%A1%9C%20%EC%9D%B4%ED%95%B4%ED%95%A0%20%EC%88%98%20%EC%9E%88%EB%8B%A4.

           ※ dgetri_() 함수: 역행렬을 구하는 함수
         */
        var pivots: [__CLPK_integer] = [__CLPK_integer](repeating: 0, count: grid.count)
        var workspace: [Double] = [Double](repeating: 0.0, count: grid.count)
        var error: __CLPK_integer = 0

        // MARK: LU 분해 수행
        dgetrf_(&N, &N2, &inMatrix, &N3, &pivots, &error)  /// 피봇은 행렬의 순서를 바꿀 때, 즉 역행렬 계산시 사용됨.

        // LU 분해를 통해 역행렬 연산
        dgetri_(&N, &inMatrix, &N2, &pivots, &workspace, &lwork, &error)

        if error != 0 {  /// 역행렬 연산이 실패한 경우
            assertionFailure("Matrix inversion failed")
        }

        /// 연산 결과 반환
        return KalmanMatrix.init(grid: inMatrix, rows: rows, columns: rows)
    }

    /**
     행렬식(determinant) 계산
       ※ 행렬식은 정사각 행렬에서만 정의되며, 역행렬이 존재하는지 여부를 판단하는 기준이 된다.
       ※ 행렬식이 0이면 역행렬이 존재하지 않으며, 이런 경우의 행렬은 특이행렬(singular matrix)이라 한다.
     */
    public var determinant: Double {
        assert(isSquare, "Matrix should be square")

        var result = 0.0

        if rows == 1 {
            result = self[0, 0]  /// 행 수가 1인 경우의 정사각 행렬의 크기는 1 × 1 이므로, 행렬식은 행렬 자신의 값이다.
        } else {
            for i in 0 ..< rows {
                /// i가 짝수인 경우 sign에 1.0을 할당, 아닌 경우 sign에 -1.0을 할당: 행렬식 부호 결정(permutation)
                let sign = i % 2 == 0 ? 1.0 : -1.0
                /// result에 sign × 행렬의 [i, 0] 위치의 원소 × 행렬의 [i, 0] 위치의 원소를 제외한 행렬식을 더함
                result += sign * self[i, 0] * additionalMatrix(row: i, column: 0).determinant
            }
        }
        return result
    }

    public func additionalMatrix(row: Int, column: Int) -> KalmanMatrix {
        /// additionalMatrix() 함수는 행렬의 [row, column] 위치의 원소를 제외한 행렬을 반환한다.
        assert(indexIsValid(forRow: row, column: column), "Invalid arguments")

        /// 행렬의 [row, column] 위치의 원소를 제외한 행렬을 resultMatrix에 할당
        var resultMatrix = KalmanMatrix(rows: rows - 1, columns: columns - 1)

        for i in 0 ..< rows {
            if i == row {
                continue
            }
            for j in 0 ..< columns {
                if j == column {
                    continue
                }
                let resI = i < row ? i : i - 1
                let resJ = j < column ? j : j - 1
                resultMatrix[resI, resJ] = self[i, j]
            }
        }
        return resultMatrix
    }

    // MARK: Private 메소드
    /// fileprivate func: 동일 소스 파일의 경우 접근 허용
    fileprivate func operate(with otherMatrix: KalmanMatrix, closure: (Double, Double) -> Double) -> KalmanMatrix {
        assert(rows == otherMatrix.rows && columns == otherMatrix.columns, "Matrices should be of equal size")
        var resultMatrix = KalmanMatrix(rows: rows, columns: columns)

        for i in 0 ..< rows {
            for j in 0 ..< columns {
                resultMatrix[i, j] = closure(self[i, j], otherMatrix[i, j])
            }
        }

        return resultMatrix
    }
}

/**
 Naive add matrices

 Complexity: O(n^2)
 */
public func + (lhs: KalmanMatrix, rhs: KalmanMatrix) -> KalmanMatrix {
    assert(lhs.rows == rhs.rows && lhs.columns == rhs.columns, "The matrices should have equal size")
    var resultMatrix = KalmanMatrix(rows: lhs.rows, columns: lhs.columns)
    vDSP_vaddD(lhs.grid, vDSP_Stride(1), rhs.grid, vDSP_Stride(1), &resultMatrix.grid, vDSP_Stride(1), vDSP_Length(lhs.rows * lhs.columns))
    return resultMatrix
}

/**
 Naive subtract matrices

 Complexity: O(n^2)
 */
public func - (lhs: KalmanMatrix, rhs: KalmanMatrix) -> KalmanMatrix {
    assert(lhs.rows == rhs.rows && lhs.columns == rhs.columns, "The matrices should have equal size")
    var resultMatrix = KalmanMatrix(rows: lhs.rows, columns: lhs.columns)
    vDSP_vsubD(rhs.grid, vDSP_Stride(1), lhs.grid, vDSP_Stride(1), &resultMatrix.grid, vDSP_Stride(1), vDSP_Length(lhs.rows * lhs.columns))
    return resultMatrix
}


/**
 Naive matrices multiplication

 Complexity: O(n^3)
 */
public func * (lhs: KalmanMatrix, rhs: KalmanMatrix) -> KalmanMatrix {
    assert(lhs.columns == rhs.rows, "The number of left matrix columns should be the same with the right matrix's rows")
    var resultMatrix = KalmanMatrix(rows: lhs.rows, columns: rhs.columns)
    let order = CblasRowMajor  /// cblas.h 헤더 파일 내에 정의되어 있음
    let atrans = CblasNoTrans
    let btrans = CblasNoTrans
    let alpha = 1.0
    let beta = 1.0
    let resultColumns = resultMatrix.columns

    lhs.grid.withUnsafeBufferPointer { pa in
        rhs.grid.withUnsafeBufferPointer { pb in
            resultMatrix.grid.withUnsafeMutableBufferPointer { pc in
                cblas_dgemm(order, atrans, btrans, Int32(lhs.rows), Int32(rhs.columns), Int32(lhs.columns), alpha, pa.baseAddress!, Int32(lhs.columns), pb.baseAddress!, Int32(rhs.columns), beta, pc.baseAddress!, Int32(resultColumns))
            }
        }
    }

    return resultMatrix
}

// MARK: - Nice additional methods
public func * (lhs: KalmanMatrix, rhs: Double) -> KalmanMatrix {
    return KMatrix(grid: lhs.grid.map({ $0 * rhs }), rows: lhs.rows, columns: lhs.columns)
}

public func * (lhs: Double, rhs: KalmanMatrix) -> KalmanMatrix {
    return rhs * lhs
}

// MARK: - CustomStringConvertible for debug output
extension KalmanMatrix: CustomStringConvertible {
    public var description: String {
        var description = ""

        for i in 0..<rows {
            let contents = (0..<columns).map{"\(self[i, $0])"}.joined(separator: "\t")

            switch (i, rows) {
            case (0, 1):
                description += "(\t\(contents)\t)"
            case (0, _):
                description += "⎛\t\(contents)\t⎞"
            case (rows - 1, _):
                description += "⎝\t\(contents)\t⎠"
            default:
                description += "⎜\t\(contents)\t⎥"
            }

            description += "\n"
        }

        return description
    }
}
