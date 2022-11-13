//
//  KalmanMatrix.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/11/11.
//  Copyright © 2022 IntelligentATLAS. All rights reserved.
//

// Source: https://github.com/wearereasonablepeople/KalmanFilter
// 참고: Cocoapods로 해당 패키지를 더 이상 설치할 수 없음.

import Foundation
import Accelerate

public struct KMatrix: Equatable {

    // MARK: 프로퍼티 정의
    public let rows: Int, columns: Int
    public var grid: [Double]

    var isSquare: Bool {
        return rows == columns
    }


    // MARK: 초기화

    /**
     행렬의 모든 원소를 0.0 으로 설정
     행렬 사이즈: rows * columns

    - parameter rows: 행렬의 행 수
    - parameter columns: 행렬의 열 수
     */
    public init(rows: Int, columns: Int) {
        let grid = Array(repeating: 0.0, count: rows * columns)
        self.init(grid: grid, rows: rows, columns: columns)
    }

    /**
     주어진 행렬의 크기로 그 행렬의 모든 원소를 포함하는 그리드를 초기화

     - parameter grid: 행렬 원소의 배열. 그리드 사이즈: 반드시 주어진 행렬의 rows * columns
     - parameter rows: 행렬의 행 수
     - parameter columns: 행렬의 열 수
     */
    public init(grid: [Double], rows: Int, columns: Int) {
        assert(rows * columns == grid.count, "The grid size should be rows * columns size")
        self.rows = rows
        self.columns = columns
        self.grid = grid
    }

    /**
     주어진 배열로 [열 벡터] 초기화.

     배열의 원소 수는 벡터의 행 수와 같음.

     - parameter vector: 벡터 요소가 담긴 배열
     */
    public init(vector: [Double]) {
        self.init(grid: vector, rows: vector.count, columns: 1)
    }

    /**
     주어진 행 수로 [열 벡터] 초기화

     열 벡터의 모든 원소를 0.0으로 초기화함.

     - parameter size: 벡터 사이즈
     */
    public init(vectorOf size: Int) {
        self.init(rows: size, columns: 1)
    }

    /**
     주어진 크기로 정사각 행렬 초기화

     배열의 원소 수는 size * size 와 같음.
     모든 요소를 0.0 으로 설정하므로 결국 size * size 크기의 영행렬을 만드는 것.

     - parameter size: 행렬의 행과 열의 수
     */
    public init(squareOfSize size: Int) {
        self.init(rows: size, columns: size)
    }

    /**
     주어진 사이즈의 단위행렬 초기화

     - parameter size: 단위행렬의 행과 열의 수
     */
    public init(identityOfSize size: Int) {
        self.init(squareOfSize: size)
        for i in 0..<size {
            self[i, i] = 1
        }
    }

    /**
     2차원 배열 초기화

     - parameter array2d: 2차원 행렬의 배열(array) 표현
     */
    public init(_ array2d: [[Double]]) {
        self.init(grid: array2d.flatMap({$0}),
                  rows: array2d.count,
                  columns: array2d.first?.count ?? 0)
    }


    // MARK: - Public 메서드
    /**
     지정된 행과 열에 원소가 있는지 판단

     - parameter row: 원소의 행 인덱스
     - parameter column: 원소의 열 인덱스
     - returns: 불리언(boolean)값 - 요소가 있으면 true, 없으면 false
     */
    public func indexIsValid(forRow row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }

