//
//  BoundingBoxDisplayView.swift
//  objDetectorTest
//
//  Created by Kim, Raymond on 2022/11/08.
//  Copyright © 2022 IntelligentATLAS. All rights reserved.
//

import Foundation
import UIKit
import Vision


class BoundingBoxDisplayView: UIView {
    // Empty array to store the center points of the bounding boxes
    var objectCenterCoordinates: [String: [CGFloat]] = [:]

    static private var colors: [String: UIColor] = [:]

    public func labelColor(with label: String) -> UIColor {
        if let color = BoundingBoxDisplayView.colors[label] {
            return color
        } else {
            let color = UIColor(hue: .random(in: 0...1), saturation: 1, brightness: 1, alpha: 0.8)
            BoundingBoxDisplayView.colors[label] = color
            return color
        }
    }

    public var predictedObjects: [VNRecognizedObjectObservation] = [] {
        didSet {
            self.drawBoxes(with: predictedObjects)
            self.setNeedsDisplay()
        }
    }

    func drawBoxes(with predictions: [VNRecognizedObjectObservation]) {
        subviews.forEach({ $0.removeFromSuperview() })

        for prediction in predictions {
            createLabelAndBox(prediction: prediction)
        }
    }

    func createLabelAndBox(prediction: VNRecognizedObjectObservation) {
        let labelString: String? = prediction.label
        let color: UIColor = labelColor(with: labelString ?? "N/A")

        let scale = CGAffineTransform.identity.scaledBy(x: bounds.width, y: bounds.height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let bgRect = prediction.boundingBox.applying(transform).applying(scale)

        let bgView = UIView(frame: bgRect)
        bgView.layer.borderColor = color.cgColor
        bgView.layer.borderWidth = 4
        bgView.backgroundColor = UIColor.clear
        addSubview(bgView)

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        label.text = labelString ?? "N/A"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.backgroundColor = color
        label.sizeToFit()
        label.frame = CGRect(x: bgRect.origin.x,
                             y: bgRect.origin.y - label.frame.height,
                             width: label.frame.width,
                             height: label.frame.height)
        addSubview(label)

        /// Create a dotView to track the object.
        let dotView = UIView(frame: CGRect(x: bgRect.midX - 2, y: bgRect.midY - 2, width: 4, height: 4))
        dotView.layer.borderColor = color.cgColor
        dotView.layer.borderWidth = 2
        dotView.backgroundColor = UIColor.clear
        addSubview(dotView)

        /// Store the object's center coordinates in the array, in the form of [label: [x coordinate, y coordinate]].
        objectCenterCoordinates[labelString!] = [bgRect.midX, bgRect.midY]

        /// Create a lineView to connect the center of the same object.
        let lineView = UIView(frame: CGRect(x: bgRect.midX, y: bgRect.midY, width: 0, height: 0))
        lineView.layer.borderColor = color.cgColor
        lineView.layer.borderWidth = 2
        lineView.backgroundColor = UIColor.clear
        addSubview(lineView)

        /// Update the center of the object as the object moves.
        objectCenterCoordinates[labelString!] = [bgRect.midX, bgRect.midY]

        /// Update the line as the object moves.
        lineView.frame = CGRect(x: objectCenterCoordinates[labelString!]![0],
                                y: objectCenterCoordinates[labelString!]![1],
                                width: bgRect.midX - objectCenterCoordinates[labelString!]![0],
                                height: bgRect.midY - objectCenterCoordinates[labelString!]![1])

        /// Remove the dot and the line when the object disappears.
        if prediction.confidence < 0.4 {
            dotView.removeFromSuperview()
            lineView.removeFromSuperview()
        }
    }
}

extension VNRecognizedObjectObservation {
    var label: String? {
        return self.labels.first?.identifier
    }
}

extension CGRect {
    func toString(digit: Int) -> String {
        let xStr = String(format: "%.\(digit)f", origin.x)
        let yStr = String(format: "%.\(digit)f", origin.y)
        let wStr = String(format: "%.\(digit)f", width)
        let hStr = String(format: "%.\(digit)f", height)
        return "(\(xStr), \(yStr), \(wStr), \(hStr))"
    }
}