    public subscript(row: Int, column: Int) -> Double {
        get {
            assert(indexIsValid(forRow: row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValid(forRow: row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }
}


// MARK: - Equatable
public func == (lhs: KMatrix, rhs: KMatrix) -> Bool {
    return lhs.rows == rhs.rows && lhs.columns == rhs.columns && lhs.grid == rhs.grid
}


// MARK: 행렬을 KalmanInput으로
extension KMatrix: KalmanInput {

    /**
     전치행렬

     시간복잡도: 두 번 돌기 때문에 O(n^2)
     */
    public var transposed: KMatrix {
        var resultMatrix = KMatrix(rows: columns, columns: rows)
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
    ** I - A  ** 형식의 유닛 추가

     단, ** I  ** : 단위행렬, ** A ** : self

     정사각 행렬일 때에만 사용 가능
     시간복잡도: 이것도 두 번 돌기 때문에 O(n^2)
     */
    public var additionToUnit: KMatrix {
        assert(isSquare, "Matrix should be square")
        return KMatrix(identityOfSize: rows) - self
    }

    /**
     가역행렬

     참고: https://ko.wikipedia.org/wiki/%EA%B0%80%EC%97%AD%ED%96%89%EB%A0%AC
     */
    public var inversed: KMatrix {
        assert(isSquare, "Matrix should be square")

        if rows == 1 {
            return KMatrix(grid: [1/self[0, 0]], rows: 1, columns: 1)
        }

        var inMatrix:[Double] = grid

        // 행렬의 차원을 가져 옴. NxN 행렬의 원소는 N^2 개이므로 sqrt( N^2 ) 는 차원 수인 N을 반환함
        var N:__CLPK_integer = __CLPK_integer(sqrt(Double(grid.count)))
        var N2:__CLPK_integer = N
        var N3:__CLPK_integer = N
        var lwork = __CLPK_integer(grid.count)

        // dgetrf_() 및 dgetri_() 함수에 대한 일부 배열 초기화
        var pivots:[__CLPK_integer] = [__CLPK_integer](repeating: 0, count: grid.count)
        var workspace:[Double] = [Double](repeating: 0.0, count: grid.count)
        var error: __CLPK_integer = 0

        // LU 분해(선대의 그 LU 분해 맞음)
        // 참고 1: https://m.blog.naver.com/PostView.naver?isHttpsRedirect=true&blogId=cj3024&logNo=221124535258
        // 참고 2: https://deep-learning-study.tistory.com/311
        dgetrf_(&N, &N2, &inMatrix, &N3, &pivots, &error)

        // LU 분해를 이용해 역행렬을 구함
        dgetri_(&N, &inMatrix, &N2, &pivots, &workspace, &lwork, &error)

        if error != 0 {
            assertionFailure("Matrix Inversion Failure")
        }
        return KMatrix.init(grid: inMatrix, rows: rows, columns: rows)
    }

    /**
     행렬식
     */
    public var determinant: Double {
        assert(isSquare, "Matrix should be square")
        var result = 0.0
        if rows == 1 {
            result = self[0, 0]
        } else {
            for i in 0..<rows {
                let sign = i % 2 == 0 ? 1.0 : -1.0
                result += sign * self[i, 0] * additionalMatrix(row: i, column: 0).determinant
            }
        }
        return result
    }

    public func additionalMatrix(row: Int, column: Int) -> KMatrix {
        assert(indexIsValid(forRow: row, column: column), "Invalid arguments")
        var resultMatrix = KMatrix(rows: rows - 1, columns: columns - 1)
        for i in 0..<rows {
            if i == row {
                continue
            }
            for j in 0..<columns {
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
    fileprivate func operate(with otherMatrix: KMatrix, closure: (Double, Double) -> Double) -> KMatrix {
        assert(rows == otherMatrix.rows && columns == otherMatrix.columns, "Matrices should be of equal size")
        var resultMatrix = KMatrix(rows: rows, columns: columns)

        for i in 0..<rows {
            for j in 0..<columns {
                resultMatrix[i, j] = closure(self[i, j], otherMatrix[i, j])
            }
        }

        return resultMatrix
    }
}

/**
 행렬 덧셈

 시간복잡도: O(n^2)
 */
public func + (lhs: KMatrix, rhs: KMatrix) -> KMatrix {
    assert(lhs.rows == rhs.rows && lhs.columns == rhs.columns, "Matrices should be of equal size")
    var resultMatrix = KMatrix(rows: lhs.rows, columns: lhs.columns)
    vDSP_vaddD(lhs.grid, vDSP_Stride(1), rhs.grid, vDSP_Stride(1), &resultMatrix.grid, vDSP_Stride(1), vDSP_Length(lhs.rows * lhs.columns))
    return resultMatrix
}

/**
 행렬 뺄셈

 시간복잡도: O(n^2)
 */
public func - (lhs: KMatrix, rhs: KMatrix) -> KMatrix {
    assert(lhs.rows == rhs.rows && lhs.columns == rhs.columns, "Matrices should be of equal size")
    var resultMatrix = KMatrix(rows: lhs.rows, columns: lhs.columns)
    vDSP_vsubD(rhs.grid, vDSP_Stride(1), lhs.grid, vDSP_Stride(1), &resultMatrix.grid, vDSP_Stride(1), vDSP_Length(lhs.rows * lhs.columns))
    return resultMatrix
}


/**
 행렬 곱셈

 시간복잡도: O(n^3)
 */
public func * (lhs: KMatrix, rhs: KMatrix) -> KMatrix {
    assert(lhs.columns == rhs.rows, "Left matrix columns should be the size of right matrix's rows")
    var resultMatrix = KMatrix(rows: lhs.rows, columns: rhs.columns)
    let order = CblasRowMajor
    let atrans = CblasNoTrans
    let btrans = CblasNoTrans
    let α = 1.0
    let β = 1.0
    let resultColumns = resultMatrix.columns
    lhs.grid.withUnsafeBufferPointer { pa in
        rhs.grid.withUnsafeBufferPointer { pb in
            resultMatrix.grid.withUnsafeMutableBufferPointer { pc in
                cblas_dgemm(order, atrans, btrans, Int32(lhs.rows), Int32(rhs.columns), Int32(lhs.columns), α, pa.baseAddress!, Int32(lhs.columns), pb.baseAddress!, Int32(rhs.columns), β, pc.baseAddress!, Int32(resultColumns))
            }
        }
    }

    return resultMatrix
}

// MARK: 곱셈 메서드 추가 - 행렬 * 실수, 실수 * 행렬
public func * (lhs: KMatrix, rhs: Double) -> KMatrix {
    return KMatrix(grid: lhs.grid.map({ $0*rhs }), rows: lhs.rows, columns: lhs.columns)
}

public func * (lhs: Double, rhs: KMatrix) -> KMatrix {
    return rhs * lhs
}

// MARK: 아웃풋 디버깅을 위한 CustomStringConvertible
extension KMatrix: CustomStringConvertible {
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
